import '../entities/delivery_offer.dart';
import '../entities/delivery_offer_status.dart';
import '../entities/delivery_result.dart';
import '../entities/reject_delivery_offer_request.dart';
import '../failures/delivery_failure.dart';
import '../policies/delivery_offer_transition_decision.dart';
import '../policies/delivery_offer_transition_policy.dart';
import '../repositories/delivery_offer_repository.dart';

/// Rejects a delivery offer without creating an assignment (ADR-021 / ADR-024).
class RejectDeliveryOffer {
  /// Creates the use case.
  const RejectDeliveryOffer(
    this._offerRepository, {
    this._transitionPolicy = const DeliveryOfferTransitionPolicy(),
  });

  final DeliveryOfferRepository _offerRepository;
  final DeliveryOfferTransitionPolicy _transitionPolicy;

  /// Validates transition preconditions then rejects via the repository.
  Future<DeliveryResult<void>> call(RejectDeliveryOfferRequest request) async {
    final offersResult = await _offerRepository.getDeliveryOffers(
      driverId: request.driverId,
    );
    final offers = offersResult.valueOrNull;
    if (offers == null) {
      return DeliveryFailureResult(
        offersResult.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }

    DeliveryOffer? matched;
    for (final offer in offers) {
      if (offer.offerId == request.offerId) {
        matched = offer;
        break;
      }
    }
    if (matched == null) {
      return const DeliveryFailureResult(DeliveryOfferNotFound());
    }
    if (matched.driverId != request.driverId) {
      return const DeliveryFailureResult(DeliverySecurityPolicyDenied());
    }

    final transition = _transitionPolicy.evaluate(
      DeliveryOfferTransitionContext(
        current: matched.status,
        requested: DeliveryOfferStatus.rejecting,
      ),
    );
    if (!transition.allowed) {
      return DeliveryFailureResult(
        transition.failure ?? const InvalidDeliveryOfferTransition(),
      );
    }

    return _offerRepository.rejectOffer(request);
  }
}
