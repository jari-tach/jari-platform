import '../models/delivery_assignment_model.dart';
import '../models/delivery_offer_model.dart';

/// Remote port for delivery offers / accept / reject (PHASE 2.5).
///
/// Implementations (HTTP, Fake, etc.) are out of scope for this increment.
/// No caching or business policy belongs here.
abstract interface class DeliveryRemoteDataSource {
  /// Fetches current offers for [driverId].
  Future<List<DeliveryOfferModel>> fetchOffers({required String driverId});

  /// Watches the active offer for [driverId] (`null` when none).
  Stream<DeliveryOfferModel?> watchActiveOffer({required String driverId});

  /// Accepts [offerId] and returns the resulting assignment model.
  Future<DeliveryAssignmentModel> acceptOffer({
    required String driverId,
    required String offerId,
    required String idempotencyKey,
    String? revision,
    String? correlationId,
  });

  /// Rejects [offerId].
  Future<void> rejectOffer({
    required String driverId,
    required String offerId,
    String? idempotencyKey,
    String? reasonCode,
    String? correlationId,
  });
}
