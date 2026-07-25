import '../entities/authoritative_availability_update.dart';
import '../entities/availability_result.dart';
import '../entities/availability_status.dart';
import '../entities/driver_availability.dart';
import '../failures/availability_failure.dart';
import '../repositories/driver_availability_repository.dart';

/// Applies Backend/system authoritative availability (server over local).
class ApplyAuthoritativeAvailability {
  const ApplyAuthoritativeAvailability(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<AvailabilityResult<DriverAvailability>> call(
    AuthoritativeAvailabilityUpdate update,
  ) async {
    // Structural source guard (also enforced on the VO constructor).
    if (update.source == AvailabilitySource.localUserAction ||
        update.source == AvailabilitySource.restoredLocalState) {
      return const AvailabilityFailureResult(
        AvailabilitySecurityPolicyDenied(
          'Authoritative update cannot use local or restored source.',
        ),
      );
    }

    final currentResult = await _repository.getCurrentAvailability();
    final current = currentResult.valueOrNull;
    if (current != null && current.driverId != update.driverId) {
      return const AvailabilityFailureResult(
        AvailabilitySecurityPolicyDenied(
          'Authoritative update driverId does not match current state.',
        ),
      );
    }

    if (current?.revision != null &&
        update.revision != null &&
        update.revision! < current!.revision!) {
      return const AvailabilityFailureResult(AvailabilityStateStale());
    }

    return _repository.applyAuthoritativeAvailability(update);
  }
}
