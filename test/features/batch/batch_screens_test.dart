import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/batch/batch_feature.dart';
import 'package:saeq_driver/features/batch/batch_offer_screen.dart';
import 'package:saeq_driver/features/batch/batch_ui_helpers.dart';
import 'package:saeq_driver/features/batch/batch_view_data.dart';
import 'package:saeq_driver/features/batch/widgets/batch_offer_entry_card.dart';
import 'package:saeq_driver/features/location/location_ui_helpers.dart';

class _FixedBatchController extends BatchController {
  _FixedBatchController(this.initial);

  final BatchState initial;

  @override
  BatchState build() => initial;

  @override
  Future<void> loadOffer({
    FakeBatchScenario scenario = FakeBatchScenario.fourOrders,
  }) async {}
}

class _FastBatchService extends FakeBatchService {
  _FastBatchService() : super(latency: Duration.zero);
}

Future<void> _pumpBatchOffer(
  WidgetTester tester,
  BatchState state, {
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const batchId = FakeBatchService.defaultBatchId;
  final router = GoRouter(
    initialLocation: AppRoutes.batchOfferPath(batchId),
    routes: [
      GoRoute(
        path: AppRoutes.batchOfferPath(':batchId'),
        builder: (_, state) =>
            BatchOfferScreen(batchId: state.pathParameters['batchId']!),
      ),
      GoRoute(
        path: AppRoutes.batchPickupPath(':batchId'),
        builder: (_, state) => const Scaffold(body: Text('pickup')),
      ),
      GoRoute(
        path: AppRoutes.deliveryOffer,
        builder: (_, _) => const Scaffold(body: Text('offers')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        batchServiceProvider.overrideWithValue(_FastBatchService()),
        batchControllerProvider.overrideWith(
          () => _FixedBatchController(state),
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

BatchState _fourOrderState() {
  return BatchState(
    offerStatus: BatchOfferViewStatus.fourOrders,
    batch: FakeBatchService.batchFixture(orderCount: 4),
  );
}

void main() {
  testWidgets('P27 115:412 four-order offer structure', (tester) async {
    await _pumpBatchOffer(tester, _fourOrderState());
    expect(find.byKey(BatchOfferScreen.pageKey), findsOneWidget);
    expect(find.byKey(BatchMultiStopMap.mapKey), findsOneWidget);
    expect(find.byType(BatchMetricChip), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.byKey(const ValueKey('batchOrderRow_B-2031')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(BatchOfferScreen.acceptKey),
      120,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(BatchOfferScreen.acceptKey), findsOneWidget);
    expect(find.byKey(BatchOfferScreen.rejectKey), findsOneWidget);
    expect(find.text('قبول الدفعة كاملة'), findsOneWidget);
  });

  testWidgets('P27 115:461 three-order offer', (tester) async {
    await _pumpBatchOffer(
      tester,
      BatchState(
        offerStatus: BatchOfferViewStatus.threeOrders,
        batch: FakeBatchService.batchFixture(orderCount: 3),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.byKey(const ValueKey('batchOrderRow_B-2031')), findsOneWidget);
    expect(find.byKey(const ValueKey('batchOrderRow_B-2033')), findsOneWidget);
    expect(find.byKey(const ValueKey('batchOrderRow_B-2034')), findsNothing);
  });

  testWidgets('P27 115:518 offer loading skeleton', (tester) async {
    await _pumpBatchOffer(
      tester,
      const BatchState(offerStatus: BatchOfferViewStatus.loading),
    );
    expect(find.byType(P27Skeleton), findsWidgets);
    expect(find.byKey(BatchOfferScreen.acceptKey), findsNothing);
  });

  testWidgets('P27 115:534 expired offer', (tester) async {
    await _pumpBatchOffer(
      tester,
      BatchState(
        offerStatus: BatchOfferViewStatus.expired,
        batch: FakeBatchService.batchFixture(
          orderCount: 4,
          remainingSeconds: 0,
        ),
      ),
    );
    expect(find.text('انتهت صلاحية العرض المجمّع'), findsOneWidget);
    expect(find.byKey(BatchOfferScreen.backKey), findsOneWidget);
  });

  testWidgets('offer error and offline states', (tester) async {
    await _pumpBatchOffer(
      tester,
      const BatchState(offerStatus: BatchOfferViewStatus.error),
    );
    expect(find.byKey(BatchOfferScreen.retryKey), findsOneWidget);
    await _pumpBatchOffer(
      tester,
      const BatchState(offerStatus: BatchOfferViewStatus.offline),
    );
    expect(find.byType(P27Banner), findsOneWidget);
    expect(find.byKey(BatchOfferScreen.retryKey), findsOneWidget);
  });

  testWidgets('masked order id never shows full id', (tester) async {
    await _pumpBatchOffer(tester, _fourOrderState());
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expect(find.textContaining('B-2031'), findsNothing);
    expect(find.textContaining('B-••31'), findsWidgets);
  });

  testWidgets('Arabic RTL and English LTR', (tester) async {
    await _pumpBatchOffer(tester, _fourOrderState());
    expect(find.text('عرض توصيل مجمّع'), findsOneWidget);
    await _pumpBatchOffer(
      tester,
      _fourOrderState(),
      locale: const Locale('en'),
    );
    expect(find.text('Batch delivery offer'), findsOneWidget);
  });

  testWidgets('dark theme and narrow 320px without overflow', (tester) async {
    await _pumpBatchOffer(
      tester,
      _fourOrderState(),
      themeMode: ThemeMode.dark,
      size: const Size(320, 800),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('accept processing shows loading on primary button', (
    tester,
  ) async {
    await _pumpBatchOffer(
      tester,
      _fourOrderState().copyWith(
        offerStatus: BatchOfferViewStatus.acceptProcessing,
        isProcessing: true,
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.byKey(BatchOfferScreen.acceptKey), findsOneWidget);
  });

  testWidgets('batch entry card on offers empty state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ar'),
          home: Scaffold(
            body: SingleChildScrollView(child: BatchOfferEntryCard()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(BatchOfferEntryCard.cardKey), findsOneWidget);
    expect(find.byKey(BatchOfferEntryCard.openKey), findsOneWidget);
    expect(find.text('يتوفر عرض توصيل مجمّع'), findsOneWidget);
  });

  test('BatchOfferViewData progress fraction', () {
    final batch = FakeBatchService.batchFixture(orderCount: 4);
    expect(batch.progressFraction, 0);
    final delivered = batch.withOrder(
      batch.orders.first.copyWith(state: BatchOrderState.delivered),
    );
    expect(delivered.progressFraction, 0.25);
  });
}
