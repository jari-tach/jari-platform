import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 16);

  group('ApplyAuthoritativeAvailability', () {
    test('backend busy update accepted structurally', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
          revision: 1,
        ),
      );
      final result = await ApplyAuthoritativeAvailability(fake)(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 2,
          activeAssignmentId: 'asg-1',
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AvailabilityStatus.busy);
      expect(result.valueOrNull!.driverId, 'drv-1');
      fake.dispose();
    });

    test('local-user authoritative update rejected before repository', () {
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

    test('negative revision rejected', () {
      expect(
        () => AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: -3,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('stale/conflict failure propagates', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 10,
        ),
      );
      final result = await ApplyAuthoritativeAvailability(fake)(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 4,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilityStateStale>());
      expect(fake.authoritativeUpdates, isEmpty);
      fake.dispose();
    });

    test('driverId is preserved', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.system,
          lastChangedAt: at,
        ),
      );
      final result = await ApplyAuthoritativeAvailability(fake)(
        AuthoritativeAvailabilityUpdate(
          driverId: 'drv-other',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          confirmedAt: at,
          revision: 1,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilitySecurityPolicyDenied>());
      fake.dispose();
    });
  });
}
