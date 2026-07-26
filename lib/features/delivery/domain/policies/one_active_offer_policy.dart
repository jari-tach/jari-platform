import '../entities/delivery_offer.dart';
import '../entities/delivery_offer_status.dart';

/// Enforces at most one active offer (ADR-023).
class OneActiveOfferPolicy {
  const OneActiveOfferPolicy();

  static const policyVersion = 'phase-2.5.one-active-offer.v1';

  /// Returns true when [candidate] may become the active offer given [current].
  ///
  /// Same [DeliveryOffer.offerId] is treated as an idempotent refresh.
  bool allowsIncoming({
    required DeliveryOffer? current,
    required DeliveryOffer candidate,
  }) {
    if (!candidate.status.isActive &&
        candidate.status != DeliveryOfferStatus.offered) {
      // Terminal/none candidates are not "incoming active" offers.
      return true;
    }

    if (current == null || !current.status.isActive) {
      return true;
    }

    return current.offerId == candidate.offerId;
  }

  /// Filters a list down to at most one active offer (first wins).
  List<DeliveryOffer> enforce(List<DeliveryOffer> offers) {
    DeliveryOffer? active;
    final result = <DeliveryOffer>[];
    for (final offer in offers) {
      if (!offer.status.isActive) {
        continue;
      }
      if (active == null) {
        active = offer;
        result.add(offer);
      } else if (active.offerId == offer.offerId) {
        // Prefer the later occurrence as refresh of the same offer.
        result[result.length - 1] = offer;
        active = offer;
      }
      // Distinct active offer ids are dropped (ADR-023 default: ignore).
    }
    return result;
  }
}
