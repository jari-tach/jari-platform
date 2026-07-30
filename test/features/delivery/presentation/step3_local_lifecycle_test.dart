import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/delivery/application/accept_delivery_offer_and_bind_busy.dart';
import 'package:saeq_driver/features/delivery/application/complete_delivery_and_release_busy.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/policies/driver_workflow_transition_policy.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/advance_delivery_workflow.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/verify_delivery_code.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/state/delivery_controller_state.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_command_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  test(
    'STEP 3 accept → restore → pickup → fake arrival → delivery → restart',
    () async {
      final at = DateTime.utc(2026, 7, 30, 12);
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository();
      final commands = FakeDeliveryCommandRepository();
      final availability = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.available,
          source: AvailabilitySource.server,
          lastChangedAt: at,
          lastConfirmedAt: at,
          pendingSync: false,
          revision: 1,
        ),
      );
      final accept = AcceptDeliveryOffer(
        offers,
        assignments,
        commandRepository: commands,
        clock: () => at,
      );
      final acceptAndBind = AcceptDeliveryOfferAndBindBusy(
        accept,
        ApplyAuthoritativeAvailability(availability),
        GetDriverAvailability(availability),
        clock: () => at,
      );
      final advance = AdvanceDeliveryWorkflow(assignments);
      final verify = VerifyDeliveryCode(assignments);
      final complete = CompleteDeliveryAndReleaseBusy(
        assignments,
        ApplyAuthoritativeAvailability(availability),
        GetDriverAvailability(availability),
        clock: () => at,
      );
      var online = true;

      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getOffersReader: (_) =>
                  GetDeliveryOffers(offers, commandRepository: commands),
              acceptAndBindReader: (_) => acceptAndBind,
              rejectReader: (_) =>
                  RejectDeliveryOffer(offers, commandRepository: commands),
              getActiveReader: (_) => GetActiveDelivery(assignments),
              advanceWorkflowReader: (_) => advance,
              verifyCodeReader: (_) => verify,
              completeDeliveryReader: (_) => complete,
              offerRepositoryReader: (_) => offers,
              driverIdReader: (_) => 'drv-1',
              acceptPreconditionsReader: (_) => DeliveryAcceptPreconditions(
                connectivityOnline: online,
                isConfirmedAvailable: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        offers.dispose();
        availability.dispose();
      });

      container.read(deliveryControllerProvider);
      await _settle();
      expect(container.read(deliveryControllerProvider).canAccept, isTrue);

      // Accept persists once and automatically reaches pickup confirmation.
      await container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();
      var state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.ready);
      expect(state.hasOffer, isFalse);
      expect(
        state.activeAssignment?.workflowStage,
        DriverWorkflowStage.waitingPickup,
      );
      expect(
        assignments.active?.workflowStage,
        DriverWorkflowStage.waitingPickup,
      );
      expect(availability.state?.status, AvailabilityStatus.busy);
      expect(offers.acceptCallCount, 1);

      // Restart restores the same assignment and never accepts again.
      container.invalidate(deliveryControllerProvider);
      container.read(deliveryControllerProvider);
      await _settle();
      state = container.read(deliveryControllerProvider);
      expect(state.isRestored, isTrue);
      expect(state.activeAssignment?.assignmentId, 'asg-1');
      expect(state.hasOffer, isFalse);
      expect(offers.acceptCallCount, 1);

      // Manual pickup, then local automatic customer arrival. No manual
      // arrival command is exposed to UI.
      online = false;
      await container
          .read(deliveryControllerProvider.notifier)
          .advanceWorkflow(DriverWorkflowCommand.confirmPickup);
      state = container.read(deliveryControllerProvider);
      expect(state.activeAssignment?.status, DeliveryStatus.pickedUp);
      expect(
        state.activeAssignment?.workflowStage,
        DriverWorkflowStage.verifying,
      );
      expect(state.activeAssignment?.pendingSync, isTrue);

      final upsertsAfterPickup = assignments.upsertCallCount;
      await container
          .read(deliveryControllerProvider.notifier)
          .advanceWorkflow(DriverWorkflowCommand.confirmPickup);
      expect(assignments.upsertCallCount, upsertsAfterPickup);

      await container
          .read(deliveryControllerProvider.notifier)
          .retryPendingSync();
      expect(
        container
            .read(deliveryControllerProvider)
            .activeAssignment
            ?.pendingSync,
        isFalse,
      );

      // Manual delivery confirmation is idempotent.
      online = true;
      await container
          .read(deliveryControllerProvider.notifier)
          .verifyDeliveryCode('1234');
      state = container.read(deliveryControllerProvider);
      expect(
        state.activeAssignment?.workflowStage,
        DriverWorkflowStage.summary,
      );
      final upsertsAfterDelivery = assignments.upsertCallCount;
      await container
          .read(deliveryControllerProvider.notifier)
          .verifyDeliveryCode('1234');
      expect(assignments.upsertCallCount, upsertsAfterDelivery);

      await container
          .read(deliveryControllerProvider.notifier)
          .completeDeliverySummary();
      expect(
        container.read(deliveryControllerProvider).activeAssignment,
        isNull,
      );
      expect(assignments.active, isNull);

      // Final restart has no active assignment and filters the old consumed
      // Fake offer from the local command ledger.
      container.invalidate(deliveryControllerProvider);
      container.read(deliveryControllerProvider);
      await _settle();
      state = container.read(deliveryControllerProvider);
      expect(state.activeAssignment, isNull);
      expect(state.hasOffer, isFalse);
      expect(offers.acceptCallCount, 1);
    },
  );
}

Future<void> _settle() async {
  for (var index = 0; index < 10; index++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
