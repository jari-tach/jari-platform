import 'driver_event_type.dart';

/// Domain view of a sanitized Backend `EventEnvelope` (contracts-v0.2.0).
///
/// Payloads never carry customer PII. Events are read-only notifications —
/// the authoritative offer list remains REST `GET /v1/offers`.
final class DriverEvent {
  const DriverEvent({
    required this.eventId,
    required this.sequence,
    required this.eventType,
    required this.occurredAt,
    required this.aggregateType,
    required this.aggregateId,
    required this.aggregateVersion,
    required this.correlationId,
    required this.payloadVersion,
    required this.payload,
  });

  final String eventId;
  final int sequence;
  final DriverEventType eventType;
  final DateTime occurredAt;
  final String aggregateType;
  final String aggregateId;
  final int aggregateVersion;
  final String correlationId;
  final int payloadVersion;
  final Map<String, Object?> payload;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverEvent &&
          eventId == other.eventId &&
          sequence == other.sequence;

  @override
  int get hashCode => Object.hash(eventId, sequence);

  @override
  String toString() =>
      'DriverEvent(type: ${eventType.wireValue}, seq: $sequence, id: $eventId)';
}
