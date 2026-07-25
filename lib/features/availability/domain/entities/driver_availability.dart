import 'availability_status.dart';

/// Effective local availability aggregate (PHASE 2.4 Increment 1).
///
/// Not Backend authority. Local [available] without confirmation must not be
/// treated as confirmed available (BR-AVAIL-007 / BR-AVAIL-008 / ADR-016).
class DriverAvailability {
  DriverAvailability({
    required this.driverId,
    required this.status,
    required this.source,
    required this.lastChangedAt,
    this.lastConfirmedAt,
    this.pendingSync = false,
    this.revision,
    this.reason,
    this.activeAssignmentId,
  }) {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    if (revision != null && revision! < 0) {
      throw ArgumentError.value(revision, 'revision', 'cannot be negative');
    }
    if (status == AvailabilityStatus.busy &&
        (source == AvailabilitySource.localUserAction ||
            source == AvailabilitySource.restoredLocalState)) {
      throw ArgumentError(
        'busy must not originate from local user or restore alone '
        '(BR-AVAIL-004 / ADR-018)',
      );
    }
    if (status == AvailabilityStatus.busy &&
        activeAssignmentId != null &&
        activeAssignmentId!.trim().isEmpty) {
      throw ArgumentError.value(
        activeAssignmentId,
        'activeAssignmentId',
        'when present must be non-empty',
      );
    }
    if (status != AvailabilityStatus.busy &&
        activeAssignmentId != null &&
        activeAssignmentId!.trim().isNotEmpty) {
      throw ArgumentError(
        'activeAssignmentId is only valid while status is busy',
      );
    }
  }

  final String driverId;
  final AvailabilityStatus status;
  final AvailabilitySource source;
  final DateTime lastChangedAt;
  final DateTime? lastConfirmedAt;
  final bool pendingSync;
  final int? revision;
  final String? reason;
  final String? activeAssignmentId;

  /// Confirmed available only when status is available, sync is settled, and
  /// confirmation is present from a non-restore source (ADR-016 / ADR-019).
  bool get isConfirmedAvailable =>
      status == AvailabilityStatus.available &&
      !pendingSync &&
      lastConfirmedAt != null &&
      source != AvailabilitySource.restoredLocalState;

  /// Restored local available intent is never authoritative confirmation.
  bool get isRestoredUnconfirmedAvailable =>
      status == AvailabilityStatus.available &&
      source == AvailabilitySource.restoredLocalState;

  /// Non-sovereign fields only — [driverId] cannot change (BR-AVAIL-014).
  DriverAvailability copyWith({
    AvailabilityStatus? status,
    AvailabilitySource? source,
    DateTime? lastChangedAt,
    DateTime? lastConfirmedAt,
    bool clearLastConfirmedAt = false,
    bool? pendingSync,
    int? revision,
    bool clearRevision = false,
    String? reason,
    bool clearReason = false,
    String? activeAssignmentId,
    bool clearActiveAssignmentId = false,
  }) {
    return DriverAvailability(
      driverId: driverId,
      status: status ?? this.status,
      source: source ?? this.source,
      lastChangedAt: lastChangedAt ?? this.lastChangedAt,
      lastConfirmedAt: clearLastConfirmedAt
          ? null
          : (lastConfirmedAt ?? this.lastConfirmedAt),
      pendingSync: pendingSync ?? this.pendingSync,
      revision: clearRevision ? null : (revision ?? this.revision),
      reason: clearReason ? null : (reason ?? this.reason),
      activeAssignmentId: clearActiveAssignmentId
          ? null
          : (activeAssignmentId ?? this.activeAssignmentId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverAvailability &&
          driverId == other.driverId &&
          status == other.status &&
          source == other.source &&
          lastChangedAt == other.lastChangedAt &&
          lastConfirmedAt == other.lastConfirmedAt &&
          pendingSync == other.pendingSync &&
          revision == other.revision &&
          reason == other.reason &&
          activeAssignmentId == other.activeAssignmentId;

  @override
  int get hashCode => Object.hash(
    driverId,
    status,
    source,
    lastChangedAt,
    lastConfirmedAt,
    pendingSync,
    revision,
    reason,
    activeAssignmentId,
  );
}
