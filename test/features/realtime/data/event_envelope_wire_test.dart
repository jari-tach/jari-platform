import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/realtime/data/models/event_envelope_wire.dart';
import 'package:saeq_driver/features/realtime/domain/entities/driver_event_type.dart';

void main() {
  group('EventEnvelopeWire', () {
    final validJson = <String, dynamic>{
      'eventId': '00000000-0000-4000-8000-000000000050',
      'sequence': 1042,
      'eventType': 'offer.created',
      'occurredAt': '2026-07-31T12:00:00Z',
      'aggregateType': 'offer',
      'aggregateId': '00000000-0000-4000-8000-000000000010',
      'aggregateVersion': 3,
      'correlationId': '00000000-0000-4000-8000-000000000002',
      'payloadVersion': 1,
      'payload': <String, Object?>{'offerId': 'offer-1'},
    };

    test('parses a contracts-v0.2.0 EventEnvelope', () {
      final wire = EventEnvelopeWire.fromJson(validJson);
      expect(wire.eventId, validJson['eventId']);
      expect(wire.sequence, 1042);
      expect(wire.eventType, 'offer.created');
      expect(wire.aggregateVersion, 3);
      expect(wire.payload['offerId'], 'offer-1');
    });

    test('toDomainOrNull maps known EventType values', () {
      for (final type in DriverEventType.values) {
        final wire = EventEnvelopeWire.fromJson({
          ...validJson,
          'eventType': type.wireValue,
        });
        final domain = wire.toDomainOrNull();
        expect(domain, isNotNull);
        expect(domain!.eventType, type);
      }
    });

    test('toDomainOrNull returns null for unknown EventType', () {
      final wire = EventEnvelopeWire.fromJson({
        ...validJson,
        'eventType': 'offer.future_unknown',
      });
      expect(wire.toDomainOrNull(), isNull);
    });

    test('rejects invalid envelopes', () {
      expect(
        () => EventEnvelopeWire.fromJson({...validJson, 'sequence': 0}),
        throwsFormatException,
      );
      expect(
        () => EventEnvelopeWire.fromJson({...validJson, 'eventId': 1}),
        throwsFormatException,
      );
    });
  });
}
