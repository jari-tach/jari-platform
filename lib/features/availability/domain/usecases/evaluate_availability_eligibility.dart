import '../entities/availability_eligibility_decision.dart';
import '../entities/availability_eligibility_input.dart';
import '../policies/availability_eligibility_policy.dart';

/// Injectable wrapper around [AvailabilityEligibilityPolicy] (no I/O).
class EvaluateAvailabilityEligibility {
  const EvaluateAvailabilityEligibility([
    this._policy = const AvailabilityEligibilityPolicy(),
  ]);

  final AvailabilityEligibilityPolicy _policy;

  AvailabilityEligibilityDecision call(AvailabilityEligibilityInput input) =>
      _policy.evaluate(input);
}
