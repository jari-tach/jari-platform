import 'event_envelope_wire.dart';

/// Wire DTO for contracts-v0.2.0 `EventPage`.
final class EventPageWire {
  const EventPageWire({
    required this.events,
    required this.latestSequence,
    required this.hasMore,
    required this.resyncRequired,
  });

  final List<EventEnvelopeWire> events;
  final int latestSequence;
  final bool hasMore;
  final bool resyncRequired;

  factory EventPageWire.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'];
    final latestSequence = json['latestSequence'];
    final hasMore = json['hasMore'];
    final resyncRequired = json['resyncRequired'];

    if (eventsRaw is! List ||
        latestSequence is! int ||
        hasMore is! bool ||
        resyncRequired is! bool) {
      throw const FormatException('EventPageWire: invalid fields');
    }
    if (latestSequence < 0) {
      throw const FormatException('EventPageWire: latestSequence');
    }

    final events = eventsRaw
        .map(
          (e) =>
              EventEnvelopeWire.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(growable: false);

    return EventPageWire(
      events: events,
      latestSequence: latestSequence,
      hasMore: hasMore,
      resyncRequired: resyncRequired,
    );
  }
}
