import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/network/network_monitor.dart';
import 'package:saeq_driver/core/providers/home_ui_providers.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller_state.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/availability/presentation/widgets/availability_connectivity_bridge.dart';
import 'package:saeq_driver/features/availability/presentation/widgets/driver_availability_card.dart';
import 'package:saeq_driver/features/driver/presentation/home_screen.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/shared/widgets/saeq_offline_banner.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/test_doubles.dart';
import '../helpers/fake_driver_availability_repository.dart';

class _ConnectivitySource {
  _ConnectivitySource(this.initial);

  ConnectivityStatus initial;
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get stream async* {
    yield initial;
    yield* _controller.stream;
  }

  void emit(ConnectivityStatus status) {
    initial = status;
    if (!_controller.isClosed) {
      _controller.add(status);
    }
  }

  void dispose() {
    _controller.close();
  }
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

  final at = DateTime.utc(2026, 7, 29, 12);

  late FakeAuthenticationRepository authRepository;
  late FakeDriverAvailabilityRepository availabilityRepository;
  late _ConnectivitySource connectivity;

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
    );
    availabilityRepository = FakeDriverAvailabilityRepository(
      seed: DriverAvailability(
        driverId: 'drv-1',
        status: AvailabilityStatus.offline,
        source: AvailabilitySource.connectivityPolicy,
        lastChangedAt: at,
      ),
    );
    connectivity = _ConnectivitySource(ConnectivityStatus.offline);
  });

  tearDown(() {
    authRepository.dispose();
    availabilityRepository.dispose();
    connectivity.dispose();
  });

  Future<ProviderContainer> pumpHarness(
    WidgetTester tester, {
    Widget? body,
    bool offlineBanner = false,
    Duration? restoreDelay,
  }) async {
    if (restoreDelay != null) {
      availabilityRepository.restoreDelay = restoreDelay;
    }

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => AuthController(repositoryReader: (_) => authRepository),
        ),
        availabilityControllerProvider.overrideWith(
          () => AvailabilityController(
            repositoryReader: (_) => availabilityRepository,
            eligibilityReader: (_, _) =>
                AvailabilitySuccess(_eligible(online: !offlineBanner)),
          ),
        ),
        connectivityStatusProvider.overrideWith((ref) => connectivity.stream),
        isOfflineProvider.overrideWith((ref) {
          final async = ref.watch(connectivityStatusProvider);
          return async.maybeWhen(
            data: (s) => s == ConnectivityStatus.offline,
            orElse: () => offlineBanner,
          );
        }),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await container.read(authControllerProvider.notifier).signIn('0501234567');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body:
                body ??
                const Column(
                  children: [
                    AvailabilityConnectivityBridge(),
                    DriverAvailabilityCard(),
                  ],
                ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  Future<void> waitForInit(
    ProviderContainer container, {
    Duration max = const Duration(seconds: 2),
  }) async {
    final end = DateTime.now().add(max);
    while (DateTime.now().isBefore(end)) {
      if (container.read(availabilityControllerProvider).isInitialized) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('Availability initialize did not complete in time');
  }

  group('Connectivity / Availability initialization race', () {
    testWidgets('Test1: Online before init-complete clears persisted Offline', (
      tester,
    ) async {
      final container = await pumpHarness(
        tester,
        restoreDelay: const Duration(milliseconds: 250),
      );

      // Online arrives while restore is still in flight.
      connectivity.emit(ConnectivityStatus.online);
      await tester.pump();

      expect(
        container.read(availabilityControllerProvider).isInitialized,
        isFalse,
      );

      await tester.pump(const Duration(milliseconds: 300));
      await waitForInit(container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final state = container.read(availabilityControllerProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isOffline, isFalse);
      expect(state.current?.status, AvailabilityStatus.unavailable);
      expect(find.byKey(SaeqOfflineBanner.bannerKey), findsNothing);

      final primary = tester.widget<SaeqPrimaryButton>(
        find.byKey(DriverAvailabilityCard.primaryActionKey),
      );
      expect(primary.onPressed, isNotNull);
    });

    testWidgets(
      'Test2: Offline throughout init keeps Offline and disables CTA',
      (tester) async {
        final container = await pumpHarness(
          tester,
          restoreDelay: const Duration(milliseconds: 100),
          offlineBanner: true,
        );
        connectivity.emit(ConnectivityStatus.offline);
        await tester.pump(const Duration(milliseconds: 150));
        await waitForInit(container);
        await tester.pump(const Duration(milliseconds: 50));

        final state = container.read(availabilityControllerProvider);
        expect(state.isOffline, isTrue);
        final primary = tester.widget<SaeqPrimaryButton>(
          find.byKey(DriverAvailabilityCard.primaryActionKey),
        );
        expect(primary.onPressed, isNull);
      },
    );

    testWidgets('Test3: Offline→Online→Offline during init ends Offline', (
      tester,
    ) async {
      final container = await pumpHarness(
        tester,
        restoreDelay: const Duration(milliseconds: 300),
      );
      connectivity.emit(ConnectivityStatus.online);
      await tester.pump();
      connectivity.emit(ConnectivityStatus.offline);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await waitForInit(container);
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(availabilityControllerProvider).isOffline, isTrue);
    });

    testWidgets(
      'Test4: Online→Offline→Online during init ends Online (cleared)',
      (tester) async {
        final container = await pumpHarness(
          tester,
          restoreDelay: const Duration(milliseconds: 300),
        );
        connectivity.emit(ConnectivityStatus.online);
        await tester.pump();
        connectivity.emit(ConnectivityStatus.offline);
        await tester.pump();
        connectivity.emit(ConnectivityStatus.online);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await waitForInit(container);
        await tester.pump(const Duration(milliseconds: 50));

        final state = container.read(availabilityControllerProvider);
        expect(state.isOffline, isFalse);
        expect(state.current?.status, AvailabilityStatus.unavailable);
      },
    );

    testWidgets('Test5: Init failure then Retry with Online reconciles', (
      tester,
    ) async {
      availabilityRepository.nextRestoreFailure =
          const AvailabilityPersistenceFailure();
      final container = await pumpHarness(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        container.read(availabilityControllerProvider).status,
        AvailabilityViewStatus.failure,
      );

      connectivity.emit(ConnectivityStatus.online);
      await tester.pump();

      availabilityRepository.nextRestoreFailure = null;
      await container
          .read(availabilityControllerProvider.notifier)
          .initialize();
      await tester.pump(const Duration(milliseconds: 50));

      final state = container.read(availabilityControllerProvider);
      expect(state.isInitialized, isTrue);
      expect(state.isOffline, isFalse);
    });

    testWidgets('Test6: Online after init completes uses normal path', (
      tester,
    ) async {
      final container = await pumpHarness(
        tester,
        restoreDelay: const Duration(milliseconds: 50),
      );
      await tester.pump(const Duration(milliseconds: 80));
      await waitForInit(container);
      expect(container.read(availabilityControllerProvider).isOffline, isTrue);

      connectivity.emit(ConnectivityStatus.online);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(availabilityControllerProvider).isOffline, isFalse);
    });

    testWidgets('Test7: Duplicate same connectivity level does not re-write', (
      tester,
    ) async {
      final container = await pumpHarness(
        tester,
        restoreDelay: const Duration(milliseconds: 50),
      );
      await tester.pump(const Duration(milliseconds: 80));
      await waitForInit(container);

      connectivity.emit(ConnectivityStatus.online);
      await tester.pump(const Duration(milliseconds: 50));
      final writesAfterFirst = availabilityRepository.requestCallCount;

      connectivity.emit(ConnectivityStatus.online);
      await tester.pump(const Duration(milliseconds: 50));
      expect(availabilityRepository.requestCallCount, writesAfterFirst);
    });

    testWidgets('Test8: Busy preserved when Online arrives during init', (
      tester,
    ) async {
      availabilityRepository.seed(
        DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.system,
          lastChangedAt: at,
          activeAssignmentId: 'asg-1',
          pendingSync: true,
        ),
      );
      final container = await pumpHarness(
        tester,
        restoreDelay: const Duration(milliseconds: 200),
      );
      connectivity.emit(ConnectivityStatus.online);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await waitForInit(container);
      await tester.pump(const Duration(milliseconds: 50));

      final state = container.read(availabilityControllerProvider);
      expect(state.isBusy, isTrue);
      expect(state.isOffline, isFalse);
      expect(state.current?.status, AvailabilityStatus.busy);
      expect(
        availabilityRepository.changeRequests.where(
          (r) => r.requestedStatus == AvailabilityStatus.available,
        ),
        isEmpty,
      );
      expect(
        availabilityRepository.changeRequests.where(
          (r) => r.requestedStatus == AvailabilityStatus.unavailable,
        ),
        isEmpty,
      );
    });

    testWidgets(
      'Test9: Home offline banner clears after init + Wi-Fi without reopen',
      (tester) async {
        connectivity = _ConnectivitySource(ConnectivityStatus.offline);
        final container = await pumpHarness(
          tester,
          body: const HomeScreen(),
          restoreDelay: const Duration(milliseconds: 200),
        );

        connectivity.emit(ConnectivityStatus.online);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await waitForInit(container);
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byKey(SaeqOfflineBanner.bannerKey), findsNothing);
        expect(
          container.read(availabilityControllerProvider).isOffline,
          isFalse,
        );
        expect(find.byType(DriverAvailabilityCard), findsOneWidget);
      },
    );
  });
}
