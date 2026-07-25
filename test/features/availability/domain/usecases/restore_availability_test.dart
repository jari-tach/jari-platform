import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/restore_availability.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 13);

  group('RestoreAvailability', () {
    test('restored available remains unconfirmed', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
        ),
      );
      final result = await RestoreAvailability(fake)();
      expect(result.valueOrNull!.isConfirmedAvailable, isFalse);
      expect(result.valueOrNull!.source, AvailabilitySource.restoredLocalState);
      fake.dispose();
    });

    test('restore does not invoke request-change', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      );
      await RestoreAvailability(fake)();
      expect(fake.requestCallCount, 0);
      expect(fake.restoreCallCount, 1);
      fake.dispose();
    });

    test('stale state is not promoted to confirmed', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.localUserAction,
          lastChangedAt: at,
          pendingSync: true,
        ),
      );
      final result = await RestoreAvailability(fake)();
      expect(result.valueOrNull!.isConfirmedAvailable, isFalse);
      fake.dispose();
    });

    test('typed restore failure propagates', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      )..nextRestoreFailure = const AvailabilityPersistenceFailure();
      final result = await RestoreAvailability(fake)();
      expect(result.failureOrNull, isA<AvailabilityPersistenceFailure>());
      fake.dispose();
    });
  });
}
