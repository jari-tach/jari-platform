import '../../domain/entities/availability_status.dart';
import '../../domain/entities/driver_availability.dart';

/// Storage record for local availability snapshot (PHASE 2.4 / ADR-019).
///
/// Separate from [DriverAvailability] — never implies Backend authority.
class PersistedDriverAvailabilityRecord {
  static const int currentSchemaVersion = 1;

  PersistedDriverAvailabilityRecord({
    required this.schemaVersion,
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
  }

  final int schemaVersion;
  final String driverId;
  final AvailabilityStatus status;
  final AvailabilitySource source;
  final DateTime lastChangedAt;
  final DateTime? lastConfirmedAt;
  final bool pendingSync;
  final int? revision;
  final String? reason;
  final String? activeAssignmentId;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'driverId': driverId,
    'status': status.name,
    'source': source.name,
    'lastChangedAt': lastChangedAt.toUtc().toIso8601String(),
    'lastConfirmedAt': lastConfirmedAt?.toUtc().toIso8601String(),
    'pendingSync': pendingSync,
    'revision': revision,
    'reason': reason,
    'activeAssignmentId': activeAssignmentId,
  };

  /// Deterministic decode. Throws [FormatException] on malformed / unsupported
  /// data — callers must clear storage and map to typed failures.
  factory PersistedDriverAvailabilityRecord.fromJson(
    Map<String, Object?> json,
  ) {
    final schema = json['schemaVersion'];
    if (schema is! int) {
      throw const FormatException('schemaVersion missing or invalid');
    }
    if (schema != currentSchemaVersion) {
      throw FormatException('unsupported schemaVersion: $schema');
    }

    final driverId = json['driverId'];
    if (driverId is! String || driverId.trim().isEmpty) {
      throw const FormatException('driverId missing or empty');
    }

    final status = _parseStatus(json['status']);
    final source = _parseSource(json['source']);
    final lastChangedAt = _parseRequiredDateTime(
      json['lastChangedAt'],
      'lastChangedAt',
    );
    final lastConfirmedAt = _parseOptionalDateTime(
      json['lastConfirmedAt'],
      'lastConfirmedAt',
    );

    final pendingSync = json['pendingSync'];
    if (pendingSync is! bool) {
      throw const FormatException('pendingSync missing or invalid');
    }

    final revision = json['revision'];
    if (revision != null && revision is! int) {
      throw const FormatException('revision invalid');
    }
    if (revision is int && revision < 0) {
      throw const FormatException('revision cannot be negative');
    }

    final reason = json['reason'];
    if (reason != null && reason is! String) {
      throw const FormatException('reason invalid');
    }

    final activeAssignmentId = json['activeAssignmentId'];
    if (activeAssignmentId != null && activeAssignmentId is! String) {
      throw const FormatException('activeAssignmentId invalid');
    }
    if (activeAssignmentId is String && activeAssignmentId.trim().isEmpty) {
      throw const FormatException('activeAssignmentId empty');
    }

    return PersistedDriverAvailabilityRecord(
      schemaVersion: schema,
      driverId: driverId,
      status: status,
      source: source,
      lastChangedAt: lastChangedAt,
      lastConfirmedAt: lastConfirmedAt,
      pendingSync: pendingSync,
      revision: revision as int?,
      reason: reason as String?,
      activeAssignmentId: activeAssignmentId as String?,
    );
  }

  factory PersistedDriverAvailabilityRecord.fromDomain(
    DriverAvailability domain,
  ) {
    return PersistedDriverAvailabilityRecord(
      schemaVersion: currentSchemaVersion,
      driverId: domain.driverId,
      status: domain.status,
      source: domain.source,
      lastChangedAt: domain.lastChangedAt,
      lastConfirmedAt: domain.lastConfirmedAt,
      pendingSync: domain.pendingSync,
      revision: domain.revision,
      reason: domain.reason,
      activeAssignmentId: domain.activeAssignmentId,
    );
  }

  /// Maps to domain without confirming restored available (caller may normalize).
  DriverAvailability toDomain() {
    return DriverAvailability(
      driverId: driverId,
      status: status,
      source: source,
      lastChangedAt: lastChangedAt,
      lastConfirmedAt: lastConfirmedAt,
      pendingSync: pendingSync,
      revision: revision,
      reason: reason,
      activeAssignmentId: status == AvailabilityStatus.busy
          ? activeAssignmentId
          : null,
    );
  }

  static AvailabilityStatus _parseStatus(Object? raw) {
    if (raw is! String) {
      throw const FormatException('status missing or invalid');
    }
    for (final value in AvailabilityStatus.values) {
      if (value.name == raw) return value;
    }
    throw FormatException('unknown status: $raw');
  }

  static AvailabilitySource _parseSource(Object? raw) {
    if (raw is! String) {
      throw const FormatException('source missing or invalid');
    }
    for (final value in AvailabilitySource.values) {
      if (value.name == raw) return value;
    }
    throw FormatException('unknown source: $raw');
  }

  static DateTime _parseRequiredDateTime(Object? raw, String field) {
    if (raw is! String || raw.isEmpty) {
      throw FormatException('$field missing or invalid');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('$field malformed timestamp');
    }
    return parsed.toUtc();
  }

  static DateTime? _parseOptionalDateTime(Object? raw, String field) {
    if (raw == null) return null;
    if (raw is! String || raw.isEmpty) {
      throw FormatException('$field invalid');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('$field malformed timestamp');
    }
    return parsed.toUtc();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistedDriverAvailabilityRecord &&
          schemaVersion == other.schemaVersion &&
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
    schemaVersion,
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
