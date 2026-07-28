import '../entities/delivery_status.dart';
import '../entities/driver_workflow_stage.dart';
import '../failures/delivery_failure.dart';

/// Named workflow commands (UI → domain). Default-deny outside this map.
enum DriverWorkflowCommand {
  startTripPickup,
  arrivedPickup,
  waitAtPickup,
  confirmPickup,
  startTripCustomer,
  arrivedCustomer,
  startVerify,
  completeDelivery,
  showSummary,
  reportIssue,
  resumeAfterIssue,
}

/// Pure Fake-authoritative transition table (PHASE 2.6).
///
/// No I/O. Widgets never call this directly — use cases apply + persist.
class DriverWorkflowTransitionPolicy {
  const DriverWorkflowTransitionPolicy();

  /// Returns the next stage or a typed failure.
  ({DriverWorkflowStage? next, DeliveryFailure? failure}) evaluate({
    required DriverWorkflowStage current,
    required DriverWorkflowCommand command,
    DriverWorkflowStage? resumeAfterIssueStage,
  }) {
    if (command == DriverWorkflowCommand.reportIssue) {
      if (current == DriverWorkflowStage.arrivedPickup ||
          current == DriverWorkflowStage.navToCustomer) {
        return (next: DriverWorkflowStage.issueOpen, failure: null);
      }
      return (
        next: null,
        failure: const InvalidDeliveryWorkflowTransition(
          'Issue reporting is not allowed in the current stage.',
        ),
      );
    }

    if (command == DriverWorkflowCommand.resumeAfterIssue) {
      if (current != DriverWorkflowStage.issueOpen) {
        return (
          next: null,
          failure: const InvalidDeliveryWorkflowTransition(
            'Resume is only allowed while an issue is open.',
          ),
        );
      }
      final resume = resumeAfterIssueStage;
      if (resume == null || resume == DriverWorkflowStage.issueOpen) {
        return (
          next: null,
          failure: const InvalidDeliveryWorkflowTransition(
            'Missing resume stage for open issue.',
          ),
        );
      }
      return (next: resume, failure: null);
    }

    final allowed = _table[current];
    if (allowed == null) {
      return (
        next: null,
        failure: const InvalidDeliveryWorkflowTransition(
          'No further workflow transitions from this stage.',
        ),
      );
    }
    final next = allowed[command];
    if (next == null) {
      return (
        next: null,
        failure: const InvalidDeliveryWorkflowTransition(
          'Workflow command is not allowed in the current stage.',
        ),
      );
    }
    return (next: next, failure: null);
  }

  /// Maps workflow stage onto coarse [DeliveryStatus] when milestones hit.
  DeliveryStatus statusForStage(
    DriverWorkflowStage stage,
    DeliveryStatus current,
  ) {
    return switch (stage) {
      DriverWorkflowStage.collected ||
      DriverWorkflowStage.navToCustomer ||
      DriverWorkflowStage.arrivedCustomer ||
      DriverWorkflowStage.verifying => DeliveryStatus.pickedUp,
      DriverWorkflowStage.delivered ||
      DriverWorkflowStage.summary => DeliveryStatus.delivered,
      DriverWorkflowStage.issueOpen => current,
      _ =>
        current == DeliveryStatus.delivered ||
                current == DeliveryStatus.pickedUp
            ? current
            : DeliveryStatus.accepted,
    };
  }

  static const Map<
    DriverWorkflowStage,
    Map<DriverWorkflowCommand, DriverWorkflowStage>
  >
  _table = {
    DriverWorkflowStage.assigned: {
      DriverWorkflowCommand.startTripPickup: DriverWorkflowStage.navToPickup,
    },
    DriverWorkflowStage.navToPickup: {
      DriverWorkflowCommand.arrivedPickup: DriverWorkflowStage.arrivedPickup,
    },
    DriverWorkflowStage.arrivedPickup: {
      DriverWorkflowCommand.waitAtPickup: DriverWorkflowStage.waitingPickup,
    },
    DriverWorkflowStage.waitingPickup: {
      DriverWorkflowCommand.confirmPickup: DriverWorkflowStage.collected,
    },
    DriverWorkflowStage.collected: {
      DriverWorkflowCommand.startTripCustomer:
          DriverWorkflowStage.navToCustomer,
    },
    DriverWorkflowStage.navToCustomer: {
      DriverWorkflowCommand.arrivedCustomer:
          DriverWorkflowStage.arrivedCustomer,
    },
    DriverWorkflowStage.arrivedCustomer: {
      DriverWorkflowCommand.startVerify: DriverWorkflowStage.verifying,
    },
    DriverWorkflowStage.verifying: {
      DriverWorkflowCommand.completeDelivery: DriverWorkflowStage.delivered,
    },
    DriverWorkflowStage.delivered: {
      DriverWorkflowCommand.showSummary: DriverWorkflowStage.summary,
    },
  };
}
