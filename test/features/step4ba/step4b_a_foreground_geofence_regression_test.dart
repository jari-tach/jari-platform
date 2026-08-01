import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/delivery/data/fake/fake_delivery_lifecycle_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/customer_contact.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/advance_delivery_workflow.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/confirm_pickup_remote.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_customer_contact.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/report_automatic_arrival_remote.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/pages/active_delivery_page.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/location/domain/geo_point.dart';
import 'package:saeq_driver/features/location/domain/geofence_policy.dart';
import 'package:saeq_driver/features/location/domain/location_fix.dart';

import '../delivery/helpers/delivery_fixtures.dart';
import '../delivery/helpers/fake_delivery_assignment_repository.dart';
import '../delivery/helpers/fake_delivery_command_repository.dart';

void main() {
  group('STEP 4B-A environment gate', () {
    test('QA report never claims live PASS until Device QA closes', () {
      final contents = File(
        'docs/device_qa/step4b_a_honor_foreground_geofence_report.md',
      ).readAsStringSync();
      // Status may be BLOCKED (environment / auth) or PENDING RETEST after
      // the independent deviceId fix (PR #30). It must never claim a live
      // device PASS until the full journey is executed and evidenced.
      final statusIsPass =
          RegExp(r'^\*\*PASS\*\*$', multiLine: true).hasMatch(contents) ||
          contents.contains('HONOR Device:\nPASS');
      expect(statusIsPass, isFalse);
      expect(contents, contains('Manual arrival button = 0'));
      expect(contents, contains('Automatic arrival exactly once'));
    });
  });

  group('STEP 4B-A foreground geofence policy regression', () {
    const target = GeoPoint(latitude: 24.7136, longitude: 46.6753);

    test('stale fix never arrives', () {
      final policy = GeofencePolicy(
        debouncer: LocationFixDebouncer(
          requiredHits: 2,
          minInterval: const Duration(milliseconds: 10),
        ),
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      final stale = LocationFix(
        point: target,
        recordedAt: DateTime.utc(2026, 7, 31, 11, 58),
        accuracyMeters: 8,
      );
      expect(
        policy.evaluate(fix: stale, target: target),
        GeofenceEvaluation.outside,
      );
    });

    test('weak accuracy never arrives', () {
      final policy = GeofencePolicy(
        debouncer: LocationFixDebouncer(
          requiredHits: 2,
          minInterval: const Duration(milliseconds: 10),
        ),
      );
      final now = DateTime.now().toUtc();
      expect(
        policy.evaluate(
          fix: LocationFix(point: target, recordedAt: now, accuracyMeters: 120),
          target: target,
        ),
        GeofenceEvaluation.outside,
      );
    });

    test('outside geofence never arrives', () {
      final policy = GeofencePolicy(
        debouncer: LocationFixDebouncer(
          requiredHits: 2,
          minInterval: const Duration(milliseconds: 10),
        ),
      );
      final now = DateTime.now().toUtc();
      const far = GeoPoint(latitude: 24.80, longitude: 46.80);
      expect(
        policy.evaluate(
          fix: LocationFix(point: far, recordedAt: now, accuracyMeters: 8),
          target: target,
        ),
        GeofenceEvaluation.outside,
      );
    });

    test('inside without full dwell stays approaching then arrives', () {
      final now = DateTime.utc(2026, 7, 31, 12, 0, 0);
      final policy = GeofencePolicy(
        debouncer: LocationFixDebouncer(
          requiredHits: 2,
          minInterval: const Duration(milliseconds: 50),
        ),
        clock: () => now.add(const Duration(seconds: 5)),
      );
      expect(
        policy.evaluate(
          fix: LocationFix(point: target, recordedAt: now, accuracyMeters: 8),
          target: target,
        ),
        GeofenceEvaluation.approaching,
      );
      expect(
        policy.evaluate(
          fix: LocationFix(
            point: target,
            recordedAt: now.add(const Duration(milliseconds: 60)),
            accuracyMeters: 8,
          ),
          target: target,
        ),
        GeofenceEvaluation.arrived,
      );
    });
  });

  group('STEP 4B-A remote automatic arrival journey', () {
    test(
      'arrival unlocks verifying once; contact only after pickup ack',
      () async {
        final lifecycle = FakeDeliveryLifecycleRepository();
        final commands = FakeDeliveryCommandRepository();
        final order = sampleOrder(
          dropoffLatitude: 24.7136,
          dropoffLongitude: 46.6753,
        );
        final assignment = sampleAssignment(
          order: order,
          workflowStage: DriverWorkflowStage.waitingPickup,
          status: DeliveryStatus.accepted,
          serverRevision: '0',
        );
        final assignments = FakeDeliveryAssignmentRepository(
          active: assignment,
        );
        lifecycle.seedActive(
          DeliveryLifecycleAck(
            deliveryId: assignment.assignmentId,
            state: CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
            aggregateVersion: 0,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        lifecycle.seedContact(
          CustomerContact(
            deliveryId: assignment.assignmentId,
            name: 'Customer Contact',
            phoneNumber: '+966500000001',
            availableUntil: DateTime.now().toUtc().add(
              const Duration(hours: 1),
            ),
          ),
        );

        final confirmPickup = ConfirmPickupRemote(
          lifecycleRepository: lifecycle,
          assignmentRepository: assignments,
          commandRepository: commands,
        );
        final reportArrival = ReportAutomaticArrivalRemote(
          lifecycleRepository: lifecycle,
          assignmentRepository: assignments,
          commandRepository: commands,
        );
        final getContact = GetCustomerContact(
          lifecycleRepository: lifecycle,
          assignmentRepository: assignments,
        );

        expect((await getContact(driverId: 'drv-1')).isFailure, isTrue);
        // Denial before pickup clears the memory cache — re-seed for post-ack.
        lifecycle.seedContact(
          CustomerContact(
            deliveryId: assignment.assignmentId,
            name: 'Customer Contact',
            phoneNumber: '+966500000001',
            availableUntil: DateTime.now().toUtc().add(
              const Duration(hours: 1),
            ),
          ),
        );

        final picked = await confirmPickup(
          driverId: 'drv-1',
          commandId: 'cmd-pickup-1',
          connectivityOnline: true,
        );
        expect(picked.isSuccess, isTrue, reason: '${picked.failureOrNull}');
        expect(
          picked.valueOrNull!.workflowStage,
          DriverWorkflowStage.navToCustomer,
        );

        final afterPickup = await getContact(driverId: 'drv-1');
        expect(
          afterPickup.isSuccess,
          isTrue,
          reason: '${afterPickup.failureOrNull}',
        );

        final evidence = ArrivalEvidence(
          clientEventId: 'arrival:${assignment.assignmentId}',
          capturedAt: DateTime.now().toUtc(),
          latitude: 24.7136,
          longitude: 46.6753,
          accuracyMeters: 8,
          policyVersion: 'geofence-v1',
        );
        final first = await reportArrival(
          driverId: 'drv-1',
          commandId: 'cmd-arrival-1',
          evidence: evidence,
          connectivityOnline: true,
        );
        expect(first.isSuccess, isTrue, reason: '${first.failureOrNull}');
        expect(first.valueOrNull!.workflowStage, DriverWorkflowStage.verifying);

        final second = await reportArrival(
          driverId: 'drv-1',
          commandId: 'cmd-arrival-1',
          evidence: evidence,
          connectivityOnline: true,
        );
        expect(second.isSuccess, isTrue);
        final active = await lifecycle.getActiveDelivery();
        // First pickup + first arrival = version 2; idempotent replay does not bump.
        expect(active.valueOrNull!.aggregateVersion, 2);
      },
    );

    test('offline arrival keeps delivery confirmation locked', () async {
      final lifecycle = FakeDeliveryLifecycleRepository();
      final commands = FakeDeliveryCommandRepository();
      final assignment = sampleAssignment(
        workflowStage: DriverWorkflowStage.navToCustomer,
        status: DeliveryStatus.pickedUp,
        serverRevision: '2',
      );
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      lifecycle.seedActive(
        DeliveryLifecycleAck(
          deliveryId: assignment.assignmentId,
          state: CanonicalDeliveryStates.enRouteToCustomer,
          aggregateVersion: 2,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final reportArrival = ReportAutomaticArrivalRemote(
        lifecycleRepository: lifecycle,
        assignmentRepository: assignments,
        commandRepository: commands,
      );
      final result = await reportArrival(
        driverId: 'drv-1',
        commandId: 'cmd-arrival-offline',
        evidence: ArrivalEvidence(
          clientEventId: 'arrival:${assignment.assignmentId}',
          capturedAt: DateTime.now().toUtc(),
          latitude: 24.7136,
          longitude: 46.6753,
          accuracyMeters: 8,
          policyVersion: 'geofence-v1',
        ),
        connectivityOnline: false,
      );
      expect(result.isFailure, isTrue);
      final current = await assignments.getActiveAssignment(driverId: 'drv-1');
      expect(current.valueOrNull!.pendingSync, isTrue);
      expect(
        current.valueOrNull!.workflowStage,
        DriverWorkflowStage.navToCustomer,
      );
    });
  });

  group('STEP 4B-A UI invariants', () {
    testWidgets('ActiveDeliveryPage has zero manual arrival buttons', (
      tester,
    ) async {
      final assignment = sampleAssignment(
        workflowStage: DriverWorkflowStage.navToCustomer,
        status: DeliveryStatus.pickedUp,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      final container = ProviderContainer(
        overrides: [
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getActiveReader: (_) => GetActiveDelivery(assignments),
              advanceWorkflowReader: (_) =>
                  AdvanceDeliveryWorkflow(assignments),
              driverIdReader: (_) => 'drv-1',
              acceptPreconditionsReader: (_) =>
                  const DeliveryAcceptPreconditions(
                    connectivityOnline: true,
                    isConfirmedAvailable: true,
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
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
            home: const ActiveDeliveryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('manualArrivalButton')), findsNothing);
      expect(find.textContaining('Manual arrival'), findsNothing);
      expect(find.textContaining('وصول يدوي'), findsNothing);
    });
  });
}
