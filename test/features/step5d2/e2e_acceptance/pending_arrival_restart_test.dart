/// STEP 5D-2 acceptance — pending automatic (geofence) arrival survives a
/// restart: the original evidence payload and Idempotency-Key are preserved,
/// delivery confirmation stays locked until the Backend acknowledgment.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import 'step5d2_e2e_helpers.dart';

void main() {
  const commandId = 'cmd-arrival-restart-1';
  const clientEventId = 'evt-geofence-restart-1';

  test('geofence event offline → restart → replay: Backend once, verifying '
      'unlocks only after ack', () async {
    final h = makeHarness(
      active: enRouteAssignment(),
      backendState: CanonicalDeliveryStates.enRouteToCustomer,
    );
    final evidence = sampleEvidence(clientEventId: clientEventId);

    // 1. Geofence arrival reported offline: pending command records the
    //    clientEventId + fixed Idempotency-Key + full original payload.
    final offline = await reportArrivalOf(h)(
      driverId: 'drv-1',
      commandId: commandId,
      evidence: evidence,
      connectivityOnline: false,
    );
    expect(offline.failureOrNull, isA<DeliveryNetworkUnavailable>());
    expect(h.lifecycle.mutations, isEmpty);

    final pending = h.commands.commands[commandId];
    expect(pending, isNotNull);
    expect(pending!.status, LocalDeliveryCommandStatus.pendingSync);
    expect(pending.type, LocalDeliveryCommandType.reportArrival);
    expect(pending.payload?['clientEventId'], clientEventId);
    expect(
      pending.payload?['capturedAt'],
      evidence.capturedAt.toIso8601String(),
    );
    expect(pending.payload?['latitude'], evidence.latitude);
    expect(pending.payload?['longitude'], evidence.longitude);
    expect(pending.payload?['accuracyMeters'], evidence.accuracyMeters);
    expect(pending.payload?['policyVersion'], evidence.policyVersion);

    // 2. Delivery confirmation is locked while the arrival ack is missing.
    final locked = await confirmDeliveryOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-confirm-too-early',
    );
    expect(locked.failureOrNull, isA<InvalidDeliveryWorkflowTransition>());
    expect(
      h.assignments.active?.workflowStage,
      DriverWorkflowStage.navToCustomer,
    );

    // 3. "Restart" (fresh use-case instances) and replay from the ledger.
    final replayed = await replayOf(h)(driverId: 'drv-1');
    expect(replayed.isSuccess, isTrue);
    final assignment = replayed.valueOrNull!;
    expect(assignment.workflowStage, DriverWorkflowStage.verifying);
    expect(assignment.pendingSync, isFalse);

    // 4. Backend executed exactly once with the preserved identity.
    final arrivals = h.lifecycle.mutationsOf('reportAutomaticArrival');
    expect(arrivals, hasLength(1));
    expect(arrivals.single.idempotencyKey, commandId);
    expect(arrivals.single.clientEventId, clientEventId);

    final ack = (await h.backend.getActiveDelivery()).valueOrNull;
    expect(ack?.state, CanonicalDeliveryStates.arrivedAutomaticallyByLocation);
    expect(ack?.aggregateVersion, 1);

    expect(
      h.commands.commands[commandId]?.status,
      LocalDeliveryCommandStatus.completed,
    );

    // 5. Verifying is unlocked now — the confirmation gate opened only after
    //    the Backend acknowledged the automatic arrival.
    final confirm = await confirmDeliveryOf(h)(
      driverId: 'drv-1',
      commandId: 'cmd-confirm-after-ack',
    );
    expect(confirm.isSuccess, isTrue);
    expect(confirm.valueOrNull?.workflowStage, DriverWorkflowStage.summary);
  });

  test('duplicate completed arrival command replays as a no-op', () async {
    final h = makeHarness(
      active: enRouteAssignment(),
      backendState: CanonicalDeliveryStates.enRouteToCustomer,
    );
    await reportArrivalOf(h)(
      driverId: 'drv-1',
      commandId: commandId,
      evidence: sampleEvidence(clientEventId: clientEventId),
      connectivityOnline: false,
    );

    final first = await replayOf(h)(driverId: 'drv-1');
    expect(first.isSuccess, isTrue);
    expect(h.lifecycle.mutationsOf('reportAutomaticArrival'), hasLength(1));

    // Restart again: the completed command must not hit the Backend again.
    final second = await replayOf(h)(driverId: 'drv-1');
    expect(second.isSuccess, isTrue);
    expect(h.lifecycle.mutationsOf('reportAutomaticArrival'), hasLength(1));
    final ack = (await h.backend.getActiveDelivery()).valueOrNull;
    expect(ack?.aggregateVersion, 1);
  });

  test('pending command with a corrupted payload fails replay as a typed '
      'contract violation', () async {
    final h = makeHarness(
      active: enRouteAssignment(),
      backendState: CanonicalDeliveryStates.enRouteToCustomer,
    );
    h.commands.commands[commandId] = LocalDeliveryCommand(
      commandId: commandId,
      driverId: 'drv-1',
      targetId: 'asg-1',
      type: LocalDeliveryCommandType.reportArrival,
      status: LocalDeliveryCommandStatus.pendingSync,
      recordedAt: DateTime.utc(2026, 7, 30, 9),
      payload: const {'clientEventId': 'evt-x'}, // evidence fields missing
    );

    final replayed = await replayOf(h)(driverId: 'drv-1');
    expect(replayed.failureOrNull, isA<DeliveryContractViolation>());
    expect(h.lifecycle.mutations, isEmpty);
  });
}
