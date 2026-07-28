import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';
import 'package:saeq_driver/core/routes/app_router.dart';

import 'fake_e2e_harness.dart';

/// PHASE 2.6 Increment 5 — E2E Fake matrix flow H:
/// Profile → Settings → theme + locale changes.
void main() {
  testWidgets('flow H: profile to settings switches dark theme and English', (
    tester,
  ) async {
    final harness = await createFakeE2eContainer();
    addTearDown(() {
      harness.container.dispose();
      harness.authRepository.dispose();
      harness.availabilityRepository.dispose();
      tester.binding.setSurfaceSize(null);
    });

    final router = await pumpFakeE2eApp(tester, harness.container);

    router.go(AppRoutes.profile);
    await pumpFakeE2eBounded(tester);

    expect(router.state.uri.path, AppRoutes.profile);
    expect(find.text('E2E Driver'), findsOneWidget);

    await tester.tap(find.text('الإعدادات'));
    await pumpFakeE2eBounded(tester);

    expect(router.state.uri.path, AppRoutes.settings);
    expect(find.text('المظهر'), findsOneWidget);

    await tester.tap(find.text('داكن'));
    await pumpFakeE2eBounded(tester);

    expect(harness.container.read(appThemeModeProvider), ThemeMode.dark);
    expect(find.byKey(const Key('settingsThemeValue')), findsOneWidget);

    await tester.tap(find.text('English'));
    await pumpFakeE2eBounded(tester);

    expect(harness.container.read(appLocaleProvider).languageCode, 'en');
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byKey(const Key('settingsLanguageValue')), findsOneWidget);
  });
}
