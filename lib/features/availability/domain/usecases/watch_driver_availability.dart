import '../entities/driver_availability.dart';
import '../repositories/driver_availability_repository.dart';

/// Observes effective availability emissions without rewriting confirmation.
class WatchDriverAvailability {
  const WatchDriverAvailability(this._repository);

  final DriverAvailabilityRepository _repository;

  Stream<DriverAvailability> call() => _repository.watchAvailability();
}
