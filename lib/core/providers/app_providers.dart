import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
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

final appThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

final appLocaleProvider = Provider<Locale>((ref) => const Locale('ar'));
