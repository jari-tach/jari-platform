import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saeq_driver/core/preferences/app_preferences.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppPreferences', () {
    test('defaults to light theme and Arabic locale', () async {
      final prefs = await SharedPreferences.getInstance();
      final appPreferences = AppPreferences(prefs);

      expect(appPreferences.loadThemeMode(), ThemeMode.light);
      expect(appPreferences.loadLocale(), const Locale('ar'));
    });

    test('persists theme mode', () async {
      final prefs = await SharedPreferences.getInstance();
      final appPreferences = AppPreferences(prefs);

      await appPreferences.saveThemeMode(ThemeMode.dark);
      expect(appPreferences.loadThemeMode(), ThemeMode.dark);

      await appPreferences.saveThemeMode(ThemeMode.system);
      expect(appPreferences.loadThemeMode(), ThemeMode.system);
    });

    test('persists locale language code', () async {
      final prefs = await SharedPreferences.getInstance();
      final appPreferences = AppPreferences(prefs);

      await appPreferences.saveLocale(const Locale('en'));
      expect(appPreferences.loadLocale(), const Locale('en'));

      await appPreferences.saveLocale(const Locale('ar', 'SA'));
      expect(appPreferences.loadLocale(), const Locale('ar'));
    });

    test('ignores invalid stored values', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.themeModeKey: 'invalid',
        AppPreferences.localeLanguageCodeKey: 'fr',
      });
      final prefs = await SharedPreferences.getInstance();
      final appPreferences = AppPreferences(prefs);

      expect(appPreferences.loadThemeMode(), ThemeMode.light);
      expect(appPreferences.loadLocale(), const Locale('ar'));
    });
  });

  group('App preference notifiers', () {
    test('AppThemeModeNotifier loads and saves theme mode', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.themeModeKey: 'dark',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appThemeModeProvider), ThemeMode.light);
      await container.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(appThemeModeProvider), ThemeMode.dark);

      await container
          .read(appThemeModeProvider.notifier)
          .setThemeMode(ThemeMode.system);
      expect(container.read(appThemeModeProvider), ThemeMode.system);
    });

    test('AppLocaleNotifier loads and saves locale', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.localeLanguageCodeKey: 'en',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appLocaleProvider).languageCode, 'ar');
      await container.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(appLocaleProvider).languageCode, 'en');

      await container
          .read(appLocaleProvider.notifier)
          .setLocale(const Locale('ar'));
      expect(container.read(appLocaleProvider).languageCode, 'ar');
    });
  });
}
