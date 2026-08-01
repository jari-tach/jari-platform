import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/network/network_monitor.dart';
import 'package:saeq_driver/core/providers/home_ui_providers.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller_state.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/availability/presentation/widgets/driver_availability_card.dart';
import 'package:saeq_driver/features/driver/presentation/home_screen.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saeq_driver/shared/widgets/saeq_offline_banner.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../../auth/test_doubles.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

AvailabilityEligibilityInput _eligible({bool online = true}) =>
    AvailabilityEligibilityInput(
      authenticated: true,
      profileExists: true,
      accountStatus: AccountStatus.verified,
      employmentStatus: EmploymentStatus.active,
      hasActiveAssignment: false,
      connectivityAvailable: online,
      securityPolicyAllows: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthenticationRepository authRepository;
  late FakeDriverAvailabilityRepository availabilityRepository;
  final at = DateTime.utc(2026, 7, 28, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final storage = FakeSecureStorageService();
    final logger = RecordingLoggerService();
    final sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
    authRepository = FakeAuthenticationRepository(
      sessionStorage: sessionStorage,
      logger: logger,
      isProductionEnvironment: () => false,
      signInDelay: Duration.zero,
      otpRequestDelay: Duration.zero,
    );
    availabilityRepository = FakeDriverAvailabilityRepository(
      seed: DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.unavailable,
        source: AvailabilitySource.system,
        lastChangedAt: at,
      ),
    );
  });

  tearDown(() {
    authRepository.dispose();
    availabilityRepository.dispose();
  });

  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
    bool offline = false,
    DriverAvailability? seed,
    AvailabilityEligibilityInput? eligibility,
  }) async {
    if (seed != null) availabilityRepository.seed(seed);

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => AuthController(repositoryReader: (_) => authRepository),
        ),
        availabilityControllerProvider.overrideWith(
          () => AvailabilityController(
            repositoryReader: (_) => availabilityRepository,
            eligibilityReader: (_, _) =>
                AvailabilitySuccess(eligibility ?? _eligible(online: !offline)),
          ),
        ),
        isOfflineProvider.overrideWithValue(offline),
        connectivityStatusProvider.overrideWith(
          (ref) => Stream.value(
            offline ? ConnectivityStatus.offline : ConnectivityStatus.online,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await container.read(authControllerProvider.notifier).signIn('0501234567');
    await container.read(availabilityControllerProvider.notifier).initialize();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await _settle(tester);
    return container;
  }

  group('Home Batch 3 shell', () {
    testWidgets('authenticated Home opens without logout CTA', (tester) async {
      await pumpHome(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byKey(HomeScreen.greetingKey), findsOneWidget);
      expect(find.text('Sign Out'), findsNothing);
      expect(find.byKey(const Key('homeSignOut')), findsNothing);
      expect(find.byIcon(Icons.logout), findsNothing);
    });

    testWidgets('notifications action and brand title are present', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.byKey(HomeScreen.notificationsActionKey), findsOneWidget);
      expect(find.byKey(const Key('saeqBrandAppBarTitle')), findsOneWidget);
      expect(find.byKey(HomeScreen.quickActionDeliveriesKey), findsNothing);
      expect(find.byKey(HomeScreen.quickActionEarningsKey), findsNothing);
    });
  });

  group('Flow B availability', () {
    testWidgets('Unavailable → Pending → Confirmed → Unavailable', (
      tester,
    ) async {
      final container = await pumpHome(tester);
      expect(find.text('Unavailable for new requests'), findsOneWidget);

      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump(const Duration(milliseconds: 100));
      await _settle(tester);

      var state = container.read(availabilityControllerProvider);
      expect(state.current?.status, AvailabilityStatus.available);
      expect(state.isPendingConfirmation || state.current!.pendingSync, isTrue);

      await container
          .read(availabilityControllerProvider.notifier)
          .applyAuthoritativeUpdate(
            AuthoritativeAvailabilityUpdate(
              driverId: 'drv-1',
              status: AvailabilityStatus.available,
              source: AvailabilitySource.system,
              confirmedAt: at.add(const Duration(seconds: 1)),
              revision: 2,
            ),
          );
      await _settle(tester);
      state = container.read(availabilityControllerProvider);
      expect(state.isConfirmedAvailable, isTrue);

      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump(const Duration(milliseconds: 100));
      await _settle(tester);
      expect(
        container.read(availabilityControllerProvider).current?.status,
        AvailabilityStatus.unavailable,
      );
    });

    testWidgets('processing disables primary CTA', (tester) async {
      availabilityRepository.requestDelay = const Duration(milliseconds: 400);
      final container = await pumpHome(tester);
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump();
      expect(
        container.read(availabilityControllerProvider).isProcessing,
        isTrue,
      );
      final primary = tester.widget<SaeqPrimaryButton>(
        find.byKey(DriverAvailabilityCard.primaryActionKey),
      );
      expect(primary.onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 450));
      await _settle(tester);
    });
  });

  group('Flow M special states', () {
    testWidgets('M1 offline disables CTA', (tester) async {
      final container = await pumpHome(
        tester,
        offline: true,
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.offline,
          source: AvailabilitySource.connectivityPolicy,
          lastChangedAt: at,
        ),
        eligibility: _eligible(online: false),
      );
      expect(find.byKey(SaeqOfflineBanner.bannerKey), findsOneWidget);
      expect(
        container.read(availabilityControllerProvider).canRequestAvailable,
        isFalse,
      );
      final primary = tester.widget<SaeqPrimaryButton>(
        find.byKey(DriverAvailabilityCard.primaryActionKey),
      );
      expect(primary.onPressed, isNull);
    });

    testWidgets('M3 failure shows message; dismiss and retry work', (
      tester,
    ) async {
      final container = await pumpHome(tester);
      availabilityRepository.nextRequestFailure =
          const AvailabilityPersistenceFailure();
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump(const Duration(milliseconds: 100));
      await _settle(tester);

      expect(
        find.byKey(DriverAvailabilityCard.failureBannerKey),
        findsOneWidget,
      );
      expect(find.byKey(DriverAvailabilityCard.retryKey), findsOneWidget);
      expect(
        container.read(availabilityControllerProvider).status,
        AvailabilityViewStatus.failure,
      );

      await tester.tap(find.byKey(DriverAvailabilityCard.dismissFailureKey));
      await _settle(tester);
      expect(find.byKey(DriverAvailabilityCard.failureBannerKey), findsNothing);

      availabilityRepository.nextRequestFailure =
          const AvailabilityPersistenceFailure();
      await tester.tap(find.byKey(DriverAvailabilityCard.primaryActionKey));
      await tester.pump(const Duration(milliseconds: 100));
      await _settle(tester);
      availabilityRepository.nextRequestFailure = null;
      await tester.tap(find.byKey(DriverAvailabilityCard.retryKey));
      await tester.pump(const Duration(milliseconds: 100));
      await _settle(tester);
      expect(
        container.read(availabilityControllerProvider).isInitialized,
        isTrue,
      );
      expect(
        find.byKey(DriverAvailabilityCard.primaryActionKey),
        findsOneWidget,
      );
    });

    testWidgets('M4/M5/M7 Busy disables CTA and shows active delivery action', (
      tester,
    ) async {
      await pumpHome(
        tester,
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.system,
          lastChangedAt: at,
          activeAssignmentId: 'asg-1',
          pendingSync: true,
        ),
      );
      expect(find.textContaining('busy'), findsWidgets);
      final primary = tester.widget<SaeqPrimaryButton>(
        find.byKey(DriverAvailabilityCard.primaryActionKey),
      );
      expect(primary.onPressed, isNull);
      expect(
        find.byKey(DriverAvailabilityCard.openActiveDeliveryKey),
        findsOneWidget,
      );
    });

    testWidgets('M6 restored unconfirmed available warning', (tester) async {
      await pumpHome(
        tester,
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.restoredLocalState,
          lastChangedAt: at,
          pendingSync: true,
        ),
      );
      expect(find.textContaining('Restored'), findsWidgets);
    });

    testWidgets('M8 Settings keeps logout with prepare path', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => AuthController(repositoryReader: (_) => authRepository),
            ),
            availabilityControllerProvider.overrideWith(
              () => AvailabilityController(
                repositoryReader: (_) => availabilityRepository,
                eligibilityReader: (_, _) => AvailabilitySuccess(_eligible()),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await _settle(tester);
      await tester.ensureVisible(find.byKey(SettingsScreen.signOutKey));
      expect(find.byKey(SettingsScreen.signOutKey), findsOneWidget);
    });
  });

  group('Locale and theme', () {
    testWidgets('Arabic RTL greeting', (tester) async {
      await pumpHome(tester, locale: const Locale('ar'));
      expect(find.text('مرحبًا بعودتك'), findsOneWidget);
    });

    testWidgets('English LTR greeting', (tester) async {
      await pumpHome(tester);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('Dark theme Home renders', (tester) async {
      await pumpHome(tester, themeMode: ThemeMode.dark);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Routed navigation smoke', () {
    testWidgets('notifications icon navigates via GoRouter', (tester) async {
      late GoRouter router;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => AuthController(repositoryReader: (_) => authRepository),
          ),
          availabilityControllerProvider.overrideWith(
            () => AvailabilityController(
              repositoryReader: (_) => availabilityRepository,
              eligibilityReader: (_, _) => AvailabilitySuccess(_eligible()),
            ),
          ),
          isOfflineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await container
          .read(authControllerProvider.notifier)
          .signIn('0501234567');
      await container
          .read(availabilityControllerProvider.notifier)
          .initialize();

      router = GoRouter(
        initialLocation: AppRoutes.home,
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const Scaffold(body: Text('Notifications Page')),
          ),
          GoRoute(
            path: AppRoutes.deliveries,
            builder: (_, _) => const Scaffold(body: Text('Deliveries Page')),
          ),
          GoRoute(
            path: AppRoutes.earnings,
            builder: (_, _) => const Scaffold(body: Text('Earnings Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await _settle(tester);

      await tester.tap(find.byKey(HomeScreen.notificationsActionKey));
      await _settle(tester);
      expect(router.state.uri.path, AppRoutes.notifications);
      expect(find.text('Notifications Page'), findsOneWidget);

      router.go(AppRoutes.home);
      await _settle(tester);
      expect(find.byKey(HomeScreen.notificationsActionKey), findsWidgets);
      expect(find.byKey(const Key('saeqBrandAppBarTitle')), findsWidgets);
    });
  });
}
