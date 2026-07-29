import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saeq_driver/features/batch/batch_feature.dart';
import 'package:saeq_driver/features/batch/batch_view_data.dart';

class _FastBatchService implements BatchService {
  @override
  Future<BatchLoadResult> loadOffer(FakeBatchScenario scenario) async {
    return switch (scenario) {
      FakeBatchScenario.fourOrders => BatchLoadResult(
        status: BatchOfferViewStatus.fourOrders,
        batch: FakeBatchService.batchFixture(orderCount: 4),
      ),
      FakeBatchScenario.threeOrders => BatchLoadResult(
        status: BatchOfferViewStatus.threeOrders,
        batch: FakeBatchService.batchFixture(orderCount: 3),
      ),
      FakeBatchScenario.expired => BatchLoadResult(
        status: BatchOfferViewStatus.expired,
        batch: FakeBatchService.batchFixture(
          orderCount: 4,
          remainingSeconds: 0,
        ),
      ),
      FakeBatchScenario.error => const BatchLoadResult(
        status: BatchOfferViewStatus.error,
      ),
      FakeBatchScenario.offline => const BatchLoadResult(
        status: BatchOfferViewStatus.offline,
      ),
    };
  }

  @override
  bool syncsImmediately(int sequence) => sequence != 2;
}

ProviderContainer _container({
  BatchService? service,
  Duration arrivalDelay = Duration.zero,
}) {
  final container = ProviderContainer(
    overrides: [
      batchServiceProvider.overrideWithValue(service ?? _FastBatchService()),
      fakeBatchArrivalDelayProvider.overrideWithValue(arrivalDelay),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('BatchOrderViewData', () {
    test('masks order id for privacy', () {
      const order = BatchOrderViewData(
        orderId: 'B-2031',
        sequence: 1,
        labelIndex: 1,
        distanceKm: 2.4,
        earningsSar: 9.5,
        state: BatchOrderState.offered,
      );
      expect(order.maskedOrderId, 'B-••31');
    });

    test('resolved states exclude cancelled from actionable stops', () {
      final batch = FakeBatchService.batchFixture(orderCount: 4);
      final cancelled = batch.orders.first.copyWith(
        state: BatchOrderState.cancelled,
      );
      final updated = batch.withOrder(cancelled);
      expect(updated.actionableStops.length, 3);
      expect(updated.cancelledCount, 1);
    });
  });

  group('BatchController offer', () {
    test('loads four-order offer', () async {
      final container = _container();
      final controller = container.read(batchControllerProvider.notifier);
      await controller.loadOffer();
      final state = container.read(batchControllerProvider);
      expect(state.offerStatus, BatchOfferViewStatus.fourOrders);
      expect(state.batch?.orderCount, 4);
    });

    test('loads three-order offer', () async {
      final container = _container();
      final controller = container.read(batchControllerProvider.notifier);
      await controller.loadOffer(scenario: FakeBatchScenario.threeOrders);
      expect(
        container.read(batchControllerProvider).offerStatus,
        BatchOfferViewStatus.threeOrders,
      );
      expect(container.read(batchControllerProvider).batch?.orderCount, 3);
    });

    test('expired, error and offline scenarios', () async {
      final container = _container();
      final controller = container.read(batchControllerProvider.notifier);
      await controller.loadOffer(scenario: FakeBatchScenario.expired);
      expect(
        container.read(batchControllerProvider).offerStatus,
        BatchOfferViewStatus.expired,
      );
      await controller.loadOffer(scenario: FakeBatchScenario.error);
      expect(
        container.read(batchControllerProvider).offerStatus,
        BatchOfferViewStatus.error,
      );
      await controller.loadOffer(scenario: FakeBatchScenario.offline);
      expect(
        container.read(batchControllerProvider).offerStatus,
        BatchOfferViewStatus.offline,
      );
    });

    test('accepts whole batch and blocks duplicate taps', () async {
      final container = _container();
      final controller = container.read(batchControllerProvider.notifier);
      await controller.loadOffer();
      final acceptFuture = controller.acceptBatch();
      expect(
        container.read(batchControllerProvider).offerStatus,
        BatchOfferViewStatus.acceptProcessing,
      );
      await controller.acceptBatch();
      await acceptFuture;
      final state = container.read(batchControllerProvider);
      expect(state.offerStatus, BatchOfferViewStatus.accepted);
      expect(state.tripStarted, isTrue);
      expect(state.pickupStatus, BatchPickupStatus.waiting);
    });

    test('rejects whole batch', () async {
      final container = _container();
      final controller = container.read(batchControllerProvider.notifier);
      await controller.loadOffer();
      await controller.rejectBatch();
      expect(
        container.read(batchControllerProvider).offerStatus,
        BatchOfferViewStatus.rejected,
      );
    });
  });

  group('BatchController journey contract', () {
    Future<BatchController> acceptedController(
      ProviderContainer container,
    ) async {
      final controller = container.read(batchControllerProvider.notifier);
      await controller.loadOffer();
      await controller.acceptBatch();
      return controller;
    }

    test('verification alone does not complete pickup or open route', () async {
      final container = _container();
      final controller = await acceptedController(container);
      controller.refreshPickupStatus();
      controller.refreshPickupStatus();
      controller.beginVerification();
      final batch = container.read(batchControllerProvider).batch!;
      for (final order in batch.orders) {
        controller.verifyOrder(order.orderId);
      }
      final state = container.read(batchControllerProvider);
      expect(state.batch!.allVerified, isTrue);
      expect(state.pickupStatus, BatchPickupStatus.verification);
      expect(state.isPickedUp, isFalse);
      expect(state.canStartRoute, isFalse);
      expect(state.journeyStage, isNull);
      expect(state.routeStatus, BatchRouteStatus.overview);
    });

    test(
      'all-required-ready + all-verified gate before manual pickup',
      () async {
        final container = _container();
        final controller = await acceptedController(container);
        expect(
          container.read(batchControllerProvider).canConfirmPickupManually,
          isFalse,
        );
        controller.refreshPickupStatus();
        expect(
          container.read(batchControllerProvider).canConfirmPickupManually,
          isFalse,
        );
        controller.refreshPickupStatus();
        controller.beginVerification();
        final orders = container.read(batchControllerProvider).batch!.orders;
        for (var i = 0; i < orders.length - 1; i++) {
          controller.verifyOrder(orders[i].orderId);
        }
        expect(
          container.read(batchControllerProvider).canConfirmPickupManually,
          isFalse,
        );
        controller.verifyOrder(orders.last.orderId);
        expect(
          container.read(batchControllerProvider).canConfirmPickupManually,
          isTrue,
        );
      },
    );

    test(
      'manual pickup has processing + duplicate-tap guard then route',
      () async {
        final container = _container();
        final controller = await acceptedController(container);
        await _verifyAll(container, controller);
        controller.openManualPickupConfirmation();
        expect(
          container.read(batchControllerProvider).pickupStatus,
          BatchPickupStatus.awaitingManualConfirmation,
        );
        expect(
          container.read(batchControllerProvider).journeyStage,
          BatchJourneyStage.pickupAwaitingManualConfirmation,
        );

        final pending = controller.confirmPickupManually();
        expect(container.read(batchControllerProvider).isProcessing, isTrue);
        expect(
          container.read(batchControllerProvider).pickupStatus,
          BatchPickupStatus.processing,
        );
        // Duplicate tap while processing must be ignored.
        await controller.confirmPickupManually();
        await pending;

        final state = container.read(batchControllerProvider);
        expect(state.pickupStatus, BatchPickupStatus.pickupConfirmed);
        expect(state.journeyStage, BatchJourneyStage.pickupConfirmedManually);
        expect(state.isPickedUp, isTrue);
        expect(state.canStartRoute, isTrue);
        expect(state.routeStatus, BatchRouteStatus.overview);
        expect(
          state.stageHistory,
          containsAll(<BatchJourneyStage>[
            BatchJourneyStage.pickupAwaitingManualConfirmation,
            BatchJourneyStage.pickupConfirmedManually,
          ]),
        );
      },
    );

    test('cannot open stop before manual pickup', () async {
      final container = _container();
      final controller = await acceptedController(container);
      controller.openStop(1);
      expect(container.read(batchControllerProvider).currentSequence, 1);
      expect(container.read(batchControllerProvider).journeyStage, isNull);
      expect(
        container
            .read(batchControllerProvider)
            .batch!
            .orderBySequence(1)!
            .state,
        BatchOrderState.preparing,
      );
    });

    test('exact journey sequence for one stop', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      expect(
        container.read(batchControllerProvider).journeyStage,
        BatchJourneyStage.enRouteToCustomer,
      );
      expect(
        container.read(batchControllerProvider).currentContactVisibility,
        BatchCustomerContactVisibility.locked,
      );

      controller.registerAutomaticArrivalByLocation(1);
      var state = container.read(batchControllerProvider);
      expect(
        state.journeyStage,
        BatchJourneyStage.deliveryAwaitingManualConfirmation,
      );
      expect(
        state.stageHistory,
        contains(BatchJourneyStage.arrivedAutomaticallyByLocation),
      );
      expect(
        state.currentContactVisibility,
        BatchCustomerContactVisibility.revealed,
      );
      expect(state.canConfirmDeliveryManually, isTrue);
      expect(state.batch!.orderBySequence(1)!.state, BatchOrderState.arrived);

      final delivery = controller.confirmDeliveryManually();
      expect(container.read(batchControllerProvider).isProcessing, isTrue);
      await controller.confirmDeliveryManually();
      await delivery;
      state = container.read(batchControllerProvider);
      expect(
        state.stageHistory,
        contains(BatchJourneyStage.deliveredConfirmedManually),
      );
      expect(state.batch!.orderBySequence(1)!.state, BatchOrderState.delivered);
    });

    test('fake automatic arrival via location controller only', () async {
      final container = _container(
        arrivalDelay: const Duration(milliseconds: 20),
      );
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      expect(
        container
            .read(batchControllerProvider)
            .batch!
            .orderBySequence(1)!
            .state,
        BatchOrderState.headingToCustomer,
      );

      container
          .read(fakeBatchLocationControllerProvider.notifier)
          .startApproach(1);
      expect(
        container.read(fakeBatchLocationControllerProvider).signal,
        FakeBatchLocationSignal.approachingCustomer,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final state = container.read(batchControllerProvider);
      expect(state.batch!.orderBySequence(1)!.state, BatchOrderState.arrived);
      expect(
        state.journeyStage,
        BatchJourneyStage.deliveryAwaitingManualConfirmation,
      );
      expect(
        container.read(fakeBatchLocationControllerProvider).signal,
        FakeBatchLocationSignal.atCustomer,
      );
    });

    test('contact locked before pickup and while en route', () async {
      final container = _container();
      final controller = await acceptedController(container);
      expect(
        container.read(batchControllerProvider).currentContactVisibility,
        BatchCustomerContactVisibility.locked,
      );
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      expect(
        container.read(batchControllerProvider).currentContactVisibility,
        BatchCustomerContactVisibility.locked,
      );
    });

    test(
      'contact revealed only after automatic arrival for current stop',
      () async {
        final container = _container();
        final controller = await acceptedController(container);
        await _advanceToRoute(container, controller);
        controller.openStop(1);
        controller.registerAutomaticArrivalByLocation(1);
        final contact = container.read(batchControllerProvider).currentContact;
        expect(contact.visibility, BatchCustomerContactVisibility.revealed);
        expect(contact.labelIndex, 1);
      },
    );

    test('fake call and WhatsApp actions count attempts only', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      controller.recordCallAttempt();
      expect(container.read(batchControllerProvider).callAttempts, 0);
      controller.registerAutomaticArrivalByLocation(1);
      controller.recordCallAttempt();
      controller.recordWhatsappAttempt();
      final state = container.read(batchControllerProvider);
      expect(state.callAttempts, 1);
      expect(state.whatsappAttempts, 1);
      expect(state.currentContact.totalAttempts, 2);
    });

    test('customer unavailable retains current contact only', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      controller.registerAutomaticArrivalByLocation(1);
      final orderId = container
          .read(batchControllerProvider)
          .batch!
          .orders
          .first
          .orderId;
      controller.openIssue(orderId);
      controller.selectIssueReason(BatchOrderIssueReason.customerUnavailable);
      await controller.submitIssue();
      final state = container.read(batchControllerProvider);
      expect(state.routeStatus, BatchRouteStatus.customerUnavailable);
      expect(
        state.currentContactVisibility,
        BatchCustomerContactVisibility.revealed,
      );
      expect(state.currentContact.labelIndex, 1);
    });

    test('contact closed after delivered or cancelled', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      controller.registerAutomaticArrivalByLocation(1);
      await controller.confirmDeliveryManually();
      // After delivery the current sequence advances; reopen stop 1 to check
      // the closed state for the delivered order.
      final delivered = container
          .read(batchControllerProvider)
          .batch!
          .orderBySequence(1)!;
      expect(delivered.state, BatchOrderState.delivered);

      // Cancel stop 2 and assert closed visibility once resolved.
      controller.openStop(2);
      controller.registerAutomaticArrivalByLocation(2);
      final orderId = container
          .read(batchControllerProvider)
          .batch!
          .orderBySequence(2)!
          .orderId;
      controller.openIssue(orderId);
      controller.selectIssueReason(BatchOrderIssueReason.merchantCancelled);
      await controller.submitIssue();
      final cancelled = container
          .read(batchControllerProvider)
          .batch!
          .orderBySequence(2)!;
      expect(cancelled.state, BatchOrderState.cancelled);
      expect(cancelled.isResolved, isTrue);
    });

    test('manual delivery refuses auto-complete before arrival', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      await controller.confirmDeliveryManually();
      expect(
        container
            .read(batchControllerProvider)
            .batch!
            .orderBySequence(1)!
            .state,
        BatchOrderState.headingToCustomer,
      );
    });

    test('offline queue on stop 2 then recovery', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(2);
      controller.registerAutomaticArrivalByLocation(2);
      await controller.confirmDeliveryManually();
      expect(
        container.read(batchControllerProvider).routeStatus,
        BatchRouteStatus.offlineQueue,
      );
      controller.retryQueuedSync();
      expect(
        container
            .read(batchControllerProvider)
            .batch!
            .orderBySequence(2)!
            .state,
        BatchOrderState.delivered,
      );
    });

    test('merchant cancel on one order continues batch', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      final orderId = container
          .read(batchControllerProvider)
          .batch!
          .orders
          .first
          .orderId;
      controller.openIssue(orderId);
      controller.selectIssueReason(BatchOrderIssueReason.merchantCancelled);
      await controller.submitIssue();
      final state = container.read(batchControllerProvider);
      expect(state.routeStatus, BatchRouteStatus.orderCancelledContinue);
      expect(state.batch!.cancelledCount, 1);
      expect(state.batch!.actionableStops.length, 3);
    });

    test('progress derives from resolved orders', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      controller.registerAutomaticArrivalByLocation(1);
      await controller.confirmDeliveryManually();
      controller.retryQueuedSync();
      controller.continueBatch();
      final batch = container.read(batchControllerProvider).batch!;
      expect(batch.progressFraction, greaterThan(0));
    });

    test('finish batch only when all resolved', () async {
      final container = _container();
      final controller = await acceptedController(container);
      expect(container.read(batchControllerProvider).canFinishBatch, isFalse);
      await _resolveAllOrders(container, controller);
      expect(container.read(batchControllerProvider).canFinishBatch, isTrue);
      controller.finishBatch();
      expect(
        container.read(batchControllerProvider).summaryStatus,
        BatchSummaryStatus.completed,
      );
    });

    test('restored snapshot flag', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(2);
      controller.markRestoredFromSnapshot();
      expect(
        container.read(batchControllerProvider).restoredFromSnapshot,
        isTrue,
      );
      expect(
        container.read(batchControllerProvider).routeStatus,
        BatchRouteStatus.restoredAfterRestart,
      );
      controller.resumeAfterRestore();
      expect(
        container.read(batchControllerProvider).restoredFromSnapshot,
        isFalse,
      );
    });

    test('earnings breakdown and return home', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _resolveAllOrders(container, controller);
      controller.finishBatch();
      controller.showEarningsBreakdown();
      expect(
        container.read(batchControllerProvider).summaryStatus,
        BatchSummaryStatus.earningsBreakdown,
      );
      controller.hideEarningsBreakdown();
      controller.returnHome();
      expect(
        container.read(batchControllerProvider).summaryStatus,
        BatchSummaryStatus.returnHome,
      );
    });
  });
}

Future<void> _verifyAll(
  ProviderContainer container,
  BatchController controller,
) async {
  controller.refreshPickupStatus();
  controller.refreshPickupStatus();
  controller.beginVerification();
  final batch = container.read(batchControllerProvider).batch!;
  for (final order in batch.orders) {
    controller.verifyOrder(order.orderId);
  }
}

Future<void> _advanceToRoute(
  ProviderContainer container,
  BatchController controller,
) async {
  await _verifyAll(container, controller);
  controller.openManualPickupConfirmation();
  await controller.confirmPickupManually();
}

Future<void> _resolveAllOrders(
  ProviderContainer container,
  BatchController controller,
) async {
  await _advanceToRoute(container, controller);
  final batch = container.read(batchControllerProvider).batch!;
  for (final order in List<BatchOrderViewData>.from(batch.actionableStops)) {
    controller.openStop(order.sequence);
    controller.registerAutomaticArrivalByLocation(order.sequence);
    await controller.confirmDeliveryManually();
    if (container.read(batchControllerProvider).routeStatus ==
        BatchRouteStatus.offlineQueue) {
      controller.retryQueuedSync();
    }
    controller.continueBatch();
  }
}
