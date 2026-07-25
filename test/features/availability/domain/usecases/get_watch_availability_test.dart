import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/watch_driver_availability.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 12);

  DriverAvailability seed([
    AvailabilityStatus status = AvailabilityStatus.unavailable,
  ]) => DriverAvailability(
    driverId: 'drv-1',
    status: status,
    source: AvailabilitySource.system,
    lastChangedAt: at,
    lastConfirmedAt: status == AvailabilityStatus.available ? at : null,
  );

  group('GetDriverAvailability', () {
    test('get delegates exactly once', () async {
      final fake = FakeDriverAvailabilityRepository(seed: seed());
      final uc = GetDriverAvailability(fake);
      final result = await uc();
      expect(result.isSuccess, isTrue);
      expect(fake.getCurrentCallCount, 1);
      fake.dispose();
    });

    test('typed failure propagates', () async {
      final fake = FakeDriverAvailabilityRepository(seed: seed())
        ..nextFailure = const AvailabilityUnauthenticated();
      final result = await GetDriverAvailability(fake)();
      expect(result.failureOrNull, isA<AvailabilityUnauthenticated>());
      fake.dispose();
    });
  });

  group('WatchDriverAvailability', () {
    test(
      'watch exposes emissions in order without rewriting confirmation',
      () async {
        final confirmed = DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
        );
        final fake = FakeDriverAvailabilityRepository(seed: confirmed);
        final emissions = <DriverAvailability>[];
        final sub = WatchDriverAvailability(fake)().listen(emissions.add);
        final restored = confirmed.copyWith(
          source: AvailabilitySource.restoredLocalState,
          clearLastConfirmedAt: true,
          pendingSync: true,
        );
        fake.seed(restored);
        await Future<void>.delayed(Duration.zero);
        expect(emissions.last.source, AvailabilitySource.restoredLocalState);
        expect(emissions.last.isConfirmedAvailable, isFalse);
        await sub.cancel();
        fake.dispose();
      },
    );
  });
}
