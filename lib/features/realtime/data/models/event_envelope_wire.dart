import '../../domain/entities/driver_event.dart';
import '../../domain/entities/driver_event_type.dart';

/// Wire DTO for contracts-v0.2.0 `EventEnvelope`.
final class EventEnvelopeWire {
  const EventEnvelopeWire({
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
  final String eventType;
  final DateTime occurredAt;
  final String aggregateType;
  final String aggregateId;
  final int aggregateVersion;
  final String correlationId;
  final int payloadVersion;
  final Map<String, Object?> payload;

  factory EventEnvelopeWire.fromJson(Map<String, dynamic> json) {
    final eventId = json['eventId'];
    final sequence = json['sequence'];
    final eventType = json['eventType'];
    final occurredAtRaw = json['occurredAt'];
    final aggregateType = json['aggregateType'];
    final aggregateId = json['aggregateId'];
    final aggregateVersion = json['aggregateVersion'];
    final correlationId = json['correlationId'];
    final payloadVersion = json['payloadVersion'];
    final payloadRaw = json['payload'];

    if (eventId is! String ||
        sequence is! int ||
        eventType is! String ||
        occurredAtRaw is! String ||
        aggregateType is! String ||
        aggregateId is! String ||
        aggregateVersion is! int ||
        correlationId is! String ||
        payloadVersion is! int ||
        payloadRaw is! Map) {
      throw const FormatException('EventEnvelopeWire: invalid fields');
    }
    if (sequence < 1 || aggregateVersion < 0 || payloadVersion < 1) {
      throw const FormatException('EventEnvelopeWire: numeric bounds');
    }
    final occurredAt = DateTime.tryParse(occurredAtRaw);
    if (occurredAt == null) {
      throw const FormatException('EventEnvelopeWire: occurredAt');
    }

    return EventEnvelopeWire(
      eventId: eventId,
      sequence: sequence,
      eventType: eventType,
      occurredAt: occurredAt.toUtc(),
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      aggregateVersion: aggregateVersion,
      correlationId: correlationId,
      payloadVersion: payloadVersion,
      payload: Map<String, Object?>.from(payloadRaw),
    );
  }

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'sequence': sequence,
    'eventType': eventType,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'aggregateType': aggregateType,
    'aggregateId': aggregateId,
    'aggregateVersion': aggregateVersion,
    'correlationId': correlationId,
    'payloadVersion': payloadVersion,
    'payload': payload,
  };

  /// Returns `null` when [eventType] is unknown (forward-compatible ignore).
  DriverEvent? toDomainOrNull() {
    final type = DriverEventType.tryParse(eventType);
    if (type == null) return null;
    return DriverEvent(
      eventId: eventId,
      sequence: sequence,
      eventType: type,
      occurredAt: occurredAt,
      aggregateType: aggregateType,
      aggregateId: aggregateId,
      aggregateVersion: aggregateVersion,
      correlationId: correlationId,
      payloadVersion: payloadVersion,
      payload: payload,
    );
  }
}
