import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/location/location_screen.dart';
import 'package:saeq_driver/features/location/location_ui_helpers.dart';
import 'package:saeq_driver/features/location/map_preview_feature.dart';
import 'package:saeq_driver/features/location/map_preview_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

class _FixedMapController extends MapPreviewController {
  _FixedMapController(this.initial);

  final MapPreviewState initial;

  @override
  MapPreviewState build() => initial;
}

Future<void> _pump(
  WidgetTester tester,
  MapPreviewState state, {
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: AppRoutes.location,
    routes: [
      GoRoute(
        path: AppRoutes.location,
        builder: (_, _) => const LocationScreen(),
      ),
      GoRoute(
        path: AppRoutes.mapPreview,
        builder: (_, _) => const MapPreviewScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  router.push(AppRoutes.mapPreview);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mapPreviewControllerProvider.overrideWith(
          () => _FixedMapController(state),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
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
}

void main() {
  testWidgets('P27 106:276 Map Loading exact structure', (tester) async {
    await _pump(
      tester,
      const MapPreviewState(
        status: MapPreviewStatus.loading,
        isProcessing: true,
      ),
    );
    expect(find.text('الخريطة'), findsOneWidget);
    expect(find.byKey(MapPreviewScreen.loadingStatusKey), findsOneWidget);
    expect(find.byKey(MapPreviewScreen.mapSkeletonKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(MapPreviewScreen.mapSkeletonKey)).height,
      300,
    );
    expect(find.byKey(MapPreviewScreen.detailSkeletonKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(MapPreviewScreen.detailSkeletonKey)).height,
      220,
    );
    final button = tester.widget<SaeqPrimaryButton>(
      find.byKey(MapPreviewScreen.loadingActionKey),
    );
    expect(button.onPressed, isNull);
    expect(button.isLoading, isTrue);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('P27 106:288 Map Error Retry', (tester) async {
    await _pump(tester, const MapPreviewState(status: MapPreviewStatus.error));
    expect(find.text('تعذر تحميل معاينة الخريطة'), findsOneWidget);
    expect(tester.getSize(find.byType(P27Skeleton)).height, 300);
    expect(find.text('العنوان'), findsOneWidget);
    expect(find.byKey(MapPreviewScreen.retryKey), findsOneWidget);
    expect(find.text('فتح العنوان في المتصفح'), findsOneWidget);
  });

  testWidgets('P27 106:304 Map Offline', (tester) async {
    await _pump(
      tester,
      const MapPreviewState(status: MapPreviewStatus.offline),
    );
    expect(find.text('معاينة الخريطة غير متاحة دون اتصال'), findsOneWidget);
    expect(tester.getSize(find.byType(P27FakeMap)), const Size(358, 300));
    expect(find.text('آخر موقع معروف'), findsOneWidget);
    expect(find.text('فتح في خرائط Google'), findsOneWidget);
    expect(find.text('إعادة المحاولة عند الاتصال'), findsOneWidget);
  });

  testWidgets('P27 106:433 External App Unavailable and safe back', (
    tester,
  ) async {
    await _pump(
      tester,
      const MapPreviewState(
        status: MapPreviewStatus.externalNavigationUnavailable,
        snapshot: FakeMapPreviewService.defaultSnapshot,
      ),
      size: const Size(320, 640),
      textScale: 1.3,
    );
    expect(find.text('الملاحة الخارجية غير متاحة'), findsNWidgets(2));
    expect(find.text('العنوان'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(MapPreviewScreen.secondaryActionKey),
      180,
    );
    await tester.pump();
    expect(find.text('الإحداثيات'), findsOneWidget);
    expect(tester.getSize(find.byType(P27Skeleton)).height, 300);
    expect(find.text('فتح المسار في المتصفح'), findsOneWidget);
    expect(find.text('نسخ العنوان'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(find.byType(BackButton), -180);
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(LocationScreen), findsOneWidget);
  });
}
