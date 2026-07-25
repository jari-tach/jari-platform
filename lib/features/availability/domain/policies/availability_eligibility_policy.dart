import '../../../profile/domain/entities/driver_status.dart';
import '../entities/availability_eligibility_decision.dart';
import '../entities/availability_eligibility_input.dart';
import '../entities/availability_status.dart';
import '../failures/availability_failure.dart';

/// Pure eligibility for confirmed [AvailabilityStatus.available] (PHASE 2.4).
///
/// Default-deny. Location permission is deferred (ignored) per architecture.
/// Precedence (first match wins):
/// 1. securityPolicyAllows == false
/// 2. unauthenticated
/// 3. profile missing
/// 4. account suspended
/// 5. account inactive/blocked (rejected)
/// 6. employment ineligible
/// 7. active assignment conflict
/// 8. offline / no connectivity
class AvailabilityEligibilityPolicy {
  const AvailabilityEligibilityPolicy();

  static const policyVersion = 'phase-2.4.eligibility.v1';

  AvailabilityEligibilityDecision evaluate(AvailabilityEligibilityInput input) {
    // 1 — Release / Fake security gate (BR-AVAIL-013).
    if (!input.securityPolicyAllows) {
      return AvailabilityEligibilityDecision.deny(
        failure: const AvailabilitySecurityPolicyDenied(),
        effectiveStatus: AvailabilityStatus.unavailable,
        retryable: false,
        requiredAction: AvailabilityRequiredAction.contactSupport,
        policyVersion: policyVersion,
      );
    }

    // 2 — Auth (BR-AVAIL-001).
    if (!input.authenticated) {
      return AvailabilityEligibilityDecision.deny(
        failure: const AvailabilityUnauthenticated(),
        effectiveStatus: AvailabilityStatus.offline,
        retryable: false,
        requiredAction: AvailabilityRequiredAction.signIn,
        policyVersion: policyVersion,
      );
    }

    // 3 — Profile (BR-AVAIL-002).
    if (!input.profileExists) {
      return AvailabilityEligibilityDecision.deny(
        failure: const DriverProfileMissing(),
        effectiveStatus: AvailabilityStatus.unavailable,
        retryable: false,
        requiredAction: AvailabilityRequiredAction.completeProfile,
        policyVersion: policyVersion,
      );
    }

    // 4 — Suspended (BR-AVAIL-003 / BR-AVAIL-017).
    if (input.accountStatus == AccountStatus.suspended) {
      return AvailabilityEligibilityDecision.deny(
        failure: const DriverAccountSuspended(),
        effectiveStatus: AvailabilityStatus.unavailable,
        retryable: false,
        requiredAction: AvailabilityRequiredAction.contactSupport,
        policyVersion: policyVersion,
      );
    }

    // 5 — Rejected / blocked / inactive account (BR-AVAIL-003).
    if (input.accountStatus == AccountStatus.rejected) {
      return AvailabilityEligibilityDecision.deny(
        failure: const DriverAccountInactive(),
        effectiveStatus: AvailabilityStatus.unavailable,
        retryable: false,
        requiredAction: AvailabilityRequiredAction.contactSupport,
        policyVersion: policyVersion,
      );
    }

    // 6 — Employment (BR-AVAIL-003).
    if (input.employmentStatus != EmploymentStatus.active) {
      return AvailabilityEligibilityDecision.deny(
        failure: const DriverEmploymentIneligible(),
        effectiveStatus: AvailabilityStatus.unavailable,
        retryable: false,
        requiredAction: AvailabilityRequiredAction.contactSupport,
        policyVersion: policyVersion,
      );
    }

    // 7 — Active assignment (BR-AVAIL-006; reserved, enforced when true).
    if (input.hasActiveAssignment) {
      return AvailabilityEligibilityDecision.deny(
        failure: const ActiveAssignmentConflict(),
        effectiveStatus: AvailabilityStatus.busy,
        retryable: true,
        requiredAction: AvailabilityRequiredAction.waitAssignment,
        policyVersion: policyVersion,
      );
    }

    // 8 — Connectivity required for confirmed available (ADR-017).
    if (!input.connectivityAvailable) {
      return AvailabilityEligibilityDecision.deny(
        failure: const AvailabilityOffline(),
        effectiveStatus: AvailabilityStatus.offline,
        retryable: true,
        requiredAction: AvailabilityRequiredAction.waitConnectivity,
        policyVersion: policyVersion,
      );
    }

    // Location permission: deferred in PHASE 2.4 — intentionally not checked.

    return AvailabilityEligibilityDecision.allow(policyVersion: policyVersion);
  }
}
