import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/realtime/data/models/event_page_wire.dart';

void main() {
  group('EventPageWire', () {
    test('parses EventPage with nested envelopes', () {
      final page = EventPageWire.fromJson({
        'events': [
          {
            'eventId': '00000000-0000-4000-8000-000000000050',
            'sequence': 1,
            'eventType': 'offer.created',
            'occurredAt': '2026-07-31T12:00:00Z',
            'aggregateType': 'offer',
            'aggregateId': '00000000-0000-4000-8000-000000000010',
            'aggregateVersion': 1,
            'correlationId': '00000000-0000-4000-8000-000000000002',
            'payloadVersion': 1,
            'payload': <String, Object?>{},
          },
        ],
        'latestSequence': 1,
        'hasMore': false,
        'resyncRequired': false,
      });

      expect(page.events, hasLength(1));
      expect(page.latestSequence, 1);
      expect(page.hasMore, isFalse);
      expect(page.resyncRequired, isFalse);
    });

    test('rejects invalid EventPage shapes', () {
      expect(
        () => EventPageWire.fromJson({
          'events': <Object>[],
          'latestSequence': -1,
          'hasMore': false,
          'resyncRequired': false,
        }),
        throwsFormatException,
      );
    });
  });
}
