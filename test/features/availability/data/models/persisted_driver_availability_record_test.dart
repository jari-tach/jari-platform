import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/data/models/persisted_driver_availability_record.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 8);

  PersistedDriverAvailabilityRecord sample({
    AvailabilityStatus status = AvailabilityStatus.unavailable,
    AvailabilitySource source = AvailabilitySource.system,
    int schemaVersion = PersistedDriverAvailabilityRecord.currentSchemaVersion,
    String driverId = 'drv-1',
    DateTime? lastConfirmedAt,
    bool pendingSync = false,
    int? revision,
    String? activeAssignmentId,
  }) => PersistedDriverAvailabilityRecord(
    schemaVersion: schemaVersion,
    driverId: driverId,
    status: status,
    source: source,
    lastChangedAt: at,
    lastConfirmedAt: lastConfirmedAt,
    pendingSync: pendingSync,
    revision: revision,
    reason: 'r',
    activeAssignmentId: activeAssignmentId,
  );

  group('PersistedDriverAvailabilityRecord', () {
    test('valid record round-trip', () {
      final original = sample(
        status: AvailabilityStatus.available,
        source: AvailabilitySource.localUserAction,
        lastConfirmedAt: at,
        pendingSync: true,
        revision: 3,
      );
      final decoded = PersistedDriverAvailabilityRecord.fromJson(
        original.toJson(),
      );
      expect(decoded, original);
    });

    test('all statuses serialize deterministically', () {
      for (final status in AvailabilityStatus.values) {
        final record = sample(
          status: status,
          source: status == AvailabilityStatus.busy
              ? AvailabilitySource.system
              : AvailabilitySource.system,
          activeAssignmentId: status == AvailabilityStatus.busy
              ? 'asg-1'
              : null,
        );
        final round = PersistedDriverAvailabilityRecord.fromJson(
          record.toJson(),
        );
        expect(round.status, status);
      }
    });

    test('timestamps round-trip as UTC', () {
      final decoded = PersistedDriverAvailabilityRecord.fromJson(
        sample(lastConfirmedAt: at).toJson(),
      );
      expect(decoded.lastChangedAt.isUtc, isTrue);
      expect(decoded.lastConfirmedAt, at);
    });

    test('nullable fields handled', () {
      final decoded = PersistedDriverAvailabilityRecord.fromJson(
        sample().toJson(),
      );
      expect(decoded.lastConfirmedAt, isNull);
      expect(decoded.revision, isNull);
      expect(decoded.activeAssignmentId, isNull);
    });

    test('negative revision rejected', () {
      expect(() => sample(revision: -1), throwsA(isA<ArgumentError>()));
    });

    test('unknown status rejected safely', () {
      final json = sample().toJson()..['status'] = 'teleporting';
      expect(
        () => PersistedDriverAvailabilityRecord.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('unknown source rejected safely', () {
      final json = sample().toJson()..['source'] = 'alien';
      expect(
        () => PersistedDriverAvailabilityRecord.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('missing driverId rejected', () {
      final json = sample().toJson()..['driverId'] = '';
      expect(
        () => PersistedDriverAvailabilityRecord.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('malformed timestamp rejected', () {
      final json = sample().toJson()..['lastChangedAt'] = 'not-a-date';
      expect(
        () => PersistedDriverAvailabilityRecord.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('unsupported schema version handled', () {
      final json = sample().toJson()..['schemaVersion'] = 99;
      expect(
        () => PersistedDriverAvailabilityRecord.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('deserialization does not invent confirmed available semantics', () {
      final decoded = PersistedDriverAvailabilityRecord.fromJson(
        sample(
          status: AvailabilityStatus.available,
          source: AvailabilitySource.restoredLocalState,
          pendingSync: true,
        ).toJson(),
      ).toDomain();
      expect(decoded.isConfirmedAvailable, isFalse);
    });
  });
}
