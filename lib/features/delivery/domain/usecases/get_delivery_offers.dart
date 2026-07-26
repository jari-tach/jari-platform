import '../entities/delivery_offer.dart';
import '../entities/delivery_result.dart';
import '../failures/delivery_failure.dart';
import '../policies/one_active_offer_policy.dart';
import '../repositories/delivery_offer_repository.dart';

/// Loads current delivery offers and enforces one-active-offer (ADR-023).
class GetDeliveryOffers {
  /// Creates the use case.
  const GetDeliveryOffers(
    this._repository, {
    this._oneActiveOfferPolicy = const OneActiveOfferPolicy(),
  });

  final DeliveryOfferRepository _repository;
  final OneActiveOfferPolicy _oneActiveOfferPolicy;

  /// Returns offers for [driverId], filtered to at most one active offer.
  Future<DeliveryResult<List<DeliveryOffer>>> call({
    required String driverId,
  }) async {
    final normalized = driverId.trim();
    if (normalized.isEmpty) {
      return const DeliveryFailureResult(DeliveryUnauthenticated());
    }

    final result = await _repository.getDeliveryOffers(driverId: normalized);
    final offers = result.valueOrNull;
    if (offers == null) {
      return DeliveryFailureResult(
        result.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }

    for (final offer in offers) {
      if (offer.driverId != normalized) {
        return const DeliveryFailureResult(
          DeliverySecurityPolicyDenied(
            'Offer driverId does not match requested driverId.',
          ),
        );
      }
    }

    return DeliverySuccess(_oneActiveOfferPolicy.enforce(offers));
  }
}
