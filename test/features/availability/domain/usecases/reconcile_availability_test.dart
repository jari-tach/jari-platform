import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_reconciliation_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/reconcile_availability.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 14);

  group('ReconcileAvailability', () {
    test('delegates explicit reconciliation request', () async {
      final local = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.available,
        source: AvailabilitySource.localUserAction,
        lastChangedAt: at,
        pendingSync: true,
        revision: 2,
      );
      final fake = FakeDriverAvailabilityRepository(seed: local);
      final req = AvailabilityReconciliationRequest(
        driverId: 'drv-1',
        requestedAt: at,
        localState: local,
        lastKnownRevision: 2,
      );
      final result = await ReconcileAvailability(fake)(req);
      expect(result.isSuccess, isTrue);
      expect(fake.reconcileRequests.single, req);
      fake.dispose();
    });

    test('backend authority is preserved (no auto local promotion)', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 5,
        ),
      );
      final result = await ReconcileAvailability(fake)(
        AvailabilityReconciliationRequest(
          driverId: 'drv-1',
          requestedAt: at,
          lastKnownRevision: 5,
        ),
      );
      expect(result.valueOrNull!.source, AvailabilitySource.server);
      expect(result.valueOrNull!.revision, 5);
      fake.dispose();
    });

    test('sync conflict propagates', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      )..nextReconcileFailure = const AvailabilitySyncConflict();
      final result = await ReconcileAvailability(fake)(
        AvailabilityReconciliationRequest(driverId: 'drv-1', requestedAt: at),
      );
      expect(result.failureOrNull, isA<AvailabilitySyncConflict>());
      fake.dispose();
    });

    test('no automatic retry occurs', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      )..nextReconcileFailure = const AvailabilitySyncConflict();
      final uc = ReconcileAvailability(fake);
      await uc(
        AvailabilityReconciliationRequest(driverId: 'drv-1', requestedAt: at),
      );
      await uc(
        AvailabilityReconciliationRequest(driverId: 'drv-1', requestedAt: at),
      );
      expect(fake.reconcileRequests.length, 2);
      fake.dispose();
    });
  });
}
