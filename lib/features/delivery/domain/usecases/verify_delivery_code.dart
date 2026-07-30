import '../entities/delivery_assignment.dart';
import '../entities/delivery_result.dart';
import '../entities/driver_workflow_stage.dart';
import '../failures/delivery_failure.dart';
import '../policies/driver_workflow_transition_policy.dart';
import '../repositories/delivery_assignment_repository.dart';
import 'advance_delivery_workflow.dart';

/// Fake/trial delivery verification code (debug only construction sites).
class FakeDeliveryVerificationCodes {
  const FakeDeliveryVerificationCodes._();

  /// Deterministic Fake code for Alpha (ADR-027 style — not for production).
  static const trialCode = '1234';
}

/// Verifies delivery code then advances verifying → delivered → summary.
class VerifyDeliveryCode {
  VerifyDeliveryCode(
    this._assignmentRepository, {
    this.policy = const DriverWorkflowTransitionPolicy(),
    String Function()? expectedCodeReader,
  }) : _expectedCodeReader =
           expectedCodeReader ??
           (() => FakeDeliveryVerificationCodes.trialCode),
       _advance = AdvanceDeliveryWorkflow(
         _assignmentRepository,
         policy: policy,
       );

  final DeliveryAssignmentRepository _assignmentRepository;
  final DriverWorkflowTransitionPolicy policy;
  final String Function() _expectedCodeReader;
  final AdvanceDeliveryWorkflow _advance;

  Future<DeliveryResult<DeliveryAssignment>> call({
    required String driverId,
    required String code,
    String? commandId,
    bool simulateOffline = false,
  }) async {
    final expected = _expectedCodeReader().trim();
    if (code.trim() != expected) {
      return const DeliveryFailureResult(DeliveryVerificationFailed());
    }

    final currentResult = await _assignmentRepository.getActiveAssignment(
      driverId: driverId,
    );
    if (currentResult.isFailure) {
      return DeliveryFailureResult(
        currentResult.failureOrNull ?? const DeliveryUnknownFailure(),
      );
    }
    final current = currentResult.valueOrNull;
    if (current == null) {
      return const DeliveryFailureResult(DeliveryAssignmentNotFound());
    }
    final normalizedCommandId = commandId?.trim();
    if (commandId != null && normalizedCommandId!.isEmpty) {
      return const DeliveryFailureResult(DeliveryInvalidCommandId());
    }
    final completeCommandId = normalizedCommandId == null
        ? null
        : '$normalizedCommandId:complete';
    final summaryCommandId = normalizedCommandId == null
        ? null
        : '$normalizedCommandId:summary';
    if (completeCommandId != null &&
        summaryCommandId != null &&
        current.completedCommandIds.contains(completeCommandId) &&
        current.completedCommandIds.contains(summaryCommandId)) {
      return DeliverySuccess(current);
    }
    if (current.workflowStage != DriverWorkflowStage.verifying) {
      return const DeliveryFailureResult(
        InvalidDeliveryWorkflowTransition(
          'Verification is only allowed in the verifying stage.',
        ),
      );
    }

    final complete = await _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.completeDelivery,
      commandId: completeCommandId,
      simulateOffline: simulateOffline,
    );
    if (complete.isFailure) return complete;

    return _advance(
      driverId: driverId,
      command: DriverWorkflowCommand.showSummary,
      commandId: summaryCommandId,
      simulateOffline: simulateOffline,
    );
  }
}
