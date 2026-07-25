import '../entities/availability_result.dart';
import '../entities/availability_status.dart';
import '../entities/logout_availability_request.dart';
import '../failures/availability_failure.dart';
import '../repositories/driver_availability_repository.dart';

/// Invalidates local operational availability on logout (BR-AVAIL-016).
///
/// Does not modify auth session or remote logout. Any [AvailabilityStatus.busy]
/// is a deterministic conflict — busy cannot be cleared locally on logout
/// (assignment ownership remains backend/system authoritative).
class ForceUnavailableOnLogout {
  const ForceUnavailableOnLogout(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<AvailabilityResult<void>> call(
    LogoutAvailabilityRequest request,
  ) async {
    final currentResult = await _repository.getCurrentAvailability();
    final current = currentResult.valueOrNull;
    if (current == null) {
      return AvailabilityFailureResult<void>(
        currentResult.failureOrNull ?? const AvailabilityUnknownFailure(),
      );
    }

    if (current.driverId != request.driverId) {
      return const AvailabilityFailureResult(
        AvailabilitySecurityPolicyDenied(
          'Logout availability clear driverId does not match current state.',
        ),
      );
    }

    // Busy is never locally cleared on logout, with or without assignment id.
    if (current.status == AvailabilityStatus.busy) {
      return const AvailabilityFailureResult(ActiveAssignmentConflict());
    }

    return _repository.clearAvailabilityOnLogout(request);
  }
}
