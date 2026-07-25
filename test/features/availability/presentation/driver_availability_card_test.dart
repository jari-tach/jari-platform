import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/mappers/availability_failure_messages.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/availability/presentation/widgets/driver_availability_card.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';

import '../helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 21);

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
    bool pendingSync = true,
  }) => DriverAvailability(
    driverId: id,
    status: AvailabilityStatus.busy,
    source: AvailabilitySource.system,
    lastChangedAt: at,
    activeAssignmentId: assignmentId,
    pendingSync: pendingSync,
  );

  AvailabilityEligibilityInput eligible() => const AvailabilityEligibilityInput(
    authenticated: true,
    profileExists: true,
    accountStatus: AccountStatus.verified,
    employmentStatus: EmploymentStatus.active,
    hasActiveAssignment: false,
    connectivityAvailable: true,
    securityPolicyAllows: true,
  );

  Future<ProviderContainer> bootCard(
    WidgetTester tester,
    FakeDriverAvailabilityRepository fake, {
    AvailabilityEligibilityReader? eligibilityReader,
    double textScale = 1.0,
    Locale locale = const Locale('en', 'US'),
    Size surfaceSize = const Size(390, 844),
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final container = ProviderContainer(
      overrides: [
        availabilityControllerProvider.overrideWith(
          () => AvailabilityController(
            repositoryReader: (_) => fake,
            eligibilityReader:
                eligibilityReader ?? (_, _) => AvailabilitySuccess(eligible()),
          ),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      fake.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                Directionality(textDirection: textDirection, child: child!),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: DriverAvailabilityCard(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    return container;
  }

  group('availabilityFailureMessage', () {
    final l10n = AppLocalizations(const Locale('en', 'US'));

    test('maps typed failures exhaustively', () {
      expect(
        availabilityFailureMessage(const AvailabilityUnauthenticated(), l10n),
        l10n.availabilityFailureUnauthenticated,
      );
      expect(
        availabilityFailureMessage(
          const AvailabilitySecurityPolicyDenied(),
          l10n,
        ),
        l10n.availabilityFailureSecurityDenied,
      );
      expect(
        availabilityFailureMessage(const DriverProfileMissing(), l10n),
        l10n.availabilityFailureProfileMissing,
      );
      expect(
        availabilityFailureMessage(const DriverAccountSuspended(), l10n),
        l10n.availabilityFailureAccountSuspended,
      );
      expect(
        availabilityFailureMessage(const DriverAccountInactive(), l10n),
        l10n.availabilityFailureAccountInactive,
      );
      expect(
        availabilityFailureMessage(const DriverEmploymentIneligible(), l10n),
        l10n.availabilityFailureEmploymentIneligible,
      );
      expect(
        availabilityFailureMessage(const ActiveAssignmentConflict(), l10n),
        l10n.availabilityFailureAssignmentConflict,
      );
      expect(
        availabilityFailureMessage(const ManualBusyTransitionDenied(), l10n),
        l10n.availabilityFailureManualBusyDenied,
      );
      expect(
        availabilityFailureMessage(const AvailabilityOffline(), l10n),
        l10n.availabilityFailureOffline,
      );
      expect(
        availabilityFailureMessage(
          const AvailabilityPersistenceFailure(),
          l10n,
        ),
        l10n.availabilityFailurePersistence,
      );
      expect(
        availabilityFailureMessage(const AvailabilityStateStale(), l10n),
        l10n.availabilityFailureStale,
      );
      expect(
        availabilityFailureMessage(const AvailabilitySyncConflict(), l10n),
        l10n.availabilityFailureSyncConflict,
      );
      expect(
        availabilityFailureMessage(const InvalidAvailabilityTransition(), l10n),
        l10n.availabilityFailureInvalidTransition,
      );
      expect(
        availabilityFailureMessage(
          const AvailabilityConfirmationRequired(),
          l10n,
        ),
        l10n.availabilityFailureConfirmationRequired,
      );
      expect(
        availabilityFailureMessage(const AvailabilityUnknownFailure(), l10n),
        l10n.availabilityFailureUnknown,
      );
    });
  });

  group('DriverAvailabilityCard status rendering', () {
    testWidgets('unavailable state', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootCard(tester, fake);
      expect(find.text('Unavailable for new requests'), findsOneWidget);
      expect(find.text('Start receiving requests'), findsOneWidget);
      expect(find.text('Confirmed'), findsNothing);
    });

    testWidgets('confirmed available never uses pending label', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await bootCard(tester, fake);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Available for new requests'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Pending confirmation'), findsNothing);
      expect(find.text('Restored — unconfirmed'), findsNothing);
    });

    testWidgets('pending available is not confirmed', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await bootCard(tester, fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .requestAvailable();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Confirming availability'), findsOneWidget);
      expect(find.text('Pending confirmation'), findsOneWidget);
      expect(find.text('Confirmed'), findsNothing);
      expect(find.text('Available for new requests'), findsNothing);
    });

    testWidgets('restored available is unconfirmed', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: availableConfirmed());
      await bootCard(tester, fake);
      expect(
        find.text('Restored previous status — confirmation needed'),
        findsOneWidget,
      );
      expect(find.text('Restored — unconfirmed'), findsOneWidget);
      expect(find.text('Confirmed'), findsNothing);
    });

    testWidgets('busy disables actions and hides assignment id', (
      tester,
    ) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await bootCard(tester, fake);
      await container
          .read(availabilityControllerProvider.notifier)
          .applyAuthoritativeUpdate(
            AuthoritativeAvailabilityUpdate(
              driverId: 'drv-1',
              status: AvailabilityStatus.busy,
              source: AvailabilitySource.server,
              confirmedAt: at,
              revision: 4,
              activeAssignmentId: 'asg-1',
            ),
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Busy with an active request'), findsOneWidget);
      expect(find.text('asg-1'), findsNothing);
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(DriverAvailabilityCard.primaryActionKey),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('restored busy shows pending verification', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: busy());
      await bootCard(tester, fake);
      expect(
        find.text('Restored busy status — awaiting verification'),
        findsOneWidget,
      );
      expect(find.text('Restored — unconfirmed'), findsOneWidget);
      expect(find.text('Confirmed'), findsNothing);
    });

    testWidgets('offline disables activation', (tester) async {
      final fake = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.offline,
          source: AvailabilitySource.connectivityPolicy,
          lastChangedAt: at,
        ),
      );
      await bootCard(tester, fake);
      expect(find.text('Offline'), findsWidgets);
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(DriverAvailabilityCard.primaryActionKey),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('loading shows progress without enabled action', (
      tester,
    ) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable())
        ..restoreDelay = const Duration(milliseconds: 200);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final container = ProviderContainer(
        overrides: [
          availabilityControllerProvider.overrideWith(
            () => AvailabilityController(
              repositoryReader: (_) => fake,
              eligibilityReader: (_, _) => AvailabilitySuccess(eligible()),
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        fake.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en', 'US'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DriverAvailabilityCard()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(DriverAvailabilityCard.progressKey), findsOneWidget);
      expect(find.text('Loading availability'), findsOneWidget);
      final loadingButton = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(DriverAvailabilityCard.primaryActionKey),
          matching: find.byType(FilledButton),
        ),
      );
      expect(loadingButton.onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 250));
    });
  });

  group('DriverAvailabilityCard actions', () {
    testWidgets(
      'unavailable action calls requestAvailable without eligibility',
      (tester) async {
        final fake = FakeDriverAvailabilityRepository(seed: unavailable());
        var sawEligibilityArg = false;
        final container = await bootCard(
          tester,
          fake,
          eligibilityReader: (_, _) {
            sawEligibilityArg = true;
            return AvailabilitySuccess(eligible());
          },
        );
        await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(fake.requestCallCount, 1);
        expect(sawEligibilityArg, isTrue);
        expect(
          container.read(availabilityControllerProvider).isConfirmedAvailable,
          isFalse,
        );
        expect(find.text('Pending confirmation'), findsOneWidget);
      },
    );

    testWidgets('available action calls requestUnavailable', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: availablePending());
      await bootCard(tester, fake);
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Unavailable for new requests'), findsOneWidget);
    });

    testWidgets('default-deny eligibility shows profile-missing message', (
      tester,
    ) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootCard(
        tester,
        fake,
        eligibilityReader: (_, _) =>
            const AvailabilityFailureResult(DriverProfileMissing()),
      );
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(fake.requestCallCount, 0);
      expect(
        find.text('Driver account readiness could not be verified yet.'),
        findsOneWidget,
      );
      expect(find.text('Unavailable for new requests'), findsOneWidget);
      expect(
        find.byKey(DriverAvailabilityCard.failureBannerKey),
        findsOneWidget,
      );
    });

    testWidgets('dismiss failure calls clearFailure', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      final container = await bootCard(
        tester,
        fake,
        eligibilityReader: (_, _) =>
            const AvailabilityFailureResult(DriverProfileMissing()),
      );
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump();
      await tester.tap(find.byKey(DriverAvailabilityCard.dismissFailureKey));
      await tester.pump();
      expect(container.read(availabilityControllerProvider).failure, isNull);
      expect(find.byKey(DriverAvailabilityCard.failureBannerKey), findsNothing);
    });

    testWidgets('processing prevents duplicate tap', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable())
        ..requestDelay = const Duration(milliseconds: 120);
      await bootCard(tester, fake);
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump();
      expect(find.byKey(DriverAvailabilityCard.progressKey), findsOneWidget);
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump(const Duration(milliseconds: 150));
      expect(fake.requestCallCount, 1);
    });
  });

  group('DriverAvailabilityCard failure banners', () {
    Future<void> expectFailureBanner(
      WidgetTester tester,
      AvailabilityFailure failure,
      String expectedMessage,
    ) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootCard(
        tester,
        fake,
        eligibilityReader: (_, _) => AvailabilityFailureResult(failure),
      );
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text(expectedMessage), findsOneWidget);
      expect(fake.requestCallCount, 0);
    }

    testWidgets('unauthenticated', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const AvailabilityUnauthenticated(),
        l10n.availabilityFailureUnauthenticated,
      );
    });

    testWidgets('security denial', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const AvailabilitySecurityPolicyDenied(),
        l10n.availabilityFailureSecurityDenied,
      );
    });

    testWidgets('offline failure message', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const AvailabilityOffline(),
        l10n.availabilityFailureOffline,
      );
    });

    testWidgets('assignment conflict', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const ActiveAssignmentConflict(),
        l10n.availabilityFailureAssignmentConflict,
      );
    });

    testWidgets('persistence failure', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const AvailabilityPersistenceFailure(),
        l10n.availabilityFailurePersistence,
      );
    });

    testWidgets('stale state', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const AvailabilityStateStale(),
        l10n.availabilityFailureStale,
      );
    });

    testWidgets('sync conflict', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const AvailabilitySyncConflict(),
        l10n.availabilityFailureSyncConflict,
      );
    });

    testWidgets('unknown fallback', (tester) async {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      await expectFailureBanner(
        tester,
        const AvailabilityUnknownFailure(),
        l10n.availabilityFailureUnknown,
      );
    });
  });

  group('DriverAvailabilityCard layout and a11y', () {
    testWidgets('narrow width has no overflow', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootCard(tester, fake, surfaceSize: const Size(320, 640));
      expect(tester.takeException(), isNull);
      expect(find.byType(DriverAvailabilityCard), findsOneWidget);
    });

    testWidgets('large text scale has no overflow', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootCard(
        tester,
        fake,
        textScale: 1.6,
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Unavailable for new requests'), findsOneWidget);
    });

    testWidgets('RTL rendering keeps card', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootCard(
        tester,
        fake,
        textDirection: TextDirection.rtl,
        locale: const Locale('ar', 'SA'),
      );
      expect(find.byType(DriverAvailabilityCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('status and action semantics exist', (tester) async {
      final fake = FakeDriverAvailabilityRepository(seed: unavailable());
      await bootCard(tester, fake);
      expect(find.byKey(DriverAvailabilityCard.statusLabelKey), findsOneWidget);
      expect(
        find.byKey(DriverAvailabilityCard.primaryActionKey),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(DriverAvailabilityCard.primaryActionKey),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
