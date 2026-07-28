import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:saeq_driver/features/auth/presentation/screens/session_expired_screen.dart';
import 'package:saeq_driver/features/auth/presentation/screens/splash_screen.dart';
import 'package:saeq_driver/features/driver/presentation/welcome_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_otp_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_doubles.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureStorageService storage;
  late RecordingLoggerService logger;
  late AuthSessionStorage sessionStorage;
  late FakeAuthenticationRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = FakeSecureStorageService();
    logger = RecordingLoggerService();
    sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
    repository = FakeAuthenticationRepository(
      sessionStorage: sessionStorage,
      logger: logger,
      isProductionEnvironment: () => false,
      signInDelay: Duration.zero,
      otpRequestDelay: Duration.zero,
    );
  });

  tearDown(() => repository.dispose());

  List<Override> overrides() => [
    authControllerProvider.overrideWith(
      () => AuthController(repositoryReader: (ref) => repository),
    ),
  ];

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required String location,
    Locale locale = const Locale('en'),
  }) async {
    late GoRouter router;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await _pumpFrames(tester);
    router.go(location);
    await _pumpFrames(tester);
    return router;
  }

  group('Auth Batch 2 UI parity flows', () {
    testWidgets('Splash auto-advances to Welcome', (tester) async {
      final router = await pumpApp(tester, location: AppRoutes.splash);
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.welcome);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Welcome Start → Onboarding → Continue → Login', (
      tester,
    ) async {
      final router = await pumpApp(tester, location: AppRoutes.welcome);
      await tester.tap(find.byKey(const Key('welcomeStart')));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.onboarding);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('onboardingContinue')));
      await tester.tap(find.byKey(const Key('onboardingContinue')));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.login);
    });

    testWidgets('A1 Onboarding Skip → Login', (tester) async {
      final router = await pumpApp(tester, location: AppRoutes.onboarding);
      await tester.ensureVisible(find.byKey(const Key('onboardingSkip')));
      await tester.tap(find.byKey(const Key('onboardingSkip')));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.login);
    });

    testWidgets('A2 Login validation error then success to OTP', (
      tester,
    ) async {
      final router = await pumpApp(tester, location: AppRoutes.login);
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await _pumpFrames(tester);
      expect(find.text('Invalid mobile number'), findsWidgets);
      await tester.enterText(find.byType(TextFormField), '0512345678');
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.loginOtp);
    });

    testWidgets('A3 OTP Change Phone → Login', (tester) async {
      final router = await pumpApp(tester, location: AppRoutes.login);
      await tester.enterText(find.byType(TextFormField), '0512345678');
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.loginOtp);
      await tester.tap(find.byKey(const Key('otpChangePhone')));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.login);
    });

    testWidgets('A5 Invalid OTP shows error', (tester) async {
      await pumpApp(tester, location: AppRoutes.login);
      await tester.enterText(find.byType(TextFormField), '0512345678');
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFrames(tester);
      await tester.enterText(find.byKey(SaeqOtpInput.fieldKey), '000000');
      await tester.tap(find.byKey(const Key('otpVerifySubmit')));
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFrames(tester);
      expect(find.byKey(const Key('otpErrorMessage')), findsOneWidget);
    });

    testWidgets('OTP success → Home', (tester) async {
      final router = await pumpApp(tester, location: AppRoutes.login);
      await tester.enterText(find.byType(TextFormField), '0512345678');
      await tester.tap(find.byKey(const Key('loginSubmit')));
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFrames(tester);
      await tester.enterText(find.byKey(SaeqOtpInput.fieldKey), '246810');
      await tester.tap(find.byKey(const Key('otpVerifySubmit')));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.home);
    });

    testWidgets('A6 Session Expired → Login Again', (tester) async {
      final router = await pumpApp(tester, location: AppRoutes.sessionExpired);
      expect(find.byType(SessionExpiredScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('sessionExpiredLoginAgain')));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.login);
    });

    testWidgets('A7 Welcome locale toggle flips EN ↔ AR', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              final router = ref.watch(appRouterProvider);
              final locale = ref.watch(appLocaleProvider);
              return MaterialApp.router(
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await _pumpFrames(tester);
      container.read(appRouterProvider).go(AppRoutes.welcome);
      await _pumpFrames(tester);
      expect(find.text('ابدأ'), findsOneWidget);
      await tester.tap(find.byKey(const Key('welcomeLocaleToggle')));
      await _pumpFrames(tester);
      expect(find.text('Start'), findsOneWidget);
      await tester.tap(find.byKey(const Key('welcomeLocaleToggle')));
      await _pumpFrames(tester);
      expect(find.text('ابدأ'), findsOneWidget);
    });

    testWidgets('A8 Welcome theme toggle flips light/dark', (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(
                locale: const Locale('en'),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await _pumpFrames(tester);
      container.read(appRouterProvider).go(AppRoutes.welcome);
      await _pumpFrames(tester);
      expect(container.read(appThemeModeProvider), ThemeMode.light);
      await tester.ensureVisible(find.byKey(const Key('welcomeThemeToggle')));
      await tester.tap(find.byKey(const Key('welcomeThemeToggle')));
      await _pumpFrames(tester);
      expect(container.read(appThemeModeProvider), ThemeMode.dark);
    });

    testWidgets('Onboarding Back → Welcome', (tester) async {
      final router = await pumpApp(tester, location: AppRoutes.onboarding);
      await tester.ensureVisible(find.byKey(const Key('onboardingBack')));
      await tester.tap(find.byKey(const Key('onboardingBack')));
      await _pumpFrames(tester);
      expect(router.state.uri.path, AppRoutes.welcome);
    });
  });
}
