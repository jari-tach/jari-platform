import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/policies/driver_workflow_transition_policy.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/advance_delivery_workflow.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/verify_delivery_code.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';

void main() {
  group('DriverWorkflowTransitionPolicy', () {
    const policy = DriverWorkflowTransitionPolicy();

    test('happy path assigned → summary milestones', () {
      var stage = DriverWorkflowStage.assigned;
      final steps = <DriverWorkflowCommand>[
        DriverWorkflowCommand.startTripPickup,
        DriverWorkflowCommand.arrivedPickup,
        DriverWorkflowCommand.waitAtPickup,
        DriverWorkflowCommand.confirmPickup,
        DriverWorkflowCommand.startTripCustomer,
        DriverWorkflowCommand.arrivedCustomer,
        DriverWorkflowCommand.startVerify,
        DriverWorkflowCommand.completeDelivery,
        DriverWorkflowCommand.showSummary,
      ];
      for (final command in steps) {
        final result = policy.evaluate(current: stage, command: command);
        expect(result.failure, isNull, reason: command.name);
        stage = result.next!;
      }
      expect(stage, DriverWorkflowStage.summary);
    });

    test('deny invalid jump', () {
      final result = policy.evaluate(
        current: DriverWorkflowStage.assigned,
        command: DriverWorkflowCommand.confirmPickup,
      );
      expect(result.failure, isNotNull);
    });

    test('confirmPickup maps status to pickedUp', () {
      expect(
        policy.statusForStage(
          DriverWorkflowStage.collected,
          DeliveryStatus.accepted,
        ),
        DeliveryStatus.pickedUp,
      );
    });
  });

  group('AdvanceDeliveryWorkflow + VerifyDeliveryCode', () {
    test(
      'full Fake path persists stages then verify reaches summary',
      () async {
        final repo = FakeDeliveryAssignmentRepository(
          active: sampleAssignment(),
        );
        final advance = AdvanceDeliveryWorkflow(repo);
        final verify = VerifyDeliveryCode(repo);

        Future<void> step(DriverWorkflowCommand command) async {
          final result = await advance(driverId: 'drv-1', command: command);
          expect(result.isFailure, isFalse, reason: command.name);
        }

        await step(DriverWorkflowCommand.startTripPickup);
        await step(DriverWorkflowCommand.arrivedPickup);
        await step(DriverWorkflowCommand.waitAtPickup);
        await step(DriverWorkflowCommand.confirmPickup);
        await step(DriverWorkflowCommand.startTripCustomer);
        await step(DriverWorkflowCommand.arrivedCustomer);
        await step(DriverWorkflowCommand.startVerify);

        final verified = await verify(driverId: 'drv-1', code: '1234');
        expect(verified.isFailure, isFalse);
        expect(
          verified.valueOrNull!.workflowStage,
          DriverWorkflowStage.summary,
        );
        expect(verified.valueOrNull!.status, DeliveryStatus.delivered);
      },
    );

    test('wrong verify code fails', () async {
      final repo = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(workflowStage: DriverWorkflowStage.verifying),
      );
      final verify = VerifyDeliveryCode(repo);
      final result = await verify(driverId: 'drv-1', code: '0000');
      expect(result.isFailure, isTrue);
    });
  });
}
