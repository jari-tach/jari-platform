/// STEP 5D-2 acceptance — pending delivery confirmation survives a restart:
/// the delivery is never closed locally before the Backend acknowledgment,
/// and the customer contact is cleared only after the ack.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import 'step5d2_e2e_helpers.dart';

void main() {
  const commandId = 'cmd-confirm-restart-1';

  test('offline confirmation → restart → replay: close only after ack and '
      'clear contact', () async {
    final h = makeHarness(
      active: verifyingAssignment(),
      backendState: CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
      withContact: true,
    );
    expect(h.backend.cachedCustomerContact, isNotNull);

    // 1. Confirmation attempted offline: pending, delivery NOT closed.
    final offline = await confirmDeliveryOf(h)(
      driverId: 'drv-1',
      commandId: commandId,
      connectivityOnline: false,
    );
    expect(offline.failureOrNull, isA<DeliveryNetworkUnavailable>());
    expect(h.lifecycle.mutations, isEmpty);

    final pending = h.commands.commands[commandId];
    expect(pending?.status, LocalDeliveryCommandStatus.pendingSync);
    expect(pending?.type, LocalDeliveryCommandType.confirmDelivery);

    final stored = h.assignments.active;
    expect(stored, isNotNull, reason: 'must not close locally while pending');
    expect(stored!.workflowStage, DriverWorkflowStage.verifying);
    expect(stored.pendingSync, isTrue);
    expect(h.assignments.clearCallCount, 0);

    // Contact is not exposed while the confirmation is pending.
    final hidden = await getContactOf(h)(driverId: 'drv-1');
    expect(hidden.failureOrNull, isA<DeliveryContactNotAvailable>());

    // 2. "Restart" with fresh use-case instances, then replay.
    final replayed = await replayOf(h)(driverId: 'drv-1');
    expect(replayed.isSuccess, isTrue);
    final assignment = replayed.valueOrNull!;
    expect(assignment.workflowStage, DriverWorkflowStage.summary);
    expect(assignment.pendingSync, isFalse);

    // 3. Backend executed exactly once with the original Idempotency-Key.
    final confirmations = h.lifecycle.mutationsOf('confirmDelivery');
    expect(confirmations, hasLength(1));
    expect(confirmations.single.idempotencyKey, commandId);

    final ack = (await h.backend.getActiveDelivery()).valueOrNull;
    expect(ack?.state, CanonicalDeliveryStates.deliveredConfirmedManually);
    expect(ack?.aggregateVersion, 1);

    expect(
      h.commands.commands[commandId]?.status,
      LocalDeliveryCommandStatus.completed,
    );

    // 4. Contact cleared after the acknowledged completion.
    expect(h.backend.cachedCustomerContact, isNull);
    final afterDelivery = await getContactOf(h)(driverId: 'drv-1');
    expect(afterDelivery.failureOrNull, isA<DeliveryContactNotAvailable>());
  });

  test('second replay after the ack never re-confirms the delivery', () async {
    final h = makeHarness(
      active: verifyingAssignment(),
      backendState: CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
    );
    await confirmDeliveryOf(h)(
      driverId: 'drv-1',
      commandId: commandId,
      connectivityOnline: false,
    );

    final first = await replayOf(h)(driverId: 'drv-1');
    expect(first.isSuccess, isTrue);
    expect(h.lifecycle.mutationsOf('confirmDelivery'), hasLength(1));

    final second = await replayOf(h)(driverId: 'drv-1');
    expect(second.isSuccess, isTrue);
    expect(h.lifecycle.mutationsOf('confirmDelivery'), hasLength(1));
    final ack = (await h.backend.getActiveDelivery()).valueOrNull;
    expect(ack?.aggregateVersion, 1);
  });
}
