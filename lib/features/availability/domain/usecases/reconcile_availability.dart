import '../entities/availability_reconciliation_request.dart';
import '../entities/availability_result.dart';
import '../entities/driver_availability.dart';
import '../repositories/driver_availability_repository.dart';

/// Delegates explicit reconciliation (no retry/queue engine in Increment 2).
class ReconcileAvailability {
  const ReconcileAvailability(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<AvailabilityResult<DriverAvailability>> call(
    AvailabilityReconciliationRequest request,
  ) => _repository.reconcileAvailability(request);
}
