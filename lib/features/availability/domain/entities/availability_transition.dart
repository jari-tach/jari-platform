import 'availability_status.dart';

/// Ephemeral transition request record (PHASE 2.4).
class AvailabilityTransition {
  const AvailabilityTransition({
    required this.from,
    required this.to,
    required this.actor,
    required this.requestedAt,
    this.reason,
    this.correlationId,
  });

  final AvailabilityStatus from;
  final AvailabilityStatus to;
  final AvailabilityActor actor;
  final DateTime requestedAt;
  final String? reason;
  final String? correlationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityTransition &&
          from == other.from &&
          to == other.to &&
          actor == other.actor &&
          requestedAt == other.requestedAt &&
          reason == other.reason &&
          correlationId == other.correlationId;

  @override
  int get hashCode =>
      Object.hash(from, to, actor, requestedAt, reason, correlationId);
}
