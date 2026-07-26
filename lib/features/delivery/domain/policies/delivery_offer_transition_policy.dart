import '../entities/delivery_offer_status.dart';
import '../failures/delivery_failure.dart';
import 'delivery_offer_transition_decision.dart';

/// Pure default-deny offer transition rules (ADR-021 / ADR-022).
///
/// Does not perform I/O. Controllers and use cases must not bypass this policy.
class DeliveryOfferTransitionPolicy {
  const DeliveryOfferTransitionPolicy();

  static const policyVersion = 'phase-2.5.offer-transition.v1';

  /// Evaluates whether [ctx] is an allow-listed transition.
  DeliveryOfferTransitionDecision evaluate(DeliveryOfferTransitionContext ctx) {
    if (ctx.current == ctx.requested) {
      return DeliveryOfferTransitionDecision.allow(
        policyVersion: policyVersion,
        idempotent: true,
      );
    }

    final allowed = _isAllowed(ctx.current, ctx.requested);
    if (!allowed) {
      return DeliveryOfferTransitionDecision.deny(
        failure: const InvalidDeliveryOfferTransition(),
        policyVersion: policyVersion,
      );
    }

    return DeliveryOfferTransitionDecision.allow(policyVersion: policyVersion);
  }

  bool _isAllowed(DeliveryOfferStatus current, DeliveryOfferStatus requested) {
    return switch ((current, requested)) {
      (DeliveryOfferStatus.none, DeliveryOfferStatus.offered) => true,
      (DeliveryOfferStatus.offered, DeliveryOfferStatus.accepting) => true,
      (DeliveryOfferStatus.offered, DeliveryOfferStatus.rejecting) => true,
      (DeliveryOfferStatus.offered, DeliveryOfferStatus.expired) => true,
      (DeliveryOfferStatus.offered, DeliveryOfferStatus.takenByOther) => true,
      (DeliveryOfferStatus.offered, DeliveryOfferStatus.cancelled) => true,
      (DeliveryOfferStatus.accepting, DeliveryOfferStatus.accepted) => true,
      (DeliveryOfferStatus.accepting, DeliveryOfferStatus.offered) => true,
      (DeliveryOfferStatus.accepting, DeliveryOfferStatus.takenByOther) => true,
      (DeliveryOfferStatus.accepting, DeliveryOfferStatus.expired) => true,
      (DeliveryOfferStatus.accepting, DeliveryOfferStatus.failed) => true,
      (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.rejected) => true,
      (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.offered) => true,
      (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.expired) => true,
      (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.failed) => true,
      (DeliveryOfferStatus.accepted, DeliveryOfferStatus.none) => true,
      (DeliveryOfferStatus.rejected, DeliveryOfferStatus.none) => true,
      (DeliveryOfferStatus.expired, DeliveryOfferStatus.none) => true,
      (DeliveryOfferStatus.takenByOther, DeliveryOfferStatus.none) => true,
      (DeliveryOfferStatus.cancelled, DeliveryOfferStatus.none) => true,
      (DeliveryOfferStatus.failed, DeliveryOfferStatus.none) => true,
      (DeliveryOfferStatus.failed, DeliveryOfferStatus.offered) => true,
      _ => false,
    };
  }
}
