import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/preferences/app_preferences.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/settings/presentation/screens/settings_screen.dart';

import '../auth/test_doubles.dart';

class _ThrowingAppPreferences extends AppPreferences {
  _ThrowingAppPreferences(super.prefs);

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    throw Exception('persist failed');
  }
}

void main() {
  testWidgets('SettingsScreen smoke — theme and language controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en', 'US'),
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

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.byKey(const Key('settingsThemeValue')), findsOneWidget);
    expect(find.byKey(const Key('settingsLanguageValue')), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('Settings logout cancel keeps session', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => AuthController(repositoryReader: (_) => repository),
        ),
      ],
    );
    addTearDown(container.dispose);

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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.ensureVisible(find.byKey(SettingsScreen.signOutKey));
    await tester.tap(find.byKey(SettingsScreen.signOutKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saeqDestructiveDialogCancel')));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider).session, isNotNull);
  });

  testWidgets('Settings language switch updates locale provider', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: container.read(appLocaleProvider),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(container.read(appLocaleProvider).languageCode, 'ar');

    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(container.read(appLocaleProvider).languageCode, 'en');
  });

  group('Settings persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('theme choice survives provider restart simulation', () async {
      SharedPreferences.setMockInitialValues({});

      final container1 = ProviderContainer();
      addTearDown(container1.dispose);
      container1.read(appThemeModeProvider);
      await container1.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container1
          .read(appThemeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      expect(container1.read(appThemeModeProvider), ThemeMode.dark);

      container1.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(appThemeModeProvider);
      await container2.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container2.read(appThemeModeProvider), ThemeMode.dark);
    });

    test('language choice survives provider restart simulation', () async {
      SharedPreferences.setMockInitialValues({});

      final container1 = ProviderContainer();
      addTearDown(container1.dispose);
      container1.read(appLocaleProvider);
      await container1.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container1
          .read(appLocaleProvider.notifier)
          .setLocale(const Locale('en'));
      expect(container1.read(appLocaleProvider).languageCode, 'en');

      container1.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      container2.read(appLocaleProvider);
      await container2.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container2.read(appLocaleProvider).languageCode, 'en');
    });

    test(
      'setThemeMode keeps in-memory state when persistence throws',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWith(
              (ref) async => _ThrowingAppPreferences(prefs),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(appThemeModeProvider);
        await container.read(appPreferencesProvider);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await expectLater(
          container
              .read(appThemeModeProvider.notifier)
              .setThemeMode(ThemeMode.dark),
          throwsA(isA<Exception>()),
        );
        expect(container.read(appThemeModeProvider), ThemeMode.dark);
      },
    );
  });
}
