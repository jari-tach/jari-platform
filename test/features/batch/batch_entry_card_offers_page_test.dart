import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/batch/batch_feature.dart';
import 'package:saeq_driver/features/batch/widgets/batch_offer_entry_card.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/incoming_delivery_offer_page.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_assignment_summary.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_card.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_empty_state.dart';

import '../delivery/helpers/delivery_fixtures.dart';
import '../delivery/helpers/fake_delivery_assignment_repository.dart';
import '../delivery/helpers/fake_delivery_offer_repository.dart';

/// Offers-surface visibility of the fake batch fixture entry card.
///
/// The card must be reachable while an individual offer is displayed and in the
/// empty state, and must disappear entirely when the debug guard is `false`.
void main() {
  const batchId = FakeBatchService.defaultBatchId;
  const batchProbeKey = Key('batchRouteProbe');

  Future<GoRouter> pumpOfferPage(
    WidgetTester tester, {
    FakeDeliveryOfferRepository? offers,
    FakeDeliveryAssignmentRepository? assignments,
    bool? batchEntryEnabled,
    Locale locale = const Locale('en', 'US'),
  }) async {
    const surfaceSize = Size(390, 844);
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final offerRepo = offers ?? FakeDeliveryOfferRepository();
    final assignmentRepo = assignments ?? FakeDeliveryAssignmentRepository();
    final getOffers = GetDeliveryOffers(offerRepo);
    final accept = AcceptDeliveryOffer(offerRepo, assignmentRepo);
    final reject = RejectDeliveryOffer(offerRepo);
    final getActive = GetActiveDelivery(assignmentRepo);

    final container = ProviderContainer(
      overrides: [
        deliveryControllerProvider.overrideWith(
          () => DeliveryController(
            getOffersReader: (_) => getOffers,
            acceptReader: (_) => accept,
            rejectReader: (_) => reject,
            getActiveReader: (_) => getActive,
            offerRepositoryReader: (_) => offerRepo,
            driverIdReader: (_) => 'drv-1',
            acceptPreconditionsReader: (_) => const DeliveryAcceptPreconditions(
              connectivityOnline: true,
              isConfirmedAvailable: true,
            ),
          ),
        ),
        if (batchEntryEnabled != null)
          batchFixtureEntryEnabledProvider.overrideWithValue(batchEntryEnabled),
      ],
    );
    addTearDown(() {
      container.dispose();
      offerRepo.dispose();
    });

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const IncomingDeliveryOfferPage(),
        ),
        GoRoute(
          path: '${AppRoutes.batchOfferRoot}/:batchId',
          builder: (_, state) => Scaffold(
            key: batchProbeKey,
            body: Text('batch ${state.pathParameters['batchId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(size: surfaceSize),
          child: MaterialApp.router(
            locale: locale,
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
    await tester.pump(const Duration(milliseconds: 50));
    return router;
  }

  FakeDeliveryOfferRepository offerRepoWithLiveOffer() {
    return FakeDeliveryOfferRepository(
      offers: [
        sampleOffer(
          expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
        ),
      ],
    );
  }

  group('batchFixtureEntryEnabledProvider', () {
    test('enabled in debug builds outside production', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(batchFixtureEntryEnabledProvider), isTrue);
    });
  });

  group('BatchOfferEntryCard on the offers surface', () {
    testWidgets('visible while an individual offer is present', (tester) async {
      await pumpOfferPage(tester, offers: offerRepoWithLiveOffer());

      expect(find.byKey(BatchOfferEntryCard.cardKey), findsOneWidget);
      expect(find.byKey(BatchOfferEntryCard.openKey), findsOneWidget);
      // The single offer keeps its own card and decision actions.
      expect(find.byKey(DeliveryOfferCard.cardKey), findsOneWidget);
      expect(find.byKey(DeliveryOfferCard.acceptKey), findsOneWidget);
      expect(find.byKey(DeliveryOfferCard.rejectKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('visible in the empty state', (tester) async {
      await pumpOfferPage(tester);

      expect(find.byKey(DeliveryOfferEmptyState.emptyKey), findsOneWidget);
      expect(find.byKey(BatchOfferEntryCard.cardKey), findsOneWidget);
      expect(find.byKey(BatchOfferEntryCard.openKey), findsOneWidget);
    });

    testWidgets('tapping the entry navigates to the batch offer route', (
      tester,
    ) async {
      final router = await pumpOfferPage(
        tester,
        offers: offerRepoWithLiveOffer(),
      );

      await tester.ensureVisible(find.byKey(BatchOfferEntryCard.openKey));
      await tester.pump();
      await tester.tap(find.byKey(BatchOfferEntryCard.openKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(batchProbeKey), findsOneWidget);
      expect(find.text('batch $batchId'), findsOneWidget);
      expect(router.state.uri.toString(), '/offers/batch/$batchId');
    });

    testWidgets('accepting the individual offer still works alongside it', (
      tester,
    ) async {
      final offerRepo = offerRepoWithLiveOffer();
      offerRepo.acceptResult = sampleAssignment();
      await pumpOfferPage(tester, offers: offerRepo);

      expect(find.byKey(BatchOfferEntryCard.cardKey), findsOneWidget);

      await tester.tap(find.byKey(DeliveryOfferCard.acceptKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(offerRepo.acceptCallCount, 1);
      expect(find.byKey(DeliveryAssignmentSummary.summaryKey), findsOneWidget);
    });
  });

  group('BatchOfferEntryCard hidden in production', () {
    testWidgets('absent with an individual offer when the guard is false', (
      tester,
    ) async {
      await pumpOfferPage(
        tester,
        offers: offerRepoWithLiveOffer(),
        batchEntryEnabled: false,
      );

      expect(find.byKey(BatchOfferEntryCard.cardKey), findsNothing);
      expect(find.byKey(BatchOfferEntryCard.openKey), findsNothing);
      expect(find.text('Batch delivery offer available'), findsNothing);
      expect(find.text('View batch offer'), findsNothing);
      expect(find.byKey(DeliveryOfferCard.cardKey), findsOneWidget);
    });

    testWidgets('absent in the empty state when the guard is false', (
      tester,
    ) async {
      await pumpOfferPage(tester, batchEntryEnabled: false);

      expect(find.byKey(BatchOfferEntryCard.cardKey), findsNothing);
      expect(find.byKey(BatchOfferEntryCard.openKey), findsNothing);
      expect(find.text('Batch delivery offer available'), findsNothing);
      expect(find.byKey(DeliveryOfferEmptyState.emptyKey), findsOneWidget);
    });
  });
}
