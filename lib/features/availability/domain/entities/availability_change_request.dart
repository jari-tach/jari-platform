import 'availability_eligibility_input.dart';
import 'availability_status.dart';

/// Client/system request to change operational availability (domain only).
///
/// Does not imply Backend confirmation. Enforces shape invariants only —
/// transition policy (e.g. driver→busy) is evaluated by use cases.
class AvailabilityChangeRequest {
  AvailabilityChangeRequest({
    required this.driverId,
    required this.requestedStatus,
    required this.actor,
    required this.requestedAt,
    this.reason,
    this.correlationId,
    this.eligibilityInput,
    this.hasActiveAssignment = false,
    this.assignmentAllowsAvailable = false,
    this.connectivityOnline = true,
  }) {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    if (correlationId != null && correlationId!.trim().isEmpty) {
      throw ArgumentError.value(
        correlationId,
        'correlationId',
        'when present must be non-empty',
      );
    }
  }

  final String driverId;
  final AvailabilityStatus requestedStatus;
  final AvailabilityActor actor;
  final DateTime requestedAt;
  final String? reason;
  final String? correlationId;

  /// Required by use case when [requestedStatus] is available.
  final AvailabilityEligibilityInput? eligibilityInput;

  final bool hasActiveAssignment;
  final bool assignmentAllowsAvailable;
  final bool connectivityOnline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityChangeRequest &&
          driverId == other.driverId &&
          requestedStatus == other.requestedStatus &&
          actor == other.actor &&
          requestedAt == other.requestedAt &&
          reason == other.reason &&
          correlationId == other.correlationId &&
          eligibilityInput == other.eligibilityInput &&
          hasActiveAssignment == other.hasActiveAssignment &&
          assignmentAllowsAvailable == other.assignmentAllowsAvailable &&
          connectivityOnline == other.connectivityOnline;

  @override
  int get hashCode => Object.hash(
    driverId,
    requestedStatus,
    actor,
    requestedAt,
    reason,
    correlationId,
    eligibilityInput,
    hasActiveAssignment,
    assignmentAllowsAvailable,
    connectivityOnline,
  );
}
