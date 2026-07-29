import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/location/location_feature.dart';
import 'package:saeq_driver/features/location/location_screen.dart';
import 'package:saeq_driver/features/location/location_ui_helpers.dart';
import 'package:saeq_driver/features/location/map_preview_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

class _FixedLocationController extends LocationController {
  _FixedLocationController(this.initial);

  final LocationState initial;

  @override
  LocationState build() => initial;
}

Future<void> _pump(
  WidgetTester tester,
  LocationState state, {
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
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        locationControllerProvider.overrideWith(
          () => _FixedLocationController(state),
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
  testWidgets('P27 106:115 Permission Intro exact structure', (tester) async {
    await _pump(tester, const LocationState());

    expect(find.text('السماح بالوصول إلى الموقع'), findsNWidgets(2));
    expect(find.byType(P27Banner), findsOneWidget);
    expect(find.byKey(LocationScreen.permissionMapKey), findsOneWidget);
    expect(find.byKey(LocationScreen.usageFieldKey), findsOneWidget);
    expect(find.text('أثناء استخدام التطبيق فقط'), findsOneWidget);
    expect(find.byKey(LocationScreen.accuracyFieldKey), findsOneWidget);
    expect(find.text('موقع دقيق عند الحاجة'), findsOneWidget);
    expect(find.byKey(LocationScreen.allowKey), findsOneWidget);
    expect(find.byKey(LocationScreen.notNowKey), findsOneWidget);
    expect(find.text('الحالات التجريبية'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.getSize(find.byType(P27FakeMap)), const Size(358, 300));
  });

  testWidgets('P27 106:148 Permission Denied', (tester) async {
    await _pump(
      tester,
      const LocationState(status: LocationViewStatus.permissionDenied),
    );
    expect(find.text('تم رفض صلاحية الموقع'), findsNWidgets(2));
    expect(find.byType(P27Skeleton), findsOneWidget);
    expect(tester.getSize(find.byType(P27Skeleton)).height, 430);
    expect(find.byKey(LocationScreen.blockedRetryKey), findsOneWidget);
    expect(find.text('العودة للرئيسية'), findsOneWidget);
  });

  testWidgets('P27 106:161 Permanently Denied', (tester) async {
    await _pump(
      tester,
      const LocationState(
        status: LocationViewStatus.permissionPermanentlyDenied,
      ),
    );
    expect(find.text('مسار الإعدادات'), findsOneWidget);
    expect(tester.getSize(find.byType(P27Skeleton)).height, 390);
    expect(find.text('فتح إعدادات التطبيق'), findsOneWidget);
    expect(find.byKey(LocationScreen.openSettingsKey), findsOneWidget);
  });

  testWidgets('P27 106:177 GPS Disabled', (tester) async {
    await _pump(
      tester,
      const LocationState(status: LocationViewStatus.gpsDisabled),
    );
    expect(find.text('خدمات الموقع مغلقة'), findsNWidgets(2));
    expect(tester.getSize(find.byType(P27FakeMap)), const Size(358, 300));
    expect(find.text('فتح إعدادات الموقع'), findsOneWidget);
    expect(find.byKey(LocationScreen.blockedRetryKey), findsOneWidget);
  });

  testWidgets('P27 106:204 Locating exact skeleton structure', (tester) async {
    await _pump(
      tester,
      const LocationState(
        status: LocationViewStatus.locating,
        isProcessing: true,
      ),
    );
    expect(find.byKey(LocationScreen.locatingMapSkeletonKey), findsOneWidget);
    expect(
      tester.getSize(find.byKey(LocationScreen.locatingMapSkeletonKey)).height,
      300,
    );
    expect(
      find.byKey(LocationScreen.locatingDetailSkeletonKey),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(LocationScreen.locatingDetailSkeletonKey))
          .height,
      220,
    );
    final button = tester.widget<SaeqPrimaryButton>(
      find.byKey(LocationScreen.allowKey),
    );
    expect(button.onPressed, isNull);
    expect(button.isLoading, isTrue);
  });

  testWidgets('P27 106:216 Available Arabic RTL', (tester) async {
    await _pump(
      tester,
      const LocationState(
        status: LocationViewStatus.available,
        accuracy: LocationAccuracyLevel.high,
        accuracyMeters: 12,
      ),
    );
    expect(find.text('الموقع متاح'), findsNWidgets(2));
    expect(find.text('الموقع التقريبي'), findsOneWidget);
    expect(find.text('فتح في خرائط Google'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LocationScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('P27 106:246 Weak Accuracy', (tester) async {
    await _pump(
      tester,
      const LocationState(
        status: LocationViewStatus.weakAccuracy,
        accuracy: LocationAccuracyLevel.weak,
        accuracyMeters: 180,
      ),
    );
    expect(find.byType(P27Banner), findsNWidgets(2));
    expect(find.text('تحديد موقعي مجددًا'), findsOneWidget);
    expect(find.text('المتابعة دون ملاحة'), findsOneWidget);
  });

  testWidgets('P27 106:452 English LTR Available', (tester) async {
    await _pump(
      tester,
      const LocationState(status: LocationViewStatus.available),
      locale: const Locale('en', 'US'),
    );
    expect(find.text('Location available'), findsNWidgets(2));
    expect(find.text('Approximate location'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LocationScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets('P27 106:482 Arabic Dark Available and narrow 1.3 is safe', (
    tester,
  ) async {
    await _pump(
      tester,
      const LocationState(status: LocationViewStatus.available),
      themeMode: ThemeMode.dark,
      size: const Size(320, 640),
      textScale: 1.3,
    );
    expect(find.text('الموقع متاح'), findsNWidgets(2));
    expect(
      Theme.of(tester.element(find.byType(LocationScreen))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
