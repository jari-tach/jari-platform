import '../entities/delivery_assignment.dart';
import '../entities/delivery_result.dart';
import '../entities/driver_workflow_stage.dart';
import '../entities/local_delivery_command.dart';
import '../failures/delivery_failure.dart';
import '../policies/driver_workflow_transition_policy.dart';
import '../repositories/delivery_assignment_repository.dart';
import '../repositories/delivery_command_repository.dart';
import '../repositories/delivery_lifecycle_repository.dart';
import 'advance_delivery_workflow.dart';

/// Confirms delivery against Backend after automatic arrival acknowledgment,
/// then advances verifying → delivered → summary and clears customer contact.
class ConfirmDeliveryRemote {
  ConfirmDeliveryRemote({
    required DeliveryLifecycleRepository lifecycleRepository,
    required DeliveryAssignmentRepository assignmentRepository,
    required DeliveryCommandRepository commandRepository,
    AdvanceDeliveryWorkflow? advanceWorkflow,
    DateTime Function()? clock,
  }) : _lifecycle = lifecycleRepository,
       _assignments = assignmentRepository,
       _commands = commandRepository,
       _advance =
           advanceWorkflow ?? AdvanceDeliveryWorkflow(assignmentRepository),
       _clock = clock ?? DateTime.now;

  final DeliveryLifecycleRepository _lifecycle;
  final DeliveryAssignmentRepository _assignments;
  final DeliveryCommandRepository _commands;
  final AdvanceDeliveryWorkflow _advance;
  final DateTime Function() _clock;

  Future<DeliveryResult<DeliveryAssignment>> call({
    required String driverId,
    required String commandId,
    bool connectivityOnline = true,
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
    if (current.workflowStage != DriverWorkflowStage.verifying) {
      return const DeliveryFailureResult(
        InvalidDeliveryWorkflowTransition(
          'Delivery confirmation is only allowed after automatic arrival.',
        ),
      );
    }

    final existing = await _commands.getById(commandId: id);
    if (existing.isFailure) {
      return DeliveryFailureResult(
        existing.failureOrNull ?? const DeliveryPersistenceFailure(),
      );
    }
    final recorded = existing.valueOrNull;
    if (recorded != null &&
        recorded.status == LocalDeliveryCommandStatus.completed) {
      return DeliverySuccess(current);
    }

    final version = int.tryParse(current.serverRevision ?? '') ?? 0;
    final payload = <String, Object?>{
      'deliveryId': current.assignmentId,
      'aggregateVersion': version,
    };

    if (!connectivityOnline) {
      await _savePending(
        commandId: id,
        driverId: driverId,
        targetId: current.assignmentId,
        payload: payload,
      );
      await _advance.markPendingSync(driverId: driverId);
      return const DeliveryFailureResult(DeliveryNetworkUnavailable());
    }

    final remote = await _lifecycle.confirmDelivery(
      deliveryId: current.assignmentId,
      aggregateVersion: version,
      idempotencyKey: id,
    );
    if (remote.isFailure) {
      final failure = remote.failureOrNull ?? const DeliveryUnknownFailure();
      if (failure is DeliveryNetworkUnavailable ||
          failure is DeliveryBackendUnavailable) {
        await _savePending(
          commandId: id,
          driverId: driverId,
          targetId: current.assignmentId,
          payload: payload,
        );
        await _advance.markPendingSync(driverId: driverId);
      }
      return DeliveryFailureResult(failure);
    }

    final ack = remote.valueOrNull!;
    _lifecycle.clearCustomerContact(deliveryId: current.assignmentId);
    await _commands.save(
      LocalDeliveryCommand(
        commandId: id,
        driverId: driverId,
        targetId: current.assignmentId,
        type: LocalDeliveryCommandType.confirmDelivery,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: _clock().toUtc(),
        payload: payload,
      ),
    );

    final complete = await _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.completeDelivery,
      commandId: '$id:complete',
      serverRevision: '${ack.aggregateVersion}',
    );
    if (complete.isFailure) return complete;

    final summary = await _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.showSummary,
      commandId: '$id:summary',
      serverRevision: '${ack.aggregateVersion}',
    );
    if (summary.isFailure) return summary;

    final cleared = await _advance.clearPendingSync(driverId: driverId);
    return cleared.isFailure ? summary : cleared;
  }

  Future<void> _savePending({
    required String commandId,
    required String driverId,
    required String targetId,
    required Map<String, Object?> payload,
  }) async {
    await _commands.save(
      LocalDeliveryCommand(
        commandId: commandId,
        driverId: driverId,
        targetId: targetId,
        type: LocalDeliveryCommandType.confirmDelivery,
        status: LocalDeliveryCommandStatus.pendingSync,
        recordedAt: _clock().toUtc(),
        payload: payload,
      ),
    );
  }
}
