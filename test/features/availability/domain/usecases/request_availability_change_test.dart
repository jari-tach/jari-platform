import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_change_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/request_availability_change.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 11);

  DriverAvailability seed({
    AvailabilityStatus status = AvailabilityStatus.unavailable,
    AvailabilitySource source = AvailabilitySource.system,
    String? activeAssignmentId,
  }) => DriverAvailability(
    driverId: 'drv-1',
    status: status,
    source: source,
    lastChangedAt: at,
    lastConfirmedAt: status == AvailabilityStatus.available ? at : null,
    activeAssignmentId: activeAssignmentId,
  );

  AvailabilityEligibilityInput eligible({
    bool connectivityAvailable = true,
    bool securityPolicyAllows = true,
    bool hasActiveAssignment = false,
  }) => AvailabilityEligibilityInput(
    authenticated: true,
    profileExists: true,
    accountStatus: AccountStatus.verified,
    employmentStatus: EmploymentStatus.active,
    hasActiveAssignment: hasActiveAssignment,
    connectivityAvailable: connectivityAvailable,
    securityPolicyAllows: securityPolicyAllows,
  );

  group('RequestAvailabilityChange', () {
    test('eligible unavailable → available delegates once', () async {
      final fake = FakeDriverAvailabilityRepository(seed: seed());
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
          eligibilityInput: eligible(),
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(fake.requestCallCount, 1);
      expect(result.valueOrNull!.driverId, 'drv-1');
      fake.dispose();
    });

    test(
      'structural transition denial does not call repository mutate',
      () async {
        final fake = FakeDriverAvailabilityRepository(
          seed: seed(status: AvailabilityStatus.offline),
        );
        final uc = RequestAvailabilityChange(fake);
        final before = fake.requestCallCount;
        final result = await uc(
          AvailabilityChangeRequest(
            driverId: 'drv-1',
            requestedStatus: AvailabilityStatus.available,
            actor: AvailabilityActor.driver,
            requestedAt: at,
            eligibilityInput: eligible(),
          ),
        );
        expect(result.failureOrNull, isA<AvailabilityOffline>());
        expect(fake.requestCallCount, before);
        fake.dispose();
      },
    );

    test('eligibility denial does not call repository mutate', () async {
      final fake = FakeDriverAvailabilityRepository(seed: seed());
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
          eligibilityInput: eligible(securityPolicyAllows: false),
        ),
      );
      expect(result.failureOrNull, isA<AvailabilitySecurityPolicyDenied>());
      expect(fake.requestCallCount, 0);
      fake.dispose();
    });

    test(
      'driver → busy returns ManualBusyTransitionDenied without mutate',
      () async {
        final fake = FakeDriverAvailabilityRepository(
          seed: seed(status: AvailabilityStatus.available),
        );
        final request = AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.busy,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        );
        final result = await RequestAvailabilityChange(fake)(request);
        expect(result.failureOrNull, isA<ManualBusyTransitionDenied>());
        expect(fake.requestCallCount, 0);
        expect(fake.changeRequests, isEmpty);
        fake.dispose();
      },
    );

    test('undocumented connectivity → busy does not mutate', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: seed(status: AvailabilityStatus.unavailable),
      );
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.busy,
          actor: AvailabilityActor.connectivity,
          requestedAt: at,
        ),
      );
      expect(result.isFailure, isTrue);
      expect(fake.requestCallCount, 0);
      fake.dispose();
    });

    test('offline → available does not call repository mutate', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: seed(status: AvailabilityStatus.offline),
      );
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
          eligibilityInput: eligible(),
          connectivityOnline: false,
        ),
      );
      expect(result.failureOrNull, isA<AvailabilityOffline>());
      expect(fake.requestCallCount, 0);
      fake.dispose();
    });

    test('same-state idempotent does not mutate repository', () async {
      final fake = FakeDriverAvailabilityRepository(seed: seed());
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(fake.requestCallCount, 0);
      fake.dispose();
    });

    test(
      'active assignment conflict does not call repository mutate',
      () async {
        final fake = FakeDriverAvailabilityRepository(
          seed: seed(
            status: AvailabilityStatus.busy,
            source: AvailabilitySource.system,
            activeAssignmentId: 'asg-1',
          ),
        );
        final uc = RequestAvailabilityChange(fake);
        final result = await uc(
          AvailabilityChangeRequest(
            driverId: 'drv-1',
            requestedStatus: AvailabilityStatus.available,
            actor: AvailabilityActor.driver,
            requestedAt: at,
            hasActiveAssignment: true,
            eligibilityInput: eligible(hasActiveAssignment: true),
          ),
        );
        expect(result.failureOrNull, isA<ActiveAssignmentConflict>());
        expect(fake.requestCallCount, 0);
        fake.dispose();
      },
    );

    test('valid available → unavailable delegates', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: seed(status: AvailabilityStatus.available),
      );
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      expect(result.isSuccess, isTrue);
      expect(fake.requestCallCount, 1);
      fake.dispose();
    });

    test('repository typed failure propagates', () async {
      final fake = FakeDriverAvailabilityRepository(seed: seed())
        ..nextRequestFailure = const AvailabilityPersistenceFailure();
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
          eligibilityInput: eligible(),
        ),
      );
      expect(result.failureOrNull, isA<AvailabilityPersistenceFailure>());
      fake.dispose();
    });

    test('driver identity is preserved', () async {
      final fake = FakeDriverAvailabilityRepository(seed: seed());
      final uc = RequestAvailabilityChange(fake);
      final result = await uc(
        AvailabilityChangeRequest(
          driverId: 'drv-other',
          requestedStatus: AvailabilityStatus.available,
          actor: AvailabilityActor.driver,
          requestedAt: at,
          eligibilityInput: eligible(),
        ),
      );
      expect(result.failureOrNull, isA<AvailabilitySecurityPolicyDenied>());
      expect(fake.requestCallCount, 0);
      fake.dispose();
    });
  });
}
