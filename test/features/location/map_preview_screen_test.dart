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
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

Future<void> _pumpMapPreview(
  WidgetTester tester, {
  MapPreviewService? mapPreviewService,
  Locale locale = const Locale('en', 'US'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1.0,
  Size surface = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: AppRoutes.mapPreview,
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
        locationServiceProvider.overrideWithValue(FakeLocationService()),
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
  FakeMapScenario scenario,
) async {
  final finder = find.byKey(MapPreviewScreen.trialOptionKey(scenario));
  await tester.scrollUntilVisible(finder, 120);
  await tester.pump();
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('Map preview loading state', (tester) async {
    await _pumpMapPreview(
      tester,
      mapPreviewService: FakeMapPreviewService(
        latency: const Duration(milliseconds: 800),
      ),
    );

    expect(find.text('Loading map preview'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(FakeMapPlaceholder.mapKey), findsOneWidget);
  });

  testWidgets('Map preview placeholder renders markers route and accuracy', (
    tester,
  ) async {
    await _pumpMapPreview(tester);

    expect(find.byKey(FakeMapPlaceholder.mapKey), findsOneWidget);
    expect(find.byKey(FakeMapPlaceholder.driverMarkerKey), findsOneWidget);
    expect(find.byKey(FakeMapPlaceholder.pickupMarkerKey), findsOneWidget);
    expect(find.byKey(FakeMapPlaceholder.dropoffMarkerKey), findsOneWidget);
    expect(find.byKey(FakeMapPlaceholder.routeKey), findsOneWidget);
    expect(find.byKey(FakeMapPlaceholder.accuracyKey), findsOneWidget);
    expect(find.text('Strong GPS accuracy · ±14 m'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Pickup'), findsOneWidget);
    expect(find.text('Dropoff'), findsOneWidget);
    expect(find.byKey(FakeMapPlaceholder.retryKey), findsOneWidget);
    expect(
      find.byKey(FakeMapPlaceholder.externalNavigationKey),
      findsOneWidget,
    );
    expect(
      find.textContaining('no map provider and no live tracking'),
      findsOneWidget,
    );
  });

  testWidgets('Map preview error state retries into the placeholder', (
    tester,
  ) async {
    await _pumpMapPreview(tester);

    await _tapTrialOption(tester, FakeMapScenario.error);
    expect(find.text('Could not load map preview'), findsOneWidget);
    expect(find.byKey(SaeqErrorState.retryKey), findsOneWidget);

    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byKey(FakeMapPlaceholder.mapKey), findsOneWidget);
  });

  testWidgets('Map preview offline state retries into the placeholder', (
    tester,
  ) async {
    await _pumpMapPreview(tester);

    await _tapTrialOption(tester, FakeMapScenario.offline);
    expect(find.text('Map preview unavailable offline'), findsOneWidget);

    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byKey(FakeMapPlaceholder.mapKey), findsOneWidget);
  });

  testWidgets('Map preview error state persists while still failing', (
    tester,
  ) async {
    await _pumpMapPreview(
      tester,
      mapPreviewService: FakeMapPreviewService(recoverAfterFailures: 0),
    );

    await _tapTrialOption(tester, FakeMapScenario.error);
    expect(find.text('Could not load map preview'), findsOneWidget);

    await tester.tap(find.byKey(SaeqErrorState.retryKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Could not load map preview'), findsOneWidget);
  });

  testWidgets('Map preview external navigation reports unavailable and backs '
      'out safely', (tester) async {
    await _pumpMapPreview(tester);

    await tester.tap(find.byKey(FakeMapPlaceholder.externalNavigationKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('External navigation unavailable'), findsOneWidget);
    expect(
      find.byKey(FakeMapPlaceholder.externalNavigationNoticeKey),
      findsOneWidget,
    );
    expect(find.byKey(FakeMapPlaceholder.mapKey), findsOneWidget);

    final backFinder = find.byKey(FakeMapPlaceholder.backKey);
    await tester.ensureVisible(backFinder);
    await tester.pump();
    await tester.tap(backFinder);
    await tester.pumpAndSettle();

    expect(find.byType(LocationScreen), findsOneWidget);
  });

  testWidgets('Map preview external navigation guards duplicate taps', (
    tester,
  ) async {
    await _pumpMapPreview(
      tester,
      mapPreviewService: FakeMapPreviewService(
        latency: const Duration(milliseconds: 800),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.byKey(FakeMapPlaceholder.externalNavigationKey));
    await tester.pump();

    final button = tester.widget<SaeqPrimaryButton>(
      find.byKey(FakeMapPlaceholder.externalNavigationKey),
    );
    expect(button.onPressed, isNull);
    expect(button.isLoading, isTrue);

    await tester.tap(find.byKey(FakeMapPlaceholder.externalNavigationKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('External navigation unavailable'), findsOneWidget);
  });

  testWidgets('Map preview English LTR renders left to right', (tester) async {
    await _pumpMapPreview(tester);

    expect(find.text('Map preview'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(MapPreviewScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets('Map preview Arabic RTL renders right to left', (tester) async {
    await _pumpMapPreview(tester, locale: const Locale('ar'));

    expect(find.text('معاينة الخريطة'), findsOneWidget);
    expect(find.text('أنت'), findsOneWidget);
    expect(find.text('الاستلام'), findsOneWidget);
    expect(find.text('التسليم'), findsOneWidget);
    expect(find.text('Pickup'), findsNothing);
    expect(
      Directionality.of(tester.element(find.byType(MapPreviewScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('Map preview Arabic dark narrow screen at text scale 1.3 has '
      'no overflow', (tester) async {
    await _pumpMapPreview(
      tester,
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      textScale: 1.3,
      surface: const Size(320, 640),
    );

    expect(find.byKey(FakeMapPlaceholder.mapKey), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapTrialOption(tester, FakeMapScenario.offline);
    expect(find.text('معاينة الخريطة غير متاحة دون اتصال'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
