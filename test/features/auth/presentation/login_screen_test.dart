import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// See test_bootstrap.dart for why this import is needed.
import 'package:riverpod/misc.dart' show Override;
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/auth/presentation/screens/login_screen.dart';
import 'package:saeq_driver/features/driver/presentation/home_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

import '../test_doubles.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required List<Override> overrides,
  Locale locale = const Locale('en', 'US'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  // Bounded: GoogleFonts/theme animations must not keep pumpAndSettle
  // spinning forever in this suite.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('LoginScreen', () {
    late FakeSecureStorageService storage;
    late RecordingLoggerService logger;
    late AuthSessionStorage sessionStorage;
    late FakeAuthenticationRepository repository;

    setUp(() {
      storage = FakeSecureStorageService();
      logger = RecordingLoggerService();
      sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
      // Default: no artificial delay. The "loading disables button" test
      // builds its own repository with a non-zero delay below.
      repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: Duration.zero,
      );
    });

    tearDown(() => repository.dispose());

    List<Override> overridesWith(FakeAuthenticationRepository repo) => [
      authControllerProvider.overrideWith(
        () => AuthController(repositoryReader: (ref) => repo),
      ),
    ];

    // 16. Login validation
    testWidgets('shows a validation error for an invalid phone number', (
      tester,
    ) async {
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
      );

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.widgetWithText(SaeqPrimaryButton, 'Sign In'));
      await tester.pump();

      expect(
        find.text('Please enter a valid phone number (05XXXXXXXX).'),
        findsOneWidget,
      );
    });

    // 17. Loading disables duplicate submission
    testWidgets('disables the sign-in button while a request is in flight', (
      tester,
    ) async {
      // Non-zero delay so the mid-flight assertion can observe the busy state
      // before the request resolves. Do NOT use pumpAndSettle while the
      // CircularProgressIndicator is spinning — it never settles.
      final slowRepository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: const Duration(milliseconds: 200),
      );
      addTearDown(slowRepository.dispose);

      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(slowRepository),
      );

      await tester.enterText(find.byType(TextFormField), '0501234567');
      await tester.tap(find.widgetWithText(SaeqPrimaryButton, 'Sign In'));
      await tester.pump();

      final button = tester.widget<SaeqPrimaryButton>(
        find.byType(SaeqPrimaryButton),
      );
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
    });

    // 18. Error message
    testWidgets('shows an error message after a rejected sign-in', (
      tester,
    ) async {
      repository.debugSimulateNextSignInFailure(
        const AuthenticationRejectedError(),
      );
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
      );

      await tester.enterText(find.byType(TextFormField), '0501234567');
      await tester.tap(find.widgetWithText(SaeqPrimaryButton, 'Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('loginErrorMessage')), findsOneWidget);
      expect(
        find.text('Sign-in was rejected. Please try again.'),
        findsOneWidget,
      );
    });

    // 19. Logout action
    testWidgets('HomeScreen sign-out button clears the session', (
      tester,
    ) async {
      final container = ProviderContainer(overrides: overridesWith(repository));
      addTearDown(container.dispose);
      // Drive the controller into an authenticated state directly, to keep
      // this test focused on the widget interaction rather than restore
      // timing.
      container.read(authControllerProvider);
      await container
          .read(authControllerProvider.notifier)
          .signIn('0501234567');

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

      await tester.tap(find.widgetWithText(SaeqPrimaryButton, 'Sign Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repository.currentSession, isNull);
    });
  });
}
