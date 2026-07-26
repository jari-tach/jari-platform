import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/incoming_delivery_offer_page.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, Locale locale) async {
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
            acceptReader: (_) => AcceptDeliveryOffer(offerRepo, assignmentRepo),
            rejectReader: (_) => RejectDeliveryOffer(offerRepo),
            getActiveReader: (_) => GetActiveDelivery(assignmentRepo),
            offerRepositoryReader: (_) => offerRepo,
            driverIdReader: (_) => 'drv-1',
            acceptPreconditionsReader: (_) => const DeliveryAcceptPreconditions(
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
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const IncomingDeliveryOfferPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('Delivery offer localization', () {
    test('Arabic getters are Arabic-only for app-owned copy', () {
      final l10n = AppLocalizations(const Locale('ar'));
      expect(l10n.deliveryOfferTitle, 'عرض توصيل جديد');
      expect(l10n.deliveryAccept, 'قبول');
      expect(l10n.deliveryReject, 'رفض');
      expect(l10n.deliveryEmptyTitle, 'لا توجد عروض متاحة');
      expect(l10n.deliveryContinueDelivery, 'متابعة التوصيل');
      expect(
        l10n.deliveryOfferTitle.contains(RegExp(r'[A-Za-z]{3,}')),
        isFalse,
      );
    });

    testWidgets('Arabic page renders Arabic action labels', (tester) async {
      await pumpPage(tester, const Locale('ar'));
      expect(find.text('عرض توصيل جديد'), findsWidgets);
      expect(find.text('قبول'), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Reject'), findsNothing);
    });

    testWidgets('English page renders English action labels', (tester) async {
      await pumpPage(tester, const Locale('en', 'US'));
      expect(find.text('New delivery offer'), findsWidgets);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('قبول'), findsNothing);
    });
  });
}
