import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/features/realtime/application/realtime_coordinator.dart';
import 'package:saeq_driver/features/realtime/application/reconnect_backoff.dart';
import 'package:saeq_driver/features/realtime/data/stores/last_event_cursor_store.dart';

import '../fakes/fake_driver_events_remote.dart';

/// Integration scenarios required by STEP 6-C acceptance:
/// delivery lifecycle events, availability sync, and the full
/// system.resync_required path across both transports.
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

  RealtimeCoordinator buildCoordinator(
    FakeDriverEventsRemote remote, {
    LastEventCursorStore? cursorStore,
    int sseFailureThreshold = 2,
  }) {
    return RealtimeCoordinator(
      remote: remote,
      cursorStore: cursorStore ?? MemoryLastEventCursorStore(),
      logger: _SilentLogger(),
      onUnauthorizedRefresh: () async => false,
      backoff: ReconnectBackoff(
        initial: const Duration(milliseconds: 1),
        maximum: const Duration(milliseconds: 5),
      ),
      pollingInterval: const Duration(milliseconds: 15),
      sseFailureThreshold: sseFailureThreshold,
    );
  }

  test(
    'integration: delivery.state_changed via SSE signals delivery resync',
    () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = buildCoordinator(remote);
      final deliverySignals = <int>[];
      final offerSignals = <int>[];
      coordinator.deliveryInvalidated.listen((_) => deliverySignals.add(1));
      coordinator.offersInvalidated.listen((_) => offerSignals.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      remote.emitSse(
        sampleEnvelope(
          sequence: 1,
          eventType: 'delivery.state_changed',
          aggregateType: 'delivery',
          payload: const {'driverId': 'drv-1', 'deliveryId': 'd-7'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(deliverySignals, hasLength(1));
      expect(offerSignals, isEmpty);
      await coordinator.dispose();
    },
  );

  test(
    'integration: delivery.cancelled arrives via polling fallback',
    () async {
      final remote = FakeDriverEventsRemote()..failNextSse = true;
      final coordinator = buildCoordinator(remote, sseFailureThreshold: 1);
      final deliverySignals = <int>[];
      coordinator.deliveryInvalidated.listen((_) => deliverySignals.add(1));

      await coordinator.start('drv-1');
      await _waitUntil(
        () => coordinator.isUsingPolling,
        timeout: const Duration(seconds: 2),
      );

      remote.polledEvents.add(
        sampleEnvelope(
          sequence: 2,
          eventType: 'delivery.cancelled',
          aggregateType: 'delivery',
          payload: const {'driverId': 'drv-1', 'deliveryId': 'd-7'},
        ),
      );
      await _waitUntil(
        () => deliverySignals.isNotEmpty,
        timeout: const Duration(seconds: 2),
      );

      expect(deliverySignals, isNotEmpty);
      expect(coordinator.inbox.lastSequence, 2);
      await coordinator.dispose();
    },
  );

  test(
    'integration: availability change on another device signals resync',
    () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = buildCoordinator(remote);
      final availabilitySignals = <int>[];
      coordinator.availabilityInvalidated.listen(
        (_) => availabilitySignals.add(1),
      );

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      remote.emitSse(
        sampleEnvelope(
          sequence: 3,
          eventType: 'driver.availability_changed',
          aggregateType: 'driver',
          aggregateId: 'drv-1',
          payload: const {'driverId': 'drv-1', 'available': false},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(availabilitySignals, hasLength(1));
      await coordinator.dispose();
    },
  );

  test('integration: system.resync_required resyncs offers, delivery and '
      'availability while preserving the cursor', () async {
    final remote = FakeDriverEventsRemote();
    final cursor = MemoryLastEventCursorStore();
    final coordinator = buildCoordinator(remote, cursorStore: cursor);
    final offers = <int>[];
    final delivery = <int>[];
    final availability = <int>[];
    coordinator.offersInvalidated.listen((_) => offers.add(1));
    coordinator.deliveryInvalidated.listen((_) => delivery.add(1));
    coordinator.availabilityInvalidated.listen((_) => availability.add(1));

    await coordinator.start('drv-1');
    await Future<void>.delayed(Duration.zero);
    remote.emitSse(
      sampleEnvelope(
        sequence: 9,
        eventType: 'system.resync_required',
        aggregateType: 'system',
        payload: const {},
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 25));

    expect(offers, hasLength(1));
    expect(delivery, hasLength(1));
    expect(availability, hasLength(1));
    expect(await cursor.read('drv-1'), 9);
    await coordinator.dispose();
  });

  test(
    'integration: retention overflow during polling triggers full resync',
    () async {
      final remote = FakeDriverEventsRemote()
        ..failNextSse = true
        ..resyncRequired = true;
      final coordinator = buildCoordinator(remote, sseFailureThreshold: 1);
      final offers = <int>[];
      final delivery = <int>[];
      final availability = <int>[];
      coordinator.offersInvalidated.listen((_) => offers.add(1));
      coordinator.deliveryInvalidated.listen((_) => delivery.add(1));
      coordinator.availabilityInvalidated.listen((_) => availability.add(1));

      await coordinator.start('drv-1');
      await _waitUntil(
        () => offers.isNotEmpty && delivery.isNotEmpty,
        timeout: const Duration(seconds: 2),
      );

      expect(offers, isNotEmpty);
      expect(delivery, isNotEmpty);
      expect(availability, isNotEmpty);
      await coordinator.dispose();
    },
  );

  test(
    'integration: no duplicate delivery signal across SSE→polling handoff',
    () async {
      final remote = FakeDriverEventsRemote();
      final coordinator = buildCoordinator(remote, sseFailureThreshold: 1);
      final deliverySignals = <int>[];
      coordinator.deliveryInvalidated.listen((_) => deliverySignals.add(1));

      await coordinator.start('drv-1');
      await Future<void>.delayed(Duration.zero);
      final envelope = sampleEnvelope(
        eventId: 'same-delivery-event',
        sequence: 4,
        eventType: 'delivery.state_changed',
        aggregateType: 'delivery',
        payload: const {'driverId': 'drv-1', 'deliveryId': 'd-7'},
      );
      remote.emitSse(envelope);
      await Future<void>.delayed(const Duration(milliseconds: 15));
      remote.polledEvents.add(envelope);
      remote.failSse();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(deliverySignals, hasLength(1));
      await coordinator.dispose();
    },
  );
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
