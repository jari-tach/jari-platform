import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/delivery/application/complete_delivery_and_release_busy.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 14);

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

  DriverAvailability unavailableComplete() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.unavailable,
    source: AvailabilitySource.system,
    lastChangedAt: at,
    lastConfirmedAt: null,
    pendingSync: false,
    revision: 3,
    reason: CompleteDeliveryAndReleaseBusy.postCompletionReason,
  );

  CompleteDeliveryAndReleaseBusy build({
    required FakeDeliveryAssignmentRepository assignments,
    required FakeDriverAvailabilityRepository availability,
  }) {
    return CompleteDeliveryAndReleaseBusy(
      assignments,
      ApplyAuthoritativeAvailability(availability),
      GetDriverAvailability(availability),
      clock: () => at,
    );
  }

  group('CompleteDeliveryAndReleaseBusy', () {
    test('availability then clear succeeds', () async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary);
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final complete = build(
        assignments: assignments,
        availability: availability,
      );

      final result = await complete(driverId: 'drv-1');

      expect(result.isSuccess, isTrue);
      expect(assignments.active, isNull);
      expect(assignments.clearCallCount, 1);
      expect(availability.authoritativeUpdates, hasLength(1));
      expect(
        availability.authoritativeUpdates.single.status,
        AvailabilityStatus.unavailable,
      );
      expect(
        availability.authoritativeUpdates.single.reason,
        'delivery.complete',
      );
      expect(availability.state?.status, AvailabilityStatus.unavailable);
      // Ordering: authoritative update recorded before clear.
      expect(availability.authoritativeUpdates.length, 1);
      expect(assignments.clearCallCount, 1);
    });

    test('availability failure keeps summary assignment', () async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary);
      final availability = FakeDriverAvailabilityRepository(seed: busy())
        ..nextAuthoritativeFailure = const AvailabilityUnknownFailure(
          'busy release failed',
        );
      final complete = build(
        assignments: assignments,
        availability: availability,
      );

      final result = await complete(driverId: 'drv-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DeliveryAvailabilityBindFailure>());
      expect(assignments.active?.workflowStage, DriverWorkflowStage.summary);
      expect(assignments.clearCallCount, 0);
      expect(availability.state?.status, AvailabilityStatus.busy);

      availability.nextAuthoritativeFailure = null;
      final retry = await complete(driverId: 'drv-1');
      expect(retry.isSuccess, isTrue);
      expect(assignments.active, isNull);
    });

    test('clear failure after availability remains recoverable', () async {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: summary)
        ..nextClearFailure = const DeliveryPersistenceFailure('clear failed');
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final complete = build(
        assignments: assignments,
        availability: availability,
      );

      final result = await complete(driverId: 'drv-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DeliveryPersistenceFailure>());
      expect(assignments.active?.workflowStage, DriverWorkflowStage.summary);
      expect(availability.state?.status, AvailabilityStatus.unavailable);
      expect(assignments.clearCallCount, 1);

      assignments.nextClearFailure = null;
      final retry = await complete(driverId: 'drv-1');
      expect(retry.isSuccess, isTrue);
      expect(assignments.active, isNull);
      expect(assignments.clearCallCount, 2);
      // Second availability apply is safe (no duplicate business completion).
      expect(availability.authoritativeUpdates.length, greaterThanOrEqualTo(2));
    });

    test(
      'already cleared + post-completion availability is idempotent',
      () async {
        final assignments = FakeDeliveryAssignmentRepository();
        final availability = FakeDriverAvailabilityRepository(
          seed: unavailableComplete(),
        );
        final complete = build(
          assignments: assignments,
          availability: availability,
        );

        final result = await complete(driverId: 'drv-1');

        expect(result.isSuccess, isTrue);
        expect(assignments.clearCallCount, 0);
        expect(availability.authoritativeUpdates, isEmpty);
      },
    );

    test('non-summary stage is denied without side effects', () async {
      final assignments = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(
          status: DeliveryStatus.pickedUp,
          workflowStage: DriverWorkflowStage.collected,
        ),
      );
      final availability = FakeDriverAvailabilityRepository(seed: busy());
      final complete = build(
        assignments: assignments,
        availability: availability,
      );

      final result = await complete(driverId: 'drv-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<InvalidDeliveryWorkflowTransition>());
      expect(assignments.active?.workflowStage, DriverWorkflowStage.collected);
      expect(assignments.clearCallCount, 0);
      expect(availability.authoritativeUpdates, isEmpty);
      expect(availability.state?.status, AvailabilityStatus.busy);
    });
  });
}
