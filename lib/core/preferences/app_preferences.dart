import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing app preferences (theme + locale only).
///
/// Never store auth tokens, sessions, or secrets here — those belong in
/// secure storage via [AuthenticationRepository].
class AppPreferences {
  AppPreferences(this._prefs);

  static const themeModeKey = 'app_theme_mode_v1';
  static const localeLanguageCodeKey = 'app_locale_language_code_v1';

  final SharedPreferences _prefs;

  /// Loads persisted [ThemeMode], defaulting to light when unset/invalid.
  ThemeMode loadThemeMode() {
    final raw = _prefs.getString(themeModeKey);
    return switch (raw) {
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.light,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
    };
    await _prefs.setString(themeModeKey, value);
  }

  /// Loads persisted locale language code (`ar` or `en`), defaulting to Arabic.
  Locale loadLocale() {
    final code = _prefs.getString(localeLanguageCodeKey);
    return switch (code) {
      'en' => const Locale('en'),
      'ar' => const Locale('ar'),
      _ => const Locale('ar'),
    };
  }

  Future<void> saveLocale(Locale locale) async {
    final code = locale.languageCode == 'en' ? 'en' : 'ar';
    await _prefs.setString(localeLanguageCodeKey, code);
  }
}
