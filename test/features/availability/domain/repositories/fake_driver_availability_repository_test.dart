import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_change_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_reconciliation_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/entities/logout_availability_request.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

import '../../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 10);

  DriverAvailability unavailable() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.unavailable,
    source: AvailabilitySource.system,
    lastChangedAt: at,
  );

  AvailabilityEligibilityInput eligibleInput() =>
      const AvailabilityEligibilityInput(
        authenticated: true,
        profileExists: true,
        accountStatus: AccountStatus.verified,
        employmentStatus: EmploymentStatus.active,
        hasActiveAssignment: false,
        connectivityAvailable: true,
        securityPolicyAllows: true,
      );

  group('FakeDriverAvailabilityRepository', () {
    test('get returns configured effective state', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final result = await fake.getCurrentAvailability();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AvailabilityStatus.unavailable);
      fake.dispose();
    });

    test('watch emits configured states in order', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final emissions = <DriverAvailability>[];
      final sub = fake.watchAvailability().listen(emissions.add);
      final next = unavailable().copyWith(
        status: AvailabilityStatus.offline,
        source: AvailabilitySource.connectivityPolicy,
        lastChangedAt: at.add(const Duration(minutes: 1)),
      );
      fake.seed(next);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last.status, AvailabilityStatus.offline);
      await sub.cancel();
      fake.dispose();
    });

    test('request captures valid change request', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final req = AvailabilityChangeRequest(
        driverId: 'drv-1',
        requestedStatus: AvailabilityStatus.available,
        actor: AvailabilityActor.driver,
        requestedAt: at,
        eligibilityInput: eligibleInput(),
      );
      final result = await fake.requestAvailabilityChange(req);
      expect(result.isSuccess, isTrue);
      expect(fake.changeRequests, [req]);
      expect(result.valueOrNull!.status, AvailabilityStatus.available);
      fake.dispose();
    });

    test(
      'restore returns restored state without marking authoritative',
      () async {
        final seeded = DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
        );
        final fake = FakeDriverAvailabilityRepository(seed: seeded);
        final result = await fake.restoreLocalAvailability();
        final restored = result.valueOrNull!;
        expect(restored.isConfirmedAvailable, isFalse);
        expect(restored.source, AvailabilitySource.restoredLocalState);
        expect(restored.lastConfirmedAt, isNull);
        fake.dispose();
      },
    );

    test('reconcile captures request and typed result', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final req = AvailabilityReconciliationRequest(
        driverId: 'drv-1',
        requestedAt: at,
        lastKnownRevision: 1,
      );
      final result = await fake.reconcileAvailability(req);
      expect(result.isSuccess, isTrue);
      expect(fake.reconcileRequests.single.driverId, 'drv-1');
      fake.dispose();
    });

    test('clear-on-logout captures identity and clears safely', () async {
      final seeded = DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.available,
        source: AvailabilitySource.server,
        lastChangedAt: at,
        lastConfirmedAt: at,
      );
      final fake = FakeDriverAvailabilityRepository(seed: seeded);
      final req = LogoutAvailabilityRequest(
        driverId: 'drv-1',
        logoutAt: at,
        connectivityOnline: true,
      );
      final result = await fake.clearAvailabilityOnLogout(req);
      expect(result.isSuccess, isTrue);
      expect(fake.logoutRequests.single.driverId, 'drv-1');
      expect(fake.state!.status, AvailabilityStatus.unavailable);
      expect(fake.state!.isConfirmedAvailable, isFalse);
      fake.dispose();
    });

    test('authoritative update captures revision/source', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final update = AuthoritativeAvailabilityUpdate(
        driverId: 'drv-1',
        status: AvailabilityStatus.busy,
        source: AvailabilitySource.server,
        confirmedAt: at,
        revision: 7,
        activeAssignmentId: 'asg-1',
      );
      final result = await fake.applyAuthoritativeAvailability(update);
      expect(result.isSuccess, isTrue);
      expect(fake.authoritativeUpdates.single.revision, 7);
      expect(result.valueOrNull!.status, AvailabilityStatus.busy);
      fake.dispose();
    });

    test('configured typed failure propagates', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable())
        ..nextFailure = const AvailabilityPersistenceFailure();
      final result = await fake.getCurrentAvailability();
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AvailabilityPersistenceFailure>());
      fake.dispose();
    });

    test('no raw exception as expected business rejection', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable())
        ..nextRequestFailure = const ManualBusyTransitionDenied();
      final result = await fake.requestAvailabilityChange(
        AvailabilityChangeRequest(
          driverId: 'drv-1',
          requestedStatus: AvailabilityStatus.unavailable,
          actor: AvailabilityActor.driver,
          requestedAt: at,
        ),
      );
      expect(result, isA<AvailabilityFailureResult<DriverAvailability>>());
      expect(result.failureOrNull, isA<ManualBusyTransitionDenied>());
      fake.dispose();
    });
  });
}
