import '../../availability/domain/entities/authoritative_availability_update.dart';
import '../../availability/domain/entities/availability_status.dart';
import '../../availability/domain/usecases/apply_authoritative_availability.dart';
import '../../availability/domain/usecases/get_driver_availability.dart';
import '../domain/entities/delivery_result.dart';
import '../domain/entities/driver_workflow_stage.dart';
import '../domain/failures/delivery_failure.dart';
import '../domain/repositories/delivery_assignment_repository.dart';

/// Releases busy/unavailable then clears a summary assignment (PHASE 2.6).
///
/// Order (strict):
/// 1. Validate summary assignment (or idempotent already-released)
/// 2. Authoritative availability → `unavailable` (`delivery.complete`)
/// 3. Clear local active assignment **only after** availability succeeds
///
/// The summary row stays persisted until step 2 succeeds so a busy-release
/// failure never loses the assignment.
class CompleteDeliveryAndReleaseBusy {
  CompleteDeliveryAndReleaseBusy(
    this._assignmentRepository,
    this._applyAuthoritativeAvailability,
    this._getDriverAvailability, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DeliveryAssignmentRepository _assignmentRepository;
  final ApplyAuthoritativeAvailability _applyAuthoritativeAvailability;
  final GetDriverAvailability _getDriverAvailability;
  final DateTime Function() _clock;

  /// Post-completion availability used by this coordinator and idempotency.
  static const postCompletionStatus = AvailabilityStatus.unavailable;
  static const postCompletionReason = 'delivery.complete';

  Future<DeliveryResult<void>> call({required String driverId}) async {
    final normalized = driverId.trim();
    if (normalized.isEmpty) {
      return const DeliveryFailureResult(DeliveryUnauthenticated());
    }

    final currentResult = await _assignmentRepository.getActiveAssignment(
      driverId: normalized,
    );
    if (currentResult.isFailure) {
      return DeliveryFailureResult(
        currentResult.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }
    final current = currentResult.valueOrNull;

    if (current == null) {
      return _idempotentSuccessIfAlreadyReleased(normalized);
    }

    if (current.driverId != normalized) {
      return const DeliveryFailureResult(DeliverySecurityPolicyDenied());
    }

    if (current.workflowStage != DriverWorkflowStage.summary) {
      return const DeliveryFailureResult(
        InvalidDeliveryWorkflowTransition(
          'Assignment can only be cleared from the summary stage.',
        ),
      );
    }
    if (current.pendingSync) {
      return const DeliveryFailureResult(DeliveryPendingSync());
    }

    final update = AuthoritativeAvailabilityUpdate(
      driverId: normalized,
      status: postCompletionStatus,
      source: AvailabilitySource.system,
      confirmedAt: _clock().toUtc(),
      reason: postCompletionReason,
    );
    final applied = await _applyAuthoritativeAvailability(update);
    if (applied.isFailure) {
      return DeliveryFailureResult(
        DeliveryAvailabilityBindFailure(
          applied.failureOrNull?.message ??
              'Delivery summary is ready but availability could not be released.',
          current,
        ),
      );
    }

    final clear = await _assignmentRepository.clear(driverId: normalized);
    if (clear.isFailure) {
      // Availability already post-completion; assignment remains for retry.
      return DeliveryFailureResult(
        clear.failureOrNull ??
            const DeliveryPersistenceFailure(
              'Availability was released but the active assignment could not be cleared.',
            ),
      );
    }

    return DeliverySuccess.unit();
  }

  Future<DeliveryResult<void>> _idempotentSuccessIfAlreadyReleased(
    String driverId,
  ) async {
    final availabilityResult = await _getDriverAvailability();
    if (availabilityResult.isFailure) {
      return const DeliveryFailureResult(DeliveryAssignmentNotFound());
    }
    final availability = availabilityResult.valueOrNull;
    if (availability != null &&
        availability.driverId == driverId &&
        availability.status == postCompletionStatus) {
      return DeliverySuccess.unit();
    }
    return const DeliveryFailureResult(DeliveryAssignmentNotFound());
  }
}
