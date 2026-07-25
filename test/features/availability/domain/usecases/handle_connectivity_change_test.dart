import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_connectivity_change.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/handle_connectivity_change.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 17);

  group('HandleConnectivityChange', () {
    test('loss while available forces effective offline', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
        ),
      );
      final result = await HandleConnectivityChange(fake)(
        AvailabilityConnectivityChange(
          driverId: 'drv-1',
          isOnline: false,
          changedAt: at,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AvailabilityStatus.offline);
      expect(fake.changeRequests.single.actor, AvailabilityActor.connectivity);
      fake.dispose();
    });

    test('loss while busy preserves busy without queueing available', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.system,
          lastChangedAt: at,
          activeAssignmentId: 'asg-1',
        ),
      );
      final result = await HandleConnectivityChange(fake)(
        AvailabilityConnectivityChange(
          driverId: 'drv-1',
          isOnline: false,
          changedAt: at,
        ),
      );
      expect(result.valueOrNull!.status, AvailabilityStatus.busy);
      expect(fake.requestCallCount, 0);
      expect(fake.reconcileRequests, isEmpty);
      fake.dispose();
    });

    test('reconnect delegates reconcile without auto available', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.offline,
          source: AvailabilitySource.connectivityPolicy,
          lastChangedAt: at,
          revision: 3,
        ),
      );
      final result = await HandleConnectivityChange(fake)(
        AvailabilityConnectivityChange(
          driverId: 'drv-1',
          isOnline: true,
          changedAt: at,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(fake.reconcileRequests, isNotEmpty);
      expect(fake.changeRequests, isEmpty);
      fake.dispose();
    });
  });
}
