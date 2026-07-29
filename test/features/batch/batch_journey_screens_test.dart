import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/core/theme/app_theme.dart';
import 'package:saeq_driver/features/batch/batch_feature.dart';
import 'package:saeq_driver/features/batch/batch_issue_screen.dart';
import 'package:saeq_driver/features/batch/batch_manual_pickup_screen.dart';
import 'package:saeq_driver/features/batch/batch_stop_screen.dart';
import 'package:saeq_driver/features/batch/batch_ui_helpers.dart';
import 'package:saeq_driver/features/batch/batch_view_data.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

class _FixedBatchController extends BatchController {
  _FixedBatchController(this.initial);

  final BatchState initial;

  @override
  BatchState build() => initial;
}

BatchOfferViewData _verifiedBatch() {
  final batch = FakeBatchService.batchFixture(orderCount: 4);
  return batch.copyWith(
    orders: [
      for (final order in batch.orders)
        order.copyWith(state: BatchOrderState.verified),
    ],
  );
}

BatchOfferViewData _pickedBatch({
  BatchOrderState stop1 = BatchOrderState.headingToCustomer,
}) {
  final batch = FakeBatchService.batchFixture(orderCount: 4);
  return batch.copyWith(
    orders: [
      for (final order in batch.orders)
        order.sequence == 1
            ? order.copyWith(state: stop1)
            : order.copyWith(state: BatchOrderState.pickedUp),
    ],
  );
}

Future<void> _pumpStop(
  WidgetTester tester,
  BatchState state, {
  Locale locale = const Locale('ar'),
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool armFakeLocation = false,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const batchId = FakeBatchService.defaultBatchId;
  final router = GoRouter(
    initialLocation: AppRoutes.batchStopPath(batchId, 1),
    routes: [
      GoRoute(
        path:
            '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchStopSegment}/:sequence',
        builder: (_, goState) => BatchStopScreen(
          batchId: goState.pathParameters['batchId']!,
          sequence: int.parse(goState.pathParameters['sequence']!),
        ),
      ),
      GoRoute(
        path:
            '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchRouteSegment}',
        builder: (_, _) => const Scaffold(body: Text('route')),
      ),
      GoRoute(
        path:
            '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchIssueSegment}/:orderId',
        builder: (_, _) => const Scaffold(body: Text('issue')),
      ),
      GoRoute(
        path:
            '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchSummarySegment}',
        builder: (_, _) => const Scaffold(body: Text('summary')),
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      batchServiceProvider.overrideWithValue(
        FakeBatchService(latency: Duration.zero),
      ),
      // Widget tests assert fixed presentation states. Arrival is covered by
      // controller tests; keep the fake location timer inert here.
      fakeBatchArrivalDelayProvider.overrideWithValue(
        armFakeLocation ? Duration.zero : const Duration(days: 1),
      ),
      if (!armFakeLocation)
        fakeBatchLocationControllerProvider.overrideWith(
          _NoopFakeBatchLocationController.new,
        ),
      batchControllerProvider.overrideWith(() => _FixedBatchController(state)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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

class _NoopFakeBatchLocationController extends FakeBatchLocationController {
  @override
  void startApproach(int sequence) {
    // Intentionally inert — presentation tests seed arrival state directly.
  }

  @override
  void reportArrival(int sequence) {}
}

Future<void> _pumpManualPickup(
  WidgetTester tester,
  BatchState state, {
  Locale locale = const Locale('ar'),
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const batchId = FakeBatchService.defaultBatchId;
  final router = GoRouter(
    initialLocation: AppRoutes.batchManualPickupPath(batchId),
    routes: [
      GoRoute(
        path:
            '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchManualPickupSegment}',
        builder: (_, goState) => BatchManualPickupScreen(
          batchId: goState.pathParameters['batchId']!,
        ),
      ),
      GoRoute(
        path:
            '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchVerifySegment}',
        builder: (_, _) => const Scaffold(body: Text('verify')),
      ),
      GoRoute(
        path:
            '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchRouteSegment}',
        builder: (_, _) => const Scaffold(body: Text('route')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        batchServiceProvider.overrideWithValue(
          FakeBatchService(latency: Duration.zero),
        ),
        batchControllerProvider.overrideWith(
          () => _FixedBatchController(state),
        ),
      ],
      child: MaterialApp.router(
        locale: locale,
        theme: AppTheme.lightTheme,
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
  );
  await tester.pump();
}

void main() {
  testWidgets('Figma 138:2714 manual pickup confirmation structure', (
    tester,
  ) async {
    await _pumpManualPickup(
      tester,
      BatchState(
        batch: _verifiedBatch(),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.awaitingManualConfirmation,
        journeyStage: BatchJourneyStage.pickupAwaitingManualConfirmation,
        tripStarted: true,
      ),
    );
    expect(find.byKey(BatchManualPickupScreen.pageKey), findsOneWidget);
    expect(find.byKey(BatchManualPickupScreen.figmaNodeKey), findsOneWidget);
    expect(find.byKey(BatchJourneyTimeline.timelineKey), findsOneWidget);
    expect(find.text('تأكيد الاستلام اليدوي'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(BatchManualPickupScreen.confirmKey),
      120,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(BatchManualPickupScreen.confirmKey), findsOneWidget);
    expect(find.text('تأكيد استلام الدفعة يدويًا'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(BatchManualPickupScreen.reviewKey),
      80,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(BatchManualPickupScreen.reviewKey), findsOneWidget);
    expect(find.text('العودة للمراجعة'), findsOneWidget);
  });

  testWidgets('en-route stop: no arrived button, contact locked', (
    tester,
  ) async {
    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.enRouteToCustomer,
        routeStatus: BatchRouteStatus.activeStop1,
        tripStarted: true,
        currentSequence: 1,
      ),
    );
    expect(find.byKey(BatchStopScreen.pageKey), findsOneWidget);
    expect(find.byKey(BatchStopScreen.figmaLockedKey), findsOneWidget);
    expect(find.byKey(BatchAutomaticArrivalStatus.statusKey), findsOneWidget);
    expect(find.byKey(BatchCustomerContactCard.cardKey), findsOneWidget);
    expect(find.byKey(BatchCustomerContactCard.phoneKey), findsOneWidget);
    expect(find.text('05• ••• ••••'), findsOneWidget);
    expect(find.text('055 123 4567'), findsNothing);
    expect(find.byKey(BatchCustomerContactCard.callKey), findsNothing);
    expect(find.byKey(BatchStopScreen.deliverKey), findsNothing);
    // No interactive "arrived" control anywhere.
    expect(find.text('لقد وصلت'), findsNothing);
    expect(find.text('I have arrived'), findsNothing);
    expect(find.text('وصلت إلى العميل'), findsNothing);
    expect(find.byKey(const Key('batchStopArrive')), findsNothing);
  });

  testWidgets('Figma 125:402 arrived automatically reveals current contact', (
    tester,
  ) async {
    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(stop1: BatchOrderState.arrived),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.deliveryAwaitingManualConfirmation,
        routeStatus: BatchRouteStatus.activeStop1,
        tripStarted: true,
        currentSequence: 1,
      ),
    );
    expect(find.byKey(BatchStopScreen.figmaArrivedKey), findsOneWidget);
    expect(find.byKey(BatchCustomerContactCard.callKey), findsOneWidget);
    expect(find.byKey(BatchCustomerContactCard.whatsappKey), findsOneWidget);
    expect(find.byKey(BatchCustomerContactCard.addressKey), findsOneWidget);
    expect(find.byKey(BatchCustomerContactCard.notesKey), findsOneWidget);
    expect(find.text('055 123 4567'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(BatchStopScreen.deliverKey),
      120,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(BatchStopScreen.deliverKey), findsOneWidget);
    expect(find.text('تأكيد التسليم يدويًا'), findsOneWidget);
    expect(find.byKey(BatchStopScreen.nextStopKey), findsOneWidget);
    // Next customer PII must stay absent from the current stop.
    expect(find.text('055 123 4568'), findsNothing);
    expect(find.textContaining('فيصل'), findsNothing);
  });

  testWidgets('customer unavailable retains current contact only', (
    tester,
  ) async {
    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(stop1: BatchOrderState.customerUnavailable),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.arrivedAutomaticallyByLocation,
        routeStatus: BatchRouteStatus.customerUnavailable,
        tripStarted: true,
        currentSequence: 1,
      ),
    );
    expect(find.byKey(BatchStopScreen.figmaUnavailableKey), findsOneWidget);
    expect(find.text('055 123 4567'), findsOneWidget);
    expect(find.byKey(BatchCustomerContactCard.callKey), findsOneWidget);
    expect(find.text('055 123 4568'), findsNothing);
  });

  testWidgets('Figma 125:508 contact closed after delivery', (tester) async {
    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(stop1: BatchOrderState.delivered),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.deliveredConfirmedManually,
        routeStatus: BatchRouteStatus.overview,
        tripStarted: true,
        currentSequence: 1,
      ),
    );
    expect(find.byKey(BatchStopScreen.figmaClosedKey), findsOneWidget);
    expect(find.text('••••••••••'), findsOneWidget);
    expect(find.text('055 123 4567'), findsNothing);
    expect(find.byKey(BatchCustomerContactCard.callKey), findsNothing);
    expect(find.byKey(BatchStopScreen.deliverKey), findsNothing);
  });

  testWidgets('Arabic RTL Tajawal and English LTR Roboto strings', (
    tester,
  ) async {
    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(stop1: BatchOrderState.arrived),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.deliveryAwaitingManualConfirmation,
        routeStatus: BatchRouteStatus.activeStop1,
        tripStarted: true,
        currentSequence: 1,
      ),
    );
    expect(find.textContaining(RegExp(r'[\u0600-\u06FF]')), findsWidgets);

    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(stop1: BatchOrderState.arrived),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.deliveryAwaitingManualConfirmation,
        routeStatus: BatchRouteStatus.activeStop1,
        tripStarted: true,
        currentSequence: 1,
      ),
      locale: const Locale('en'),
    );
    await tester.scrollUntilVisible(
      find.byKey(BatchStopScreen.deliverKey),
      120,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Confirm delivery manually'), findsOneWidget);
    expect(find.textContaining(RegExp(r'[\u0600-\u06FF]')), findsNothing);
  });

  testWidgets('dark + narrow 320 + textScale 1.3 without overflow', (
    tester,
  ) async {
    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(stop1: BatchOrderState.arrived),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.deliveryAwaitingManualConfirmation,
        routeStatus: BatchRouteStatus.activeStop1,
        tripStarted: true,
        currentSequence: 1,
      ),
      themeMode: ThemeMode.dark,
      size: const Size(320, 800),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(BatchCustomerContactCard.cardKey), findsOneWidget);
  });

  testWidgets('Report a problem opens issue with selectable cancel reason', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const batchId = FakeBatchService.defaultBatchId;
    final batch = _pickedBatch(stop1: BatchOrderState.arrived);
    final orderId = batch.orders.first.orderId;
    final router = GoRouter(
      initialLocation: AppRoutes.batchStopPath(batchId, 1),
      routes: [
        GoRoute(
          path:
              '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchStopSegment}/:sequence',
          builder: (_, goState) => BatchStopScreen(
            batchId: goState.pathParameters['batchId']!,
            sequence: int.parse(goState.pathParameters['sequence']!),
          ),
        ),
        GoRoute(
          path:
              '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchIssueSegment}/:orderId',
          builder: (_, goState) => BatchIssueScreen(
            batchId: goState.pathParameters['batchId']!,
            orderId: goState.pathParameters['orderId']!,
          ),
        ),
        GoRoute(
          path:
              '${AppRoutes.batchPickupRoot}/:batchId/${AppRoutes.batchRouteSegment}',
          builder: (_, _) => const Scaffold(body: Text('route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        batchServiceProvider.overrideWithValue(
          FakeBatchService(latency: Duration.zero),
        ),
        fakeBatchArrivalDelayProvider.overrideWithValue(
          const Duration(days: 1),
        ),
        fakeBatchLocationControllerProvider.overrideWith(
          _NoopFakeBatchLocationController.new,
        ),
        batchControllerProvider.overrideWith(
          () => _FixedBatchController(
            BatchState(
              batch: batch,
              offerStatus: BatchOfferViewStatus.accepted,
              pickupStatus: BatchPickupStatus.pickupConfirmed,
              journeyStage:
                  BatchJourneyStage.deliveryAwaitingManualConfirmation,
              routeStatus: BatchRouteStatus.activeStop1,
              tripStarted: true,
              currentSequence: 1,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          theme: AppTheme.lightTheme,
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
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byKey(BatchStopScreen.issueKey),
      120,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(BatchStopScreen.issueKey));
    await tester.pumpAndSettle();

    expect(find.byType(BatchIssueScreen), findsOneWidget);
    expect(container.read(batchControllerProvider).issueOrderId, orderId);

    await tester.scrollUntilVisible(
      find.byKey(const Key('batchIssueReasonCancelled')),
      80,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('batchIssueReasonCancelled')));
    await tester.pump();
    expect(
      container.read(batchControllerProvider).selectedIssueReason,
      BatchOrderIssueReason.merchantCancelled,
    );

    await tester.scrollUntilVisible(
      find.byKey(BatchIssueScreen.confirmKey),
      80,
      scrollable: find.byType(Scrollable),
    );
    final confirm = tester.widget<SaeqPrimaryButton>(
      find.byKey(BatchIssueScreen.confirmKey),
    );
    expect(confirm.onPressed, isNotNull);
  });

  testWidgets('semantics expose contact and automatic arrival', (tester) async {
    await _pumpStop(
      tester,
      BatchState(
        batch: _pickedBatch(stop1: BatchOrderState.arrived),
        offerStatus: BatchOfferViewStatus.accepted,
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        journeyStage: BatchJourneyStage.deliveryAwaitingManualConfirmation,
        routeStatus: BatchRouteStatus.activeStop1,
        tripStarted: true,
        currentSequence: 1,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(BatchAutomaticArrivalStatus.statusKey)),
      isNotNull,
    );
    expect(
      tester.getSemantics(find.byKey(BatchCustomerContactCard.cardKey)),
      isNotNull,
    );
    expect(
      tester.getSemantics(find.byKey(BatchJourneyTimeline.timelineKey)),
      isNotNull,
    );
  });
}
