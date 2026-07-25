import '../entities/availability_status.dart';
import '../failures/availability_failure.dart';
import 'availability_transition_decision.dart';

/// Pure default-deny transition rules (ADR-015 / BR-AVAIL-004..012).
///
/// Does not evaluate profile/auth eligibility — that is
/// [AvailabilityEligibilityPolicy]. Does not perform I/O.
class AvailabilityTransitionPolicy {
  const AvailabilityTransitionPolicy();

  static const policyVersion = 'phase-2.4.transition.v1';

  AvailabilityTransitionDecision evaluate(AvailabilityTransitionContext ctx) {
    if (ctx.current == ctx.requested) {
      return AvailabilityTransitionDecision.allow(
        policyVersion: policyVersion,
        idempotent: true,
      );
    }

    // Driver may never select busy (BR-AVAIL-004).
    if (ctx.requested == AvailabilityStatus.busy &&
        ctx.actor == AvailabilityActor.driver) {
      return AvailabilityTransitionDecision.deny(
        failure: const ManualBusyTransitionDenied(),
        policyVersion: policyVersion,
      );
    }

    // Connectivity may force non-authoritative effective offline (ADR-017).
    if (ctx.requested == AvailabilityStatus.offline &&
        ctx.actor == AvailabilityActor.connectivity) {
      return AvailabilityTransitionDecision.allow(policyVersion: policyVersion);
    }

    // offline → available always denied (ADR-017).
    if (ctx.current == AvailabilityStatus.offline &&
        ctx.requested == AvailabilityStatus.available) {
      return AvailabilityTransitionDecision.deny(
        failure: const AvailabilityOffline(),
        policyVersion: policyVersion,
      );
    }

    // Active assignment: user must not freely leave busy or claim available.
    if (ctx.hasActiveAssignment && ctx.actor == AvailabilityActor.driver) {
      if (ctx.requested == AvailabilityStatus.available ||
          (ctx.current == AvailabilityStatus.busy &&
              ctx.requested == AvailabilityStatus.unavailable)) {
        return AvailabilityTransitionDecision.deny(
          failure: const ActiveAssignmentConflict(),
          policyVersion: policyVersion,
        );
      }
    }

    switch ((ctx.current, ctx.requested, ctx.actor)) {
      case (
        AvailabilityStatus.unavailable,
        AvailabilityStatus.available,
        AvailabilityActor.driver,
      ):
      case (
        AvailabilityStatus.unavailable,
        AvailabilityStatus.available,
        AvailabilityActor.system,
      ):
      case (
        AvailabilityStatus.unavailable,
        AvailabilityStatus.available,
        AvailabilityActor.backend,
      ):
        // Structural OK; eligibility policy decides final allow.
        return AvailabilityTransitionDecision.allow(
          policyVersion: policyVersion,
        );

      case (
        AvailabilityStatus.available,
        AvailabilityStatus.unavailable,
        AvailabilityActor.driver,
      ):
      case (
        AvailabilityStatus.available,
        AvailabilityStatus.unavailable,
        AvailabilityActor.system,
      ):
      case (
        AvailabilityStatus.available,
        AvailabilityStatus.unavailable,
        AvailabilityActor.backend,
      ):
        if (ctx.hasActiveAssignment && ctx.actor == AvailabilityActor.driver) {
          return AvailabilityTransitionDecision.deny(
            failure: const ActiveAssignmentConflict(),
            policyVersion: policyVersion,
          );
        }
        return AvailabilityTransitionDecision.allow(
          policyVersion: policyVersion,
        );

      case (
        AvailabilityStatus.available,
        AvailabilityStatus.busy,
        AvailabilityActor.system,
      ):
      case (
        AvailabilityStatus.available,
        AvailabilityStatus.busy,
        AvailabilityActor.backend,
      ):
        return AvailabilityTransitionDecision.allow(
          policyVersion: policyVersion,
        );

      case (
        AvailabilityStatus.busy,
        AvailabilityStatus.available,
        AvailabilityActor.system,
      ):
      case (
        AvailabilityStatus.busy,
        AvailabilityStatus.available,
        AvailabilityActor.backend,
      ):
        // PHASE 2.4 domain gate only: system/backend may leave busy when
        // assignment context explicitly allows and no active assignment
        // remains. Authoritative assignment lifecycle is deferred; drivers
        // never self-exit busy (denied earlier for AvailabilityActor.driver).
        if (!ctx.assignmentAllowsAvailable || ctx.hasActiveAssignment) {
          return AvailabilityTransitionDecision.deny(
            failure: const ActiveAssignmentConflict(),
            policyVersion: policyVersion,
          );
        }
        return AvailabilityTransitionDecision.allow(
          policyVersion: policyVersion,
        );

      case (
        AvailabilityStatus.busy,
        AvailabilityStatus.unavailable,
        AvailabilityActor.system,
      ):
      case (
        AvailabilityStatus.busy,
        AvailabilityStatus.unavailable,
        AvailabilityActor.backend,
      ):
        return AvailabilityTransitionDecision.allow(
          policyVersion: policyVersion,
        );

      case (
        AvailabilityStatus.offline,
        AvailabilityStatus.unavailable,
        AvailabilityActor.connectivity,
      ):
      case (
        AvailabilityStatus.offline,
        AvailabilityStatus.unavailable,
        AvailabilityActor.system,
      ):
      case (
        AvailabilityStatus.offline,
        AvailabilityStatus.unavailable,
        AvailabilityActor.backend,
      ):
      case (
        AvailabilityStatus.offline,
        AvailabilityStatus.unavailable,
        AvailabilityActor.driver,
      ):
        return AvailabilityTransitionDecision.allow(
          policyVersion: policyVersion,
        );

      // Forced safety → unavailable.
      case (_, AvailabilityStatus.unavailable, AvailabilityActor.system):
      case (_, AvailabilityStatus.unavailable, AvailabilityActor.backend):
        return AvailabilityTransitionDecision.allow(
          policyVersion: policyVersion,
        );

      default:
        return AvailabilityTransitionDecision.deny(
          failure: const InvalidAvailabilityTransition(),
          policyVersion: policyVersion,
        );
    }
  }
}
