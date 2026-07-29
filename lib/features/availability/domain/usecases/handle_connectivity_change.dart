import '../entities/availability_change_request.dart';
import '../entities/availability_connectivity_change.dart';
import '../entities/availability_result.dart';
import '../entities/availability_status.dart';
import '../entities/driver_availability.dart';
import '../failures/availability_failure.dart';
import '../repositories/driver_availability_repository.dart';

/// Maps connectivity signals to safe domain transitions (ADR-017).
///
/// Does not listen to device connectivity, schedule retries, or queue
/// available activation. Callers supply the online/offline signal.
class HandleConnectivityChange {
  const HandleConnectivityChange(this._repository);

  final DriverAvailabilityRepository _repository;

  Future<AvailabilityResult<DriverAvailability>> call(
    AvailabilityConnectivityChange change,
  ) async {
    final currentResult = await _repository.getCurrentAvailability();
    final current = currentResult.valueOrNull;
    if (current == null) {
      return AvailabilityFailureResult<DriverAvailability>(
        currentResult.failureOrNull ?? const AvailabilityUnknownFailure(),
      );
    }

    if (current.driverId != change.driverId) {
      return const AvailabilityFailureResult(
        AvailabilitySecurityPolicyDenied(
          'Connectivity change driverId does not match current state.',
        ),
      );
    }

    if (!change.isOnline) {
      // Lost connectivity while available → effective offline (safe).
      // Busy is preserved as assignment-derived local view.
      if (current.status == AvailabilityStatus.busy) {
        return AvailabilitySuccess(current);
      }
      if (current.status == AvailabilityStatus.offline) {
        return AvailabilitySuccess(current);
      }
      return _repository.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: change.driverId,
          requestedStatus: AvailabilityStatus.offline,
          actor: AvailabilityActor.connectivity,
          requestedAt: change.changedAt,
          correlationId: change.correlationId,
          connectivityOnline: false,
        ),
      );
    }

    // Reconnect: clear connectivity-offline into safe unavailable.
    // Never auto-activate available (ADR-017). Preserve Busy/Available/
    // Unavailable/Pending operational states when not connectivity-offline.
    if (current.status == AvailabilityStatus.offline) {
      return _repository.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: change.driverId,
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.connectivity,
          requestedAt: change.changedAt,
          correlationId: change.correlationId,
          connectivityOnline: true,
        ),
      );
    }

    // Idempotent: already an online operational status — no write.
    return AvailabilitySuccess(current);
  }
}
