import 'availability_eligibility_input.dart';
import 'availability_status.dart';
import '../failures/availability_failure.dart';

/// Structured eligibility result — never a bare bool (PHASE 2.4).
class AvailabilityEligibilityDecision {
  const AvailabilityEligibilityDecision({
    required this.allowed,
    required this.effectiveStatus,
    required this.retryable,
    required this.requiredAction,
    required this.policyVersion,
    this.failure,
  });

  factory AvailabilityEligibilityDecision.allow({
    required String policyVersion,
  }) => AvailabilityEligibilityDecision(
    allowed: true,
    effectiveStatus: AvailabilityStatus.available,
    retryable: false,
    requiredAction: AvailabilityRequiredAction.none,
    policyVersion: policyVersion,
  );

  factory AvailabilityEligibilityDecision.deny({
    required AvailabilityFailure failure,
    required AvailabilityStatus effectiveStatus,
    required bool retryable,
    required AvailabilityRequiredAction requiredAction,
    required String policyVersion,
  }) => AvailabilityEligibilityDecision(
    allowed: false,
    failure: failure,
    effectiveStatus: effectiveStatus,
    retryable: retryable,
    requiredAction: requiredAction,
    policyVersion: policyVersion,
  );

  final bool allowed;
  final AvailabilityFailure? failure;
  final AvailabilityStatus effectiveStatus;
  final bool retryable;
  final AvailabilityRequiredAction requiredAction;
  final String policyVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityEligibilityDecision &&
          allowed == other.allowed &&
          failure == other.failure &&
          effectiveStatus == other.effectiveStatus &&
          retryable == other.retryable &&
          requiredAction == other.requiredAction &&
          policyVersion == other.policyVersion;

  @override
  int get hashCode => Object.hash(
    allowed,
    failure,
    effectiveStatus,
    retryable,
    requiredAction,
    policyVersion,
  );
}
