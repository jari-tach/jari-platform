import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/accept_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';

import '../../helpers/delivery_fixtures.dart';
import '../../helpers/fake_delivery_assignment_repository.dart';
import '../../helpers/fake_delivery_offer_repository.dart';

void main() {
  AcceptDeliveryOfferRequest request({
    bool connectivityOnline = true,
    bool isConfirmedAvailable = true,
    bool hasActiveAssignment = false,
    String offerId = 'off-1',
  }) => AcceptDeliveryOfferRequest(
    driverId: 'drv-1',
    offerId: offerId,
    idempotencyKey: 'idem-1',
    connectivityOnline: connectivityOnline,
    isConfirmedAvailable: isConfirmedAvailable,
    hasActiveAssignment: hasActiveAssignment,
    revision: 'rev-1',
  );

  group('AcceptDeliveryOffer', () {
    test('offline accept is denied without repository mutation', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final assignments = FakeDeliveryAssignmentRepository();
      final result = await AcceptDeliveryOffer(offers, assignments)(
        request(connectivityOnline: false),
      );
      expect(result.failureOrNull, isA<DeliveryOfflineAcceptDenied>());
      expect(offers.acceptCallCount, 0);
      expect(assignments.upsertCallCount, 0);
      offers.dispose();
    });

    test('not confirmed available is denied', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final assignments = FakeDeliveryAssignmentRepository();
      final result = await AcceptDeliveryOffer(offers, assignments)(
        request(isConfirmedAvailable: false),
      );
      expect(result.failureOrNull, isA<DeliveryNotAvailable>());
      expect(offers.acceptCallCount, 0);
      offers.dispose();
    });

    test('active assignment flag denies accept', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final assignments = FakeDeliveryAssignmentRepository();
      final result = await AcceptDeliveryOffer(offers, assignments)(
        request(hasActiveAssignment: true),
      );
      expect(result.failureOrNull, isA<DeliveryActiveAssignmentExists>());
      expect(offers.acceptCallCount, 0);
      offers.dispose();
    });

    test('persisted active assignment denies accept', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final assignments = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(),
      );
      final result = await AcceptDeliveryOffer(offers, assignments)(request());
      expect(result.failureOrNull, isA<DeliveryActiveAssignmentExists>());
      expect(offers.acceptCallCount, 0);
      offers.dispose();
    });

    test('delivered summary assignment still blocks accept', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final assignments = FakeDeliveryAssignmentRepository(
        active: sampleAssignment(
          status: DeliveryStatus.delivered,
          workflowStage: DriverWorkflowStage.summary,
        ),
      );
      final result = await AcceptDeliveryOffer(offers, assignments)(request());
      expect(result.failureOrNull, isA<DeliveryActiveAssignmentExists>());
      expect(offers.acceptCallCount, 0);
      offers.dispose();
    });

    test('missing offer returns not found', () async {
      final offers = FakeDeliveryOfferRepository();
      final assignments = FakeDeliveryAssignmentRepository();
      final result = await AcceptDeliveryOffer(offers, assignments)(request());
      expect(result.failureOrNull, isA<DeliveryOfferNotFound>());
      expect(offers.acceptCallCount, 0);
      offers.dispose();
    });

    test('invalid transition does not accept', () async {
      final offers = FakeDeliveryOfferRepository(
        offers: [sampleOffer(status: DeliveryOfferStatus.expired)],
      );
      final assignments = FakeDeliveryAssignmentRepository();
      final result = await AcceptDeliveryOffer(offers, assignments)(request());
      expect(result.failureOrNull, isA<InvalidDeliveryOfferTransition>());
      expect(offers.acceptCallCount, 0);
      offers.dispose();
    });

    test(
      'accept success persists assignment via assignment repository',
      () async {
        final assignment = sampleAssignment();
        final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()])
          ..acceptResult = assignment;
        final assignments = FakeDeliveryAssignmentRepository();

        final result = await AcceptDeliveryOffer(offers, assignments)(
          request(),
        );

        final persisted = assignment.copyWith(
          completedCommandIds: {'idem-1'},
        );
        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull, persisted);
        expect(offers.acceptCallCount, 1);
        expect(assignments.upsertCallCount, 1);
        expect(assignments.upserted.single, persisted);
        expect(assignments.active, persisted);
        offers.dispose();
      },
    );

    test('accept repository failure does not persist', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..nextAcceptFailure = const DeliveryOfferTaken();
      final assignments = FakeDeliveryAssignmentRepository();
      final result = await AcceptDeliveryOffer(offers, assignments)(request());
      expect(result.failureOrNull, isA<DeliveryOfferTaken>());
      expect(assignments.upsertCallCount, 0);
      offers.dispose();
    });

    test('persist failure surfaces after successful accept', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository()
        ..nextUpsertFailure = const DeliveryPersistenceFailure();
      final result = await AcceptDeliveryOffer(offers, assignments)(request());
      expect(result.failureOrNull, isA<DeliveryPersistenceFailure>());
      expect(offers.acceptCallCount, 1);
      expect(assignments.upsertCallCount, 1);
      offers.dispose();
    });

    test(
      'identity mismatch on accepted assignment is security denial',
      () async {
        final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()])
          ..acceptResult = sampleAssignment(driverId: 'other');
        final assignments = FakeDeliveryAssignmentRepository();
        final result = await AcceptDeliveryOffer(offers, assignments)(
          request(),
        );
        expect(result.failureOrNull, isA<DeliverySecurityPolicyDenied>());
        expect(assignments.upsertCallCount, 0);
        offers.dispose();
      },
    );
  });
}
