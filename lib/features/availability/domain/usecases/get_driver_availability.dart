import '../entities/availability_result.dart';
import '../entities/driver_availability.dart';
import '../repositories/driver_availability_repository.dart';

/// One-shot read of effective availability (not Backend confirmation).
class GetDriverAvailability {
  const GetDriverAvailability(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<AvailabilityResult<DriverAvailability>> call() =>
      _repository.getCurrentAvailability();
}
