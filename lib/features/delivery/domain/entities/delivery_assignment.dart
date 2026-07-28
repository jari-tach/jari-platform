import 'delivery_order.dart';
import 'delivery_status.dart';
import 'driver_workflow_stage.dart';

/// Authoritative driver↔delivery binding after successful accept (ADR-020).
///
/// Owns availability `busy` linkage via [assignmentId] (ADR-025 / ADR-018).
/// [workflowStage] is the driver-facing PHASE 2.6 stage machine (ADR-028 JSON).
class DeliveryAssignment {
  /// Creates an immutable delivery assignment.
  ///
  /// Throws [ArgumentError] when identity fields are empty.
  DeliveryAssignment({
    required this.assignmentId,
    required this.offerId,
    required this.driverId,
    required this.status,
    required this.order,
    required this.acceptedAt,
    this.serverRevision,
    this.workflowStage = DriverWorkflowStage.assigned,
    this.resumeAfterIssueStage,
  }) {
    final aid = assignmentId.trim();
    if (aid.isEmpty) {
      throw ArgumentError.value(
        assignmentId,
        'assignmentId',
        'must be non-empty',
      );
    }
    final oid = offerId.trim();
    if (oid.isEmpty) {
      throw ArgumentError.value(offerId, 'offerId', 'must be non-empty');
    }
    final did = driverId.trim();
    if (did.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    if (serverRevision != null && serverRevision!.trim().isEmpty) {
      throw ArgumentError.value(
        serverRevision,
        'serverRevision',
        'when present must be non-empty',
      );
    }
  }

  /// Authoritative assignment id (also used as availability `activeAssignmentId`).
  final String assignmentId;

  /// Provenance offer id.
  final String offerId;

  /// Must match the authenticated session driver id.
  final String driverId;

  /// Coarse operational status.
  final DeliveryStatus status;

  /// Minimal persisted work snapshot for restart (ADR-028).
  final DeliveryOrder order;

  /// Accept confirmation time from authority / local record.
  final DateTime acceptedAt;

  /// Opaque Backend revision when provided.
  final String? serverRevision;

  /// Driver-facing workflow stage (PHASE 2.6).
  final DriverWorkflowStage workflowStage;

  /// Stage to resume after [DriverWorkflowStage.issueOpen].
  final DriverWorkflowStage? resumeAfterIssueStage;

  /// Whether this assignment still owns the driver's active-delivery slot.
  ///
  /// Includes [DeliveryStatus.delivered] so the delivered/summary phase still:
  /// - blocks accepting a new offer
  /// - retains local assignment ownership until final successful release
  /// - remains resumable after restart
  ///
  /// This is **not** limited to “physically transporting an order”. Prefer
  /// [blocksNewOffers] when that intent should be explicit at a call site.
  bool get isActive =>
      status == DeliveryStatus.accepted ||
      status == DeliveryStatus.pickedUp ||
      status == DeliveryStatus.delivered;

  /// Explicit alias for offer-blocking / active-slot ownership ([isActive]).
  bool get blocksNewOffers => isActive;

  /// Returns a copy with selected fields replaced.
  ///
  /// [assignmentId], [offerId], and [driverId] are sovereign.
  DeliveryAssignment copyWith({
    DeliveryStatus? status,
    DeliveryOrder? order,
    DateTime? acceptedAt,
    String? serverRevision,
    bool clearServerRevision = false,
    DriverWorkflowStage? workflowStage,
    DriverWorkflowStage? resumeAfterIssueStage,
    bool clearResumeAfterIssueStage = false,
  }) {
    return DeliveryAssignment(
      assignmentId: assignmentId,
      offerId: offerId,
      driverId: driverId,
      status: status ?? this.status,
      order: order ?? this.order,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      serverRevision: clearServerRevision
          ? null
          : (serverRevision ?? this.serverRevision),
      workflowStage: workflowStage ?? this.workflowStage,
      resumeAfterIssueStage: clearResumeAfterIssueStage
          ? null
          : (resumeAfterIssueStage ?? this.resumeAfterIssueStage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAssignment &&
          assignmentId == other.assignmentId &&
          offerId == other.offerId &&
          driverId == other.driverId &&
          status == other.status &&
          order == other.order &&
          acceptedAt == other.acceptedAt &&
          serverRevision == other.serverRevision &&
          workflowStage == other.workflowStage &&
          resumeAfterIssueStage == other.resumeAfterIssueStage;

  @override
  int get hashCode => Object.hash(
    assignmentId,
    offerId,
    driverId,
    status,
    order,
    acceptedAt,
    serverRevision,
    workflowStage,
    resumeAfterIssueStage,
  );

  @override
  String toString() =>
      'DeliveryAssignment(assignmentId: $assignmentId, '
      'driverId: $driverId, status: $status, stage: $workflowStage)';
}
