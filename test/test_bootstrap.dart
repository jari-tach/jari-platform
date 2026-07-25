import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// `Override` is not re-exported by flutter_riverpod.dart's public barrel;
// riverpod (a transitive dependency here) exposes it via misc.dart. Test-only
// usage, needed only to type the `overrides` parameter below.
import 'package:riverpod/misc.dart' show Override;

import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';

/// Test bootstrap that creates a minimal app without service registry dependencies
class TestApp extends ConsumerWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'SAEQ Driver',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Pumps the test app with ProviderScope.
///
/// [overrides] defaults to none, preserving existing call sites. PHASE 2.2
/// navigation tests pass an `authControllerProvider` override so they can
/// drive the guard logic without a real `AppServiceRegistry`.
Future<void> pumpTestApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(overrides: overrides, child: const TestApp()),
  );
  // Bounded pump: AuthController.restoreSession is a single microtask +
  // await, and GoogleFonts/theme must not keep pumpAndSettle spinning.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}
