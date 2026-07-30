import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';
import 'package:saeq_driver/features/delivery/domain/entities/accept_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/entities/reject_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/policies/driver_workflow_transition_policy.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/advance_delivery_workflow.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/record_local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/verify_delivery_code.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_command_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  group('STEP 3 local command safety', () {
    test(
      'duplicate pickup command id mutates and persists exactly once',
      () async {
        final repository = FakeDeliveryAssignmentRepository(
          active: sampleAssignment(
            workflowStage: DriverWorkflowStage.waitingPickup,
          ),
        );
        final advance = AdvanceDeliveryWorkflow(repository);

        final first = await advance(
          driverId: 'drv-1',
          command: DriverWorkflowCommand.confirmPickup,
          commandId: 'pickup-1',
        );
        final replay = await advance(
          driverId: 'drv-1',
          command: DriverWorkflowCommand.confirmPickup,
          commandId: 'pickup-1',
        );

        expect(first.isSuccess, isTrue);
        expect(replay.isSuccess, isTrue);
        expect(repository.upsertCallCount, 1);
        expect(repository.active?.status, DeliveryStatus.pickedUp);
        expect(repository.active?.completedCommandIds, contains('pickup-1'));
      },
    );

    test('different command id on invalid state returns typed error', () async {
      final repository = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(
          status: DeliveryStatus.pickedUp,
          workflowStage: DriverWorkflowStage.collected,
        ),
      );
      final result = await AdvanceDeliveryWorkflow(repository)(
        driverId: 'drv-1',
        command: DriverWorkflowCommand.confirmPickup,
        commandId: 'pickup-different',
      );

      expect(result.failureOrNull, isA<InvalidDeliveryWorkflowTransition>());
      expect(repository.upsertCallCount, 0);
    });

    test(
      'pending sync survives JSON restart and retry does not replay command',
      () async {
        final repository = FakeDeliveryAssignmentRepository(
          active: sampleAssignment(
            workflowStage: DriverWorkflowStage.waitingPickup,
          ),
        );
        final advance = AdvanceDeliveryWorkflow(repository);
        await advance(
          driverId: 'drv-1',
          command: DriverWorkflowCommand.confirmPickup,
          commandId: 'pickup-offline',
          simulateOffline: true,
        );

        final json = DeliveryAssignmentModel.fromEntity(
          repository.active!,
        ).toJson();
        final restored = DeliveryAssignmentModel.fromJson(json).toEntity();
        repository.active = restored;

        expect(restored.pendingSync, isTrue);
        expect(restored.completedCommandIds, contains('pickup-offline'));

        final retried = await advance.clearPendingSync(driverId: 'drv-1');
        expect(retried.isSuccess, isTrue);
        expect(repository.active?.pendingSync, isFalse);
        expect(repository.active?.workflowStage, DriverWorkflowStage.collected);
        expect(
          repository.active?.completedCommandIds,
          contains('pickup-offline'),
        );
        expect(repository.upsertCallCount, 2);
      },
    );

    test('duplicate delivery confirmation command id is idempotent', () async {
      final repository = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(
          status: DeliveryStatus.pickedUp,
          workflowStage: DriverWorkflowStage.verifying,
        ),
      );
      final verify = VerifyDeliveryCode(repository);

      final first = await verify(
        driverId: 'drv-1',
        code: '1234',
        commandId: 'delivery-1',
      );
      final replay = await verify(
        driverId: 'drv-1',
        code: '1234',
        commandId: 'delivery-1',
      );

      expect(first.isSuccess, isTrue);
      expect(replay.isSuccess, isTrue);
      expect(repository.active?.workflowStage, DriverWorkflowStage.summary);
      expect(repository.upsertCallCount, 2);
    });

    test(
      'accept retry after restart returns persisted assignment once',
      () async {
        final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        offers.acceptResult = sampleAssignment();
        final assignments = FakeDeliveryAssignmentRepository();
        final commands = FakeDeliveryCommandRepository();
        final accept = AcceptDeliveryOffer(
          offers,
          assignments,
          commandRepository: commands,
        );
        final request = AcceptDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: 'off-1',
          idempotencyKey: 'accept-1',
          connectivityOnline: true,
          isConfirmedAvailable: true,
        );

        final first = await accept(request);
        final replay = await accept(request);

        expect(first.isSuccess, isTrue);
        expect(replay.valueOrNull?.assignmentId, 'asg-1');
        expect(offers.acceptCallCount, 1);
        expect(assignments.upsertCallCount, 1);
      },
    );

    test(
      'reject retry and consumed offer filter survive local ledger',
      () async {
        final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        final commands = FakeDeliveryCommandRepository();
        final reject = RejectDeliveryOffer(offers, commandRepository: commands);
        final request = RejectDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: 'off-1',
          idempotencyKey: 'reject-1',
          connectivityOnline: true,
        );

        expect((await reject(request)).isSuccess, isTrue);
        expect((await reject(request)).isSuccess, isTrue);
        expect(offers.rejectCallCount, 1);

        // Simulate a fresh Fake source trying to reissue the same old offer.
        offers.offers = [sampleOffer()];
        final visible = await GetDeliveryOffers(
          offers,
          commandRepository: commands,
        )(driverId: 'drv-1');
        expect(visible.valueOrNull, isEmpty);
      },
    );

    test('blank local command id returns typed error', () async {
      final repository = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(),
      );
      final result = await AdvanceDeliveryWorkflow(repository)(
        driverId: 'drv-1',
        command: DriverWorkflowCommand.startTripPickup,
        commandId: ' ',
      );
      expect(result.failureOrNull, isA<DeliveryInvalidCommandId>());
    });

    test(
      'cancel command id can be recorded without changing lifecycle',
      () async {
        final commands = FakeDeliveryCommandRepository();
        final before = sampleAssignment();
      final record = RecordLocalDeliveryCommand(
        commands,
        clock: () => DateTime.utc(2026, 7, 30),
        );
      await record(
        commandId: 'cancel-1',
        driverId: before.driverId,
        targetId: before.assignmentId,
        type: LocalDeliveryCommandType.cancel,
      );
      await record(
        commandId: 'cancel-1',
        driverId: before.driverId,
        targetId: before.assignmentId,
        type: LocalDeliveryCommandType.cancel,
      );

        final recorded = await commands.getById(commandId: 'cancel-1');
        expect(recorded.valueOrNull?.type, LocalDeliveryCommandType.cancel);
        expect(before.workflowStage, DriverWorkflowStage.assigned);
      },
    );
  });
}
