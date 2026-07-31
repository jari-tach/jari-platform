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

/// Reports a delivery issue to Backend and opens the local issue stage.
class ReportDeliveryIssueRemote {
  ReportDeliveryIssueRemote({
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
    required String code,
    String? notes,
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
    if (current.workflowStage != DriverWorkflowStage.arrivedPickup &&
        current.workflowStage != DriverWorkflowStage.navToCustomer) {
      return const DeliveryFailureResult(
        InvalidDeliveryWorkflowTransition(
          'Issue reporting is not allowed in the current stage.',
        ),
      );
    }

    final version = int.tryParse(current.serverRevision ?? '') ?? 0;
    final remote = await _lifecycle.reportIssue(
      deliveryId: current.assignmentId,
      aggregateVersion: version,
      idempotencyKey: id,
      code: code,
      notes: notes,
    );
    if (remote.isFailure) {
      return DeliveryFailureResult(
        remote.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }

    await _commands.save(
      LocalDeliveryCommand(
        commandId: id,
        driverId: driverId,
        targetId: current.assignmentId,
        type: LocalDeliveryCommandType.reportIssue,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: _clock().toUtc(),
        payload: {'code': code, 'notes': ?notes},
      ),
    );

    return _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.reportIssue,
      commandId: '$id:localIssue',
      serverRevision: '${remote.valueOrNull!.aggregateVersion}',
    );
  }
}
