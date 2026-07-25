import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/entities/logout_availability_request.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/force_unavailable_on_logout.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 15);

  group('ForceUnavailableOnLogout', () {
    test('unavailable state clears safely', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      );
      final result = await ForceUnavailableOnLogout(fake)(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(fake.state!.status, AvailabilityStatus.unavailable);
      expect(fake.state!.isConfirmedAvailable, isFalse);
      fake.dispose();
    });

    test('available state invalidates without confirmed appearance', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
        ),
      );
      final result = await ForceUnavailableOnLogout(fake)(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: false,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(fake.state!.isConfirmedAvailable, isFalse);
      expect(fake.state!.status, AvailabilityStatus.unavailable);
      fake.dispose();
    });

    test('busy with assignment returns deterministic conflict', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.system,
          lastChangedAt: at,
          activeAssignmentId: 'asg-9',
        ),
      );
      final result = await ForceUnavailableOnLogout(fake)(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(result.failureOrNull, isA<ActiveAssignmentConflict>());
      expect(fake.logoutRequests, isEmpty);
      expect(fake.state!.status, AvailabilityStatus.busy);
      expect(fake.state!.activeAssignmentId, 'asg-9');
      fake.dispose();
    });

    test('busy without assignment id is also denied', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      );
      final result = await ForceUnavailableOnLogout(fake)(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(result.failureOrNull, isA<ActiveAssignmentConflict>());
      expect(fake.logoutRequests, isEmpty);
      expect(fake.state!.status, AvailabilityStatus.busy);
      fake.dispose();
    });

    test('repository failure propagates', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      )..nextLogoutFailure = const AvailabilityPersistenceFailure();
      final result = await ForceUnavailableOnLogout(fake)(
        LogoutAvailabilityRequest(
          driverId: 'drv-1',
          logoutAt: at,
          connectivityOnline: true,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilityPersistenceFailure>());
      fake.dispose();
    });
  });
}
