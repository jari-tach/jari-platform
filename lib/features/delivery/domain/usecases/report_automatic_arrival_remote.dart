import '../entities/delivery_assignment.dart';
import '../entities/delivery_lifecycle_ack.dart';
import '../entities/delivery_result.dart';
import '../entities/driver_workflow_stage.dart';
import '../entities/local_delivery_command.dart';
import '../failures/delivery_failure.dart';
import '../policies/driver_workflow_transition_policy.dart';
import '../repositories/delivery_assignment_repository.dart';
import '../repositories/delivery_command_repository.dart';
import '../repositories/delivery_lifecycle_repository.dart';
import 'advance_delivery_workflow.dart';

/// Reports automatic geofence arrival to Backend, then advances local state.
///
/// Delivery confirmation stays locked until Backend acknowledgment.
class ReportAutomaticArrivalRemote {
  ReportAutomaticArrivalRemote({
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
    required ArrivalEvidence evidence,
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

    if (current.workflowStage != DriverWorkflowStage.navToCustomer) {
      return const DeliveryFailureResult(
        InvalidDeliveryWorkflowTransition(
          'Automatic arrival is only allowed while en route to the customer.',
        ),
      );
    }

    final version = int.tryParse(current.serverRevision ?? '') ?? 0;
    final payload = <String, Object?>{
      'deliveryId': current.assignmentId,
      'aggregateVersion': version,
      'clientEventId': evidence.clientEventId,
      'capturedAt': evidence.capturedAt.toUtc().toIso8601String(),
      'latitude': evidence.latitude,
      'longitude': evidence.longitude,
      'accuracyMeters': evidence.accuracyMeters,
      'policyVersion': evidence.policyVersion,
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

    final remote = await _lifecycle.reportAutomaticArrival(
      deliveryId: current.assignmentId,
      aggregateVersion: version,
      idempotencyKey: id,
      evidence: evidence,
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
    await _commands.save(
      LocalDeliveryCommand(
        commandId: id,
        driverId: driverId,
        targetId: current.assignmentId,
        type: LocalDeliveryCommandType.reportArrival,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: _clock().toUtc(),
        payload: payload,
      ),
    );

    final arrived = await _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.arrivedCustomer,
      commandId: '$id:arrivedCustomer',
      serverRevision: '${ack.aggregateVersion}',
    );
    if (arrived.isFailure) return arrived;

    final verifying = await _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.startVerify,
      commandId: '$id:startVerify',
      serverRevision: '${ack.aggregateVersion}',
    );
    if (verifying.isFailure) return verifying;

    final cleared = await _advance.clearPendingSync(driverId: driverId);
    return cleared.isFailure ? verifying : cleared;
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
        type: LocalDeliveryCommandType.reportArrival,
        status: LocalDeliveryCommandStatus.pendingSync,
        recordedAt: _clock().toUtc(),
        payload: payload,
      ),
    );
  }
}
