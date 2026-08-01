import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/features/realtime/application/realtime_coordinator.dart';
import 'package:saeq_driver/features/realtime/application/reconnect_backoff.dart';
import 'package:saeq_driver/features/realtime/data/stores/last_event_cursor_store.dart';
import 'package:saeq_driver/features/realtime/domain/entities/realtime_connection_status.dart';

import '../fakes/fake_driver_events_remote.dart';

/// Integration scenarios required by STEP 6-B acceptance.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RealtimeCoordinator buildCoordinator(FakeDriverEventsRemote remote) {
    return RealtimeCoordinator(
      remote: remote,
      cursorStore: MemoryLastEventCursorStore(),
      logger: _SilentLogger(),
      onUnauthorizedRefresh: () async => false,
      backoff: ReconnectBackoff(
        initial: const Duration(milliseconds: 5),
        maximum: const Duration(milliseconds: 10),
      ),
      pollingInterval: const Duration(milliseconds: 20),
      sseFailureThreshold: 2,
    );
  }

  test('integration: new offer via SSE triggers offers invalidation', () async {
    final remote = FakeDriverEventsRemote();
    final coordinator = buildCoordinator(remote);
    final refreshSignals = <String>[];
    coordinator.offersInvalidated.listen((_) => refreshSignals.add('refresh'));

    await coordinator.start('drv-1');
    await Future<void>.delayed(Duration.zero);
    remote.emitSse(
      sampleEnvelope(
        sequence: 1,
        eventType: 'offer.created',
        payload: const {'driverId': 'drv-1', 'offerId': 'offer-new'},
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(refreshSignals, ['refresh']);
    expect(coordinator.status, RealtimeConnectionStatus.connected);
    await coordinator.dispose();
  });

  test(
    'integration: SSE outage is recovered via polling without loss',
    () async {
      final remote = FakeDriverEventsRemote()..failNextSse = true;
      final coordinator = RealtimeCoordinator(
        remote: remote,
        cursorStore: MemoryLastEventCursorStore(),
        logger: _SilentLogger(),
        onUnauthorizedRefresh: () async => false,
        backoff: ReconnectBackoff(
          initial: const Duration(milliseconds: 1),
          maximum: const Duration(milliseconds: 1),
        ),
        pollingInterval: const Duration(milliseconds: 10),
        sseFailureThreshold: 1,
      );
      final refreshSignals = <int>[];
      coordinator.offersInvalidated.listen((_) => refreshSignals.add(1));

      await coordinator.start('drv-1');
      await _waitUntil(
        () => coordinator.isUsingPolling,
        timeout: const Duration(seconds: 2),
      );

      remote.failNextSse = false;
      remote.polledEvents.add(
        sampleEnvelope(
          sequence: 2,
          eventType: 'offer.created',
          payload: const {'driverId': 'drv-1'},
        ),
      );
      await _waitUntil(
        () => refreshSignals.isNotEmpty,
        timeout: const Duration(seconds: 2),
      );

      expect(refreshSignals, isNotEmpty);
      await coordinator.dispose();
    },
  );

  test('integration: Last-Event-ID resume after reconnect', () async {
    final remote = FakeDriverEventsRemote();
    final coordinator = buildCoordinator(remote);

    await coordinator.start('drv-1');
    await Future<void>.delayed(Duration.zero);
    remote.emitSse(sampleEnvelope(sequence: 17));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    remote.failSse();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(remote.streamLastEventIds.contains(17), isTrue);
    await coordinator.dispose();
  });

  test('integration: no duplicate offer after SSE→Polling handoff', () async {
    final remote = FakeDriverEventsRemote();
    final coordinator = RealtimeCoordinator(
      remote: remote,
      cursorStore: MemoryLastEventCursorStore(),
      logger: _SilentLogger(),
      onUnauthorizedRefresh: () async => false,
      backoff: ReconnectBackoff(
        initial: const Duration(milliseconds: 1),
        maximum: const Duration(milliseconds: 1),
      ),
      pollingInterval: const Duration(milliseconds: 15),
      sseFailureThreshold: 1,
    );

    final refreshes = <int>[];
    coordinator.offersInvalidated.listen((_) => refreshes.add(1));

    await coordinator.start('drv-1');
    await Future<void>.delayed(Duration.zero);
    final envelope = sampleEnvelope(
      eventId: 'same-event',
      sequence: 9,
      eventType: 'offer.created',
      payload: const {'driverId': 'drv-1'},
    );
    remote.emitSse(envelope);
    await Future<void>.delayed(const Duration(milliseconds: 15));
    remote.polledEvents.add(envelope);
    remote.failSse();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(refreshes, hasLength(1));
    await coordinator.dispose();
  });

  test('integration: offer.expired removes via refresh signal', () async {
    final remote = FakeDriverEventsRemote();
    final coordinator = buildCoordinator(remote);
    final refreshes = <String>[];
    coordinator.offersInvalidated.listen((_) => refreshes.add('expired'));

    await coordinator.start('drv-1');
    await Future<void>.delayed(Duration.zero);
    remote.emitSse(
      sampleEnvelope(
        sequence: 3,
        eventType: 'offer.expired',
        payload: const {'driverId': 'drv-1', 'offerId': 'gone'},
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(refreshes, ['expired']);
    await coordinator.dispose();
  });

  test('integration: background pause + resume catch-up', () async {
    final remote = FakeDriverEventsRemote();
    final coordinator = buildCoordinator(remote);
    final refreshes = <int>[];

    await coordinator.start('drv-1');
    await Future<void>.delayed(Duration.zero);
    coordinator.onAppPaused();

    remote.polledEvents.add(
      sampleEnvelope(
        sequence: 4,
        eventType: 'offer.created',
        payload: const {'driverId': 'drv-1'},
      ),
    );
    coordinator.offersInvalidated.listen((_) => refreshes.add(1));
    await coordinator.onAppResumed();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(remote.pollAfterCalls, isNotEmpty);
    expect(refreshes, hasLength(1));
    expect(coordinator.status, isNot(RealtimeConnectionStatus.catchingUp));
    await coordinator.dispose();
  });

  test('integration: session end closes the channel', () async {
    final remote = FakeDriverEventsRemote();
    final coordinator = buildCoordinator(remote);

    await coordinator.start('drv-1');
    await Future<void>.delayed(Duration.zero);
    await coordinator.onLogout();

    expect(coordinator.isRunning, isFalse);
    expect(coordinator.status, RealtimeConnectionStatus.stopped);
    expect(remote.closeCount, greaterThan(0));
    await coordinator.dispose();
  });
}

Future<void> _waitUntil(
  bool Function() predicate, {
  required Duration timeout,
  Duration step = const Duration(milliseconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (predicate()) return;
    await Future<void>.delayed(step);
  }
  if (!predicate()) {
    fail('Condition not met within $timeout');
  }
}
