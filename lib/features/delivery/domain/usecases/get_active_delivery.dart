import '../entities/delivery_assignment.dart';
import '../entities/delivery_result.dart';
import '../failures/delivery_failure.dart';
import '../repositories/delivery_assignment_repository.dart';

/// Returns the driver's active accepted delivery assignment, if any.
class GetActiveDelivery {
  /// Creates the use case.
  const GetActiveDelivery(this._assignmentRepository);

  final DeliveryAssignmentRepository _assignmentRepository;

  /// Loads the active assignment for [driverId].
  ///
  /// Returns [DeliverySuccess] with `null` when none exists.
  Future<DeliveryResult<DeliveryAssignment?>> call({
    required String driverId,
  }) async {
    final normalized = driverId.trim();
    if (normalized.isEmpty) {
      return const DeliveryFailureResult(DeliveryUnauthenticated());
    }

    final result = await _assignmentRepository.getActiveAssignment(
      driverId: normalized,
    );
    final assignment = result.valueOrNull;
    if (result.isFailure) {
      return DeliveryFailureResult(
        result.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }

    if (assignment != null && assignment.driverId != normalized) {
      return const DeliveryFailureResult(
        DeliverySecurityPolicyDenied(
          'Active assignment driverId does not match requested driverId.',
        ),
      );
    }

    return DeliverySuccess(assignment);
  }
}
