/// STEP 5D-2 acceptance — pending pickup survives a restart and replays
/// exactly once with the same Idempotency-Key from the Local Command Ledger.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import 'step5d2_e2e_helpers.dart';

void main() {
  const commandId = 'cmd-pickup-restart-1';

  test('offline pickup → restart → replay: Backend executes once, contact '
      'reveals only after ack', () async {
    final h = makeHarness(active: waitingPickupAssignment(), withContact: true);

    // 1. Pickup attempted offline: saved pending with the created command id.
    final offline = await confirmPickupOf(h)(
      driverId: 'drv-1',
      commandId: commandId,
      notes: 'gate 3',
      connectivityOnline: false,
    );
    expect(offline.failureOrNull, isA<DeliveryNetworkUnavailable>());

    final pending = h.commands.commands[commandId];
    expect(pending, isNotNull);
    expect(pending!.status, LocalDeliveryCommandStatus.pendingSync);
    expect(pending.type, LocalDeliveryCommandType.confirmPickup);
    expect(h.assignments.active?.pendingSync, isTrue);
    // No Backend mutation happened while offline.
    expect(h.lifecycle.mutations, isEmpty);

    // 2. Contact stays hidden while the pickup is pending.
    final hiddenContact = await getContactOf(h)(driverId: 'drv-1');
    expect(hiddenContact.failureOrNull, isA<DeliveryContactNotAvailable>());

    // 3. "Restart": brand-new use-case instances share the same command
    //    ledger + assignment repository; the SAME command id is restored.
    final restored = await h.commands.listPending(driverId: 'drv-1');
    expect(
      restored.valueOrNull?.map((c) => c.commandId),
      [commandId],
      reason: 'restart must restore the identical command id',
    );

    final replayed = await replayOf(h)(driverId: 'drv-1');
    expect(replayed.isSuccess, isTrue);
    final assignment = replayed.valueOrNull!;
    expect(assignment.workflowStage, DriverWorkflowStage.navToCustomer);
    expect(assignment.pendingSync, isFalse);

    // 4. Backend executed exactly once, with the original Idempotency-Key.
    final pickupMutations = h.lifecycle.mutationsOf('confirmPickup');
    expect(pickupMutations, hasLength(1));
    expect(pickupMutations.single.idempotencyKey, commandId);
    expect(pickupMutations.single.aggregateVersion, 0);

    final ack = (await h.backend.getActiveDelivery()).valueOrNull;
    expect(ack?.state, CanonicalDeliveryStates.pickupConfirmedManually);
    expect(ack?.aggregateVersion, 1);

    // A duplicate submission with the stale version would now conflict —
    // proof the aggregate advanced exactly once.
    final duplicate = await h.backend.confirmPickup(
      deliveryId: 'asg-1',
      aggregateVersion: 0,
      idempotencyKey: commandId,
    );
    expect(duplicate.failureOrNull, isA<DeliveryConflict>());

    // 5. The ledger entry converted to synced (completed).
    expect(
      h.commands.commands[commandId]?.status,
      LocalDeliveryCommandStatus.completed,
    );

    // 6. Contact is revealed only after the Backend acknowledgment.
    //    (The Fake lifecycle wiped its memory copy on the earlier denial, so
    //    the Backend serves it again for the post-ack state.)
    h.backend.seedContact(sampleContact());
    final revealed = await getContactOf(h)(driverId: 'drv-1');
    expect(revealed.isSuccess, isTrue);
    expect(revealed.valueOrNull?.phoneNumber, '+966500000001');
  });

  test('replay is a no-op when the restored command is already '
      'completed', () async {
    final h = makeHarness(active: waitingPickupAssignment());

    final offline = await confirmPickupOf(h)(
      driverId: 'drv-1',
      commandId: commandId,
      connectivityOnline: false,
    );
    expect(offline.isFailure, isTrue);

    // First replay after restart syncs the command.
    final first = await replayOf(h)(driverId: 'drv-1');
    expect(first.isSuccess, isTrue);
    expect(h.lifecycle.mutationsOf('confirmPickup'), hasLength(1));

    // A second restart + replay finds no pending work and never re-posts.
    final second = await replayOf(h)(driverId: 'drv-1');
    expect(second.isSuccess, isTrue);
    expect(h.lifecycle.mutationsOf('confirmPickup'), hasLength(1));
    final ack = (await h.backend.getActiveDelivery()).valueOrNull;
    expect(ack?.aggregateVersion, 1);
  });

  test('replay refuses to run while still offline and keeps the pending '
      'command untouched', () async {
    final h = makeHarness(active: waitingPickupAssignment());
    await confirmPickupOf(h)(
      driverId: 'drv-1',
      commandId: commandId,
      connectivityOnline: false,
    );

    final stillOffline = await replayOf(h)(
      driverId: 'drv-1',
      connectivityOnline: false,
    );
    expect(stillOffline.failureOrNull, isA<DeliveryNetworkUnavailable>());
    expect(
      h.commands.commands[commandId]?.status,
      LocalDeliveryCommandStatus.pendingSync,
    );
    expect(h.lifecycle.mutations, isEmpty);
  });
}
