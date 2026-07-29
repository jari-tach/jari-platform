import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/location/fake_map_placeholder.dart';
import 'package:saeq_driver/features/location/location_feature.dart';
import 'package:saeq_driver/features/location/location_screen.dart';
import 'package:saeq_driver/features/location/map_preview_feature.dart';
import 'package:saeq_driver/features/location/map_preview_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_error_state.dart';
import 'package:saeq_driver/shared/widgets/saeq_loading_skeleton.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

Future<void> _pumpLocationScreen(
  WidgetTester tester, {
  LocationService? locationService,
  MapPreviewService? mapPreviewService,
  bool overrideLocationServiceWithNull = false,
  Locale locale = const Locale('en', 'US'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1.0,
  Size surface = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: AppRoutes.location,
    routes: [
      GoRoute(
        path: AppRoutes.location,
        builder: (context, state) => const LocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.mapPreview,
        builder: (context, state) => const MapPreviewScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (overrideLocationServiceWithNull)
          locationServiceProvider.overrideWithValue(null)
        else
          locationServiceProvider.overrideWithValue(
            locationService ?? FakeLocationService(),
          ),
        mapPreviewServiceProvider.overrideWithValue(
          mapPreviewService ?? FakeMapPreviewService(),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: surface,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(
          locale: locale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _tapTrialOption(
  WidgetTester tester,
  FakeLocationScenario scenario,
) async {
  final finder = find.byKey(LocationScreen.trialOptionKey(scenario));
  await tester.scrollUntilVisible(finder, 120);
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('Location permission intro is the entry state', (tester) async {
    await _pumpLocationScreen(tester);

    expect(find.text('Share your location'), findsOneWidget);
    expect(find.byKey(LocationScreen.allowKey), findsOneWidget);
    expect(find.byKey(LocationScreen.trialSelectorKey), findsOneWidget);
    expect(
      find.textContaining('no real GPS and no system permission'),
      findsOneWidget,
    );
  });

  testWidgets('Location primary flow reaches available then map preview', (
    tester,
  ) async {
    await _pumpLocationScreen(
      tester,
      locationService: FakeLocationService(
        latency: const Duration(milliseconds: 300),
      ),
    );

    await tester.tap(find.byKey(LocationScreen.allowKey));
    await tester.pump();
    expect(find.text('Locating you'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Location available'), findsOneWidget);
    expect(find.text('Strong GPS accuracy · ±12 m'), findsOneWidget);
    expect(find.byKey(LocationScreen.accuracyChipKey), findsOneWidget);

    await tester.tap(find.byKey(LocationScreen.mapPreviewKey));
    await tester.pumpAndSettle();

    expect(find.byType(MapPreviewScreen), findsOneWidget);
    expect(find.byKey(FakeMapPlaceholder.mapKey), findsOneWidget);
  });

  testWidgets('Location back navigation returns from map preview', (
    tester,
  ) async {
    await _pumpLocationScreen(tester);

    await tester.tap(find.byKey(LocationScreen.allowKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LocationScreen.mapPreviewKey));
    await tester.pumpAndSettle();
    expect(find.byType(MapPreviewScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LocationScreen), findsOneWidget);
    expect(find.text('Location available'), findsOneWidget);
  });

  testWidgets('Location denied state retries and recovers when granted', (
    tester,
  ) async {
    await _pumpLocationScreen(tester);

    await _tapTrialOption(tester, FakeLocationScenario.permissionDenied);
    expect(find.text('Location permission denied'), findsOneWidget);

    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Location permission denied'), findsOneWidget);

    await _tapTrialOption(tester, FakeLocationScenario.permissionGranted);
    expect(find.text('Location available'), findsOneWidget);
  });

  testWidgets('Location permanently denied only shows settings guidance', (
    tester,
  ) async {
    await _pumpLocationScreen(tester);

    await _tapTrialOption(
      tester,
      FakeLocationScenario.permissionPermanentlyDenied,
    );
    expect(find.text('Location permission blocked'), findsWidgets);
    expect(find.byKey(LocationScreen.settingsGuidanceKey), findsNothing);

    await tester.tap(find.byKey(LocationScreen.openSettingsKey));
    await tester.pump();

    expect(find.byKey(LocationScreen.settingsGuidanceKey), findsOneWidget);
    expect(find.textContaining('cannot open settings for you'), findsOneWidget);
    expect(find.byType(LocationScreen), findsOneWidget);
    expect(find.byKey(LocationScreen.blockedRetryKey), findsOneWidget);
  });

  testWidgets('Location GPS disabled state offers retry', (tester) async {
    await _pumpLocationScreen(tester);

    await _tapTrialOption(tester, FakeLocationScenario.gpsDisabled);

    expect(find.text('Location services are off'), findsOneWidget);
    expect(find.byKey(SaeqErrorState.retryKey), findsOneWidget);

    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Location services are off'), findsOneWidget);
  });

  testWidgets('Location weak accuracy warns but still allows map preview', (
    tester,
  ) async {
    await _pumpLocationScreen(tester);

    await _tapTrialOption(tester, FakeLocationScenario.weakAccuracy);

    expect(find.text('Weak location accuracy'), findsOneWidget);
    expect(find.text('Weak GPS accuracy · ±180 m'), findsOneWidget);
    expect(find.byKey(LocationScreen.mapPreviewKey), findsOneWidget);
  });

  testWidgets('Location offline state recovers after retry', (tester) async {
    await _pumpLocationScreen(tester);

    await _tapTrialOption(tester, FakeLocationScenario.offline);
    expect(find.text('Location unavailable offline'), findsOneWidget);

    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Location available'), findsOneWidget);
    expect(find.text('Strong GPS accuracy · ±18 m'), findsOneWidget);
  });

  testWidgets('Location offline state persists while still offline', (
    tester,
  ) async {
    await _pumpLocationScreen(
      tester,
      locationService: FakeLocationService(recoverAfterFailures: 0),
    );

    await _tapTrialOption(tester, FakeLocationScenario.offline);
    expect(find.text('Location unavailable offline'), findsOneWidget);

    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Location unavailable offline'), findsOneWidget);
  });

  testWidgets('Location processing guard blocks duplicate taps', (
    tester,
  ) async {
    await _pumpLocationScreen(
      tester,
      locationService: FakeLocationService(
        latency: const Duration(milliseconds: 800),
      ),
    );

    await tester.tap(find.byKey(LocationScreen.allowKey));
    await tester.pump();

    final button = tester.widget<SaeqPrimaryButton>(
      find.byKey(LocationScreen.allowKey),
    );
    expect(button.onPressed, isNull);
    expect(button.isLoading, isTrue);
    expect(find.text('Locating you'), findsOneWidget);

    await tester.tap(find.byKey(LocationScreen.allowKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Location available'), findsOneWidget);
    expect(find.text('Locating you'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Location trial options are disabled while locating', (
    tester,
  ) async {
    await _pumpLocationScreen(
      tester,
      locationService: FakeLocationService(
        latency: const Duration(milliseconds: 800),
      ),
    );

    await tester.tap(find.byKey(LocationScreen.allowKey));
    await tester.pump();
    expect(find.byKey(SaeqLoadingSkeleton.progressKey), findsOneWidget);

    final chipFinder = find.byKey(
      LocationScreen.trialOptionKey(FakeLocationScenario.gpsDisabled),
    );
    await tester.scrollUntilVisible(chipFinder, 120);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(chipFinder).onSelected, isNull);

    // A tap on the disabled option must not re-trigger a transition.
    await tester.tap(chipFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Location available'), findsOneWidget);
    expect(find.text('Location services are off'), findsNothing);
  });

  testWidgets('Location unavailable when no fake service is wired', (
    tester,
  ) async {
    await _pumpLocationScreen(tester, overrideLocationServiceWithNull: true);

    await tester.tap(find.byKey(LocationScreen.allowKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Location unavailable'), findsOneWidget);
    expect(find.byKey(SaeqErrorState.retryKey), findsOneWidget);
  });

  testWidgets('Location English LTR renders left to right', (tester) async {
    await _pumpLocationScreen(tester);

    expect(find.text('Location and GPS'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LocationScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets('Location Arabic RTL renders right to left', (tester) async {
    await _pumpLocationScreen(tester, locale: const Locale('ar'));

    expect(find.text('الموقع وتحديد المواقع'), findsOneWidget);
    expect(find.text('شارك موقعك'), findsOneWidget);
    expect(find.text('Share your location'), findsNothing);
    expect(
      Directionality.of(tester.element(find.byType(LocationScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('Location dark theme renders without exception', (tester) async {
    await _pumpLocationScreen(tester, themeMode: ThemeMode.dark);

    await tester.tap(find.byKey(LocationScreen.allowKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Location available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Location Arabic narrow screen at text scale 1.3 has no '
      'overflow', (tester) async {
    await _pumpLocationScreen(
      tester,
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      textScale: 1.3,
      surface: const Size(320, 640),
    );

    expect(find.text('شارك موقعك'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapTrialOption(tester, FakeLocationScenario.weakAccuracy);
    expect(find.text('دقة الموقع ضعيفة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
