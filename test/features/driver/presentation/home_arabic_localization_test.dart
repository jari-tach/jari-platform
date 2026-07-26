import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
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
import 'package:saeq_driver/features/driver/presentation/welcome_screen.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../../auth/test_doubles.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  required Locale locale,
  double textScale = 1.0,
  Size surfaceSize = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

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
          home: const HomeScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpWelcome(WidgetTester tester, {required Locale locale}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WelcomeScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('HomeScreen localization', () {
    testWidgets('Arabic greeting and sign-out are Arabic-only', (tester) async {
      await _pumpHome(tester, locale: const Locale('ar'));

      expect(find.text('تم تسجيل الدخول بنجاح'), findsWidgets);
      expect(find.text('تسجيل الخروج'), findsOneWidget);
      expect(find.text('التوفر'), findsOneWidget);
      expect(find.text('Signed in successfully'), findsNothing);
      expect(find.text('Sign Out'), findsNothing);
      expect(find.text('Availability'), findsNothing);
    });

    testWidgets('English home rendering regression', (tester) async {
      await _pumpHome(tester, locale: const Locale('en', 'US'));

      expect(find.text('Signed in successfully'), findsWidgets);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('تم تسجيل الدخول بنجاح'), findsNothing);
      expect(find.text('تسجيل الخروج'), findsNothing);
    });

    testWidgets('Arabic locale drives RTL on home', (tester) async {
      await _pumpHome(tester, locale: const Locale('ar'));
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality).first,
        ),
      );
      expect(directionality.textDirection, TextDirection.rtl);
      expect(find.byType(SaeqPrimaryButton), findsWidgets);
    });

    testWidgets('English locale drives LTR on home', (tester) async {
      await _pumpHome(tester, locale: const Locale('en'));
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality).first,
        ),
      );
      expect(directionality.textDirection, TextDirection.ltr);
    });
  });

  group('WelcomeScreen localization', () {
    testWidgets('Arabic welcome has no English app-owned sentences', (
      tester,
    ) async {
      await _pumpWelcome(tester, locale: const Locale('ar'));

      expect(find.textContaining('الأساسيات والهيكلية'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('الخطوات التالية'), findsOneWidget);
      expect(find.textContaining('Focus now on fundamentals'), findsNothing);
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Next Steps'), findsNothing);
      expect(find.text('Saeq Driver'), findsNothing);
      expect(find.text('سائق'), findsOneWidget);
    });

    testWidgets('English welcome has no Arabic app-owned sentences', (
      tester,
    ) async {
      await _pumpWelcome(tester, locale: const Locale('en'));

      expect(find.textContaining('Focus now on fundamentals'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Next Steps'), findsOneWidget);
      expect(find.textContaining('الأساسيات والهيكلية'), findsNothing);
      expect(find.text('تسجيل الدخول'), findsNothing);
      expect(find.text('Saeq Driver'), findsOneWidget);
    });
  });
}
