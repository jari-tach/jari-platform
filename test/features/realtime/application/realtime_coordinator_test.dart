import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/features/realtime/application/realtime_coordinator.dart';
import 'package:saeq_driver/features/realtime/application/reconnect_backoff.dart';
import 'package:saeq_driver/features/realtime/data/remote/sse_transport.dart';
import 'package:saeq_driver/features/realtime/data/stores/last_event_cursor_store.dart';
import 'package:saeq_driver/features/realtime/domain/entities/driver_event_type.dart';
import 'package:saeq_driver/features/realtime/domain/entities/realtime_connection_status.dart';

import '../fakes/fake_driver_events_remote.dart';

class _SilentLogger implements LoggerService {
  LogLevel _level = LogLevel.debug;

  @override
  LogLevel get level => _level;

  @override
  set level(LogLevel value) => _level = value;

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}
}

RealtimeCoordinator _build({
  required FakeDriverEventsRemote remote,
  LastEventCursorStore? cursorStore,
  ReconnectBackoff? backoff,
  TokenRefreshFn? onUnauthorizedRefresh,
  Duration pollingInterval = const Duration(milliseconds: 20),
  int sseFailureThreshold = 3,
}) {
  return RealtimeCoordinator(
    remote: remote,
    cursorStore: cursorStore ?? MemoryLastEventCursorStore(),
    logger: _SilentLogger(),
    onUnauthorizedRefresh: onUnauthorizedRefresh ?? () async => false,
    backoff:
        backoff ??
        ReconnectBackoff(
          initial: const Duration(milliseconds: 10),
          maximum: const Duration(milliseconds: 40),
          random: null,
        ),
    pollingInterval: pollingInterval,
    sseFailureThreshold: sseFailureThreshold,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealtimeCoordinator', () {
    test(
      'SSE offer.created invalidates offers and persists Last-Event-ID',
      () async {
        final remote = FakeDriverEventsRemote();
        final cursor = MemoryLastEventCursorStore();
        final coordinator = _build(remote: remote, cursorStore: cursor);

        final invalidated = <int>[];
        coordinator.offersInvalidated.listen((_) => invalidated.add(1));

        await coordinator.start('drv-1');
        await Future<void>.delayed(Duration.zero);
        expect(remote.streamOpenCount, 1);
        expect(remote.streamLastEventIds.single, isNull);

        remote.emitSse(
          sampleEnvelope(
            sequence: 11,
            eventType: 'offer.created',
            payload: const {'driverId': 'drv-1', 'offerId': 'o-1'},
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(coordinator.status, RealtimeConnectionStatus.connected);
        expect(invalidated, hasLength(1));
        expect(await cursor.read('drv-1'), 11);
        expect(coordinator.inbox.lastSequence, 11);

        await coordinator.dispose();
      },
    );

    test('reconnects with Last-Event-ID after SSE drop', () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = _build(
        remote: remote,
        backoff: ReconnectBackoff(
          initial: const Duration(milliseconds: 5),
          maximum: const Duration(milliseconds: 5),
          random: null,
        ),
        sseFailureThreshold: 10,
      );

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      remote.emitSse(sampleEnvelope(sequence: 5));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      remote.failSse();
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(remote.streamOpenCount, greaterThanOrEqualTo(2));
      expect(remote.streamLastEventIds.last, 5);

      await coordinator.dispose();
    });

    test('falls back to polling after SSE failure threshold', () async {
      final remote = FakeDriverEventsRemote()..failNextSse = true;
      final coordinator = _build(
        remote: remote,
        backoff: ReconnectBackoff(
          initial: const Duration(milliseconds: 1),
          maximum: const Duration(milliseconds: 1),
          random: null,
        ),
        sseFailureThreshold: 2,
        pollingInterval: const Duration(milliseconds: 15),
      );

      final invalidated = <int>[];
      coordinator.offersInvalidated.listen((_) => invalidated.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(coordinator.isUsingPolling, isTrue);
      expect(coordinator.status, RealtimeConnectionStatus.degraded);

      remote.failNextSse = false;
      remote.polledEvents.add(
        sampleEnvelope(
          sequence: 3,
          eventType: 'offer.created',
          payload: const {'driverId': 'drv-1'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(invalidated, isNotEmpty);
      expect(remote.pollAfterCalls, isNotEmpty);

      await coordinator.dispose();
    });

    test('does not duplicate events across SSE then polling', () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = _build(
        remote: remote,
        sseFailureThreshold: 1,
        backoff: ReconnectBackoff(
          initial: const Duration(milliseconds: 1),
          maximum: const Duration(milliseconds: 1),
          random: null,
        ),
        pollingInterval: const Duration(milliseconds: 20),
      );

      final acceptedTypes = <DriverEventType>[];
      coordinator.events.listen((e) => acceptedTypes.add(e.eventType));
      final invalidated = <int>[];
      coordinator.offersInvalidated.listen((_) => invalidated.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);

      final envelope = sampleEnvelope(
        eventId: 'dup-1',
        sequence: 8,
        eventType: 'offer.created',
        payload: const {'driverId': 'drv-1'},
      );
      remote.emitSse(envelope);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      remote.polledEvents.add(envelope);
      remote.failSse();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(
        acceptedTypes.where((t) => t == DriverEventType.offerCreated),
        hasLength(1),
      );
      expect(invalidated, hasLength(1));

      await coordinator.dispose();
    });

    test('offer.expired invalidates offers for list refresh/removal', () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = _build(remote: remote);
      final invalidated = <int>[];
      coordinator.offersInvalidated.listen((_) => invalidated.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      remote.emitSse(
        sampleEnvelope(
          sequence: 2,
          eventType: 'offer.expired',
          payload: const {'driverId': 'drv-1', 'offerId': 'o-9'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(invalidated, hasLength(1));
      await coordinator.dispose();
    });

    test('catch-up poll on resume then restores SSE', () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = _build(remote: remote);

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      final opensBeforePause = remote.streamOpenCount;

      coordinator.onAppPaused();
      remote.polledEvents.add(
        sampleEnvelope(
          sequence: 4,
          eventType: 'offer.created',
          payload: const {'driverId': 'drv-1'},
        ),
      );

      final invalidated = <int>[];
      coordinator.offersInvalidated.listen((_) => invalidated.add(1));

      await coordinator.onAppResumed();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(remote.pollAfterCalls, isNotEmpty);
      expect(invalidated, hasLength(1));
      expect(remote.streamOpenCount, greaterThan(opensBeforePause));
      expect(coordinator.isUsingPolling, isFalse);

      await coordinator.dispose();
    });

    test('logout closes stream and timers', () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = _build(remote: remote);

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      expect(coordinator.isRunning, isTrue);

      await coordinator.onLogout();
      expect(coordinator.isRunning, isFalse);
      expect(coordinator.status, RealtimeConnectionStatus.stopped);
      expect(remote.closeCount, greaterThan(0));
      expect(coordinator.driverId, isNull);

      await coordinator.dispose();
    });

    test('ignores unknown EventType safely while advancing cursor', () async {
      final remote = FakeDriverEventsRemote();
      final cursor = MemoryLastEventCursorStore();
      final coordinator = _build(remote: remote, cursorStore: cursor);
      final accepted = <int>[];
      coordinator.events.listen((_) => accepted.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      remote.emitSse(
        sampleEnvelope(sequence: 6, eventType: 'offer.brand_new_type'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(accepted, isEmpty);
      expect(await cursor.read('drv-1'), 6);
      await coordinator.dispose();
    });

    test('rejects foreign driver events', () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = _build(remote: remote);
      final invalidated = <int>[];
      coordinator.offersInvalidated.listen((_) => invalidated.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      remote.emitSse(
        sampleEnvelope(
          sequence: 1,
          eventType: 'offer.created',
          payload: const {'driverId': 'drv-other'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(invalidated, isEmpty);
      expect(coordinator.inbox.lastSequence, 0);
      await coordinator.dispose();
    });

    test('401 refresh succeeds once then resumes; second 401 stops', () async {
      final remote = FakeDriverEventsRemote();
      var refreshCalls = 0;
      final coordinator = _build(
        remote: remote,
        onUnauthorizedRefresh: () async {
          refreshCalls += 1;
          return refreshCalls == 1;
        },
        backoff: ReconnectBackoff(
          initial: const Duration(milliseconds: 1),
          maximum: const Duration(milliseconds: 1),
          random: null,
        ),
      );

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      remote.failSse(const SseUnauthorizedException('expired'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(refreshCalls, 1);
      expect(coordinator.isRunning, isTrue);

      remote.failSse(const SseUnauthorizedException('expired again'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(coordinator.isRunning, isFalse);

      await coordinator.dispose();
    });

    test('stale aggregateVersion does not re-invalidate offers', () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = _build(remote: remote);
      final invalidated = <int>[];
      coordinator.offersInvalidated.listen((_) => invalidated.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);

      remote.emitSse(
        sampleEnvelope(
          eventId: 'a',
          sequence: 1,
          aggregateVersion: 5,
          eventType: 'offer.created',
          payload: const {'driverId': 'drv-1'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 15));
      remote.emitSse(
        sampleEnvelope(
          eventId: 'b',
          sequence: 2,
          aggregateVersion: 4,
          eventType: 'offer.created',
          payload: const {'driverId': 'drv-1'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 15));

      expect(invalidated, hasLength(1));
      expect(coordinator.inbox.lastSequence, 2);
      await coordinator.dispose();
    });
  });
}
