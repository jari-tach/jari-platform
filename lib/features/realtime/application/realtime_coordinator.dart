// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import '../../../core/services/logger/logger_service.dart';
import '../data/models/event_envelope_wire.dart';
import '../data/remote/driver_events_remote.dart';
import '../data/remote/sse_transport.dart';
import '../data/stores/last_event_cursor_store.dart';
import '../domain/entities/driver_event.dart';
import '../domain/entities/driver_event_type.dart';
import '../domain/entities/realtime_connection_status.dart';
import 'event_inbox.dart';
import 'reconnect_backoff.dart';

typedef TokenRefreshFn = Future<bool> Function();

/// Single realtime coordinator per authenticated driver session (STEP 6-B).
///
/// Transport policy:
/// 1. Prefer SSE (`GET /v1/events/stream`) with `Last-Event-ID`.
/// 2. On SSE failure, switch to polling (`GET /v1/events?after=`) — never
///    run both in parallel.
/// 3. After polling stabilizes, attempt to return to SSE.
/// 4. On background: pause. On resume: catch-up poll, then SSE.
///
/// Events are treated as invalidation signals — offer list truth stays REST.
final class RealtimeCoordinator {
  RealtimeCoordinator({
    required DriverEventsRemote remote,
    required LastEventCursorStore cursorStore,
    required LoggerService logger,
    required TokenRefreshFn onUnauthorizedRefresh,
    ReconnectBackoff? backoff,
    this.pollingInterval = const Duration(seconds: 5),
    this.sseFailureThreshold = 3,
  }) : _remote = remote,
       _cursorStore = cursorStore,
       _logger = logger,
       _onUnauthorizedRefresh = onUnauthorizedRefresh,
       _backoff = backoff ?? ReconnectBackoff();

  final DriverEventsRemote _remote;
  final LastEventCursorStore _cursorStore;
  final LoggerService _logger;
  final TokenRefreshFn _onUnauthorizedRefresh;
  final ReconnectBackoff _backoff;
  final Duration pollingInterval;
  final int sseFailureThreshold;

  final EventInbox _inbox = EventInbox();
  final StreamController<RealtimeConnectionStatus> _statusController =
      StreamController<RealtimeConnectionStatus>.broadcast();
  final StreamController<DriverEvent> _eventController =
      StreamController<DriverEvent>.broadcast();
  final StreamController<void> _offersInvalidatedController =
      StreamController<void>.broadcast();

  RealtimeConnectionStatus _status = RealtimeConnectionStatus.idle;
  String? _driverId;
  bool _running = false;
  bool _foreground = true;
  bool _usePolling = false;
  int _consecutiveSseFailures = 0;
  int _pollsSinceSseAttempt = 0;
  bool _refreshAttempted = false;
  StreamSubscription<EventEnvelopeWire>? _sseSub;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  int _loopGeneration = 0;

  Stream<RealtimeConnectionStatus> get statusChanges =>
      _statusController.stream;
  Stream<DriverEvent> get events => _eventController.stream;
  Stream<void> get offersInvalidated => _offersInvalidatedController.stream;
  RealtimeConnectionStatus get status => _status;
  EventInbox get inbox => _inbox;
  String? get driverId => _driverId;
  bool get isRunning => _running;
  bool get isUsingPolling => _usePolling;

  Future<void> start(String driverId) async {
    final trimmed = driverId.trim();
    if (trimmed.isEmpty) return;
    if (_running && _driverId == trimmed) return;

    await stop();
    _driverId = trimmed;
    _running = true;
    _foreground = true;
    _usePolling = false;
    _consecutiveSseFailures = 0;
    _pollsSinceSseAttempt = 0;
    _refreshAttempted = false;
    _backoff.reset();

    final stored = await _cursorStore.read(trimmed) ?? 0;
    _inbox.reset(boundDriverId: trimmed, initialSequence: stored);
    _setStatus(RealtimeConnectionStatus.reconnecting);
    _scheduleLoop();
  }

  Future<void> stop() async {
    _running = false;
    _loopGeneration++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _sseSub?.cancel();
    _sseSub = null;
    await _remote.closeStream();
    _driverId = null;
    _usePolling = false;
    _setStatus(RealtimeConnectionStatus.stopped);
  }

  /// Called on logout / account switch — closes everything.
  Future<void> onLogout() => stop();

  void onAppPaused() {
    if (!_running) return;
    _foreground = false;
    _loopGeneration++;
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    unawaited(_sseSub?.cancel());
    _sseSub = null;
    unawaited(_remote.closeStream());
  }

  Future<void> onAppResumed() async {
    if (!_running || _driverId == null) return;
    _foreground = true;
    _setStatus(RealtimeConnectionStatus.catchingUp);
    await _catchUp();
    if (!_running || !_foreground) return;
    _usePolling = false;
    _consecutiveSseFailures = 0;
    _backoff.reset();
    _scheduleLoop();
  }

  void _scheduleLoop({Duration delay = Duration.zero}) {
    if (!_running || !_foreground) return;
    final generation = ++_loopGeneration;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (generation != _loopGeneration) return;
      unawaited(_runTransport(generation));
    });
  }

  Future<void> _runTransport(int generation) async {
    if (!_running || !_foreground || generation != _loopGeneration) return;

    if (_usePolling) {
      _setStatus(RealtimeConnectionStatus.degraded);
      await _pollOnce();
      if (!_running || !_foreground || generation != _loopGeneration) return;
      _pollsSinceSseAttempt += 1;
      // Keep polling on an interval; every third tick try returning to SSE
      // without overlapping the two transports.
      if (_pollsSinceSseAttempt >= 3) {
        _pollsSinceSseAttempt = 0;
        _usePolling = false;
        _consecutiveSseFailures = 0;
        _backoff.reset();
        _scheduleLoop();
      } else {
        _scheduleLoop(delay: pollingInterval);
      }
      return;
    }

    _setStatus(
      _status == RealtimeConnectionStatus.connected
          ? RealtimeConnectionStatus.connected
          : RealtimeConnectionStatus.reconnecting,
    );
    await _openSse(generation);
  }

  Future<void> _openSse(int generation) async {
    await _sseSub?.cancel();
    _sseSub = null;
    await _remote.closeStream();

    final lastId = _inbox.lastSequence > 0 ? _inbox.lastSequence : null;
    final completer = Completer<void>();

    try {
      _sseSub = _remote
          .streamEvents(lastEventId: lastId)
          .listen(
            (wire) {
              if (generation != _loopGeneration) return;
              _consecutiveSseFailures = 0;
              _backoff.reset();
              _setStatus(RealtimeConnectionStatus.connected);
              unawaited(_handleWire(wire));
            },
            onError: (Object error) {
              if (generation != _loopGeneration) return;
              if (!completer.isCompleted) completer.completeError(error);
            },
            onDone: () {
              if (!completer.isCompleted) completer.complete();
            },
            cancelOnError: true,
          );
      await completer.future;
      if (!_running || generation != _loopGeneration) return;
      await _onSseFailure(generation, null);
    } catch (error) {
      if (!_running || generation != _loopGeneration) return;
      await _onSseFailure(generation, error);
    }
  }

  Future<void> _onSseFailure(int generation, Object? error) async {
    await _sseSub?.cancel();
    _sseSub = null;
    await _remote.closeStream();

    if (error is SseUnauthorizedException ||
        (error != null && error.toString().contains('unauthorized'))) {
      if (!_refreshAttempted) {
        _refreshAttempted = true;
        final ok = await _onUnauthorizedRefresh();
        if (ok && _running) {
          _scheduleLoop();
          return;
        }
        await stop();
        return;
      }
      await stop();
      return;
    }

    _consecutiveSseFailures += 1;
    if (_consecutiveSseFailures >= sseFailureThreshold) {
      _usePolling = true;
      _setStatus(RealtimeConnectionStatus.degraded);
      _scheduleLoop();
      return;
    }

    _setStatus(RealtimeConnectionStatus.reconnecting);
    final delay = _backoff.next();
    _scheduleLoop(delay: delay);
  }

  Future<void> _pollOnce() async {
    final driverId = _driverId;
    if (driverId == null) return;
    try {
      var page = await _remote.listEvents(after: _inbox.lastSequence);
      if (page.resyncRequired) {
        _notifyOffersInvalidated();
      }
      for (final wire in page.events) {
        await _handleWire(wire);
      }
      while (page.hasMore) {
        page = await _remote.listEvents(after: _inbox.lastSequence);
        for (final wire in page.events) {
          await _handleWire(wire);
        }
        if (page.events.isEmpty) break;
      }
    } catch (error) {
      _logger.debug('Realtime poll failed', error);
    }
  }

  Future<void> _catchUp() async {
    _pollTimer?.cancel();
    await _sseSub?.cancel();
    _sseSub = null;
    await _remote.closeStream();
    await _pollOnce();
  }

  Future<void> _handleWire(EventEnvelopeWire wire) async {
    final domain = wire.toDomainOrNull();
    if (domain == null) {
      // Unknown EventType — ignore safely for forward compatibility.
      _inbox.noteSequence(wire.sequence);
      await _persistCursor();
      return;
    }

    if (domain.eventType == DriverEventType.systemResyncRequired) {
      _inbox.noteSequence(domain.sequence);
      await _persistCursor();
      _notifyOffersInvalidated();
      if (!_eventController.isClosed) _eventController.add(domain);
      return;
    }

    final decision = _inbox.accept(domain);
    switch (decision) {
      case EventInboxDecision.accepted:
        await _persistCursor();
        if (!_eventController.isClosed) _eventController.add(domain);
        if (domain.eventType.invalidatesOffers) {
          _notifyOffersInvalidated();
        }
      case EventInboxDecision.staleAggregate:
        await _persistCursor();
      case EventInboxDecision.duplicate:
      case EventInboxDecision.staleSequence:
      case EventInboxDecision.foreignDriver:
        break;
    }
  }

  void _notifyOffersInvalidated() {
    if (!_offersInvalidatedController.isClosed) {
      _offersInvalidatedController.add(null);
    }
  }

  Future<void> _persistCursor() async {
    final driverId = _driverId;
    if (driverId == null) return;
    await _cursorStore.write(driverId, _inbox.lastSequence);
  }

  void _setStatus(RealtimeConnectionStatus next) {
    if (_status == next) return;
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  Future<void> dispose() async {
    await stop();
    await _statusController.close();
    await _eventController.close();
    await _offersInvalidatedController.close();
  }
}
