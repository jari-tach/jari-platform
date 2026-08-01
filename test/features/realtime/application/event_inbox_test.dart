import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/realtime/application/event_inbox.dart';
import 'package:saeq_driver/features/realtime/domain/entities/driver_event.dart';
import 'package:saeq_driver/features/realtime/domain/entities/driver_event_type.dart';

DriverEvent _event({
  String eventId = 'e1',
  int sequence = 1,
  DriverEventType type = DriverEventType.offerCreated,
  String aggregateType = 'offer',
  String aggregateId = 'offer-1',
  int aggregateVersion = 1,
  Map<String, Object?> payload = const {},
}) {
  return DriverEvent(
    eventId: eventId,
    sequence: sequence,
    eventType: type,
    occurredAt: DateTime.utc(2026, 7, 31),
    aggregateType: aggregateType,
    aggregateId: aggregateId,
    aggregateVersion: aggregateVersion,
    correlationId: 'c1',
    payloadVersion: 1,
    payload: payload,
  );
}

void main() {
  group('EventInbox', () {
    test('accepts increasing sequences and advances cursor', () {
      final inbox = EventInbox(boundDriverId: 'drv-1');
      expect(
        inbox.accept(_event(eventId: 'a', sequence: 1, aggregateVersion: 1)),
        EventInboxDecision.accepted,
      );
      expect(
        inbox.accept(_event(eventId: 'b', sequence: 2, aggregateVersion: 2)),
        EventInboxDecision.accepted,
      );
      expect(inbox.lastSequence, 2);
    });

    test('deduplicates by eventId and sequence', () {
      final inbox = EventInbox(boundDriverId: 'drv-1');
      expect(
        inbox.accept(_event(eventId: 'a', sequence: 1)),
        EventInboxDecision.accepted,
      );
      expect(
        inbox.accept(_event(eventId: 'a', sequence: 2)),
        EventInboxDecision.duplicate,
      );
      expect(
        inbox.accept(_event(eventId: 'b', sequence: 1)),
        EventInboxDecision.duplicate,
      );
    });

    test('rejects stale sequences', () {
      final inbox = EventInbox(boundDriverId: 'drv-1', initialSequence: 5);
      expect(
        inbox.accept(_event(eventId: 'a', sequence: 5)),
        EventInboxDecision.staleSequence,
      );
      expect(
        inbox.accept(_event(eventId: 'b', sequence: 4)),
        EventInboxDecision.staleSequence,
      );
    });

    test('filters foreign driverId in payload', () {
      final inbox = EventInbox(boundDriverId: 'drv-1');
      expect(
        inbox.accept(
          _event(
            eventId: 'a',
            sequence: 1,
            payload: const {'driverId': 'drv-other'},
          ),
        ),
        EventInboxDecision.foreignDriver,
      );
      expect(inbox.lastSequence, 0);
    });

    test('filters foreign driver aggregate', () {
      final inbox = EventInbox(boundDriverId: 'drv-1');
      expect(
        inbox.accept(
          _event(
            eventId: 'a',
            sequence: 1,
            aggregateType: 'driver',
            aggregateId: 'drv-other',
            type: DriverEventType.driverAvailabilityChanged,
          ),
        ),
        EventInboxDecision.foreignDriver,
      );
    });

    test('stale aggregateVersion advances cursor but does not accept', () {
      final inbox = EventInbox(boundDriverId: 'drv-1');
      expect(
        inbox.accept(_event(eventId: 'a', sequence: 1, aggregateVersion: 5)),
        EventInboxDecision.accepted,
      );
      expect(
        inbox.accept(_event(eventId: 'b', sequence: 2, aggregateVersion: 5)),
        EventInboxDecision.staleAggregate,
      );
      expect(inbox.lastSequence, 2);
      expect(
        inbox.accept(_event(eventId: 'c', sequence: 3, aggregateVersion: 4)),
        EventInboxDecision.staleAggregate,
      );
      expect(
        inbox.accept(_event(eventId: 'd', sequence: 4, aggregateVersion: 6)),
        EventInboxDecision.accepted,
      );
    });

    test(
      'noteSequence advances cursor for unknown types without aggregates',
      () {
        final inbox = EventInbox(boundDriverId: 'drv-1');
        inbox.noteSequence(9);
        expect(inbox.lastSequence, 9);
        expect(
          inbox.accept(_event(eventId: 'a', sequence: 9)),
          EventInboxDecision.staleSequence,
        );
      },
    );
  });
}
