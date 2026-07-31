import '../entities/batch_summary.dart';
import '../entities/delivery_result.dart';
import '../repositories/delivery_lifecycle_repository.dart';

/// Loads the driver's active batch (current stop only exposes safe labels).
class GetActiveBatch {
  const GetActiveBatch(this._lifecycle);

  final DeliveryLifecycleRepository _lifecycle;

  Future<DeliveryResult<BatchSummary?>> call() => _lifecycle.getActiveBatch();

  Future<DeliveryResult<BatchSummary>> byId(String batchId) =>
      _lifecycle.getBatch(batchId);
}
