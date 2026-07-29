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

ProviderContainer _container({BatchService? service}) {
  final container = ProviderContainer(
    overrides: [
      batchServiceProvider.overrideWithValue(service ?? _FastBatchService()),
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

  group('BatchController pickup and route', () {
    Future<BatchController> acceptedController(
      ProviderContainer container,
    ) async {
      final controller = container.read(batchControllerProvider.notifier);
      await controller.loadOffer();
      await controller.acceptBatch();
      return controller;
    }

    test('pickup waiting → partial → all ready → verify → confirm', () async {
      final container = _container();
      final controller = await acceptedController(container);
      controller.refreshPickupStatus();
      expect(
        container.read(batchControllerProvider).pickupStatus,
        BatchPickupStatus.partiallyReady,
      );
      controller.refreshPickupStatus();
      expect(
        container.read(batchControllerProvider).pickupStatus,
        BatchPickupStatus.allReady,
      );
      controller.beginVerification();
      final batch = container.read(batchControllerProvider).batch!;
      for (final order in batch.orders) {
        controller.verifyOrder(order.orderId);
      }
      expect(
        container.read(batchControllerProvider).batch!.allVerified,
        isTrue,
      );
      await controller.confirmPickup();
      final state = container.read(batchControllerProvider);
      expect(state.pickupStatus, BatchPickupStatus.pickupConfirmed);
      expect(state.routeStatus, BatchRouteStatus.overview);
    });

    test('verification mismatch then dismiss', () async {
      final container = _container();
      final controller = await acceptedController(container);
      controller.refreshPickupStatus();
      controller.refreshPickupStatus();
      controller.beginVerification();
      final orderId = container
          .read(batchControllerProvider)
          .batch!
          .orders
          .first
          .orderId;
      controller.reportVerificationMismatch(orderId);
      expect(
        container.read(batchControllerProvider).pickupStatus,
        BatchPickupStatus.verificationError,
      );
      controller.dismissVerificationError();
      expect(
        container.read(batchControllerProvider).pickupStatus,
        BatchPickupStatus.verification,
      );
    });

    test('offline queue on stop 2 then recovery', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(2);
      controller.markArrived();
      await controller.confirmDelivery();
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

    test('customer unavailable issue', () async {
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
      controller.selectIssueReason(BatchOrderIssueReason.customerUnavailable);
      await controller.submitIssue();
      expect(
        container.read(batchControllerProvider).routeStatus,
        BatchRouteStatus.customerUnavailable,
      );
    });

    test('progress derives from resolved orders', () async {
      final container = _container();
      final controller = await acceptedController(container);
      await _advanceToRoute(container, controller);
      controller.openStop(1);
      controller.markArrived();
      await controller.confirmDelivery();
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

Future<void> _advanceToRoute(
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
  await controller.confirmPickup();
}

Future<void> _resolveAllOrders(
  ProviderContainer container,
  BatchController controller,
) async {
  await _advanceToRoute(container, controller);
  final batch = container.read(batchControllerProvider).batch!;
  for (final order in batch.actionableStops) {
    controller.openStop(order.sequence);
    controller.markArrived();
    await controller.confirmDelivery();
    if (container.read(batchControllerProvider).routeStatus ==
        BatchRouteStatus.offlineQueue) {
      controller.retryQueuedSync();
    }
    controller.continueBatch();
  }
}
