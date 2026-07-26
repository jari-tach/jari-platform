import '../entities/delivery_offer_status.dart';
import '../failures/delivery_failure.dart';

/// Outcome of evaluating a delivery-offer transition (ADR-022).
class DeliveryOfferTransitionDecision {
  const DeliveryOfferTransitionDecision._({
    required this.allowed,
    required this.policyVersion,
    this.failure,
    this.idempotent = false,
  });

  /// Creates an allow decision.
  factory DeliveryOfferTransitionDecision.allow({
    required String policyVersion,
    bool idempotent = false,
  }) {
    return DeliveryOfferTransitionDecision._(
      allowed: true,
      policyVersion: policyVersion,
      idempotent: idempotent,
    );
  }

  /// Creates a deny decision with a typed [failure].
  factory DeliveryOfferTransitionDecision.deny({
    required DeliveryFailure failure,
    required String policyVersion,
  }) {
    return DeliveryOfferTransitionDecision._(
      allowed: false,
      failure: failure,
      policyVersion: policyVersion,
    );
  }

  final bool allowed;
  final DeliveryFailure? failure;
  final String policyVersion;
  final bool idempotent;
}

/// Inputs for [DeliveryOfferTransitionPolicy].
class DeliveryOfferTransitionContext {
  const DeliveryOfferTransitionContext({
    required this.current,
    required this.requested,
  });

  final DeliveryOfferStatus current;
  final DeliveryOfferStatus requested;
}
