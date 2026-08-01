import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/delivery/data/fake/fake_delivery_lifecycle_repository.dart';
import 'package:saeq_driver/features/delivery/data/models/batch_summary_wire.dart';
import 'package:saeq_driver/features/delivery/domain/entities/batch_summary.dart';
import 'package:saeq_driver/features/delivery/domain/entities/customer_contact.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/policies/driver_workflow_transition_policy.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/cancel_delivery_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/confirm_delivery_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/confirm_pickup_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_batch.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_customer_contact.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/replay_pending_delivery_commands.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/report_automatic_arrival_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/report_delivery_issue_remote.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/active_delivery_page.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/state/delivery_controller_state.dart';

import '../delivery/helpers/delivery_fixtures.dart';
import '../delivery/helpers/fake_delivery_assignment_repository.dart';
import '../delivery/helpers/fake_delivery_command_repository.dart';

typedef Step5dHarness = ({
  FakeDeliveryLifecycleRepository lifecycle,
  FakeDeliveryAssignmentRepository assignments,
  FakeDeliveryCommandRepository commands,
});

void main() {
  CustomerContact sampleContact({String deliveryId = 'asg-1'}) =>
      CustomerContact(
        deliveryId: deliveryId,
        name: 'Customer One',
        phoneNumber: '+966500000001',
        availableUntil: DateTime.utc(2026, 7, 26, 12),
      );

  ArrivalEvidence sampleEvidence() => ArrivalEvidence(
    clientEventId: 'evt-1',
    capturedAt: DateTime.utc(2026, 7, 26, 11),
    latitude: 24.72,
    longitude: 46.68,
    accuracyMeters: 8,
    policyVersion: 'geofence-v1',
  );

  Step5dHarness makeHarness({
    DeliveryAssignment? active,
    String backendState =
        CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
    int backendVersion = 0,
    bool withContact = false,
  }) {
    final lifecycle = FakeDeliveryLifecycleRepository();
    if (active != null) {
      lifecycle.seedActive(
        DeliveryLifecycleAck(
          deliveryId: active.assignmentId,
          state: backendState,
          aggregateVersion: backendVersion,
          updatedAt: DateTime.utc(2026, 7, 26, 10),
        ),
      );
    }
    if (withContact) {
      lifecycle.seedContact(
        sampleContact(deliveryId: active?.assignmentId ?? 'asg-1'),
      );
    }
    return (
      lifecycle: lifecycle,
      assignments: FakeDeliveryAssignmentRepository(active: active),
      commands: FakeDeliveryCommandRepository(),
    );
  }

  ConfirmPickupRemote confirmPickupOf(Step5dHarness h) => ConfirmPickupRemote(
    lifecycleRepository: h.lifecycle,
    assignmentRepository: h.assignments,
    commandRepository: h.commands,
  );

  ReportAutomaticArrivalRemote reportArrivalOf(Step5dHarness h) =>
      ReportAutomaticArrivalRemote(
        lifecycleRepository: h.lifecycle,
        assignmentRepository: h.assignments,
        commandRepository: h.commands,
      );

  ConfirmDeliveryRemote confirmDeliveryOf(Step5dHarness h) =>
      ConfirmDeliveryRemote(
        lifecycleRepository: h.lifecycle,
        assignmentRepository: h.assignments,
        commandRepository: h.commands,
      );

  CancelDeliveryRemote cancelDeliveryOf(Step5dHarness h) =>
      CancelDeliveryRemote(
        lifecycleRepository: h.lifecycle,
        assignmentRepository: h.assignments,
        commandRepository: h.commands,
      );

  ReportDeliveryIssueRemote reportIssueOf(Step5dHarness h) =>
      ReportDeliveryIssueRemote(
        lifecycleRepository: h.lifecycle,
        assignmentRepository: h.assignments,
        commandRepository: h.commands,
      );

  GetCustomerContact getContactOf(Step5dHarness h) => GetCustomerContact(
    lifecycleRepository: h.lifecycle,
    assignmentRepository: h.assignments,
  );

  ReplayPendingDeliveryCommands replayOf(Step5dHarness h) =>
      ReplayPendingDeliveryCommands(
        commandRepository: h.commands,
        assignmentRepository: h.assignments,
        confirmPickup: confirmPickupOf(h),
        reportArrival: reportArrivalOf(h),
        confirmDelivery: confirmDeliveryOf(h),
      );

  DeliveryAssignment waitingPickupAssignment() => sampleAssignment(
    workflowStage: DriverWorkflowStage.waitingPickup,
    status: DeliveryStatus.accepted,
    serverRevision: '0',
  );

  DeliveryAssignment enRouteAssignment() => sampleAssignment(
    workflowStage: DriverWorkflowStage.navToCustomer,
    status: DeliveryStatus.pickedUp,
    serverRevision: '0',
  );

  DeliveryAssignment verifyingAssignment() => sampleAssignment(
    workflowStage: DriverWorkflowStage.verifying,
    status: DeliveryStatus.pickedUp,
    serverRevision: '0',
  );

  group('ConfirmPickupRemote', () {
    test(
      'success advances local stage to en route and clears pending',
      () async {
        final h = makeHarness(active: waitingPickupAssignment());
        final result = await confirmPickupOf(h)(
          driverId: 'drv-1',
          commandId: 'cmd-cp',
        );

        expect(result.isSuccess, isTrue);
        final assignment = result.valueOrNull!;
        expect(assignment.workflowStage, DriverWorkflowStage.navToCustomer);
        expect(assignment.status, DeliveryStatus.pickedUp);
        expect(assignment.pendingSync, isFalse);
        expect(assignment.serverRevision, '1');

        final command = h.commands.commands['cmd-cp'];
        expect(command, isNotNull);
        expect(command!.status, LocalDeliveryCommandStatus.completed);
        expect(command.type, LocalDeliveryCommandType.confirmPickup);

        final ack = (await h.lifecycle.getActiveDelivery()).valueOrNull;
        expect(ack?.state, CanonicalDeliveryStates.pickupConfirmedManually);
        expect(ack?.aggregateVersion, 1);
      },
    );

    test(
      'offline saves pending command with same commandId and hides contact',
      () async {
        final h = makeHarness(
          active: waitingPickupAssignment(),
          withContact: true,
        );
        final result = await confirmPickupOf(h)(
          driverId: 'drv-1',
          commandId: 'cmd-cp',
          connectivityOnline: false,
        );

        expect(result.failureOrNull, isA<DeliveryNetworkUnavailable>());

        final command = h.commands.commands['cmd-cp'];
        expect(command, isNotNull);
        expect(command!.status, LocalDeliveryCommandStatus.pendingSync);
        expect(command.type, LocalDeliveryCommandType.confirmPickup);

        final stored = h.assignments.active!;
        expect(stored.pendingSync, isTrue);
        expect(stored.workflowStage, DriverWorkflowStage.waitingPickup);

        // Contact path stays hidden while pendingSync is true.
        final contact = await getContactOf(h)(driverId: 'drv-1');
        expect(contact.failureOrNull, isA<DeliveryContactNotAvailable>());
      },
    );

    test('Backend ack is required before contact is allowed', () async {
      final h = makeHarness(
        active: waitingPickupAssignment(),
        withContact: true,
      );

      final before = await getContactOf(h)(driverId: 'drv-1');
      expect(before.failureOrNull, isA<DeliveryContactNotAvailable>());

      final pickup = await confirmPickupOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-cp',
      );
      expect(pickup.isSuccess, isTrue);

      // Re-seed: the Fake lifecycle clears its memory cache on denial above.
      h.lifecycle.seedContact(sampleContact());
      final after = await getContactOf(h)(driverId: 'drv-1');
      expect(after.isSuccess, isTrue);
      expect(after.valueOrNull?.phoneNumber, '+966500000001');
    });
  });

  group('ReportAutomaticArrivalRemote', () {
    test('success unlocks verifying after Backend ack', () async {
      final h = makeHarness(
        active: enRouteAssignment(),
        backendState: CanonicalDeliveryStates.enRouteToCustomer,
      );
      final result = await reportArrivalOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-arr',
        evidence: sampleEvidence(),
      );

      expect(result.isSuccess, isTrue);
      final assignment = result.valueOrNull!;
      expect(assignment.workflowStage, DriverWorkflowStage.verifying);
      expect(assignment.pendingSync, isFalse);

      final command = h.commands.commands['cmd-arr'];
      expect(command?.status, LocalDeliveryCommandStatus.completed);
      expect(command?.type, LocalDeliveryCommandType.reportArrival);

      final ack = (await h.lifecycle.getActiveDelivery()).valueOrNull;
      expect(
        ack?.state,
        CanonicalDeliveryStates.arrivedAutomaticallyByLocation,
      );
    });

    test('offline keeps pending and does not advance to verifying', () async {
      final h = makeHarness(
        active: enRouteAssignment(),
        backendState: CanonicalDeliveryStates.enRouteToCustomer,
      );
      final result = await reportArrivalOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-arr',
        evidence: sampleEvidence(),
        connectivityOnline: false,
      );

      expect(result.failureOrNull, isA<DeliveryNetworkUnavailable>());
      expect(
        h.commands.commands['cmd-arr']?.status,
        LocalDeliveryCommandStatus.pendingSync,
      );
      final stored = h.assignments.active!;
      expect(stored.workflowStage, DriverWorkflowStage.navToCustomer);
      expect(stored.pendingSync, isTrue);
    });

    test('duplicate completed command is idempotent', () async {
      final h = makeHarness(
        active: enRouteAssignment(),
        backendState: CanonicalDeliveryStates.enRouteToCustomer,
      );
      h.commands.commands['cmd-arr'] = LocalDeliveryCommand(
        commandId: 'cmd-arr',
        driverId: 'drv-1',
        targetId: 'asg-1',
        type: LocalDeliveryCommandType.reportArrival,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: DateTime.utc(2026, 7, 26, 10, 30),
      );

      final result = await reportArrivalOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-arr',
        evidence: sampleEvidence(),
      );

      expect(result.isSuccess, isTrue);
      // No second Backend mutation and no local stage change.
      final ack = (await h.lifecycle.getActiveDelivery()).valueOrNull;
      expect(ack?.aggregateVersion, 0);
      expect(ack?.state, CanonicalDeliveryStates.enRouteToCustomer);
      expect(h.assignments.upserted, isEmpty);
      expect(
        h.assignments.active?.workflowStage,
        DriverWorkflowStage.navToCustomer,
      );
    });
  });

  group('ConfirmDeliveryRemote', () {
    test('success clears contact via lifecycle.clearCustomerContact', () async {
      final h = makeHarness(
        active: verifyingAssignment(),
        backendState:
            CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
        withContact: true,
      );
      expect(h.lifecycle.cachedCustomerContact, isNotNull);

      final result = await confirmDeliveryOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-cd',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.workflowStage, DriverWorkflowStage.summary);
      expect(h.lifecycle.cachedCustomerContact, isNull);
      expect(
        h.commands.commands['cmd-cd']?.status,
        LocalDeliveryCommandStatus.completed,
      );
    });

    test('offline pending does not close the assignment locally', () async {
      final h = makeHarness(
        active: verifyingAssignment(),
        backendState:
            CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
      );
      final result = await confirmDeliveryOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-cd',
        connectivityOnline: false,
      );

      expect(result.failureOrNull, isA<DeliveryNetworkUnavailable>());
      expect(
        h.commands.commands['cmd-cd']?.status,
        LocalDeliveryCommandStatus.pendingSync,
      );
      final stored = h.assignments.active;
      expect(stored, isNotNull);
      expect(stored!.workflowStage, DriverWorkflowStage.verifying);
      expect(stored.pendingSync, isTrue);
      expect(h.assignments.clearCallCount, 0);
    });
  });

  group('CancelDeliveryRemote', () {
    test('clears contact and assignment', () async {
      final h = makeHarness(
        active: enRouteAssignment(),
        backendState: CanonicalDeliveryStates.enRouteToCustomer,
        withContact: true,
      );
      final result = await cancelDeliveryOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-cancel',
        reasonCode: 'customer_request',
      );

      expect(result.isSuccess, isTrue);
      expect(h.lifecycle.cachedCustomerContact, isNull);
      expect(h.assignments.active, isNull);
      expect(h.assignments.clearedDriverIds, ['drv-1']);
      final command = h.commands.commands['cmd-cancel'];
      expect(command?.type, LocalDeliveryCommandType.cancel);
      expect(command?.status, LocalDeliveryCommandStatus.completed);
    });
  });

  group('GetCustomerContact', () {
    test('hidden before pickup even when a contact is cached', () async {
      final h = makeHarness(
        active: waitingPickupAssignment(),
        withContact: true,
      );
      final result = await getContactOf(h)(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryContactNotAvailable>());
      expect(h.lifecycle.cachedCustomerContact, isNull);
    });

    test('hidden during pendingSync', () async {
      final h = makeHarness(
        active: enRouteAssignment().copyWith(pendingSync: true),
        withContact: true,
      );
      final result = await getContactOf(h)(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryContactNotAvailable>());
      expect(h.lifecycle.cachedCustomerContact, isNull);
    });

    test('allowed after collected with Backend-allowed state', () async {
      final h = makeHarness(
        active: sampleAssignment(
          workflowStage: DriverWorkflowStage.collected,
          status: DeliveryStatus.pickedUp,
          serverRevision: '1',
        ),
        withContact: true,
      );
      final result = await getContactOf(h)(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.name, 'Customer One');
    });

    test('allowed while en route to customer', () async {
      final h = makeHarness(active: enRouteAssignment(), withContact: true);
      final result = await getContactOf(h)(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.phoneNumber, '+966500000001');
    });

    test(
      'returns DeliveryContactNotAvailable after delivery completes',
      () async {
        final h = makeHarness(
          active: sampleAssignment(
            workflowStage: DriverWorkflowStage.summary,
            status: DeliveryStatus.delivered,
            serverRevision: '3',
          ),
          withContact: true,
        );
        final result = await getContactOf(h)(driverId: 'drv-1');
        expect(result.failureOrNull, isA<DeliveryContactNotAvailable>());
      },
    );

    test(
      'returns DeliveryContactNotAvailable while an issue is open',
      () async {
        final h = makeHarness(
          active: sampleAssignment(
            workflowStage: DriverWorkflowStage.issueOpen,
            status: DeliveryStatus.pickedUp,
            serverRevision: '1',
            resumeAfterIssueStage: DriverWorkflowStage.navToCustomer,
          ),
          withContact: true,
        );
        final result = await getContactOf(h)(driverId: 'drv-1');
        expect(result.failureOrNull, isA<DeliveryContactNotAvailable>());
      },
    );
  });

  group('ReplayPendingDeliveryCommands', () {
    test(
      'replays pending confirmPickup with same commandId once connectivity returns',
      () async {
        final h = makeHarness(active: waitingPickupAssignment());

        final offline = await confirmPickupOf(h)(
          driverId: 'drv-1',
          commandId: 'cmd-cp',
          connectivityOnline: false,
        );
        expect(offline.failureOrNull, isA<DeliveryNetworkUnavailable>());
        expect(
          h.commands.commands['cmd-cp']?.status,
          LocalDeliveryCommandStatus.pendingSync,
        );

        final replayed = await replayOf(h)(driverId: 'drv-1');
        expect(replayed.isSuccess, isTrue);
        final assignment = replayed.valueOrNull!;
        expect(assignment.workflowStage, DriverWorkflowStage.navToCustomer);
        expect(assignment.pendingSync, isFalse);
        expect(
          h.commands.commands['cmd-cp']?.status,
          LocalDeliveryCommandStatus.completed,
        );

        // The Backend mutation ran exactly once with the same idempotency key.
        final ack = (await h.lifecycle.getActiveDelivery()).valueOrNull;
        expect(ack?.aggregateVersion, 1);

        // A second replay finds no pending commands and mutates nothing.
        final again = await replayOf(h)(driverId: 'drv-1');
        expect(again.isSuccess, isTrue);
        final ackAfter = (await h.lifecycle.getActiveDelivery()).valueOrNull;
        expect(ackAfter?.aggregateVersion, 1);
      },
    );

    test('refuses to replay while still offline', () async {
      final h = makeHarness(active: waitingPickupAssignment());
      await confirmPickupOf(h)(
        driverId: 'drv-1',
        commandId: 'cmd-cp',
        connectivityOnline: false,
      );

      final result = await replayOf(h)(
        driverId: 'drv-1',
        connectivityOnline: false,
      );
      expect(result.failureOrNull, isA<DeliveryNetworkUnavailable>());
      expect(
        h.commands.commands['cmd-cp']?.status,
        LocalDeliveryCommandStatus.pendingSync,
      );
    });
  });

  group('DeliveryController remote path', () {
    Future<ProviderContainer> bootRemote(Step5dHarness h) async {
      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getActiveReader: (_) => GetActiveDelivery(h.assignments),
              driverIdReader: (_) => 'drv-1',
              acceptPreconditionsReader: (_) =>
                  const DeliveryAcceptPreconditions(
                    connectivityOnline: true,
                    isConfirmedAvailable: true,
                  ),
              availabilityRefreshReader: (_) async {},
              confirmPickupReader: (_) => confirmPickupOf(h),
              reportArrivalReader: (_) => reportArrivalOf(h),
              confirmDeliveryReader: (_) => confirmDeliveryOf(h),
              cancelDeliveryReader: (_) => cancelDeliveryOf(h),
              reportIssueReader: (_) => reportIssueOf(h),
              getCustomerContactReader: (_) => getContactOf(h),
              getActiveBatchReader: (_) => GetActiveBatch(h.lifecycle),
              replayPendingReader: (_) => replayOf(h),
              clearCustomerContactReader: (Ref _, {String? deliveryId}) =>
                  h.lifecycle.clearCustomerContact(deliveryId: deliveryId),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(deliveryControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return container;
    }

    Future<DriverWorkflowStage?> pollForStage(
      ProviderContainer container,
      DriverWorkflowStage want,
    ) async {
      DriverWorkflowStage? stage;
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        stage = container
            .read(deliveryControllerProvider)
            .activeAssignment
            ?.workflowStage;
        if (stage == want) break;
      }
      return stage;
    }

    test('confirmPickup uses ConfirmPickupRemote and automatic arrival uses '
        'ReportAutomaticArrivalRemote', () async {
      final h = makeHarness(
        active: waitingPickupAssignment(),
        withContact: true,
      );
      final container = await bootRemote(h);
      // Boot legitimately denied + wiped the cached contact (pre-pickup).
      // Re-seed it: the Backend serves contact only after the pickup ack.
      h.lifecycle.seedContact(sampleContact());

      await container
          .read(deliveryControllerProvider.notifier)
          .advanceWorkflow(DriverWorkflowCommand.confirmPickup);

      // Order has no dropoff coordinates, so the automatic arrival applies
      // immediately after the Backend pickup acknowledgment.
      final stage = await pollForStage(
        container,
        DriverWorkflowStage.verifying,
      );
      expect(stage, DriverWorkflowStage.verifying);
      // Let the post-arrival contact soft-refresh settle.
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(
        h.commands.commands['local_drv-1_asg-1_confirmPickup']?.status,
        LocalDeliveryCommandStatus.completed,
      );
      expect(
        h.commands.commands['local_drv-1_asg-1_reportArrival']?.status,
        LocalDeliveryCommandStatus.completed,
      );

      final ack = (await h.lifecycle.getActiveDelivery()).valueOrNull;
      expect(
        ack?.state,
        CanonicalDeliveryStates.arrivedAutomaticallyByLocation,
      );
      expect(ack?.aggregateVersion, 2);

      // PII: after the Backend pickup ack the seeded contact is exposed.
      final state = container.read(deliveryControllerProvider);
      expect(state.customerContact?.phoneNumber, '+966500000001');
      expect(state.isCustomerContactVisible, isTrue);
    });

    test(
      'verifyDeliveryCode routes to ConfirmDeliveryRemote and clears contact',
      () async {
        final h = makeHarness(
          active: verifyingAssignment(),
          backendState:
              CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
          withContact: true,
        );
        final container = await bootRemote(h);
        // Initialize soft-refresh loaded the contact for the verifying stage.
        expect(
          container.read(deliveryControllerProvider).customerContact,
          isNotNull,
        );

        await container
            .read(deliveryControllerProvider.notifier)
            .verifyDeliveryCode('123456');

        final state = container.read(deliveryControllerProvider);
        expect(state.status, DeliveryViewStatus.ready);
        expect(
          state.activeAssignment?.workflowStage,
          DriverWorkflowStage.summary,
        );
        expect(state.customerContact, isNull);
        expect(h.lifecycle.cachedCustomerContact, isNull);
        expect(
          h.commands.commands['local_drv-1_asg-1_confirm-delivery']?.status,
          LocalDeliveryCommandStatus.completed,
        );
      },
    );

    test('cancelActiveDelivery clears contact and assignment', () async {
      final h = makeHarness(
        active: enRouteAssignment(),
        backendState: CanonicalDeliveryStates.enRouteToCustomer,
        withContact: true,
      );
      final container = await bootRemote(h);

      await container
          .read(deliveryControllerProvider.notifier)
          .cancelActiveDelivery(reasonCode: 'customer_request');

      final state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.ready);
      expect(state.activeAssignment, isNull);
      expect(state.customerContact, isNull);
      expect(h.assignments.active, isNull);
      expect(h.lifecycle.cachedCustomerContact, isNull);
      expect(
        h.commands.commands['local_drv-1_asg-1_cancel']?.status,
        LocalDeliveryCommandStatus.completed,
      );
    });

    test(
      'reportIssueRemote reports via Backend and opens issue stage',
      () async {
        final h = makeHarness(
          active: enRouteAssignment(),
          backendState: CanonicalDeliveryStates.enRouteToCustomer,
        );
        final container = await bootRemote(h);

        await container
            .read(deliveryControllerProvider.notifier)
            .reportIssueRemote(
              code: 'customer_unreachable',
              notes: 'no answer',
            );

        final state = container.read(deliveryControllerProvider);
        expect(state.status, DeliveryViewStatus.ready);
        expect(
          state.activeAssignment?.workflowStage,
          DriverWorkflowStage.issueOpen,
        );
        final command = h.commands.commands['local_drv-1_asg-1_reportIssue'];
        expect(command?.status, LocalDeliveryCommandStatus.completed);
        expect(command?.type, LocalDeliveryCommandType.reportIssue);
      },
    );

    test('retryPendingSync uses ReplayPendingDeliveryCommands with the same '
        'commandId', () async {
      final h = makeHarness(
        active: waitingPickupAssignment(),
        withContact: true,
      );
      final container = await bootRemote(h);
      final controller = container.read(deliveryControllerProvider.notifier);

      await controller.advanceWorkflow(
        DriverWorkflowCommand.confirmPickup,
        simulateOffline: true,
      );

      var state = container.read(deliveryControllerProvider);
      expect(state.failure, isA<DeliveryNetworkUnavailable>());
      expect(state.activeAssignment?.pendingSync, isTrue);
      expect(
        h.commands.commands['local_drv-1_asg-1_confirmPickup']?.status,
        LocalDeliveryCommandStatus.pendingSync,
      );

      await controller.retryPendingSync();

      state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.ready);
      expect(state.activeAssignment?.pendingSync, isFalse);
      expect(
        state.activeAssignment?.workflowStage,
        DriverWorkflowStage.navToCustomer,
      );
      expect(
        h.commands.commands['local_drv-1_asg-1_confirmPickup']?.status,
        LocalDeliveryCommandStatus.completed,
      );
      // Replay reused the pending idempotency key: one Backend mutation.
      final ack = (await h.lifecycle.getActiveDelivery()).valueOrNull;
      expect(ack?.aggregateVersion, 1);
    });

    test('clearCustomerContactMemory purges memory-only contact', () async {
      final h = makeHarness(
        active: enRouteAssignment(),
        backendState: CanonicalDeliveryStates.enRouteToCustomer,
        withContact: true,
      );
      final container = await bootRemote(h);
      expect(
        container.read(deliveryControllerProvider).customerContact,
        isNotNull,
      );
      expect(h.lifecycle.cachedCustomerContact, isNotNull);

      container
          .read(deliveryControllerProvider.notifier)
          .clearCustomerContactMemory();

      expect(
        container.read(deliveryControllerProvider).customerContact,
        isNull,
      );
      expect(h.lifecycle.cachedCustomerContact, isNull);
    });
  });

  group('ActiveDeliveryPage (STEP 5D-1 widget checks)', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      required DeliveryAssignment assignment,
      FakeDeliveryLifecycleRepository? lifecycle,
    }) async {
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getActiveReader: (_) => GetActiveDelivery(assignments),
              driverIdReader: (_) => 'drv-1',
              availabilityRefreshReader: (_) async {},
              getCustomerContactReader: lifecycle == null
                  ? null
                  : (_) => GetCustomerContact(
                      lifecycleRepository: lifecycle,
                      assignmentRepository: assignments,
                    ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ActiveDeliveryPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }

    testWidgets('manual arrival button is absent while en route', (
      tester,
    ) async {
      await pumpPage(tester, assignment: enRouteAssignment());

      expect(find.byKey(const Key('manualArrivalButton')), findsNothing);
      expect(find.text('I arrived at customer'), findsNothing);
    });

    testWidgets('customer details hidden before pickup', (tester) async {
      await pumpPage(tester, assignment: waitingPickupAssignment());

      expect(
        find.byKey(ActiveDeliveryPage.customerDetailsHiddenKey),
        findsOneWidget,
      );
      expect(find.byKey(ActiveDeliveryPage.customerDetailsKey), findsNothing);
    });

    testWidgets('customer details hidden during pendingSync', (tester) async {
      await pumpPage(
        tester,
        assignment: enRouteAssignment().copyWith(pendingSync: true),
      );

      expect(
        find.byKey(ActiveDeliveryPage.customerDetailsHiddenKey),
        findsOneWidget,
      );
      expect(find.byKey(ActiveDeliveryPage.customerDetailsKey), findsNothing);
      expect(find.byKey(const Key('manualArrivalButton')), findsNothing);
    });

    testWidgets(
      'customer contact keys visible after Backend pickup ack with seeded '
      'contact',
      (tester) async {
        final lifecycle = FakeDeliveryLifecycleRepository()
          ..seedContact(sampleContact());
        await pumpPage(
          tester,
          assignment: enRouteAssignment(),
          lifecycle: lifecycle,
        );

        expect(
          find.byKey(const Key('activeDeliveryCustomerContactName')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('activeDeliveryCustomerContactPhone')),
          findsOneWidget,
        );
        expect(find.text('Customer One'), findsOneWidget);
        expect(find.text('+966500000001'), findsOneWidget);
      },
    );
  });

  group('Batch (STEP 5D-1)', () {
    test('GetActiveBatch returns the active batch summary', () async {
      final lifecycle = FakeDeliveryLifecycleRepository()
        ..seedBatch(
          BatchSummary(
            batchId: 'batch-1',
            currentStopSequence: 1,
            aggregateVersion: 3,
            stops: const [
              BatchStop(
                sequence: 1,
                deliveryId: 'asg-1',
                stopType: 'dropoff',
                label: 'Stop 1',
              ),
              BatchStop(
                sequence: 2,
                deliveryId: 'asg-2',
                stopType: 'dropoff',
                label: 'Stop 2',
              ),
            ],
          ),
        );

      final result = await GetActiveBatch(lifecycle)();
      expect(result.isSuccess, isTrue);
      final batch = result.valueOrNull!;
      expect(batch.batchId, 'batch-1');
      expect(batch.totalStops, 2);
      expect(batch.currentStop?.label, 'Stop 1');

      final byId = await GetActiveBatch(lifecycle).byId('batch-1');
      expect(byId.valueOrNull?.batchId, 'batch-1');
    });

    test('BatchSummaryWire flags upcoming stops carrying contact fields', () {
      final wire = BatchSummaryWire.fromJson({
        'batchId': 'batch-1',
        'currentStopSequence': 1,
        'aggregateVersion': 1,
        'stops': [
          {
            'sequence': 1,
            'deliveryId': 'asg-1',
            'stopType': 'dropoff',
            'label': 'Stop 1',
          },
          {
            'sequence': 2,
            'deliveryId': 'asg-2',
            'stopType': 'dropoff',
            'label': 'Stop 2',
            'phoneNumber': '+966500000009',
          },
        ],
      });
      expect(wire.upcomingStopsHaveContactFields, isTrue);
    });

    test('BatchSummaryWire flags upcoming customerName fields too', () {
      final wire = BatchSummaryWire.fromJson({
        'batchId': 'batch-1',
        'currentStopSequence': 1,
        'aggregateVersion': 1,
        'stops': [
          {
            'sequence': 2,
            'deliveryId': 'asg-2',
            'stopType': 'dropoff',
            'label': 'Stop 2',
            'customerName': 'Someone',
          },
        ],
      });
      expect(wire.upcomingStopsHaveContactFields, isTrue);
    });

    test(
      'BatchSummaryWire passes clean payloads and ignores the current stop',
      () {
        final clean = BatchSummaryWire.fromJson({
          'batchId': 'batch-1',
          'currentStopSequence': 1,
          'aggregateVersion': 1,
          'stops': [
            {
              'sequence': 1,
              'deliveryId': 'asg-1',
              'stopType': 'dropoff',
              'label': 'Stop 1',
            },
            {
              'sequence': 2,
              'deliveryId': 'asg-2',
              'stopType': 'dropoff',
              'label': 'Stop 2',
            },
          ],
        });
        expect(clean.upcomingStopsHaveContactFields, isFalse);

        // Contact fields on the CURRENT stop are allowed by the wire guard —
        // only upcoming (sequence > current) stops are rejected.
        final currentOnly = BatchSummaryWire.fromJson({
          'batchId': 'batch-1',
          'currentStopSequence': 2,
          'aggregateVersion': 1,
          'stops': [
            {
              'sequence': 2,
              'deliveryId': 'asg-2',
              'stopType': 'dropoff',
              'label': 'Stop 2',
              'phoneNumber': '+966500000001',
            },
          ],
        });
        expect(currentOnly.upcomingStopsHaveContactFields, isFalse);
      },
    );
  });
}
