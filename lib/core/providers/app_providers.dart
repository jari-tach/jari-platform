import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../preferences/app_preferences.dart';
import '../routes/app_router.dart';

/// Built once per [ProviderScope]/`ProviderContainer`. It does not
/// `ref.watch` the auth state directly — doing so would rebuild the whole
/// `GoRouter` (losing its internal navigation stack) on every sign-in/
/// sign-out. Instead it wires `refreshListenable` (see
/// `AuthRouterRefreshNotifier`), which is GoRouter's own supported
/// mechanism for reacting to external state changes without a rebuild.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(authRouterRefreshProvider);
  return AppRouter.build(
    refreshListenable: refreshListenable,
    authStatus: () => ref.read(authControllerProvider).routingStatus,
  );
});

/// Provider-local preferences construction (not AppServiceRegistry) — keeps
/// bootstrap light; theme/locale are UI-only and do not need registry wiring.
final appPreferencesProvider = Provider<Future<AppPreferences>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AppPreferences(prefs);
});

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  AppPreferences? _preferences;

  @override
  ThemeMode build() {
    Future.microtask(_loadPersisted);
    return ThemeMode.light;
  }

  Future<void> _loadPersisted() async {
    final preferences = await ref.read(appPreferencesProvider);
    _preferences = preferences;
    final loaded = preferences.loadThemeMode();
    if (ref.mounted) state = loaded;
  }

  Future<AppPreferences> _resolvePreferences() async {
    _preferences ??= await ref.read(appPreferencesProvider);
    return _preferences!;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    final preferences = await _resolvePreferences();
    await preferences.saveThemeMode(mode);
  }
}

class AppLocaleNotifier extends Notifier<Locale> {
  AppPreferences? _preferences;

  @override
  Locale build() {
    Future.microtask(_loadPersisted);
    return const Locale('ar');
  }

  Future<void> _loadPersisted() async {
    final preferences = await ref.read(appPreferencesProvider);
    _preferences = preferences;
    final loaded = preferences.loadLocale();
    if (ref.mounted) state = loaded;
  }

  Future<AppPreferences> _resolvePreferences() async {
    _preferences ??= await ref.read(appPreferencesProvider);
    return _preferences!;
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = locale.languageCode == 'en'
        ? const Locale('en')
        : const Locale('ar');
    if (state.languageCode == normalized.languageCode) return;
    state = normalized;
    final preferences = await _resolvePreferences();
    await preferences.saveLocale(normalized);
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);
