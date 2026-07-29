import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_connectivity_change.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller_state.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_eligibility_reader.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

import '../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 20);

  DriverAvailability unavailable({String id = 'drv-1'}) => DriverAvailability(
    driverId: id,
    status: AvailabilityStatus.unavailable,
    source: AvailabilitySource.system,
    lastChangedAt: at,
  );

  DriverAvailability availablePending({String id = 'drv-1'}) =>
      DriverAvailability(
        driverId: id,
        status: AvailabilityStatus.available,
        source: AvailabilitySource.localUserAction,
        lastChangedAt: at,
        pendingSync: true,
      );

  DriverAvailability availableConfirmed({String id = 'drv-1'}) =>
      DriverAvailability(
        driverId: id,
        status: AvailabilityStatus.available,
        source: AvailabilitySource.server,
        lastChangedAt: at,
        lastConfirmedAt: at,
        pendingSync: false,
        revision: 2,
      );

  DriverAvailability busy({
    String id = 'drv-1',
    String? assignmentId = 'asg-1',
  }) => DriverAvailability(
    driverId: id,
    status: AvailabilityStatus.busy,
    source: AvailabilitySource.system,
    lastChangedAt: at,
    activeAssignmentId: assignmentId,
    pendingSync: true,
  );

  AvailabilityEligibilityInput eligible({
    bool connectivityAvailable = true,
    bool securityPolicyAllows = true,
  }) => AvailabilityEligibilityInput(
    authenticated: true,
    profileExists: true,
    accountStatus: AccountStatus.verified,
    employmentStatus: EmploymentStatus.active,
    hasActiveAssignment: false,
    connectivityAvailable: connectivityAvailable,
    securityPolicyAllows: securityPolicyAllows,
  );

  Future<ProviderContainer> boot(
    FakeDriverAvailabilityRepository fake, {
    AvailabilityEligibilityReader? eligibilityReader,
    AvailabilityDebugTrialConfirmer? debugTrialConfirmer,
  }) async {
    final container = ProviderContainer(
      overrides: [
        availabilityControllerProvider.overrideWith(
          () => AvailabilityController(
            repositoryReader: (_) => fake,
            eligibilityReader:
                eligibilityReader ?? (_, _) => AvailabilitySuccess(eligible()),
            debugTrialConfirmer: debugTrialConfirmer,
          ),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      fake.dispose();
    });
    container.read(availabilityControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container;
  }

  Ref captureRef(ProviderContainer container) {
    late Ref captured;
    final probe = Provider<void>((ref) {
      captured = ref;
    });
    container.read(probe);
    return captured;
  }

  group('AvailabilityControllerState derived flags', () {
    test('confirmed / pending / busy / offline derivation', () {
      final confirmed = AvailabilityControllerState.ready(
        current: availableConfirmed(),
      );
      expect(confirmed.isConfirmedAvailable, isTrue);
      expect(confirmed.isPendingConfirmation, isFalse);
      expect(confirmed.canRequestUnavailable, isTrue);
      expect(confirmed.canRequestAvailable, isFalse);

      final pending = AvailabilityControllerState.ready(
        current: availablePending(),
      );
      expect(pending.isConfirmedAvailable, isFalse);
      expect(pending.isPendingConfirmation, isTrue);

      final restored = AvailabilityControllerState.ready(
        current: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.restoredLocalState,
          lastChangedAt: at,
          pendingSync: true,
        ),
        isRestored: true,
      );
      expect(restored.isRestoredUnconfirmedAvailable, isTrue);
      expect(restored.isConfirmedAvailable, isFalse);

      final busyState = AvailabilityControllerState.ready(current: busy());
      expect(busyState.isBusy, isTrue);
      expect(busyState.canRequestAvailable, isFalse);
      expect(busyState.canRequestUnavailable, isFalse);

      final offline = AvailabilityControllerState.ready(
        current: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.offline,
          source: AvailabilitySource.connectivityPolicy,
          lastChangedAt: at,
        ),
      );
      expect(offline.isOffline, isTrue);
      expect(offline.canRequestAvailable, isFalse);
    });

    test('failure retains typed failure and equality', () {
      const failure = ManualBusyTransitionDenied();
      final a = AvailabilityControllerState.failure(
        failure: failure,
        current: unavailable(),
      );
      final b = AvailabilityControllerState.failure(
        failure: failure,
        current: unavailable(),
      );
      expect(a, b);
      expect(a.failure, isA<ManualBusyTransitionDenied>());
    });
  });

  group('AvailabilityController initialize', () {
    test('restore succeeds and watch is ready', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(fake);
      final state = container.read(availabilityControllerProvider);
      expect(state.status, AvailabilityViewStatus.ready);
      expect(state.isInitialized, isTrue);
      expect(state.isRestored, isTrue);
      expect(state.current!.driverId, 'drv-1');
      expect(state.isConfirmedAvailable, isFalse);
    });

    test('restored available remains pending/unconfirmed', () async {
      final fake = FakeDriverAvailabilityRepository(seed: availableConfirmed());
      final container = await boot(fake);
      final state = container.read(availabilityControllerProvider);
      expect(state.current!.source, AvailabilitySource.restoredLocalState);
      expect(state.isConfirmedAvailable, isFalse);
      expect(state.isPendingConfirmation, isTrue);
    });

    test(
      'restored busy remains pending/unconfirmed and not available',
      () async {
        final fake = FakeDriverAvailabilityRepository(seed: busy());
        final container = await boot(fake);
        final state = container.read(availabilityControllerProvider);
        expect(state.isBusy, isTrue);
        expect(state.current!.pendingSync, isTrue);
        expect(state.current!.status, isNot(AvailabilityStatus.available));
        expect(state.canRequestAvailable, isFalse);
      },
    );

    test('restore failure becomes typed failure', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable())
        ..nextRestoreFailure = const AvailabilityPersistenceFailure();
      final container = await boot(fake);
      final state = container.read(availabilityControllerProvider);
      expect(state.status, AvailabilityViewStatus.failure);
      expect(state.failure, isA<AvailabilityPersistenceFailure>());
    });

    test('repeated initialize does not throw', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .initialize();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        container.read(availabilityControllerProvider).status,
        AvailabilityViewStatus.ready,
      );
    });
  });

  group('production eligibility reader', () {
    test('does not fabricate AvailabilityEligibilityInput', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = readAvailabilityEligibility(
        captureRef(container),
        'drv-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<DriverProfileMissing>());
    });

    test('empty driverId is unauthenticated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = readAvailabilityEligibility(captureRef(container), '  ');
      expect(result.failureOrNull, isA<AvailabilityUnauthenticated>());
    });

    test(
      'authenticated session alone is not treated as eligibility proof',
      () async {
        final fake = FakeDriverAvailabilityRepository(seed: unavailable());
        final container = await boot(
          fake,
          eligibilityReader: readAvailabilityEligibility,
        );
        await container
            .read(availabilityControllerProvider.notifier)
            .requestAvailable();
        final state = container.read(availabilityControllerProvider);
        expect(state.failure, isA<DriverProfileMissing>());
        expect(fake.requestCallCount, 0);
        expect(state.current?.status, AvailabilityStatus.unavailable);
        expect(state.lastStable?.status, AvailabilityStatus.unavailable);
        expect(state.isProcessing, isFalse);
      },
    );
  });

  group('AvailabilityController requestAvailable', () {
    test('valid unavailable → pending available via reader', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final state = container.read(availabilityControllerProvider);
      expect(state.current!.status, AvailabilityStatus.available);
      expect(state.isConfirmedAvailable, isFalse);
      expect(state.current!.driverId, 'drv-1');
      expect(fake.requestCallCount, greaterThan(0));
    });

    test(
      'DEV-ONLY confirmer applies confirmation without self-dependency',
      () async {
        final fake = FakeDriverAvailabilityRepository(seed: unavailable());
        var confirmerCalls = 0;
        final container = await boot(
          fake,
          debugTrialConfirmer: (ref, driverId) async {
            confirmerCalls++;
            // Must not read availabilityControllerProvider here.
            return AuthoritativeAvailabilityUpdate(
              driverId: driverId,
              status: AvailabilityStatus.available,
              source: AvailabilitySource.system,
              confirmedAt: DateTime.utc(2026, 7, 26, 21),
              reason: 'dev.fake_trial_confirm',
            );
          },
        );
        await container
            .read(availabilityControllerProvider.notifier)
            .requestAvailable();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        final state = container.read(availabilityControllerProvider);
        expect(confirmerCalls, 1);
        expect(state.current!.status, AvailabilityStatus.available);
        expect(state.isConfirmedAvailable, isTrue);
        expect(state.failure, isNull);
      },
    );

    test('explicit eligible override permits pending available', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(
        fake,
        eligibilityReader: (_, _) =>
            const AvailabilityFailureResult(DriverProfileMissing()),
      );
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable(eligibility: eligible());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final state = container.read(availabilityControllerProvider);
      expect(state.current!.status, AvailabilityStatus.available);
      expect(state.isConfirmedAvailable, isFalse);
    });

    test('busy denial keeps busy state', () async {
      final fake = FakeDriverAvailabilityRepository(seed: busy());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<ActiveAssignmentConflict>());
      expect(state.current!.status, AvailabilityStatus.busy);
      expect(state.current!.activeAssignmentId, 'asg-1');
      expect(fake.requestCallCount, 0);
    });

    test('offline denial', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.offline,
          source: AvailabilitySource.connectivityPolicy,
          lastChangedAt: at,
        ),
      );
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      expect(
        container.read(availabilityControllerProvider).failure,
        isA<AvailabilityOffline>(),
      );
    });

    test('eligibility denial does not mutate repository', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(
        fake,
        eligibilityReader: (_, _) =>
            AvailabilitySuccess(eligible(securityPolicyAllows: false)),
      );
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<AvailabilitySecurityPolicyDenied>());
      expect(fake.requestCallCount, 0);
      expect(state.lastStable?.status, AvailabilityStatus.unavailable);
    });

    test('profile missing denial from reader preserves stable state', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(
        fake,
        eligibilityReader: (_, _) =>
            const AvailabilityFailureResult(DriverProfileMissing()),
      );
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<DriverProfileMissing>());
      expect(fake.requestCallCount, 0);
      expect(state.current?.status, AvailabilityStatus.unavailable);
      expect(state.isProcessing, isFalse);
    });

    test('suspended account denial follows eligibility policy', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(
        fake,
        eligibilityReader: (_, _) => AvailabilitySuccess(
          const AvailabilityEligibilityInput(
            authenticated: true,
            profileExists: true,
            accountStatus: AccountStatus.suspended,
            employmentStatus: EmploymentStatus.active,
            hasActiveAssignment: false,
            connectivityAvailable: true,
            securityPolicyAllows: true,
          ),
        ),
      );
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<DriverAccountSuspended>());
      expect(fake.requestCallCount, 0);
    });

    test('rejected account denial follows eligibility policy', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(
        fake,
        eligibilityReader: (_, _) => AvailabilitySuccess(
          const AvailabilityEligibilityInput(
            authenticated: true,
            profileExists: true,
            accountStatus: AccountStatus.rejected,
            employmentStatus: EmploymentStatus.active,
            hasActiveAssignment: false,
            connectivityAvailable: true,
            securityPolicyAllows: true,
          ),
        ),
      );
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      expect(
        container.read(availabilityControllerProvider).failure,
        isA<DriverAccountInactive>(),
      );
      expect(fake.requestCallCount, 0);
    });

    test('identity mismatch from reader denies without mutation', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(
        fake,
        eligibilityReader: (_, driverId) {
          expect(driverId, 'drv-1');
          return const AvailabilityFailureResult(
            AvailabilitySecurityPolicyDenied(
              'Eligibility identity does not match the authenticated session.',
            ),
          );
        },
      );
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<AvailabilitySecurityPolicyDenied>());
      expect(fake.requestCallCount, 0);
      expect(state.current?.driverId, 'drv-1');
    });

    test('persistence failure preserves last stable', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable())
        ..nextRequestFailure = const AvailabilityPersistenceFailure();
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<AvailabilityPersistenceFailure>());
      expect(state.current?.status, AvailabilityStatus.unavailable);
    });

    test('concurrent second request is ignored', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(fake);
      final notifier = container.read(availabilityControllerProvider.notifier);
      final first = notifier.requestAvailable();
      final second = notifier.requestAvailable();
      await Future.wait([first, second]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fake.requestCallCount, 1);
    });
  });

  group('AvailabilityController requestUnavailable', () {
    test(
      'available → unavailable success without eligibility lookup',
      () async {
        final fake = FakeDriverAvailabilityRepository(seed: availablePending());
        var eligibilityCalls = 0;
        final container = await boot(
          fake,
          eligibilityReader: (_, _) {
            eligibilityCalls++;
            return const AvailabilityFailureResult(DriverProfileMissing());
          },
        );
        await container
            .read(availabilityControllerProvider.notifier)
            .requestUnavailable();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(
          container.read(availabilityControllerProvider).current!.status,
          AvailabilityStatus.unavailable,
        );
        expect(eligibilityCalls, 0);
      },
    );

    test('busy denied', () async {
      final fake = FakeDriverAvailabilityRepository(seed: busy());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .requestUnavailable();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<ActiveAssignmentConflict>());
      expect(state.isBusy, isTrue);
    });
  });

  group('AvailabilityController authoritative/connectivity/logout', () {
    test('higher revision authoritative success', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .applyAuthoritativeUpdate(
            AuthoritativeAvailabilityUpdate(
              driverId: 'drv-1',
              status: AvailabilityStatus.available,
              source: AvailabilitySource.server,
              confirmedAt: at,
              revision: 3,
            ),
          );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final state = container.read(availabilityControllerProvider);
      expect(state.isConfirmedAvailable, isTrue);
      expect(state.current!.pendingSync, isFalse);
    });

    test('backend busy accepted', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .applyAuthoritativeUpdate(
            AuthoritativeAvailabilityUpdate(
              driverId: 'drv-1',
              status: AvailabilityStatus.busy,
              source: AvailabilitySource.server,
              confirmedAt: at,
              revision: 1,
              activeAssignmentId: 'asg-9',
            ),
          );
      expect(container.read(availabilityControllerProvider).isBusy, isTrue);
    });

    test('stale revision failure', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.unavailable,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          revision: 9,
        ),
      );
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .applyAuthoritativeUpdate(
            AuthoritativeAvailabilityUpdate(
              driverId: 'drv-1',
              status: AvailabilityStatus.unavailable,
              source: AvailabilitySource.server,
              confirmedAt: at,
              revision: 2,
            ),
          );
      expect(
        container.read(availabilityControllerProvider).failure,
        isA<AvailabilityStateStale>(),
      );
    });

    test(
      'connectivity regain restores unavailable without auto-activate',
      () async {
        final fake = FakeDriverAvailabilityRepository(
          seed: DriverAvailability(
            driverId: 'drv-1',
            status: AvailabilityStatus.offline,
            source: AvailabilitySource.connectivityPolicy,
            lastChangedAt: at,
            revision: 1,
          ),
        );
        final container = await boot(fake);
        final requestsBefore = fake.requestCallCount;
        await container
            .read(availabilityControllerProvider.notifier)
            .handleConnectivityChange(
              AvailabilityConnectivityChange(
                driverId: 'drv-1',
                isOnline: true,
                changedAt: at,
              ),
            );
        expect(
          container.read(availabilityControllerProvider).current?.status,
          AvailabilityStatus.unavailable,
        );
        expect(
          fake.changeRequests.where(
            (r) => r.requestedStatus == AvailabilityStatus.available,
          ),
          isEmpty,
        );
        expect(fake.requestCallCount, greaterThan(requestsBefore));
      },
    );

    test('available logout resets controller', () async {
      final fake = FakeDriverAvailabilityRepository(seed: availablePending());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .prepareForLogout();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final state = container.read(availabilityControllerProvider);
      expect(state.status, AvailabilityViewStatus.initial);
      expect(state.isInitialized, isFalse);
      expect(fake.logoutRequests, isNotEmpty);
    });

    test('busy with assignment denied on logout', () async {
      final fake = FakeDriverAvailabilityRepository(seed: busy());
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .prepareForLogout();
      final state = container.read(availabilityControllerProvider);
      expect(state.failure, isA<ActiveAssignmentConflict>());
      expect(state.isBusy, isTrue);
      expect(fake.logoutRequests, isEmpty);
    });

    test('busy without assignment id denied on logout', () async {
      final fake = FakeDriverAvailabilityRepository(
        seed: busy(assignmentId: null),
      );
      final container = await boot(fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .prepareForLogout();
      expect(
        container.read(availabilityControllerProvider).failure,
        isA<ActiveAssignmentConflict>(),
      );
      expect(fake.logoutRequests, isEmpty);
    });

    test('dispose cancels further updates safely', () async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await boot(fake);
      container.dispose();
      fake.seed(availablePending());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // No throw after dispose.
    });
  });
}
