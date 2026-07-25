import '../entities/availability_status.dart';
import '../failures/availability_failure.dart';

/// Structured transition-policy result — expected denials are not throws.
class AvailabilityTransitionDecision {
  const AvailabilityTransitionDecision({
    required this.allowed,
    required this.policyVersion,
    this.failure,
    this.idempotent = false,
  });

  factory AvailabilityTransitionDecision.allow({
    required String policyVersion,
    bool idempotent = false,
  }) => AvailabilityTransitionDecision(
    allowed: true,
    policyVersion: policyVersion,
    idempotent: idempotent,
  );

  factory AvailabilityTransitionDecision.deny({
    required AvailabilityFailure failure,
    required String policyVersion,
  }) => AvailabilityTransitionDecision(
    allowed: false,
    failure: failure,
    policyVersion: policyVersion,
  );

  final bool allowed;
  final AvailabilityFailure? failure;
  final bool idempotent;
  final String policyVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityTransitionDecision &&
          allowed == other.allowed &&
          failure == other.failure &&
          idempotent == other.idempotent &&
          policyVersion == other.policyVersion;

  @override
  int get hashCode => Object.hash(allowed, failure, idempotent, policyVersion);
}

/// Context for [AvailabilityTransitionPolicy] (no I/O).
class AvailabilityTransitionContext {
  const AvailabilityTransitionContext({
    required this.current,
    required this.requested,
    required this.actor,
    this.hasActiveAssignment = false,
    this.assignmentAllowsAvailable = false,
    this.connectivityOnline = true,
  });

  final AvailabilityStatus current;
  final AvailabilityStatus requested;
  final AvailabilityActor actor;
  final bool hasActiveAssignment;

  /// When leaving busy toward available, system/backend must set true.
  final bool assignmentAllowsAvailable;
  final bool connectivityOnline;
}
