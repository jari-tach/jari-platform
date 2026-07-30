import '../entities/delivery_result.dart';
import '../entities/local_delivery_command.dart';

/// Local-only STEP 3 command ledger.
///
/// The later Backend idempotency contract remains STEP 5. This repository
/// prevents duplicate local mutations and consumed-offer resurrection across
/// app restarts.
abstract interface class DeliveryCommandRepository {
  Future<DeliveryResult<LocalDeliveryCommand?>> getById({
    required String commandId,
  });

  Future<DeliveryResult<void>> save(LocalDeliveryCommand command);

  Future<DeliveryResult<bool>> isOfferConsumed({
    required String driverId,
    required String offerId,
  });
}
