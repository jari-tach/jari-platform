import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/state/delivery_controller_state.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

void main() {
  Future<ProviderContainer> boot({
    FakeDeliveryOfferRepository? offers,
    FakeDeliveryAssignmentRepository? assignments,
    String? driverId = 'drv-1',
    DeliveryAcceptPreconditions preconditions =
        const DeliveryAcceptPreconditions(
          connectivityOnline: true,
          isConfirmedAvailable: true,
        ),
    bool wireOffers = true,
    bool wireActive = true,
  }) async {
    final offerRepo = offers ?? FakeDeliveryOfferRepository();
    final assignmentRepo = assignments ?? FakeDeliveryAssignmentRepository();
    final getOffers = GetDeliveryOffers(offerRepo);
    final accept = AcceptDeliveryOffer(offerRepo, assignmentRepo);
    final reject = RejectDeliveryOffer(offerRepo);
    final getActive = GetActiveDelivery(assignmentRepo);

    final container = ProviderContainer(
      overrides: [
        deliveryControllerProvider.overrideWith(
          () => DeliveryController(
            getOffersReader: (_) => wireOffers ? getOffers : null,
            acceptReader: (_) => wireOffers && wireActive ? accept : null,
            rejectReader: (_) => wireOffers ? reject : null,
            getActiveReader: (_) => wireActive ? getActive : null,
            offerRepositoryReader: (_) => wireOffers ? offerRepo : null,
            driverIdReader: (_) => driverId,
            acceptPreconditionsReader: (_) => preconditions,
          ),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      offerRepo.dispose();
    });
    container.read(deliveryControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container;
  }

  group('DeliveryControllerState', () {
    test('empty / canAccept derivation', () {
      final empty = DeliveryControllerState.ready(
        offers: const [],
        boundDriverId: 'drv-1',
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.canAccept, isFalse);

      final withOffer = DeliveryControllerState.ready(
        offers: [sampleOffer()],
        boundDriverId: 'drv-1',
      );
      expect(withOffer.hasOffer, isTrue);
      expect(withOffer.canAccept, isTrue);
      expect(withOffer.canReject, isTrue);
    });
  });

  group('DeliveryController', () {
    test(
      'initial boot reaches ready empty when no offers/assignment',
      () async {
        final container = await boot();
        final state = container.read(deliveryControllerProvider);
        expect(state.status, DeliveryViewStatus.ready);
        expect(state.isEmpty, isTrue);
        expect(state.isInitialized, isTrue);
      },
    );

    test('successful offer load', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final container = await boot(offers: offerRepo);
      final state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.ready);
      expect(state.offers, hasLength(1));
      expect(state.activeOffer?.offerId, 'off-1');
    });

    test(
      'initialize suppresses remote offers when local assignment exists',
      () async {
        final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        final assignmentRepo = FakeDeliveryAssignmentRepository(
          active: sampleAssignment(),
        );
        final container = await boot(
          offers: offerRepo,
          assignments: assignmentRepo,
        );
        final state = container.read(deliveryControllerProvider);
        expect(state.hasActiveAssignment, isTrue);
        expect(state.offers, isEmpty);
        expect(state.hasOffer, isFalse);
        expect(state.activeAssignment?.assignmentId, isNotEmpty);
      },
    );

    test('empty offer state', () async {
      final container = await boot();
      expect(container.read(deliveryControllerProvider).isEmpty, isTrue);
    });

    test('duplicate refreshOffers is ignored while in flight', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final container = await boot(offers: offerRepo);
      final controller = container.read(deliveryControllerProvider.notifier);

      final first = controller.refreshOffers();
      final second = controller.refreshOffers();
      await Future.wait([first, second]);

      expect(offerRepo.getCallCount, 2); // initialize + one refresh
      expect(
        container.read(deliveryControllerProvider).status,
        DeliveryViewStatus.ready,
      );
    });

    test('offer stream updates replace active offer', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final container = await boot(offers: offerRepo);
      final updated = sampleOffer(
        status: DeliveryOfferStatus.accepting,
        revision: 'rev-2',
      );
      offerRepo.emitActive(updated);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(deliveryControllerProvider);
      expect(state.activeOffer?.status, DeliveryOfferStatus.accepting);
      expect(state.activeOffer?.revision, 'rev-2');
    });

    test('accept success exposes assignment and clears offer', () async {
      final assignment = sampleAssignment();
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..acceptResult = assignment;
      final assignmentRepo = FakeDeliveryAssignmentRepository();
      final container = await boot(
        offers: offerRepo,
        assignments: assignmentRepo,
      );

      await container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();

      final state = container.read(deliveryControllerProvider);
      final persisted = assignment.copyWith(
        completedCommandIds: {'local:drv-1:off-1:accept'},
      );
      expect(state.status, DeliveryViewStatus.ready);
      expect(state.activeOffer, isNull);
      expect(state.activeAssignment, persisted);
      expect(state.lastAcceptedAssignment, persisted);
      expect(assignmentRepo.upsertCallCount, 1);
    });

    test('accept failure retains offer and surfaces typed failure', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..nextAcceptFailure = const DeliveryOfferTaken();
      final container = await boot(offers: offerRepo);

      await container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();

      final state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.failure);
      expect(state.failure, isA<DeliveryOfferTaken>());
      expect(state.activeOffer?.offerId, 'off-1');
    });

    test('offline acceptance failure', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..acceptResult = sampleAssignment();
      final container = await boot(
        offers: offerRepo,
        preconditions: const DeliveryAcceptPreconditions(
          connectivityOnline: false,
          isConfirmedAvailable: true,
        ),
      );

      await container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();

      final state = container.read(deliveryControllerProvider);
      expect(state.failure, isA<DeliveryOfflineAcceptDenied>());
      expect(offerRepo.acceptCallCount, 0);
    });

    test('repeated accept tap is prevented while processing', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..acceptResult = sampleAssignment();
      final gate = Completer<void>();
      offerRepo.acceptGate = gate.future;
      final container = await boot(offers: offerRepo);
      final controller = container.read(deliveryControllerProvider.notifier);

      final first = controller.acceptCurrentOffer();
      await Future<void>.delayed(Duration.zero);
      final second = controller.acceptCurrentOffer();
      gate.complete();
      await Future.wait([first, second]);

      expect(offerRepo.acceptCallCount, 1);
    });

    test('repeated reject tap is prevented while processing', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final gate = Completer<void>();
      offerRepo.rejectGate = gate.future;
      final container = await boot(offers: offerRepo);
      final controller = container.read(deliveryControllerProvider.notifier);

      final first = controller.rejectCurrentOffer();
      await Future<void>.delayed(Duration.zero);
      final second = controller.rejectCurrentOffer();
      gate.complete();
      await Future.wait([first, second]);

      expect(offerRepo.rejectCallCount, 1);
    });

    test('reject success clears active offer', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final container = await boot(offers: offerRepo);

      await container
          .read(deliveryControllerProvider.notifier)
          .rejectCurrentOffer();

      final state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.ready);
      expect(state.activeOffer, isNull);
      expect(state.offers, isEmpty);
      expect(offerRepo.rejectCallCount, 1);
    });

    test(
      'offer watch stays active after reject and receives later offers',
      () async {
        final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        final container = await boot(offers: offerRepo);
        final controller = container.read(deliveryControllerProvider.notifier);

        await controller.rejectCurrentOffer();
        expect(container.read(deliveryControllerProvider).activeOffer, isNull);

        final later = sampleOffer(offerId: 'off-2', revision: 'rev-later');
        offerRepo.offers = [later];
        offerRepo.emitActive(later);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(deliveryControllerProvider);
        expect(state.activeOffer?.offerId, 'off-2');
        expect(state.hasOffer, isTrue);
      },
    );

    test(
      'reject then immediate refresh does not orphan watch; later offer arrives',
      () async {
        final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        final container = await boot(offers: offerRepo);
        final controller = container.read(deliveryControllerProvider.notifier);

        await controller.rejectCurrentOffer();
        expect(container.read(deliveryControllerProvider).activeOffer, isNull);

        // Immediate refresh (race path) — must not bump generation / orphan watch.
        await controller.refreshOffers();
        expect(container.read(deliveryControllerProvider).activeOffer, isNull);
        expect(
          container.read(deliveryControllerProvider).isProcessing,
          isFalse,
        );

        // Immediate second reject must no-op (no active offer).
        await controller.rejectCurrentOffer();
        expect(container.read(deliveryControllerProvider).activeOffer, isNull);
        expect(offerRepo.rejectCallCount, 1);

        final later = sampleOffer(offerId: 'off-reissue', revision: 'rev-r');
        offerRepo.offers = [later];
        offerRepo.emitActive(later);
        await Future<void>.delayed(Duration.zero);

        final state = container.read(deliveryControllerProvider);
        expect(state.activeOffer?.offerId, 'off-reissue');
        expect(state.hasOffer, isTrue);
      },
    );

    test('accept does not orphan the offer watch', () async {
      final assignment = sampleAssignment();
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..acceptResult = assignment;
      final container = await boot(
        offers: offerRepo,
        assignments: FakeDeliveryAssignmentRepository(),
      );

      await container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();
      expect(
        container.read(deliveryControllerProvider).hasActiveAssignment,
        isTrue,
      );

      // Watch must still be subscribed: a competing offer emission is
      // suppressed while assignment exists (not ignored by orphaned watch).
      offerRepo.emitActive(sampleOffer(offerId: 'off-ghost'));
      await Future<void>.delayed(Duration.zero);
      final state = container.read(deliveryControllerProvider);
      expect(state.hasActiveAssignment, isTrue);
      expect(state.hasOffer, isFalse);
      expect(state.offers, isEmpty);
    });

    test('stale accept completion is ignored after re-initialize', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..acceptResult = sampleAssignment();
      final gate = Completer<void>();
      offerRepo.acceptGate = gate.future;
      final container = await boot(offers: offerRepo);
      final controller = container.read(deliveryControllerProvider.notifier);

      final pending = controller.acceptCurrentOffer();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(deliveryControllerProvider).isProcessing, isTrue);

      // Lifecycle boundary: bumps generation and replaces watch context.
      await controller.initialize();
      gate.complete();
      await pending;

      final state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.ready);
      expect(state.isProcessing, isFalse);
      // Stale accept must not apply assignment onto presentation state.
      expect(state.activeAssignment, isNull);
      expect(state.activeOffer?.offerId, 'off-1');
    });

    test(
      'stale reject completion is ignored after dispose generation bump',
      () async {
        final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
        final gate = Completer<void>();
        offerRepo.rejectGate = gate.future;
        final container = await boot(offers: offerRepo);

        final pending = container
            .read(deliveryControllerProvider.notifier)
            .rejectCurrentOffer();
        await Future<void>.delayed(Duration.zero);
        container.dispose();
        gate.complete();
        await pending;
        // Must not throw; disposed controller ignores stale completion.
      },
    );

    test('reject failure surfaces typed failure', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..nextRejectFailure = const DeliveryConflict();
      final container = await boot(offers: offerRepo);

      await container
          .read(deliveryControllerProvider.notifier)
          .rejectCurrentOffer();

      final state = container.read(deliveryControllerProvider);
      expect(state.failure, isA<DeliveryConflict>());
      expect(state.activeOffer?.offerId, 'off-1');
    });

    test('active assignment load', () async {
      final assignment = sampleAssignment();
      final container = await boot(
        assignments: FakeDeliveryAssignmentRepository(active: assignment),
      );
      final state = container.read(deliveryControllerProvider);
      expect(state.activeAssignment, assignment);
      expect(state.hasActiveAssignment, isTrue);
    });

    test('active assignment empty', () async {
      final container = await boot();
      expect(
        container.read(deliveryControllerProvider).activeAssignment,
        isNull,
      );
    });

    test('active assignment failure', () async {
      final assignments = FakeDeliveryAssignmentRepository()
        ..nextGetFailure = const DeliveryPersistenceFailure();
      final container = await boot(assignments: assignments);
      final state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.failure);
      expect(state.failure, isA<DeliveryPersistenceFailure>());
    });

    test('refresh active assignment after successful acceptance', () async {
      final assignment = sampleAssignment();
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..acceptResult = assignment;
      final assignmentRepo = FakeDeliveryAssignmentRepository();
      final container = await boot(
        offers: offerRepo,
        assignments: assignmentRepo,
      );

      await container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();
      // Clear in-memory presentation assignment then refresh from repo.
      assignmentRepo.active = assignment;
      await container
          .read(deliveryControllerProvider.notifier)
          .refreshActiveDelivery();

      expect(
        container.read(deliveryControllerProvider).activeAssignment,
        assignment,
      );
      expect(assignmentRepo.getCallCount, greaterThanOrEqualTo(2));
    });

    test('registry service unavailable behavior', () async {
      final container = await boot(wireOffers: false, wireActive: false);
      final state = container.read(deliveryControllerProvider);
      expect(state.status, DeliveryViewStatus.failure);
      expect(state.failure, isA<DeliveryUnknownFailure>());
    });

    test('missing driver id is unauthenticated', () async {
      final container = await boot(driverId: null);
      final state = container.read(deliveryControllerProvider);
      expect(state.failure, isA<DeliveryUnauthenticated>());
    });

    test('controller disposal cancels offer watch', () async {
      final offerRepo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final container = await boot(offers: offerRepo);
      container.dispose();
      offerRepo.emitActive(sampleOffer(revision: 'after-dispose'));
      await Future<void>.delayed(Duration.zero);
      // No further assertions — must not throw after dispose.
    });
  });
}
