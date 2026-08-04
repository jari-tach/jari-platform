import '../entities/delivery_result.dart';
import '../entities/local_delivery_command.dart';
import '../failures/delivery_failure.dart';
import '../repositories/delivery_assignment_repository.dart';
import '../repositories/delivery_command_repository.dart';
import '../repositories/delivery_lifecycle_repository.dart';

/// Cancels the active delivery via Backend and clears customer contact.
class CancelDeliveryRemote {
  CancelDeliveryRemote({
    required DeliveryLifecycleRepository lifecycleRepository,
    required DeliveryAssignmentRepository assignmentRepository,
    required DeliveryCommandRepository commandRepository,
    DateTime Function()? clock,
  }) : _lifecycle = lifecycleRepository,
       _assignments = assignmentRepository,
       _commands = commandRepository,
       _clock = clock ?? DateTime.now;

  final DeliveryLifecycleRepository _lifecycle;
  final DeliveryAssignmentRepository _assignments;
  final DeliveryCommandRepository _commands;
  final DateTime Function() _clock;

  Future<DeliveryResult<void>> call({
    required String driverId,
    required String commandId,
    String? reasonCode,
  }) async {
    final id = commandId.trim();
    if (id.isEmpty) {
      return const DeliveryFailureResult(DeliveryInvalidCommandId());
    }

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

    final version = int.tryParse(current.serverRevision ?? '') ?? 0;
    // Backend DeliveryCancellationDto requires reasonCode; UI Cancel from
    // Issue/Verify pages may omit it (Device QA #16). Align with STEP 5D-2
    // contract fixtures that use customer_request.
    final resolvedReason = (reasonCode == null || reasonCode.trim().isEmpty)
        ? 'customer_request'
        : reasonCode.trim();
    final remote = await _lifecycle.cancelDelivery(
      deliveryId: current.assignmentId,
      aggregateVersion: version,
      idempotencyKey: id,
      reasonCode: resolvedReason,
    );
    if (remote.isFailure) {
      return DeliveryFailureResult(
        remote.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }

    _lifecycle.clearCustomerContact(deliveryId: current.assignmentId);
    await _commands.save(
      LocalDeliveryCommand(
        commandId: id,
        driverId: driverId,
        targetId: current.assignmentId,
        type: LocalDeliveryCommandType.cancel,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: _clock().toUtc(),
      ),
    );

    return _assignments.clear(driverId: driverId);
  }
}
