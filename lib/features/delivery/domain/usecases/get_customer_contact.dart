import '../entities/customer_contact.dart';
import '../entities/delivery_lifecycle_ack.dart';
import '../entities/delivery_result.dart';
import '../entities/driver_workflow_stage.dart';
import '../failures/delivery_failure.dart';
import '../repositories/delivery_assignment_repository.dart';
import '../repositories/delivery_lifecycle_repository.dart';

/// Loads current-customer contact only after Backend pickup acknowledgment.
///
/// Upcoming customer contact is never requested. Contact stays memory-only.
class GetCustomerContact {
  const GetCustomerContact({
    required DeliveryLifecycleRepository lifecycleRepository,
    required DeliveryAssignmentRepository assignmentRepository,
  }) : _lifecycle = lifecycleRepository,
       _assignments = assignmentRepository;

  final DeliveryLifecycleRepository _lifecycle;
  final DeliveryAssignmentRepository _assignments;

  Future<DeliveryResult<CustomerContact>> call({
    required String driverId,
  }) async {
    final currentResult = await _assignments.getActiveAssignment(
      driverId: driverId,
    );
    if (currentResult.isFailure) {
      return DeliveryFailureResult(
        currentResult.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }
    final current = currentResult.valueOrNull;
    if (current == null || !current.isActive) {
      return const DeliveryFailureResult(DeliveryAssignmentNotFound());
    }
    if (current.pendingSync) {
      _lifecycle.clearCustomerContact(deliveryId: current.assignmentId);
      return const DeliveryFailureResult(DeliveryContactNotAvailable());
    }

    final state = canonicalDeliveryStateForStage(current.workflowStage);
    if (state == null ||
        !CanonicalDeliveryStates.contactAllowed.contains(state)) {
      _lifecycle.clearCustomerContact(deliveryId: current.assignmentId);
      return const DeliveryFailureResult(DeliveryContactNotAvailable());
    }

    // Local stages before collected must never reveal contact.
    if (current.workflowStage == DriverWorkflowStage.assigned ||
        current.workflowStage == DriverWorkflowStage.navToPickup ||
        current.workflowStage == DriverWorkflowStage.arrivedPickup ||
        current.workflowStage == DriverWorkflowStage.waitingPickup) {
      _lifecycle.clearCustomerContact(deliveryId: current.assignmentId);
      return const DeliveryFailureResult(DeliveryContactNotAvailable());
    }

    return _lifecycle.getCustomerContact(
      deliveryId: current.assignmentId,
      deliveryState: state,
    );
  }
}
