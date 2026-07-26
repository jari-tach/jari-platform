import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/delivery/application/complete_delivery_and_release_busy.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/state/delivery_controller_state.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 15);

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

  Future<ProviderContainer> boot({
    required FakeDeliveryAssignmentRepository assignments,
    required FakeDeliveryOfferRepository offers,
    required CompleteDeliveryAndReleaseBusy complete,
  }) async {
    final getOffers = GetDeliveryOffers(offers);
    final getActive = GetActiveDelivery(assignments);
    final container = ProviderContainer(
      overrides: [
        deliveryControllerProvider.overrideWith(
          () => DeliveryController(
            getOffersReader: (_) => getOffers,
            getActiveReader: (_) => getActive,
            completeDeliveryReader: (_) => complete,
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
    container.read(deliveryControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container;
  }

  group('DeliveryController completeDeliverySummary', () {
    test('duplicate taps run a single completion command', () async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary);
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final gate = Completer<void>();
      final complete = _GatedCompleteDelivery(
        assignments: assignments,
        availability: availability,
        clock: () => at,
        gate: gate,
      );

      final container = await boot(
        assignments: assignments,
        offers: offers,
        complete: complete,
      );
      final controller = container.read(deliveryControllerProvider.notifier);

      final first = controller.completeDeliverySummary();
      final second = controller.completeDeliverySummary();
      await Future<void>.delayed(Duration.zero);
      expect(complete.calls, 1);
      gate.complete();
      await Future.wait([first, second]);
      expect(complete.calls, 1);
      expect(
        container.read(deliveryControllerProvider).activeAssignment,
        isNull,
      );
    });

    test('does not add offer-watch subscriptions during completion', () async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary);
      final offers = FakeDeliveryOfferRepository();
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final complete = CompleteDeliveryAndReleaseBusy(
        assignments,
        ApplyAuthoritativeAvailability(availability),
        GetDriverAvailability(availability),
        clock: () => at,
      );
      final container = await boot(
        assignments: assignments,
        offers: offers,
        complete: complete,
      );
      final before = offers.watchSubscribeCount;
      await container
          .read(deliveryControllerProvider.notifier)
          .completeDeliverySummary();
      expect(offers.watchSubscribeCount, before);
    });

    test(
      'availability failure re-syncs persisted summary into state',
      () async {
        final summary = sampleAssignment(
          status: DeliveryStatus.delivered,
          workflowStage: DriverWorkflowStage.summary,
        );
        final assignments = FakeDeliveryAssignmentRepository(active: summary);
        final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        final availability = FakeDriverAvailabilityRepository(seed: busy())
          ..nextAuthoritativeFailure = const AvailabilityUnknownFailure('fail');
        final complete = CompleteDeliveryAndReleaseBusy(
          assignments,
          ApplyAuthoritativeAvailability(availability),
          GetDriverAvailability(availability),
          clock: () => at,
        );
        final container = await boot(
          assignments: assignments,
          offers: offers,
          complete: complete,
        );

        await container
            .read(deliveryControllerProvider.notifier)
            .completeDeliverySummary();

        final state = container.read(deliveryControllerProvider);
        expect(state.status, DeliveryViewStatus.failure);
        expect(
          state.activeAssignment?.workflowStage,
          DriverWorkflowStage.summary,
        );
        expect(state.offers, isEmpty);
        expect(assignments.active, isNotNull);

        availability.nextAuthoritativeFailure = null;
        await container
            .read(deliveryControllerProvider.notifier)
            .completeDeliverySummary();
        final retry = container.read(deliveryControllerProvider);
        expect(retry.status, DeliveryViewStatus.ready);
        expect(retry.activeAssignment, isNull);
        expect(assignments.active, isNull);
      },
    );

    test(
      'successful completion clears assignment and keeps offers empty',
      () async {
        final summary = sampleAssignment(
          status: DeliveryStatus.delivered,
          workflowStage: DriverWorkflowStage.summary,
        );
        final assignments = FakeDeliveryAssignmentRepository(active: summary);
        final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        final availability = FakeDriverAvailabilityRepository(seed: busy());
        final complete = CompleteDeliveryAndReleaseBusy(
          assignments,
          ApplyAuthoritativeAvailability(availability),
          GetDriverAvailability(availability),
          clock: () => at,
        );
        final container = await boot(
          assignments: assignments,
          offers: offers,
          complete: complete,
        );

        await container
            .read(deliveryControllerProvider.notifier)
            .completeDeliverySummary();

        final state = container.read(deliveryControllerProvider);
        expect(state.status, DeliveryViewStatus.ready);
        expect(state.activeAssignment, isNull);
        expect(state.offers, isEmpty);
        expect(availability.state?.status, AvailabilityStatus.unavailable);
      },
    );
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
