import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';

import 'package:saeq_driver/features/profile/vehicle/vehicle_edit_screen.dart';
import 'package:saeq_driver/features/profile/vehicle/vehicle_feature.dart';
import 'package:saeq_driver/features/profile/vehicle/vehicle_overview_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

Future<void> _pumpVehicleOverview(
  WidgetTester tester, {
  required VehicleRepository repository,
  Locale locale = const Locale('en', 'US'),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1.0,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const VehicleOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileVehicleEdit,
        builder: (context, state) => const VehicleEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileDocuments,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Documents route'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [vehicleRepositoryProvider.overrideWithValue(repository)],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
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

void main() {
  testWidgets('Vehicle overview shows seeded vehicle with masked plate', (
    tester,
  ) async {
    await _pumpVehicleOverview(tester, repository: FakeVehicleRepository());

    expect(find.textContaining('Toyota Camry'), findsOneWidget);
    expect(find.text('•••••21'), findsOneWidget);
    expect(find.text('ABC 4821'), findsNothing);
    expect(find.text('Approved'), findsOneWidget);
  });

  testWidgets('Vehicle overview empty state offers add action', (tester) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(mode: FakeVehicleMode.empty),
    );

    expect(find.text('No vehicle on file'), findsOneWidget);
    expect(find.text('Add vehicle'), findsOneWidget);
  });

  testWidgets('Vehicle overview loading state', (tester) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(
        latency: const Duration(milliseconds: 800),
      ),
    );
    expect(find.text('Loading vehicle'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('Vehicle overview error state retries', (tester) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(mode: FakeVehicleMode.error),
    );
    expect(find.text('Could not load vehicle'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Vehicle overview offline state', (tester) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(mode: FakeVehicleMode.offline),
    );
    expect(find.text('Vehicle unavailable offline'), findsOneWidget);
  });

  testWidgets('Vehicle documents secondary action opens documents route', (
    tester,
  ) async {
    await _pumpVehicleOverview(tester, repository: FakeVehicleRepository());

    await tester.tap(find.byKey(VehicleOverviewScreen.documentsKey));
    await tester.pumpAndSettle();
    expect(find.text('Documents route'), findsOneWidget);
  });

  testWidgets('Vehicle English light shows edit and documents actions', (
    tester,
  ) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(),
      locale: const Locale('en', 'US'),
      themeMode: ThemeMode.light,
    );
    expect(find.text('Edit vehicle'), findsOneWidget);
    expect(find.text('View vehicle documents'), findsOneWidget);
  });

  testWidgets('Vehicle edit validation and save success', (tester) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(mode: FakeVehicleMode.empty),
    );
    await tester.tap(find.text('Add vehicle'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(VehicleEditScreen.saveKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('vehicleValidationError')), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Honda');
    await tester.enterText(find.byType(TextField).at(1), 'Accord');
    await tester.enterText(find.byType(TextField).at(2), '2023');
    await tester.enterText(find.byType(TextField).at(3), 'Black');
    await tester.enterText(find.byType(TextField).at(4), 'XYZ 9901');
    await tester.enterText(find.byType(TextField).at(5), 'Sedan');

    await tester.tap(find.byKey(VehicleEditScreen.saveKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Vehicle saved.'), findsWidgets);
  });

  testWidgets('Vehicle save processing disables duplicate taps', (
    tester,
  ) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(
        latency: const Duration(milliseconds: 800),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.byKey(VehicleOverviewScreen.editKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(VehicleEditScreen.saveKey));
    await tester.pump();

    final button = tester.widget<SaeqPrimaryButton>(
      find.byKey(VehicleEditScreen.saveKey),
    );
    expect(button.onPressed, isNull);
    expect(button.isLoading, isTrue);

    await tester.tap(find.byKey(VehicleEditScreen.saveKey));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('Vehicle saved.'), findsWidgets);
  });

  testWidgets('Vehicle save failure shows error message', (tester) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(failSave: true),
    );
    await tester.tap(find.byKey(VehicleOverviewScreen.editKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(VehicleEditScreen.saveKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text('Could not save vehicle. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('Vehicle Arabic dark theme smoke', (tester) async {
    await _pumpVehicleOverview(
      tester,
      repository: FakeVehicleRepository(),
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      textScale: 1.3,
    );
    expect(find.text('المركبة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
