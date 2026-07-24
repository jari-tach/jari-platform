import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Pumps the test app with ProviderScope
Future<void> pumpTestApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: TestApp(),
    ),
  );
  await tester.pumpAndSettle();
}