import '../entities/availability_change_request.dart';
import '../entities/availability_result.dart';
import '../entities/availability_status.dart';
import '../entities/driver_availability.dart';
import '../failures/availability_failure.dart';
import '../policies/availability_eligibility_policy.dart';
import '../policies/availability_transition_decision.dart';
import '../policies/availability_transition_policy.dart';
import '../repositories/driver_availability_repository.dart';

/// Orchestrates policy checks then delegates an approved change request.
class RequestAvailabilityChange {
  const RequestAvailabilityChange(
    this._repository, {
    this._transitionPolicy = const AvailabilityTransitionPolicy(),
    this._eligibilityPolicy = const AvailabilityEligibilityPolicy(),
  });

  final DriverAvailabilityRepository _repository;
  final AvailabilityTransitionPolicy _transitionPolicy;
  final AvailabilityEligibilityPolicy _eligibilityPolicy;

  Future<AvailabilityResult<DriverAvailability>> call(
    AvailabilityChangeRequest request,
  ) async {
    final currentResult = await _repository.getCurrentAvailability();
    final current = currentResult.valueOrNull;
    if (current == null) {
      return AvailabilityFailureResult<DriverAvailability>(
        currentResult.failureOrNull ?? const AvailabilityUnknownFailure(),
      );
    }

    if (current.driverId != request.driverId) {
      return const AvailabilityFailureResult(
        AvailabilitySecurityPolicyDenied(
          'Availability change driverId does not match current state.',
        ),
      );
    }

    final transition = _transitionPolicy.evaluate(
      AvailabilityTransitionContext(
        current: current.status,
        requested: request.requestedStatus,
        actor: request.actor,
        hasActiveAssignment: request.hasActiveAssignment,
        assignmentAllowsAvailable: request.assignmentAllowsAvailable,
        connectivityOnline: request.connectivityOnline,
      ),
    );

    if (!transition.allowed) {
      return AvailabilityFailureResult(
        transition.failure ?? const InvalidAvailabilityTransition(),
      );
    }

    // Same-state: success without repository mutation (BR-AVAIL-010).
    if (transition.idempotent) {
      return AvailabilitySuccess(current);
    }

    if (request.requestedStatus == AvailabilityStatus.available) {
      final eligibilityInput = request.eligibilityInput;
      if (eligibilityInput == null) {
        return const AvailabilityFailureResult(
          AvailabilityConfirmationRequired(
            'Eligibility input required when requesting available.',
          ),
        );
      }
      final eligibility = _eligibilityPolicy.evaluate(eligibilityInput);
      if (!eligibility.allowed) {
        return AvailabilityFailureResult(
          eligibility.failure ?? const AvailabilityUnknownFailure(),
        );
      }
    }

    return _repository.requestAvailabilityChange(request);
  }
}
