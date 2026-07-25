import 'availability_status.dart';

/// Backend/system-owned availability snapshot applied to local effective state.
///
/// Must not use [AvailabilitySource.localUserAction] (not authoritative).
class AuthoritativeAvailabilityUpdate {
  AuthoritativeAvailabilityUpdate({
    required this.driverId,
    required this.status,
    required this.source,
    required this.confirmedAt,
    this.revision,
    this.activeAssignmentId,
    this.reason,
  }) {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    if (source == AvailabilitySource.localUserAction ||
        source == AvailabilitySource.restoredLocalState) {
      throw ArgumentError(
        'authoritative update cannot use local or restored source',
      );
    }
    if (revision != null && revision! < 0) {
      throw ArgumentError.value(revision, 'revision', 'cannot be negative');
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
  }

  final String driverId;
  final AvailabilityStatus status;
  final AvailabilitySource source;
  final DateTime confirmedAt;
  final int? revision;
  final String? activeAssignmentId;
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthoritativeAvailabilityUpdate &&
          driverId == other.driverId &&
          status == other.status &&
          source == other.source &&
          confirmedAt == other.confirmedAt &&
          revision == other.revision &&
          activeAssignmentId == other.activeAssignmentId &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(
    driverId,
    status,
    source,
    confirmedAt,
    revision,
    activeAssignmentId,
    reason,
  );
}
