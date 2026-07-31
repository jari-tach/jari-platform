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

/// Confirms pickup against Backend (remote) or Fake lifecycle, then advances
/// the local workflow to en-route. Keeps PII hidden until Backend ack.
class ConfirmPickupRemote {
  ConfirmPickupRemote({
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
    String? notes,
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
    if (current.workflowStage != DriverWorkflowStage.waitingPickup &&
        current.workflowStage != DriverWorkflowStage.arrivedPickup) {
      return const DeliveryFailureResult(
        InvalidDeliveryWorkflowTransition(
          'Pickup confirmation is not allowed in the current stage.',
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
      'notes': ?notes,
    };

    if (!connectivityOnline) {
      await _savePending(
        commandId: id,
        driverId: driverId,
        targetId: current.assignmentId,
        payload: payload,
      );
      final pending = await _advance.markPendingSync(driverId: driverId);
      if (pending.isFailure) return pending;
      return DeliveryFailureResult(DeliveryNetworkUnavailable());
    }

    final remote = await _lifecycle.confirmPickup(
      deliveryId: current.assignmentId,
      aggregateVersion: version,
      idempotencyKey: id,
      notes: notes,
    );
    if (remote.isFailure) {
      final failure = remote.failureOrNull ?? const DeliveryUnknownFailure();
      if (_isRetryable(failure)) {
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
    await _saveCompleted(
      commandId: id,
      driverId: driverId,
      targetId: current.assignmentId,
      payload: payload,
    );

    // Local stage: waitingPickup → collected → navToCustomer.
    final confirm = await _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.confirmPickup,
      commandId: '$id:confirmPickup',
      serverRevision: '${ack.aggregateVersion}',
    );
    if (confirm.isFailure) return confirm;

    final enRoute = await _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.startTripCustomer,
      commandId: '$id:startTripCustomer',
      serverRevision: '${ack.aggregateVersion}',
    );
    if (enRoute.isFailure) return enRoute;

    final cleared = await _advance.clearPendingSync(driverId: driverId);
    return cleared.isFailure ? enRoute : cleared;
  }

  bool _isRetryable(DeliveryFailure failure) =>
      failure is DeliveryNetworkUnavailable ||
      failure is DeliveryBackendUnavailable;

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
        type: LocalDeliveryCommandType.confirmPickup,
        status: LocalDeliveryCommandStatus.pendingSync,
        recordedAt: _clock().toUtc(),
        payload: payload,
      ),
    );
  }

  Future<void> _saveCompleted({
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
        type: LocalDeliveryCommandType.confirmPickup,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: _clock().toUtc(),
        payload: payload,
      ),
    );
  }
}
