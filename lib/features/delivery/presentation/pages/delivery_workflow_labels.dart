import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/driver_workflow_stage.dart';
import '../../domain/policies/driver_workflow_transition_policy.dart';

String deliveryWorkflowStageLabel(
  AppLocalizations l10n,
  DriverWorkflowStage stage,
) {
  return switch (stage) {
    DriverWorkflowStage.assigned => l10n.deliveryStageAssigned,
    DriverWorkflowStage.navToPickup => l10n.deliveryStageNavPickup,
    DriverWorkflowStage.arrivedPickup => l10n.deliveryStageArrivedPickup,
    DriverWorkflowStage.waitingPickup => l10n.deliveryStageWaitingPickup,
    DriverWorkflowStage.collected => l10n.deliveryStageCollected,
    DriverWorkflowStage.navToCustomer => l10n.deliveryStageNavCustomer,
    DriverWorkflowStage.arrivedCustomer => l10n.deliveryStageArrivedCustomer,
    DriverWorkflowStage.verifying => l10n.deliveryStageVerifying,
    DriverWorkflowStage.delivered => l10n.deliveryStageDelivered,
    DriverWorkflowStage.summary => l10n.deliveryStageSummary,
    DriverWorkflowStage.issueOpen => l10n.deliveryStageIssueOpen,
  };
}

List<String> deliveryWorkflowTimelineLabels(AppLocalizations l10n) => [
  l10n.deliveryStageAssigned,
  l10n.deliveryStageNavPickup,
  l10n.deliveryStageArrivedPickup,
  l10n.deliveryStageWaitingPickup,
  l10n.deliveryStageCollected,
  l10n.deliveryStageNavCustomer,
  l10n.deliveryStageArrivedCustomer,
  l10n.deliveryStageVerifying,
  l10n.deliveryStageDelivered,
  l10n.deliveryStageSummary,
];

int deliveryWorkflowTimelineIndex(DriverWorkflowStage stage) {
  return switch (stage) {
    DriverWorkflowStage.assigned => 0,
    DriverWorkflowStage.navToPickup => 1,
    DriverWorkflowStage.arrivedPickup => 2,
    DriverWorkflowStage.waitingPickup => 3,
    DriverWorkflowStage.collected => 4,
    DriverWorkflowStage.navToCustomer => 5,
    DriverWorkflowStage.arrivedCustomer => 6,
    DriverWorkflowStage.verifying => 7,
    DriverWorkflowStage.delivered => 8,
    DriverWorkflowStage.summary => 9,
    DriverWorkflowStage.issueOpen => 2,
  };
}

DriverWorkflowCommand? deliveryPrimaryCommand(DriverWorkflowStage stage) {
  return switch (stage) {
    DriverWorkflowStage.assigned => DriverWorkflowCommand.startTripPickup,
    DriverWorkflowStage.navToPickup => null,
    DriverWorkflowStage.arrivedPickup => DriverWorkflowCommand.waitAtPickup,
    DriverWorkflowStage.waitingPickup => DriverWorkflowCommand.confirmPickup,
    DriverWorkflowStage.collected => DriverWorkflowCommand.startTripCustomer,
    DriverWorkflowStage.navToCustomer => null,
    DriverWorkflowStage.delivered => DriverWorkflowCommand.showSummary,
    _ => null,
  };
}

String deliveryPrimaryActionLabel(
  AppLocalizations l10n,
  DriverWorkflowCommand command,
) {
  return switch (command) {
    DriverWorkflowCommand.startTripPickup => l10n.deliveryActionStartPickup,
    DriverWorkflowCommand.arrivedPickup => l10n.deliveryActionArrivedPickup,
    DriverWorkflowCommand.waitAtPickup => l10n.deliveryActionWaitPickup,
    DriverWorkflowCommand.confirmPickup => l10n.deliveryActionConfirmPickup,
    DriverWorkflowCommand.startTripCustomer => l10n.deliveryActionStartCustomer,
    DriverWorkflowCommand.arrivedCustomer => l10n.deliveryActionArrivedCustomer,
    DriverWorkflowCommand.startVerify => l10n.deliveryActionStartVerify,
    DriverWorkflowCommand.showSummary => l10n.deliveryActionShowSummary,
    DriverWorkflowCommand.completeDelivery => l10n.deliveryVerifySubmit,
    DriverWorkflowCommand.reportIssue => l10n.deliveryReportIssueAction,
    DriverWorkflowCommand.resumeAfterIssue => l10n.deliveryResumeIssueAction,
  };
}
