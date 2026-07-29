import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/providers/home_ui_providers.dart';
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
import 'package:saeq_driver/features/driver/presentation/home_screen.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/shared/widgets/saeq_offline_banner.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../../auth/test_doubles.dart';

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  bool offline = false,
}) async {
  final storage = FakeSecureStorageService();
  final logger = RecordingLoggerService();
  final sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
  final repository = FakeAuthenticationRepository(
    sessionStorage: sessionStorage,
    logger: logger,
    isProductionEnvironment: () => false,
    signInDelay: Duration.zero,
  );
  addTearDown(repository.dispose);

  final fakeAvailability = FakeDriverAvailabilityRepository(
    seed: DriverAvailability(
      driverId: 'drv-1',
      status: AvailabilityStatus.unavailable,
      source: AvailabilitySource.system,
      lastChangedAt: DateTime.utc(2026, 7, 26),
    ),
  );

  final container = ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => AuthController(repositoryReader: (ref) => repository),
      ),
      availabilityControllerProvider.overrideWith(
        () => AvailabilityController(
          repositoryReader: (_) => fakeAvailability,
          eligibilityReader: (_, _) => AvailabilitySuccess(
            const AvailabilityEligibilityInput(
              authenticated: true,
              profileExists: true,
              accountStatus: AccountStatus.verified,
              employmentStatus: EmploymentStatus.active,
              hasActiveAssignment: false,
              connectivityAvailable: true,
              securityPolicyAllows: true,
            ),
          ),
        ),
      ),
      isOfflineProvider.overrideWithValue(offline),
    ],
  );
  addTearDown(() {
    container.dispose();
    fakeAvailability.dispose();
  });

  container.read(authControllerProvider);
  await container.read(authControllerProvider.notifier).signIn('0501234567');

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
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}

void main() {
  testWidgets('Home shows summary and quick actions', (tester) async {
    await _pumpHome(tester);
    expect(find.textContaining("Today's summary"), findsOneWidget);
    expect(find.text('View deliveries'), findsOneWidget);
    expect(find.text('View earnings'), findsOneWidget);
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('Home shows offline banner when offline', (tester) async {
    await _pumpHome(tester, offline: true);
    expect(find.byKey(SaeqOfflineBanner.bannerKey), findsOneWidget);
  });

  testWidgets('Home does not expose fixed sign-out CTA', (tester) async {
    await _pumpHome(tester);
    expect(find.text('Sign Out'), findsNothing);
    expect(find.byKey(const Key('homeSignOut')), findsNothing);
  });
}
