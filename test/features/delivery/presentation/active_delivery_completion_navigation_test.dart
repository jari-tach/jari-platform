import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/delivery/application/complete_delivery_and_release_busy.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/advance_delivery_workflow.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/active_delivery_page.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/delivery_issue_page.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 16);

  DriverAvailability busy() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.busy,
    source: AvailabilitySource.system,
    lastChangedAt: at,
    lastConfirmedAt: at,
    pendingSync: false,
    revision: 2,
    activeAssignmentId: 'asg-1',
  );

  Future<void> pumpActiveRouter(
    WidgetTester tester, {
    required ProviderContainer container,
    required ValueNotifier<String> location,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.deliveryActive,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) =>
              const Scaffold(key: Key('homeProbe'), body: Text('Home')),
        ),
        GoRoute(
          path: AppRoutes.deliveryActive,
          builder: (context, state) => const ActiveDeliveryPage(),
        ),
        GoRoute(
          path: AppRoutes.deliveryIssue,
          builder: (context, state) => const DeliveryIssuePage(),
        ),
      ],
      redirect: (context, state) {
        location.value = state.uri.path;
        return null;
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en', 'US'),
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
    await tester.pump(const Duration(milliseconds: 50));
  }

  ProviderContainer buildContainer({
    required FakeDeliveryAssignmentRepository assignments,
    required CompleteDeliveryAndReleaseBusy complete,
    AdvanceDeliveryWorkflow? advance,
  }) {
    final offers = FakeDeliveryOfferRepository();
    final container = ProviderContainer(
      overrides: [
        deliveryControllerProvider.overrideWith(
          () => DeliveryController(
            getOffersReader: (_) => GetDeliveryOffers(offers),
            getActiveReader: (_) => GetActiveDelivery(assignments),
            completeDeliveryReader: (_) => complete,
            advanceWorkflowReader: (_) => advance,
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
    return container;
  }

  group('ActiveDeliveryPage completion navigation', () {
    testWidgets('success navigates Home', (tester) async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary);
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final complete = CompleteDeliveryAndReleaseBusy(
        assignments,
        ApplyAuthoritativeAvailability(availability),
        GetDriverAvailability(availability),
        clock: () => at,
      );
      final container = buildContainer(
        assignments: assignments,
        complete: complete,
      );
      container.read(deliveryControllerProvider);
      await tester.pump(const Duration(milliseconds: 30));

      final location = ValueNotifier(AppRoutes.deliveryActive);
      await pumpActiveRouter(tester, container: container, location: location);

      await tester.tap(find.byKey(ActiveDeliveryPage.primaryActionKey));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('homeProbe')), findsOneWidget);
      expect(location.value, AppRoutes.home);
      expect(assignments.active, isNull);
    });

    testWidgets('failure stays on summary with error and retry', (
      tester,
    ) async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary);
      final availability = FakeDriverAvailabilityRepository(seed: busy())
        ..nextAuthoritativeFailure = const AvailabilityUnknownFailure('fail');
      final complete = CompleteDeliveryAndReleaseBusy(
        assignments,
        ApplyAuthoritativeAvailability(availability),
        GetDriverAvailability(availability),
        clock: () => at,
      );
      final container = buildContainer(
        assignments: assignments,
        complete: complete,
      );
      container.read(deliveryControllerProvider);
      await tester.pump(const Duration(milliseconds: 30));

      final location = ValueNotifier(AppRoutes.deliveryActive);
      await pumpActiveRouter(tester, container: container, location: location);

      await tester.tap(find.byKey(ActiveDeliveryPage.primaryActionKey));
      await tester.pumpAndSettle();

      expect(find.byKey(ActiveDeliveryPage.pageKey), findsOneWidget);
      expect(find.byKey(const Key('homeProbe')), findsNothing);
      expect(location.value, AppRoutes.deliveryActive);
      expect(find.byKey(ActiveDeliveryPage.primaryActionKey), findsOneWidget);
      expect(assignments.active, isNotNull);
    });

    testWidgets('rapid Finish taps do not navigate twice before settle', (
      tester,
    ) async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary);
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final gate = Completer<void>();
      final complete = _GatedCompleteDelivery(
        assignments: assignments,
        availability: availability,
        clock: () => at,
        gate: gate,
      );
      final container = buildContainer(
        assignments: assignments,
        complete: complete,
      );
      container.read(deliveryControllerProvider);
      await tester.pump(const Duration(milliseconds: 30));

      final location = ValueNotifier(AppRoutes.deliveryActive);
      await pumpActiveRouter(tester, container: container, location: location);

      await tester.tap(find.byKey(ActiveDeliveryPage.primaryActionKey));
      await tester.pump();
      await tester.tap(find.byKey(ActiveDeliveryPage.primaryActionKey));
      await tester.pump();
      expect(complete.calls, 1);
      expect(location.value, AppRoutes.deliveryActive);

      gate.complete();
      await tester.pumpAndSettle();
      expect(complete.calls, 1);
      expect(location.value, AppRoutes.home);
    });
  });

  group('DeliveryIssuePage navigation', () {
    testWidgets('success returns to active delivery', (tester) async {
      final assignment = sampleAssignment(
        workflowStage: DriverWorkflowStage.arrivedPickup,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final complete = CompleteDeliveryAndReleaseBusy(
        assignments,
        ApplyAuthoritativeAvailability(availability),
        GetDriverAvailability(availability),
        clock: () => at,
      );
      final advance = AdvanceDeliveryWorkflow(assignments);
      final offers = FakeDeliveryOfferRepository();
      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getOffersReader: (_) => GetDeliveryOffers(offers),
              getActiveReader: (_) => GetActiveDelivery(assignments),
              completeDeliveryReader: (_) => complete,
              advanceWorkflowReader: (_) => advance,
              offerRepositoryReader: (_) => offers,
              driverIdReader: (_) => 'drv-1',
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        offers.dispose();
      });
      container.read(deliveryControllerProvider);
      await tester.pump(const Duration(milliseconds: 30));

      final router = GoRouter(
        initialLocation: AppRoutes.deliveryIssue,
        routes: [
          GoRoute(
            path: AppRoutes.deliveryActive,
            builder: (context, state) => const ActiveDeliveryPage(),
          ),
          GoRoute(
            path: AppRoutes.deliveryIssue,
            builder: (context, state) => const DeliveryIssuePage(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('en', 'US'),
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unexpected delay'));
      await tester.pump();
      await tester.tap(find.text('Submit issue'));
      await tester.pumpAndSettle();

      expect(find.byKey(ActiveDeliveryPage.pageKey), findsOneWidget);
      expect(
        container
            .read(deliveryControllerProvider)
            .activeAssignment
            ?.workflowStage,
        DriverWorkflowStage.issueOpen,
      );
    });

    testWidgets('failure remains on issue page', (tester) async {
      final assignment = sampleAssignment(
        workflowStage: DriverWorkflowStage.assigned,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final complete = CompleteDeliveryAndReleaseBusy(
        assignments,
        ApplyAuthoritativeAvailability(availability),
        GetDriverAvailability(availability),
        clock: () => at,
      );
      final advance = AdvanceDeliveryWorkflow(assignments);
      final offers = FakeDeliveryOfferRepository();
      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getOffersReader: (_) => GetDeliveryOffers(offers),
              getActiveReader: (_) => GetActiveDelivery(assignments),
              completeDeliveryReader: (_) => complete,
              advanceWorkflowReader: (_) => advance,
              offerRepositoryReader: (_) => offers,
              driverIdReader: (_) => 'drv-1',
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        offers.dispose();
      });
      container.read(deliveryControllerProvider);
      await tester.pump(const Duration(milliseconds: 30));

      final router = GoRouter(
        initialLocation: AppRoutes.deliveryIssue,
        routes: [
          GoRoute(
            path: AppRoutes.deliveryActive,
            builder: (context, state) => const ActiveDeliveryPage(),
          ),
          GoRoute(
            path: AppRoutes.deliveryIssue,
            builder: (context, state) => const DeliveryIssuePage(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('en', 'US'),
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unexpected delay'));
      await tester.pump();
      await tester.tap(find.text('Submit issue'));
      await tester.pumpAndSettle();

      expect(find.byKey(DeliveryIssuePage.pageKey), findsOneWidget);
      expect(find.byKey(ActiveDeliveryPage.pageKey), findsNothing);
      expect(
        container
            .read(deliveryControllerProvider)
            .activeAssignment
            ?.workflowStage,
        DriverWorkflowStage.assigned,
      );
    });
  });
}

final class _GatedCompleteDelivery extends CompleteDeliveryAndReleaseBusy {
  _GatedCompleteDelivery({
    required FakeDeliveryAssignmentRepository assignments,
    required FakeDriverAvailabilityRepository availability,
    required DateTime Function() clock,
    required this.gate,
  }) : super(
         assignments,
         ApplyAuthoritativeAvailability(availability),
         GetDriverAvailability(availability),
         clock: clock,
       );

  final Completer<void> gate;
  int calls = 0;

  @override
  Future<DeliveryResult<void>> call({required String driverId}) async {
    calls++;
    await gate.future;
    return super.call(driverId: driverId);
  }
}
