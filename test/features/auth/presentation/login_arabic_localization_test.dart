import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/auth/presentation/screens/login_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

import '../test_doubles.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required List<Override> overrides,
  required Locale locale,
  double textScale = 1.0,
  Size surfaceSize = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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
          home: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('LoginScreen localization', () {
    late FakeSecureStorageService storage;
    late RecordingLoggerService logger;
    late AuthSessionStorage sessionStorage;
    late FakeAuthenticationRepository repository;

    setUp(() {
      storage = FakeSecureStorageService();
      logger = RecordingLoggerService();
      sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
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

    testWidgets('Arabic login shows Arabic-only application copy', (
      tester,
    ) async {
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
        locale: const Locale('ar'),
      );

      expect(find.text('تسجيل دخول السائق'), findsOneWidget);
      expect(find.textContaining('رقم جوالك'), findsOneWidget);
      expect(find.text('رقم الجوال'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Driver Sign In'), findsNothing);
      expect(find.text('Phone number'), findsNothing);
    });

    testWidgets('English login shows English-only application copy', (
      tester,
    ) async {
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
        locale: const Locale('en', 'US'),
      );

      expect(find.text('Driver Sign In'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('تسجيل الدخول'), findsNothing);
      expect(find.text('تسجيل دخول السائق'), findsNothing);
    });

    testWidgets('Arabic validation message is Arabic-only', (tester) async {
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
        locale: const Locale('ar'),
      );

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.widgetWithText(SaeqPrimaryButton, 'تسجيل الدخول'));
      await tester.pump();

      expect(find.textContaining('رقم جوال صالح'), findsOneWidget);
      expect(
        find.text('Please enter a valid phone number (05XXXXXXXX).'),
        findsNothing,
      );
    });

    testWidgets('Arabic typed failure is Arabic-only', (tester) async {
      repository.debugSimulateNextSignInFailure(
        const AuthenticationRejectedError(),
      );
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
        locale: const Locale('ar'),
      );

      await tester.enterText(find.byType(TextFormField), '0501234567');
      await tester.tap(find.widgetWithText(SaeqPrimaryButton, 'تسجيل الدخول'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('تم رفض تسجيل الدخول'), findsOneWidget);
      expect(
        find.text('Sign-in was rejected. Please try again.'),
        findsNothing,
      );
    });

    testWidgets('Arabic locale drives RTL on login', (tester) async {
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
        locale: const Locale('ar'),
      );
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality).first,
        ),
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('Arabic large text has no overflow on login', (tester) async {
      await _pump(
        tester,
        const LoginScreen(),
        overrides: overridesWith(repository),
        locale: const Locale('ar'),
        textScale: 1.6,
        surfaceSize: const Size(360, 800),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('تسجيل دخول السائق'), findsOneWidget);
    });
  });
}
