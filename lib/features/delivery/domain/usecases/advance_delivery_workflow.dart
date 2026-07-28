import '../entities/delivery_assignment.dart';
import '../entities/delivery_result.dart';
import '../entities/driver_workflow_stage.dart';
import '../failures/delivery_failure.dart';
import '../policies/driver_workflow_transition_policy.dart';
import '../repositories/delivery_assignment_repository.dart';

/// Advances (or issues/resumes) the active delivery workflow and persists.
class AdvanceDeliveryWorkflow {
  const AdvanceDeliveryWorkflow(
    this._assignmentRepository, {
    this.policy = const DriverWorkflowTransitionPolicy(),
  });

  final DeliveryAssignmentRepository _assignmentRepository;
  final DriverWorkflowTransitionPolicy policy;

  Future<DeliveryResult<DeliveryAssignment>> call({
    required String driverId,
    required DriverWorkflowCommand command,
  }) async {
    final currentResult = await _assignmentRepository.getActiveAssignment(
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
    if (current.driverId != driverId) {
      return const DeliveryFailureResult(DeliverySecurityPolicyDenied());
    }

    final evaluation = policy.evaluate(
      current: current.workflowStage,
      command: command,
      resumeAfterIssueStage: current.resumeAfterIssueStage,
    );
    if (evaluation.failure != null) {
      return DeliveryFailureResult(evaluation.failure!);
    }
    final next = evaluation.next!;

    final updated = _applyStage(current, next, command);
    final persist = await _assignmentRepository.upsertAccepted(updated);
    if (persist.isFailure) {
      return DeliveryFailureResult(
        persist.failureOrNull ?? const DeliveryPersistenceFailure(),
      );
    }
    return DeliverySuccess(updated);
  }

  DeliveryAssignment _applyStage(
    DeliveryAssignment current,
    DriverWorkflowStage next,
    DriverWorkflowCommand command,
  ) {
    final status = policy.statusForStage(next, current.status);
    if (command == DriverWorkflowCommand.reportIssue) {
      return current.copyWith(
        workflowStage: next,
        status: status,
        resumeAfterIssueStage: current.workflowStage,
      );
    }
    if (command == DriverWorkflowCommand.resumeAfterIssue) {
      return current.copyWith(
        workflowStage: next,
        status: status,
        clearResumeAfterIssueStage: true,
      );
    }
    return current.copyWith(workflowStage: next, status: status);
  }
}
