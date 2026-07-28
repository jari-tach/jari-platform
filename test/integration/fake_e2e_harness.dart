import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_eligibility_input.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_profile.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/profile/domain/entities/profile_error.dart';
import 'package:saeq_driver/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/presentation/controllers/profile_controller.dart';
import 'package:saeq_driver/features/profile/presentation/providers/profile_providers.dart';

import '../features/auth/test_doubles.dart';
import '../features/availability/helpers/fake_driver_availability_repository.dart';

/// Bounded pump for full-router Fake E2E widget tests.
Future<void> pumpFakeE2eBounded(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

class FakeE2eProfileRepository implements DriverProfileRepository {
  FakeE2eProfileRepository(this.profile);

  final DriverProfile profile;

  @override
  Future<DriverProfile> getCurrentProfile() async => profile;

  @override
  Future<DriverProfile> updateCurrentProfile(
    DriverProfileUpdate update,
  ) async => profile;
}

/// Shared Fake Alpha harness for PHASE 2.6 Increment 5 router-level flows.
Future<
  ({
    ProviderContainer container,
    FakeAuthenticationRepository authRepository,
    FakeDriverAvailabilityRepository availabilityRepository,
  })
>
createFakeE2eContainer({
  List<Override> extraOverrides = const [],
  DriverProfile? profile,
}) async {
  SharedPreferences.setMockInitialValues({});

  final storage = FakeSecureStorageService();
  final logger = RecordingLoggerService();
  final sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
  final authRepository = FakeAuthenticationRepository(
    sessionStorage: sessionStorage,
    logger: logger,
    isProductionEnvironment: () => false,
    signInDelay: Duration.zero,
  );
  await authRepository.signIn('0501234567');

  final now = DateTime.utc(2026, 7, 28);
  final seededProfile =
      profile ??
      DriverProfile(
        driverId: 'drv-e2e',
        fullName: 'E2E Driver',
        phoneNumber: '0512345678',
        accountStatus: AccountStatus.verified,
        employmentStatus: EmploymentStatus.active,
        createdAt: now,
        updatedAt: now,
      );

  final availabilityRepository = FakeDriverAvailabilityRepository(
    seed: DriverAvailability(
      driverId: seededProfile.driverId,
      status: AvailabilityStatus.unavailable,
      source: AvailabilitySource.system,
      lastChangedAt: now,
    ),
  );

  final profileRepository = FakeE2eProfileRepository(seededProfile);

  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => AuthController(repositoryReader: (ref) => authRepository),
      ),
      profileControllerProvider.overrideWith(
        () => ProfileController(repositoryReader: (_) => profileRepository),
      ),
      availabilityControllerProvider.overrideWith(
        () => AvailabilityController(
          repositoryReader: (_) => availabilityRepository,
          eligibilityReader: (_, _) => AvailabilitySuccess(
            AvailabilityEligibilityInput(
              authenticated: true,
              profileExists: true,
              accountStatus: seededProfile.accountStatus,
              employmentStatus: seededProfile.employmentStatus,
              hasActiveAssignment: false,
              connectivityAvailable: true,
              securityPolicyAllows: true,
            ),
          ),
        ),
      ),
      ...extraOverrides,
    ],
  );

  return (
    container: container,
    authRepository: authRepository,
    availabilityRepository: availabilityRepository,
  );
}

Future<GoRouter> pumpFakeE2eApp(
  WidgetTester tester,
  ProviderContainer container, {
  Size surfaceSize = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);

  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const _FakeE2eRouterApp(),
    ),
  );
  await pumpFakeE2eBounded(tester);
  return router;
}

class _FakeE2eRouterApp extends ConsumerWidget {
  const _FakeE2eRouterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'SAEQ Driver',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
