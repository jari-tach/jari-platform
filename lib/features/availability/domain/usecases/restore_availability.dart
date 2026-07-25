import '../entities/availability_result.dart';
import '../entities/driver_availability.dart';
import '../repositories/driver_availability_repository.dart';

/// Restores local availability without promoting it to confirmed available.
class RestoreAvailability {
  const RestoreAvailability(this._repository);

  final DriverAvailabilityRepository _repository;

  /// Does not call [DriverAvailabilityRepository.requestAvailabilityChange].
  Future<AvailabilityResult<DriverAvailability>> call() =>
      _repository.restoreLocalAvailability();
}
