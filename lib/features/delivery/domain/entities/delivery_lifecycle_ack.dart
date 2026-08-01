import 'delivery_status.dart';
import 'driver_workflow_stage.dart';

/// Canonical Backend delivery lifecycle states (contracts-v0.1.0).
///
/// These names are wire-level contract values and must never be renamed.
abstract final class CanonicalDeliveryStates {
  static const offered = 'offered';
  static const accepted = 'accepted';
  static const pickupAwaitingManualConfirmation =
      'pickupAwaitingManualConfirmation';
  static const pickupConfirmedManually = 'pickupConfirmedManually';
  static const enRouteToCustomer = 'enRouteToCustomer';
  static const arrivedAutomaticallyByLocation =
      'arrivedAutomaticallyByLocation';
  static const deliveryAwaitingManualConfirmation =
      'deliveryAwaitingManualConfirmation';
  static const deliveredConfirmedManually = 'deliveredConfirmedManually';
  static const cancelled = 'cancelled';
  static const expired = 'expired';
  static const rejected = 'rejected';

  /// States in which the Backend allows reading the current customer contact.
  static const contactAllowed = {
    pickupConfirmedManually,
    enRouteToCustomer,
    arrivedAutomaticallyByLocation,
    deliveryAwaitingManualConfirmation,
  };
}

/// Maps a canonical Backend delivery state to the local [DeliveryStatus]
/// used by assignment persistence and Active Delivery UI.
///
/// Backend accept commits the delivery to
/// [CanonicalDeliveryStates.pickupAwaitingManualConfirmation] (not the bare
/// string `accepted`). The previous client path stored `action.state` verbatim
/// and then failed in `_parseDeliveryStatus`, so the HTTP accept succeeded
/// while local assignment persistence never ran.
DeliveryStatus deliveryStatusForCanonicalState(String state) {
  switch (state) {
    case CanonicalDeliveryStates.offered:
    case CanonicalDeliveryStates.accepted:
    case CanonicalDeliveryStates.pickupAwaitingManualConfirmation:
      return DeliveryStatus.accepted;
    case CanonicalDeliveryStates.pickupConfirmedManually:
    case CanonicalDeliveryStates.enRouteToCustomer:
    case CanonicalDeliveryStates.arrivedAutomaticallyByLocation:
    case CanonicalDeliveryStates.deliveryAwaitingManualConfirmation:
      return DeliveryStatus.pickedUp;
    case CanonicalDeliveryStates.deliveredConfirmedManually:
      return DeliveryStatus.delivered;
    case CanonicalDeliveryStates.cancelled:
    case CanonicalDeliveryStates.expired:
    case CanonicalDeliveryStates.rejected:
      return DeliveryStatus.cancelled;
    default:
      // Local enum names already used by Fake / Drift snapshots.
      for (final value in DeliveryStatus.values) {
        if (value.name == state) return value;
      }
      throw FormatException('unknown delivery status: $state');
  }
}

/// Maps the local [DriverWorkflowStage] to the canonical Backend state used
/// for read-side calls (for example customer contact eligibility).
String? canonicalDeliveryStateForStage(DriverWorkflowStage stage) {
  return switch (stage) {
    DriverWorkflowStage.assigned ||
    DriverWorkflowStage.navToPickup ||
    DriverWorkflowStage.arrivedPickup ||
    DriverWorkflowStage.waitingPickup =>
      CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
    DriverWorkflowStage.collected =>
      CanonicalDeliveryStates.pickupConfirmedManually,
    DriverWorkflowStage.navToCustomer =>
      CanonicalDeliveryStates.enRouteToCustomer,
    DriverWorkflowStage.arrivedCustomer =>
      CanonicalDeliveryStates.arrivedAutomaticallyByLocation,
    DriverWorkflowStage.verifying =>
      CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
    DriverWorkflowStage.delivered || DriverWorkflowStage.summary =>
      CanonicalDeliveryStates.deliveredConfirmedManually,
    DriverWorkflowStage.issueOpen => null,
  };
}

/// Backend acknowledgment for a delivery lifecycle mutation or read.
final class DeliveryLifecycleAck {
  const DeliveryLifecycleAck({
    required this.deliveryId,
    required this.state,
    required this.aggregateVersion,
    required this.updatedAt,
  });

  /// Backend delivery aggregate id.
  final String deliveryId;

  /// Canonical Backend state after the mutation (see [CanonicalDeliveryStates]).
  final String state;

  /// Authoritative aggregate version after the mutation.
  final int aggregateVersion;

  /// Backend-side mutation timestamp (UTC).
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryLifecycleAck &&
          deliveryId == other.deliveryId &&
          state == other.state &&
          aggregateVersion == other.aggregateVersion &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(deliveryId, state, aggregateVersion, updatedAt);

  @override
  String toString() =>
      'DeliveryLifecycleAck(deliveryId: $deliveryId, state: $state, '
      'aggregateVersion: $aggregateVersion)';
}

/// Location evidence attached to an automatic-arrival report.
final class ArrivalEvidence {
  const ArrivalEvidence({
    required this.clientEventId,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.policyVersion,
  });

  /// Stable client-generated id — identical across retries of one event.
  final String clientEventId;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;

  /// Geofence policy version used to evaluate the arrival (ADR-029).
  final String policyVersion;
}
