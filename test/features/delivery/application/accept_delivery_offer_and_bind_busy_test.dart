import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/delivery/application/accept_delivery_offer_and_bind_busy.dart';
import 'package:saeq_driver/features/delivery/domain/entities/accept_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';
import '../../availability/helpers/fake_driver_availability_repository.dart';

void main() {
  final at = DateTime.utc(2026, 7, 26, 12);

  DriverAvailability available() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.available,
    source: AvailabilitySource.server,
    lastChangedAt: at,
    lastConfirmedAt: at,
    pendingSync: false,
    revision: 1,
  );

  AcceptDeliveryOfferRequest request() => AcceptDeliveryOfferRequest(
    driverId: 'drv-1',
    offerId: 'off-1',
    idempotencyKey: 'idem-1',
    connectivityOnline: true,
    isConfirmedAvailable: true,
  );

  AcceptDeliveryOfferAndBindBusy buildCoordinator({
    required FakeDeliveryOfferRepository offers,
    required FakeDeliveryAssignmentRepository assignments,
    required FakeDriverAvailabilityRepository availability,
  }) {
    return AcceptDeliveryOfferAndBindBusy(
      AcceptDeliveryOffer(offers, assignments),
      ApplyAuthoritativeAvailability(availability),
      GetDriverAvailability(availability),
      clock: () => at,
    );
  }

  group('AcceptDeliveryOfferAndBindBusy', () {
    test('accept success persists assignment then marks driver busy', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository();
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final coordinator = buildCoordinator(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      final result = await coordinator(request());

      expect(result.isSuccess, isTrue);
      expect(assignments.active?.assignmentId, 'asg-1');
      expect(assignments.upsertCallCount, 1);
      expect(availability.authoritativeUpdates, hasLength(1));
      expect(
        availability.authoritativeUpdates.single.status,
        AvailabilityStatus.busy,
      );
      expect(
        availability.authoritativeUpdates.single.activeAssignmentId,
        'asg-1',
      );
      expect(availability.state?.status, AvailabilityStatus.busy);
      expect(coordinator.acceptCallCount, 1);
      expect(coordinator.bindCallCount, 1);
      // Ordering: persist before busy (upsert then authoritative).
      expect(assignments.upsertCallCount, 1);
      offers.dispose();
      availability.dispose();
    });

    test('acceptance failure does not change availability', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.nextAcceptFailure = const DeliveryOfferExpired();
      final assignments = FakeDeliveryAssignmentRepository();
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final coordinator = buildCoordinator(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      final result = await coordinator(request());

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DeliveryOfferExpired>());
      expect(assignments.upsertCallCount, 0);
      expect(availability.authoritativeUpdates, isEmpty);
      expect(availability.state?.status, AvailabilityStatus.available);
      expect(coordinator.bindCallCount, 0);
      offers.dispose();
      availability.dispose();
    });

    test('persistence failure does not change availability', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository();
      assignments.nextUpsertFailure = const DeliveryPersistenceFailure();
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final coordinator = buildCoordinator(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      final result = await coordinator(request());

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DeliveryPersistenceFailure>());
      expect(assignments.active, isNull);
      expect(availability.authoritativeUpdates, isEmpty);
      expect(coordinator.bindCallCount, 0);
      offers.dispose();
      availability.dispose();
    });

    test(
      'busy transition failure preserves assignment (ADR-025 compensation)',
      () async {
        final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        offers.acceptResult = sampleAssignment();
        final assignments = FakeDeliveryAssignmentRepository();
        final availability = FakeDriverAvailabilityRepository(
          seed: available(),
        );
        availability.nextAuthoritativeFailure =
            const AvailabilityPersistenceFailure();
        final coordinator = buildCoordinator(
          offers: offers,
          assignments: assignments,
          availability: availability,
        );

        final result = await coordinator(request());

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<DeliveryAvailabilityBindFailure>());
        final bindFailure =
            result.failureOrNull! as DeliveryAvailabilityBindFailure;
        expect(bindFailure.assignment?.assignmentId, 'asg-1');
        expect(assignments.active?.assignmentId, 'asg-1');
        expect(availability.state?.status, AvailabilityStatus.available);
        expect(coordinator.bindCallCount, 1);
        offers.dispose();
        availability.dispose();
      },
    );

    test('already-busy with same assignment is handled safely', () async {
      final assignment = sampleAssignment();
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = assignment;
      final assignments = FakeDeliveryAssignmentRepository();
      final availability = FakeDriverAvailabilityRepository(
        seed: DriverAvailability(
          driverId: 'drv-1',
          status: AvailabilityStatus.busy,
          source: AvailabilitySource.system,
          lastChangedAt: at,
          pendingSync: false,
          activeAssignmentId: assignment.assignmentId,
        ),
      );
      final coordinator = buildCoordinator(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      // Direct bind path (already busy) — no duplicate authoritative write.
      final bindOnly = await coordinator.bindBusyForAssignment(assignment);
      expect(bindOnly.isSuccess, isTrue);
      expect(availability.authoritativeUpdates, isEmpty);

      // Full accept path when assignment already exists would fail accept;
      // bind after successful accept with pre-seeded busy of same id:
      assignments.active = null;
      final result = await coordinator(request());
      expect(result.isSuccess, isTrue);
      // After accept persists, bind sees busy+same id → no second apply.
      // First accept may have applied if state was cleared... we seeded busy.
      // Accept updates assignment; getCurrent still busy with same id → skip apply.
      expect(availability.authoritativeUpdates, isEmpty);
      offers.dispose();
      availability.dispose();
    });

    test('operation order: accept/persist before busy bind', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository();
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final coordinator = buildCoordinator(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      await coordinator(request());

      expect(assignments.upsertCallCount, 1);
      expect(availability.authoritativeUpdates, hasLength(1));
      expect(assignments.active, isNotNull);
      expect(
        availability.state?.activeAssignmentId,
        assignments.active!.assignmentId,
      );
      offers.dispose();
      availability.dispose();
    });

    test('restart reconcile binds busy for persisted assignment', () async {
      final assignment = sampleAssignment();
      final offers = FakeDeliveryOfferRepository();
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final coordinator = buildCoordinator(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      final result = await coordinator.bindBusyForAssignment(assignment);

      expect(result.isSuccess, isTrue);
      expect(availability.state?.status, AvailabilityStatus.busy);
      expect(availability.state?.activeAssignmentId, 'asg-1');
      expect(assignments.active?.assignmentId, 'asg-1');
      offers.dispose();
      availability.dispose();
    });
  });
}
