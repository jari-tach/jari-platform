import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/mappers/delivery_failure_messages.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/incoming_delivery_offer_page.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_assignment_summary.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_card.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_countdown.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_empty_state.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_error_state.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_home_banner.dart';
import 'package:saeq_driver/features/delivery/presentation/widgets/delivery_offer_loading_state.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  Future<ProviderContainer> pumpOfferPage(
    WidgetTester tester, {
    FakeDeliveryOfferRepository? offers,
    FakeDeliveryAssignmentRepository? assignments,
    String? driverId = 'drv-1',
    DeliveryAcceptPreconditions preconditions =
        const DeliveryAcceptPreconditions(
          connectivityOnline: true,
          isConfirmedAvailable: true,
        ),
    bool wireOffers = true,
    bool wireActive = true,
    Locale locale = const Locale('en', 'US'),
    DateTime Function()? now,
    Size surfaceSize = const Size(390, 844),
    double textScale = 1.0,
  }) async {
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
            getOffersReader: (_) => wireOffers ? getOffers : null,
            acceptReader: (_) => wireOffers && wireActive ? accept : null,
            rejectReader: (_) => wireOffers ? reject : null,
            getActiveReader: (_) => wireActive ? getActive : null,
            offerRepositoryReader: (_) => wireOffers ? offerRepo : null,
            driverIdReader: (_) => driverId,
            acceptPreconditionsReader: (_) => preconditions,
          ),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      offerRepo.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: IncomingDeliveryOfferPage(now: now),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  group('IncomingDeliveryOfferPage states', () {
    testWidgets('loading then empty state', (tester) async {
      await pumpOfferPage(tester);
      expect(find.byKey(DeliveryOfferEmptyState.emptyKey), findsOneWidget);
      expect(find.text('No available offers'), findsOneWidget);
    });

    testWidgets('offer card shows store pickup dropoff distance earnings', (
      tester,
    ) async {
      final offerRepo = FakeDeliveryOfferRepository(
        offers: [
          sampleOffer(
            expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
          ),
        ],
      );
      await pumpOfferPage(tester, offers: offerRepo);

      expect(find.byKey(DeliveryOfferCard.cardKey), findsOneWidget);
      expect(find.text('Merchant'), findsOneWidget);
      expect(find.text('Pickup A'), findsOneWidget);
      expect(find.text('Dropoff B'), findsOneWidget);
      expect(find.text('Estimated distance'), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('Estimated earnings'), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
      expect(find.byKey(DeliveryOfferCountdown.countdownKey), findsOneWidget);
      expect(find.byKey(DeliveryOfferCard.acceptKey), findsOneWidget);
      expect(find.byKey(DeliveryOfferCard.rejectKey), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      await pumpOfferPage(tester, wireOffers: false, wireActive: false);
      expect(find.byKey(DeliveryOfferErrorState.errorKey), findsOneWidget);
      expect(find.byKey(DeliveryOfferErrorState.retryKey), findsOneWidget);
    });

    testWidgets('accepted assignment summary and continue', (tester) async {
      final assignments = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(),
      );
      await pumpOfferPage(tester, assignments: assignments);

      expect(find.byKey(DeliveryAssignmentSummary.summaryKey), findsOneWidget);
      expect(find.text('Delivery accepted'), findsWidgets);
      expect(find.byKey(DeliveryAssignmentSummary.continueKey), findsOneWidget);

      await tester.tap(find.byKey(DeliveryAssignmentSummary.continueKey));
      await tester.pumpAndSettle();
      // Without GoRouter and without a push stack, continue is a no-op pop.
      expect(find.byKey(IncomingDeliveryOfferPage.pageKey), findsOneWidget);
    });

    testWidgets('accept success transitions to assignment summary', (
      tester,
    ) async {
      final offer = sampleOffer(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
      );
      final offerRepo = FakeDeliveryOfferRepository(offers: [offer]);
      offerRepo.acceptResult = sampleAssignment();
      final container = await pumpOfferPage(tester, offers: offerRepo);

      await tester.tap(find.byKey(DeliveryOfferCard.acceptKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final state = container.read(deliveryControllerProvider);
      expect(state.hasActiveAssignment, isTrue);
      expect(find.byKey(DeliveryAssignmentSummary.summaryKey), findsOneWidget);
    });

    testWidgets('duplicate accept tap is prevented while processing', (
      tester,
    ) async {
      final offer = sampleOffer(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
      );
      final offerRepo = FakeDeliveryOfferRepository(offers: [offer]);
      offerRepo.acceptResult = sampleAssignment();
      // Slow accept via delayed Future is hard; use in-flight guard by
      // tapping twice quickly after first starts.
      await pumpOfferPage(tester, offers: offerRepo);

      await tester.tap(find.byKey(DeliveryOfferCard.acceptKey));
      await tester.tap(find.byKey(DeliveryOfferCard.acceptKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(offerRepo.acceptCallCount, 1);
    });

    testWidgets('reject clears offer and shows empty', (tester) async {
      final offer = sampleOffer(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
      );
      final offerRepo = FakeDeliveryOfferRepository(offers: [offer]);
      await pumpOfferPage(tester, offers: offerRepo);

      await tester.tap(find.byKey(DeliveryOfferCard.rejectKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(DeliveryOfferEmptyState.emptyKey), findsOneWidget);
      expect(offerRepo.rejectCallCount, 1);
    });

    testWidgets('accept failure keeps offer and shows banner', (tester) async {
      final offer = sampleOffer(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
      );
      final offerRepo = FakeDeliveryOfferRepository(offers: [offer]);
      offerRepo.nextAcceptFailure = const DeliveryOfferExpired();
      await pumpOfferPage(tester, offers: offerRepo);

      await tester.tap(find.byKey(DeliveryOfferCard.acceptKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(DeliveryOfferCard.cardKey), findsOneWidget);
      expect(find.text('This offer has expired.'), findsOneWidget);
    });

    testWidgets('large text does not overflow critical actions', (
      tester,
    ) async {
      final offerRepo = FakeDeliveryOfferRepository(
        offers: [
          sampleOffer(
            expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
          ),
        ],
      );
      await pumpOfferPage(tester, offers: offerRepo, textScale: 1.6);
      expect(tester.takeException(), isNull);
      expect(find.byKey(DeliveryOfferCard.acceptKey), findsOneWidget);
      expect(find.byKey(DeliveryOfferCard.rejectKey), findsOneWidget);
    });
  });

  group('DeliveryOfferHomeBanner', () {
    testWidgets('hidden when empty', (tester) async {
      final offerRepo = FakeDeliveryOfferRepository();
      final assignmentRepo = FakeDeliveryAssignmentRepository();
      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getOffersReader: (_) => GetDeliveryOffers(offerRepo),
              acceptReader: (_) =>
                  AcceptDeliveryOffer(offerRepo, assignmentRepo),
              rejectReader: (_) => RejectDeliveryOffer(offerRepo),
              getActiveReader: (_) => GetActiveDelivery(assignmentRepo),
              offerRepositoryReader: (_) => offerRepo,
              driverIdReader: (_) => 'drv-1',
              acceptPreconditionsReader: (_) =>
                  const DeliveryAcceptPreconditions(
                    connectivityOnline: true,
                    isConfirmedAvailable: true,
                  ),
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        offerRepo.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DeliveryOfferHomeBanner()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(DeliveryOfferHomeBanner.bannerKey), findsNothing);
    });

    testWidgets('visible when offer present', (tester) async {
      final offerRepo = FakeDeliveryOfferRepository(
        offers: [
          sampleOffer(
            expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 2)),
          ),
        ],
      );
      final assignmentRepo = FakeDeliveryAssignmentRepository();
      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getOffersReader: (_) => GetDeliveryOffers(offerRepo),
              acceptReader: (_) =>
                  AcceptDeliveryOffer(offerRepo, assignmentRepo),
              rejectReader: (_) => RejectDeliveryOffer(offerRepo),
              getActiveReader: (_) => GetActiveDelivery(assignmentRepo),
              offerRepositoryReader: (_) => offerRepo,
              driverIdReader: (_) => 'drv-1',
              acceptPreconditionsReader: (_) =>
                  const DeliveryAcceptPreconditions(
                    connectivityOnline: true,
                    isConfirmedAvailable: true,
                  ),
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        offerRepo.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DeliveryOfferHomeBanner()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(DeliveryOfferHomeBanner.bannerKey), findsOneWidget);
      expect(find.text('Incoming delivery offer'), findsOneWidget);
    });
  });

  group('deliveryFailureMessage', () {
    test('maps typed failures to localized copy', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(
        deliveryFailureMessage(const DeliveryOfflineAcceptDenied(), l10n),
        l10n.deliveryFailureOfflineAccept,
      );
      expect(
        deliveryFailureMessage(const DeliveryOfferTaken(), l10n),
        l10n.deliveryFailureOfferTaken,
      );
    });
  });

  group('DeliveryOfferLoadingState', () {
    testWidgets('renders progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DeliveryOfferLoadingState()),
        ),
      );
      await tester.pump();
      expect(find.byKey(DeliveryOfferLoadingState.progressKey), findsOneWidget);
      expect(find.text('Loading offers'), findsOneWidget);
    });
  });
}
