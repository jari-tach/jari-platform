import '../entities/accept_delivery_offer_request.dart';
import '../entities/delivery_assignment.dart';
import '../entities/delivery_offer.dart';
import '../entities/delivery_result.dart';
import '../entities/reject_delivery_offer_request.dart';

/// Domain contract for incoming delivery offers (PHASE 2.5).
///
/// Implementations may be Fake (ADR-027) or Backend-backed. This contract does
/// not imply local assignment persistence — see [DeliveryAssignmentRepository].
abstract interface class DeliveryOfferRepository {
  /// Returns currently known offers for [driverId] (0..n; policy enforces one).
  ///
  /// Authority: Backend / Fake. Not a confirmed assignment.
  Future<DeliveryResult<List<DeliveryOffer>>> getDeliveryOffers({
    required String driverId,
  });

  /// Watches the active offer stream for [driverId] (nullable when none).
  Stream<DeliveryOffer?> watchActiveOffer({required String driverId});

  /// Attempts authoritative accept; on success returns a [DeliveryAssignment].
  ///
  /// Authority: Backend / Fake. Must honor idempotency keys.
  /// Offline: callers must deny before invoking (ADR-024).
  Future<DeliveryResult<DeliveryAssignment>> acceptOffer(
    AcceptDeliveryOfferRequest request,
  );

  /// Attempts reject of an offer.
  ///
  /// Must not create an assignment or availability busy state.
  Future<DeliveryResult<void>> rejectOffer(RejectDeliveryOfferRequest request);
}
