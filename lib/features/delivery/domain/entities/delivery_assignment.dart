import 'delivery_order.dart';
import 'delivery_status.dart';

/// Authoritative driver↔delivery binding after successful accept (ADR-020).
///
/// Owns availability `busy` linkage via [assignmentId] (ADR-025 / ADR-018).
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

  /// Operational status ([DeliveryStatus.accepted] in PHASE 2.5).
  final DeliveryStatus status;

  /// Minimal persisted work snapshot for restart (ADR-028).
  final DeliveryOrder order;

  /// Accept confirmation time from authority / local record.
  final DateTime acceptedAt;

  /// Opaque Backend revision when provided.
  final String? serverRevision;

  /// Whether this assignment is still the driver's active work in PHASE 2.5.
  bool get isActive =>
      status == DeliveryStatus.accepted || status == DeliveryStatus.pickedUp;

  /// Returns a copy with selected fields replaced.
  ///
  /// [assignmentId], [offerId], and [driverId] are sovereign.
  DeliveryAssignment copyWith({
    DeliveryStatus? status,
    DeliveryOrder? order,
    DateTime? acceptedAt,
    String? serverRevision,
    bool clearServerRevision = false,
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
          serverRevision == other.serverRevision;

  @override
  int get hashCode => Object.hash(
    assignmentId,
    offerId,
    driverId,
    status,
    order,
    acceptedAt,
    serverRevision,
  );

  @override
  String toString() =>
      'DeliveryAssignment(assignmentId: $assignmentId, '
      'driverId: $driverId, status: $status)';
}
