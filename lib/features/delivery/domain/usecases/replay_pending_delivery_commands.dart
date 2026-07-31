import '../entities/delivery_assignment.dart';
import '../entities/delivery_lifecycle_ack.dart';
import '../entities/delivery_result.dart';
import '../entities/local_delivery_command.dart';
import '../failures/delivery_failure.dart';
import '../repositories/delivery_assignment_repository.dart';
import '../repositories/delivery_command_repository.dart';
import 'advance_delivery_workflow.dart';
import 'confirm_delivery_remote.dart';
import 'confirm_pickup_remote.dart';
import 'report_automatic_arrival_remote.dart';

/// Replays pending local lifecycle commands with the same idempotency keys.
///
/// Uses the existing command ledger — does not create a second outbox.
class ReplayPendingDeliveryCommands {
  final DeliveryCommandRepository _commands;
  final DeliveryAssignmentRepository _assignments;
  final ConfirmPickupRemote _confirmPickup;
  final ReportAutomaticArrivalRemote _reportArrival;
  final ConfirmDeliveryRemote _confirmDelivery;
  final AdvanceDeliveryWorkflow _advance;

  ReplayPendingDeliveryCommands({
    required DeliveryCommandRepository commandRepository,
    required DeliveryAssignmentRepository assignmentRepository,
    required this._confirmPickup,
    required this._reportArrival,
    required this._confirmDelivery,
    AdvanceDeliveryWorkflow? advanceWorkflow,
  }) : _commands = commandRepository,
       _assignments = assignmentRepository,
       _advance =
           advanceWorkflow ?? AdvanceDeliveryWorkflow(assignmentRepository);

  Future<DeliveryResult<DeliveryAssignment?>> call({
    required String driverId,
    bool connectivityOnline = true,
  }) async {
    if (!connectivityOnline) {
      return const DeliveryFailureResult(DeliveryNetworkUnavailable());
    }

    final pendingResult = await _commands.listPending(driverId: driverId);
    if (pendingResult.isFailure) {
      return DeliveryFailureResult(
        pendingResult.failureOrNull ?? const DeliveryPersistenceFailure(),
      );
    }

    DeliveryAssignment? latest;
    for (final command in pendingResult.valueOrNull ?? const []) {
      final replayed = await _replay(command);
      if (replayed.isFailure) {
        return DeliveryFailureResult(
          replayed.failureOrNull ?? const DeliveryUnknownFailure(),
        );
      }
      latest = replayed.valueOrNull ?? latest;
    }

    if (latest == null) {
      final active = await _assignments.getActiveAssignment(driverId: driverId);
      if (active.isFailure) {
        return DeliveryFailureResult(
          active.failureOrNull ?? const DeliveryUnknownFailure(),
        );
      }
      latest = active.valueOrNull;
      if (latest?.pendingSync == true) {
        final cleared = await _advance.clearPendingSync(driverId: driverId);
        if (cleared.isFailure) {
          return DeliveryFailureResult(
            cleared.failureOrNull ?? const DeliveryPersistenceFailure(),
          );
        }
        latest = cleared.valueOrNull;
      }
    }
    return DeliverySuccess(latest);
  }

  Future<DeliveryResult<DeliveryAssignment>> _replay(
    LocalDeliveryCommand command,
  ) {
    switch (command.type) {
      case LocalDeliveryCommandType.confirmPickup:
        return _confirmPickup(
          driverId: command.driverId,
          commandId: command.commandId,
          notes: command.payload?['notes'] as String?,
          connectivityOnline: true,
        );
      case LocalDeliveryCommandType.reportArrival:
        final evidence = _evidenceFrom(command.payload);
        if (evidence == null) {
          return Future.value(
            const DeliveryFailureResult(DeliveryContractViolation()),
          );
        }
        return _reportArrival(
          driverId: command.driverId,
          commandId: command.commandId,
          evidence: evidence,
          connectivityOnline: true,
        );
      case LocalDeliveryCommandType.confirmDelivery:
        return _confirmDelivery(
          driverId: command.driverId,
          commandId: command.commandId,
          connectivityOnline: true,
        );
      case LocalDeliveryCommandType.acceptOffer:
      case LocalDeliveryCommandType.rejectOffer:
      case LocalDeliveryCommandType.reportIssue:
      case LocalDeliveryCommandType.cancel:
        // Not replayed by the lifecycle pending-sync path.
        return _assignments
            .getActiveAssignment(driverId: command.driverId)
            .then((result) {
              if (result.isFailure) {
                return DeliveryFailureResult(
                  result.failureOrNull ?? const DeliveryUnknownFailure(),
                );
              }
              final assignment = result.valueOrNull;
              if (assignment == null) {
                return const DeliveryFailureResult(
                  DeliveryAssignmentNotFound(),
                );
              }
              return DeliverySuccess(assignment);
            });
    }
  }

  ArrivalEvidence? _evidenceFrom(Map<String, Object?>? payload) {
    if (payload == null) return null;
    final clientEventId = payload['clientEventId'];
    final capturedAtRaw = payload['capturedAt'];
    final latitude = payload['latitude'];
    final longitude = payload['longitude'];
    final accuracy = payload['accuracyMeters'];
    final policy = payload['policyVersion'];
    if (clientEventId is! String ||
        capturedAtRaw is! String ||
        latitude is! num ||
        longitude is! num ||
        accuracy is! num ||
        policy is! String) {
      return null;
    }
    final capturedAt = DateTime.tryParse(capturedAtRaw);
    if (capturedAt == null) return null;
    return ArrivalEvidence(
      clientEventId: clientEventId,
      capturedAt: capturedAt.toUtc(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      accuracyMeters: accuracy.toDouble(),
      policyVersion: policy,
    );
  }
}
