import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/data/models/persisted_driver_availability_record.dart';
import 'package:saeq_driver/features/availability/data/repositories/local_driver_availability_repository.dart';
import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_change_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_reconciliation_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/entities/logout_availability_request.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';

import '../../helpers/in_memory_driver_availability_local_data_source.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 9);

  late InMemoryDriverAvailabilityLocalDataSource local;
  late String driverId;
  late LocalDriverAvailabilityRepository repo;

  setUp(() {
    local = InMemoryDriverAvailabilityLocalDataSource();
    driverId = 'drv-1';
    repo = LocalDriverAvailabilityRepository(
      localDataSource: local,
      currentDriverIdReader: () => driverId,
    );
  });

  tearDown(() {
    repo.dispose();
  });

  Future<void> seedPersisted(DriverAvailability domain) async {
    local.record = PersistedDriverAvailabilityRecord.fromDomain(domain);
  }

  group('LocalDriverAvailabilityRepository get/restore', () {
    test('missing record returns safe unavailable default', () async {
      final result = await repo.getCurrentAvailability();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AvailabilityStatus.unavailable);
      expect(result.valueOrNull!.isConfirmedAvailable, isFalse);
    });

    test('unavailable restores safely', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.localUserAction,
          lastChangedAt: at,
        ),
      );
      final result = await repo.restoreLocalAvailability();
      expect(result.valueOrNull!.status, AvailabilityStatus.unavailable);
      expect(result.valueOrNull!.source, AvailabilitySource.restoredLocalState);
    });

    test('available restores unconfirmed', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
          pendingSync: false,
          revision: 4,
        ),
      );
      final result = await repo.restoreLocalAvailability();
      final restored = result.valueOrNull!;
      expect(restored.status, AvailabilityStatus.available);
      expect(restored.isConfirmedAvailable, isFalse);
      expect(restored.source, AvailabilitySource.restoredLocalState);
      expect(restored.pendingSync, isTrue);
      expect(restored.lastConfirmedAt, isNull);
    });

    test('offline restores safely', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.offline,
          source: AvailabilitySource.connectivityPolicy,
          lastChangedAt: at,
        ),
      );
      final result = await repo.restoreLocalAvailability();
      expect(result.valueOrNull!.status, AvailabilityStatus.offline);
      expect(result.valueOrNull!.isConfirmedAvailable, isFalse);
    });

    test('busy restores without user authority', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          activeAssignmentId: 'asg-1',
          revision: 2,
        ),
      );
      final result = await repo.restoreLocalAvailability();
      final restored = result.valueOrNull!;
      expect(restored.status, AvailabilityStatus.busy);
      expect(restored.source, isNot(AvailabilitySource.localUserAction));
      expect(restored.source, isNot(AvailabilitySource.restoredLocalState));
      expect(restored.pendingSync, isTrue);
      expect(restored.activeAssignmentId, 'asg-1');
    });

    test('corrupted record returns typed failure', () async {
      local.failReads = true;
      final result = await repo.getCurrentAvailability();
      expect(result.failureOrNull, isA<AvailabilityPersistenceFailure>());
    });

    test('driverId mismatch denied and cleared', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-other',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      );
      final result = await repo.getCurrentAvailability();
      expect(result.failureOrNull, isA<AvailabilitySecurityPolicyDenied>());
      expect(local.record, isNull);
    });

    test(
      'restore never invokes request-change write for available confirm',
      () async {
        await seedPersisted(
          DriverAvailability(
            driverId: 'drv-1',
            status: AvailabilityStatus.available,
            source: AvailabilitySource.server,
            lastChangedAt: at,
            lastConfirmedAt: at,
          ),
        );
        final writesBefore = local.writeCount;
        await repo.restoreLocalAvailability();
        expect(local.writeCount, writesBefore);
      },
    );

    test('restored available never becomes confirmed', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.localUserAction,
          lastChangedAt: at,
          lastConfirmedAt: at,
        ),
      );
      final get = await repo.getCurrentAvailability();
      expect(get.valueOrNull!.isConfirmedAvailable, isFalse);
    });
  });

  group('LocalDriverAvailabilityRepository request-change', () {
    test('unavailable request persists safe local state', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.localUserAction,
          lastChangedAt: at,
          pendingSync: true,
        ),
      );
      final result = await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(local.record!.status, AvailabilityStatus.unavailable);
      expect(result.valueOrNull!.isConfirmedAvailable, isFalse);
    });

    test('available request persists pending/unconfirmed state', () async {
      await repo.getCurrentAvailability();
      final result = await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
          connectivityOnline: true,
        ),
      );
      final value = result.valueOrNull!;
      expect(value.status, AvailabilityStatus.available);
      expect(value.pendingSync, isTrue);
      expect(value.lastConfirmedAt, isNull);
      expect(value.isConfirmedAvailable, isFalse);
      expect(local.record!.pendingSync, isTrue);
    });

    test('valid request emits watch update', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.localUserAction,
          lastChangedAt: at,
          pendingSync: true,
        ),
      );
      final emissions = <DriverAvailability>[];
      final sub = repo.watchAvailability().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);
      await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          requestedAt: at.add(const Duration(seconds: 1)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        emissions.any((e) => e.status == AvailabilityStatus.unavailable),
        isTrue,
      );
      await sub.cancel();
    });

    test('same-state idempotent request does not duplicate write', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      );
      await repo.getCurrentAvailability();
      final writes = local.writeCount;
      await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          requestedAt: at.add(const Duration(seconds: 2)),
        ),
      );
      expect(local.writeCount, writes);
    });

    test('user busy cannot be persisted', () async {
      await repo.getCurrentAvailability();
      final result = await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.busy,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      expect(result.failureOrNull, isA<ManualBusyTransitionDenied>());
      expect(local.writeCount, 0);
    });

    test('datasource write failure maps to typed failure', () async {
      await repo.getCurrentAvailability();
      local.failWrites = true;
      final result = await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilityPersistenceFailure>());
    });

    test('driver identity preserved', () async {
      await repo.getCurrentAvailability();
      final result = await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      expect(result.valueOrNull!.driverId, 'drv-1');
    });
  });

  group('LocalDriverAvailabilityRepository authoritative', () {
    test('higher revision replaces local', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 1,
        ),
      );
      final result = await repo.applyAuthoritativeAvailability(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 2,
        ),
      );
      expect(result.valueOrNull!.revision, 2);
      expect(result.valueOrNull!.isConfirmedAvailable, isTrue);
      expect(result.valueOrNull!.pendingSync, isFalse);
    });

    test('equal identical revision is idempotent', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 5,
        ),
      );
      await repo.getCurrentAvailability();
      final writes = local.writeCount;
      final result = await repo.applyAuthoritativeAvailability(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 5,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(local.writeCount, writes);
    });

    test('equal conflicting revision returns sync conflict', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 5,
        ),
      );
      final result = await repo.applyAuthoritativeAvailability(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 5,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilitySyncConflict>());
    });

    test('lower revision returns stale failure', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 9,
        ),
      );
      final result = await repo.applyAuthoritativeAvailability(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 3,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilityStateStale>());
    });

    test('backend busy accepted', () async {
      await repo.getCurrentAvailability();
      final result = await repo.applyAuthoritativeAvailability(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 1,
          activeAssignmentId: 'asg-2',
        ),
      );
      expect(result.valueOrNull!.status, AvailabilityStatus.busy);
      expect(result.valueOrNull!.activeAssignmentId, 'asg-2');
    });

    test('local/restored authoritative source rejected', () async {
      expect(
        () => AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.localUserAction,
          confirmedAt: at,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('confirmed update clears pendingSync', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.localUserAction,
          lastChangedAt: at,
          pendingSync: true,
          revision: 1,
        ),
      );
      final result = await repo.applyAuthoritativeAvailability(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 2,
        ),
      );
      expect(result.valueOrNull!.pendingSync, isFalse);
      expect(result.valueOrNull!.isConfirmedAvailable, isTrue);
    });

    test('identity mismatch denied', () async {
      await repo.getCurrentAvailability();
      final result = await repo.applyAuthoritativeAvailability(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-other',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 1,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilitySecurityPolicyDenied>());
    });
  });

  group('LocalDriverAvailabilityRepository reconcile/logout/watch', () {
    test('authoritative newer wins over stale known revision', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 10,
        ),
      );
      final result = await repo.reconcileAvailability(
        AvailabilityReconciliationRequest(
          driverId: 'drv-1',
          requestedAt: at,
          lastKnownRevision: 2,
          localState: DriverAvailability(
            driverId: 'drv-1',
            status: AvailabilityStatus.available,
            source: AvailabilitySource.localUserAction,
            lastChangedAt: at,
            pendingSync: true,
            revision: 2,
          ),
        ),
      );
      expect(result.valueOrNull!.revision, 10);
      expect(result.valueOrNull!.status, AvailabilityStatus.unavailable);
    });

    test('equal conflicting state returns conflict', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 4,
        ),
      );
      final result = await repo.reconcileAvailability(
        AvailabilityReconciliationRequest(
          driverId: 'drv-1',
          requestedAt: at,
          lastKnownRevision: 4,
          localState: DriverAvailability(
            driverId: 'drv-1',
            status: AvailabilityStatus.busy,
            source: AvailabilitySource.system,
            lastChangedAt: at,
            revision: 4,
            activeAssignmentId: 'asg-x',
          ),
        ),
      );
      expect(result.failureOrNull, isA<AvailabilitySyncConflict>());
    });

    test('unavailable clears on logout', () async {
      await repo.getCurrentAvailability();
      final result = await repo.clearAvailabilityOnLogout(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(local.record, isNull);
      expect(local.clearCount, 1);
    });

    test('available invalidates safely on logout', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
          revision: 1,
        ),
      );
      await repo.getCurrentAvailability();
      await repo.clearAvailabilityOnLogout(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(local.record, isNull);
      final after = await repo.getCurrentAvailability();
      expect(after.valueOrNull!.isConfirmedAvailable, isFalse);
      expect(after.valueOrNull!.status, AvailabilityStatus.unavailable);
    });

    test(
      'previous driver state unavailable after logout / no cross-driver leak',
      () async {
        await seedPersisted(
          DriverAvailability(
            driverId: 'drv-1',
            status: AvailabilityStatus.available,
            source: AvailabilitySource.server,
            lastChangedAt: at,
            lastConfirmedAt: at,
          ),
        );
        await repo.clearAvailabilityOnLogout(
          LogoutAvailabilityRequest(
            driverId: 'drv-1',
            logoutAt: at,
            connectivityOnline: true,
          ),
        );
        driverId = 'drv-2';
        final result = await repo.getCurrentAvailability();
        expect(result.valueOrNull!.driverId, 'drv-2');
        expect(result.valueOrNull!.status, AvailabilityStatus.unavailable);
        expect(result.valueOrNull!.isConfirmedAvailable, isFalse);
      },
    );

    test('datasource clear failure typed', () async {
      await repo.getCurrentAvailability();
      local.failClears = true;
      final result = await repo.clearAvailabilityOnLogout(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilityPersistenceFailure>());
    });

    test('busy path blocked by repository defense', () async {
      await seedPersisted(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.system,
          lastChangedAt: at,
          activeAssignmentId: 'asg-1',
        ),
      );
      await repo.getCurrentAvailability();
      final result = await repo.clearAvailabilityOnLogout(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(result.failureOrNull, isA<ActiveAssignmentConflict>());
      expect(local.clearCount, 0);
      expect(local.record, isNotNull);
    });

    test('watch emits in order without business rejection crashes', () async {
      final emissions = <AvailabilityStatus>[];
      final sub = repo.watchAvailability().listen((e) {
        emissions.add(e.status);
      });
      await repo.getCurrentAvailability();
      await repo.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.last, AvailabilityStatus.available);
      await sub.cancel();
    });
  });
}
