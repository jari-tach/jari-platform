import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/active_delivery_page.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  Future<void> pumpAssignment(
    WidgetTester tester,
    DeliveryAssignment assignment, {
    Locale locale = const Locale('en', 'US'),
    Brightness brightness = Brightness.light,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final assignments = FakeDeliveryAssignmentRepository(active: assignment);
    final offers = FakeDeliveryOfferRepository();
    final container = ProviderContainer(
      overrides: [
        deliveryControllerProvider.overrideWith(
          () => DeliveryController(
            getOffersReader: (_) => GetDeliveryOffers(offers),
            getActiveReader: (_) => GetActiveDelivery(assignments),
            offerRepositoryReader: (_) => offers,
            driverIdReader: (_) => 'drv-1',
            availabilityRefreshReader: (_) async {},
          ),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      offers.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          theme: ThemeData(brightness: brightness),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const ActiveDeliveryPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets('customer PII is hidden before manual pickup', (tester) async {
    await pumpAssignment(
      tester,
      sampleAssignment(workflowStage: DriverWorkflowStage.waitingPickup),
    );

    expect(
      find.byKey(ActiveDeliveryPage.customerDetailsHiddenKey),
      findsOneWidget,
    );
    expect(find.byKey(ActiveDeliveryPage.customerDetailsKey), findsNothing);
    expect(find.text('Dropoff B'), findsNothing);
  });

  testWidgets('customer PII is visible after pickup', (tester) async {
    await pumpAssignment(
      tester,
      sampleAssignment(
        status: DeliveryStatus.pickedUp,
        workflowStage: DriverWorkflowStage.verifying,
      ),
    );

    expect(find.byKey(ActiveDeliveryPage.customerDetailsKey), findsOneWidget);
    expect(find.text('Dropoff B'), findsOneWidget);
    expect(
      find.byKey(ActiveDeliveryPage.customerDetailsHiddenKey),
      findsNothing,
    );
  });

  testWidgets('customer PII closes after delivery', (tester) async {
    await pumpAssignment(
      tester,
      sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      ),
    );

    expect(
      find.byKey(ActiveDeliveryPage.customerDetailsHiddenKey),
      findsOneWidget,
    );
    expect(find.byKey(ActiveDeliveryPage.customerDetailsKey), findsNothing);
    expect(find.text('Dropoff B'), findsNothing);
  });

  testWidgets('no manual arrival button exists', (tester) async {
    await pumpAssignment(
      tester,
      sampleAssignment(workflowStage: DriverWorkflowStage.navToCustomer),
    );

    expect(find.text('I arrived at pickup'), findsNothing);
    expect(find.text('I arrived at customer'), findsNothing);
  });

  testWidgets('pending sync and restored states are visible', (tester) async {
    await pumpAssignment(
      tester,
      sampleAssignment(
        status: DeliveryStatus.pickedUp,
        workflowStage: DriverWorkflowStage.verifying,
      ).copyWith(pendingSync: true),
    );

    expect(find.byKey(ActiveDeliveryPage.pendingSyncKey), findsOneWidget);
    expect(find.text('Restored from this device'), findsOneWidget);
    expect(find.text('Retry local sync'), findsOneWidget);
  });

  testWidgets('Arabic RTL renders at 320px and text scale 1.3', (tester) async {
    await pumpAssignment(
      tester,
      sampleAssignment(workflowStage: DriverWorkflowStage.waitingPickup),
      locale: const Locale('ar', 'SA'),
      size: const Size(320, 700),
      textScale: 1.3,
    );

    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English LTR dark mode renders at 320px', (tester) async {
    await pumpAssignment(
      tester,
      sampleAssignment(
        status: DeliveryStatus.pickedUp,
        workflowStage: DriverWorkflowStage.verifying,
      ),
      brightness: Brightness.dark,
      size: const Size(320, 700),
    );

    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
  });
}
