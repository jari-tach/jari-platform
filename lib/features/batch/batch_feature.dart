/// Multi-order batch assignment — fake UI state (STEP 2C).
///
/// Fake/Mock only: no backend, no realtime channel, no map SDK, no GPS and no
/// change to the real Delivery lifecycle or the Availability/Busy domain. The
/// batch a driver sees here is a synthetic fixture built in memory.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'batch_view_data.dart';

/// Offer surface states required by the P27 batch specification.
enum BatchOfferViewStatus {
  loading,
  threeOrders,
  fourOrders,
  acceptProcessing,
  rejectProcessing,
  expired,
  error,
  offline,

  /// Whole batch accepted — the offer surface hands over to pickup.
  accepted,

  /// Whole batch rejected — the offer surface returns to the offers list.
  rejected,
}

/// Pickup surface states (waiting → verified → manually confirmed).
///
/// [verification] never completes pickup: it hands over to
/// [awaitingManualConfirmation], the distinct manual-confirmation surface
/// required by Figma 138:2714.
enum BatchPickupStatus {
  waiting,
  partiallyReady,
  allReady,
  verification,
  verificationError,
  awaitingManualConfirmation,
  processing,
  pickupConfirmed,
}

/// Route surface states. `activeStop1` / `activeStop2` mirror the Figma stop
/// screens; `activeStop` covers any further middle stop of a 4-order batch.
enum BatchRouteStatus {
  overview,
  activeStop1,
  activeStop2,
  activeStop,
  finalStop,
  offlineQueue,
  restoredAfterRestart,
  orderCancelledContinue,
  customerUnavailable,
  deliveryIssue,
  processing,
}

/// Summary surface states.
enum BatchSummaryStatus {
  completed,
  partial,
  cancelledOrderIncluded,
  earningsBreakdown,
  returnHome,
}

/// Fixture scenarios the fake service can serve for the offer surface.
enum FakeBatchScenario { fourOrders, threeOrders, expired, error, offline }

/// Outcome of loading a fake batch offer.
class BatchLoadResult {
  const BatchLoadResult({required this.status, this.batch});

  final BatchOfferViewStatus status;
  final BatchOfferViewData? batch;
}

abstract interface class BatchService {
  /// Loads the synthetic batch offer for [scenario].
  Future<BatchLoadResult> loadOffer(FakeBatchScenario scenario);

  /// Whether the fake delivery confirmation for [sequence] reaches the
  /// (imaginary) server. `false` queues the update locally instead.
  bool syncsImmediately(int sequence);
}

/// Deterministic in-memory batch source. No IO of any kind.
class FakeBatchService implements BatchService {
  FakeBatchService({
    this.latency = Duration.zero,
    this.offlineSyncSequence = 2,
  });

  /// Trial latency so `acceptProcessing` / `processing` stay observable.
  final Duration latency;

  /// Stop whose first delivery confirmation is queued locally once, so the
  /// offline-queue + recovery flow is reachable without touching the radio.
  /// `0` disables the queued outcome.
  final int offlineSyncSequence;

  final Set<int> _queuedOnce = <int>{};

  static const String defaultBatchId = 'B-778';

  @override
  Future<BatchLoadResult> loadOffer(FakeBatchScenario scenario) async {
    await Future<void>.delayed(latency);
    return switch (scenario) {
      FakeBatchScenario.fourOrders => BatchLoadResult(
        status: BatchOfferViewStatus.fourOrders,
        batch: batchFixture(orderCount: 4),
      ),
      FakeBatchScenario.threeOrders => BatchLoadResult(
        status: BatchOfferViewStatus.threeOrders,
        batch: batchFixture(orderCount: 3),
      ),
      FakeBatchScenario.expired => BatchLoadResult(
        status: BatchOfferViewStatus.expired,
        batch: batchFixture(orderCount: 4, remainingSeconds: 0),
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
  bool syncsImmediately(int sequence) {
    if (offlineSyncSequence <= 0) return true;
    if (sequence != offlineSyncSequence) return true;
    return !_queuedOnce.add(sequence);
  }

  /// Synthetic batch fixture: one store, one pickup point, 2–4 orders.
  static BatchOfferViewData batchFixture({
    int orderCount = 4,
    String batchId = defaultBatchId,
    int remainingSeconds = 42,
  }) {
    final count = orderCount.clamp(2, 4);
    final orders = <BatchOrderViewData>[
      for (var index = 0; index < count; index++)
        BatchOrderViewData(
          orderId: _orderIds[index],
          sequence: index + 1,
          labelIndex: index + 1,
          distanceKm: _distancesKm[index],
          earningsSar: _earningsSar[index],
          state: BatchOrderState.offered,
        ),
    ];
    return BatchOfferViewData(
      batchId: batchId,
      orders: orders,
      totalDistanceKm: orders.fold<double>(0, (sum, o) => sum + o.distanceKm),
      etaMinutes: 12 + 11 * count,
      totalEarningsSar: orders.fold<double>(0, (sum, o) => sum + o.earningsSar),
      remainingSeconds: remainingSeconds,
    );
  }

  static const List<String> _orderIds = [
    'B-2031',
    'B-2032',
    'B-2033',
    'B-2034',
  ];
  static const List<double> _distancesKm = [2.4, 3.1, 1.8, 2.7];
  static const List<double> _earningsSar = [9.5, 11, 8.5, 10];
}

/// Immutable batch view state. One order changing never rewrites another.
class BatchState {
  const BatchState({
    this.batch,
    this.offerStatus = BatchOfferViewStatus.loading,
    this.pickupStatus = BatchPickupStatus.waiting,
    this.routeStatus = BatchRouteStatus.overview,
    this.summaryStatus = BatchSummaryStatus.partial,
    this.journeyStage,
    this.stageHistory = const <BatchJourneyStage>[],
    this.currentSequence = 1,
    this.issueOrderId,
    this.selectedIssueReason = BatchOrderIssueReason.none,
    this.callAttempts = 0,
    this.whatsappAttempts = 0,
    this.isProcessing = false,
    this.tripStarted = false,
    this.restoredFromSnapshot = false,
    this.serviceUnavailable = false,
  });

  final BatchOfferViewData? batch;
  final BatchOfferViewStatus offerStatus;
  final BatchPickupStatus pickupStatus;
  final BatchRouteStatus routeStatus;
  final BatchSummaryStatus summaryStatus;

  /// Where the batch sits in the mandatory driver journey, or `null` before
  /// the batch has been picked up.
  final BatchJourneyStage? journeyStage;

  /// Ordered record of every journey stage the batch passed through. Tests
  /// assert the exact sequence against the Figma 150:427 contract.
  final List<BatchJourneyStage> stageHistory;

  /// Stop the driver is working on (stable 1-based sequence).
  final int currentSequence;

  /// Order the issue screen is scoped to — the only order it may reveal.
  final String? issueOrderId;

  final BatchOrderIssueReason selectedIssueReason;

  /// Fake contact attempts for the current stop. Nothing dials out.
  final int callAttempts;
  final int whatsappAttempts;

  /// In-flight guard — repeated taps must not re-trigger a transition.
  final bool isProcessing;

  /// True once the batch was accepted; back navigation then needs confirming.
  final bool tripStarted;

  /// Fake restart recovery marker (in-memory only, nothing persisted).
  final bool restoredFromSnapshot;

  /// Fake services are never wired into production builds.
  final bool serviceUnavailable;

  bool get hasBatch => batch != null;

  /// Whole-batch decision is only offered while the offer is live.
  bool get canDecideOffer =>
      !isProcessing &&
      (offerStatus == BatchOfferViewStatus.threeOrders ||
          offerStatus == BatchOfferViewStatus.fourOrders);

  /// Finish stays hidden/disabled until every order is resolved.
  bool get canFinishBatch => batch?.allResolved ?? false;

  /// Journey rule 1 + 2: verification alone is not pickup. The manual
  /// confirmation is armed only when every required order is ready *and*
  /// verified.
  bool get canConfirmPickupManually =>
      !isProcessing && (batch?.canConfirmPickupManually ?? false);

  /// The batch is on the road only after the driver confirmed pickup.
  bool get isPickedUp =>
      journeyStage != null &&
      journeyStage != BatchJourneyStage.pickupAwaitingManualConfirmation;

  /// Journey rule 3: the route overview opens only after manual pickup.
  bool get canStartRoute =>
      isPickedUp && (batch?.actionableStops.isNotEmpty ?? false);

  /// Journey rule 4 + 5: arrival is a read-only state produced by the fake
  /// location signal, never by a driver action.
  bool get hasArrivedAtCurrentStop =>
      currentOrder?.state == BatchOrderState.arrived ||
      currentOrder?.state == BatchOrderState.customerUnavailable;

  /// Journey rule 9: delivery needs an explicit manual confirmation and can
  /// only be armed after the automatic arrival.
  bool get canConfirmDeliveryManually =>
      !isProcessing &&
      currentOrder?.state == BatchOrderState.arrived &&
      (journeyStage == BatchJourneyStage.arrivedAutomaticallyByLocation ||
          journeyStage == BatchJourneyStage.deliveryAwaitingManualConfirmation);

  /// Journey rules 6–8: locked before pickup and en route, revealed for the
  /// current stop after the automatic arrival, closed once the order is
  /// delivered or cancelled. A customer who did not answer keeps their
  /// contact visible until the outcome is recorded.
  BatchCustomerContactVisibility get currentContactVisibility {
    final order = currentOrder;
    if (order == null) return BatchCustomerContactVisibility.locked;
    if (order.state == BatchOrderState.customerUnavailable) {
      return BatchCustomerContactVisibility.revealed;
    }
    if (order.isResolved) return BatchCustomerContactVisibility.closed;
    if (order.state == BatchOrderState.arrived) {
      return BatchCustomerContactVisibility.revealed;
    }
    return BatchCustomerContactVisibility.locked;
  }

  BatchCustomerContactViewData get currentContact =>
      BatchCustomerContactViewData(
        visibility: currentContactVisibility,
        labelIndex: currentOrder?.labelIndex ?? 1,
        callAttempts: callAttempts,
        whatsappAttempts: whatsappAttempts,
      );

  BatchOrderViewData? get currentOrder =>
      batch?.orderBySequence(currentSequence);

  BatchOrderViewData? get issueOrder {
    final id = issueOrderId;
    if (id == null) return null;
    return batch?.orderById(id);
  }

  /// Next actionable stop after the current one, or `null` when last.
  int? get nextActionableSequence {
    final orders = batch?.actionableStops ?? const <BatchOrderViewData>[];
    for (final order in orders) {
      if (order.sequence > currentSequence) return order.sequence;
    }
    return null;
  }

  BatchState copyWith({
    BatchOfferViewData? batch,
    bool clearBatch = false,
    BatchOfferViewStatus? offerStatus,
    BatchPickupStatus? pickupStatus,
    BatchRouteStatus? routeStatus,
    BatchSummaryStatus? summaryStatus,
    BatchJourneyStage? journeyStage,
    List<BatchJourneyStage>? stageHistory,
    int? currentSequence,
    String? issueOrderId,
    bool clearIssueOrderId = false,
    BatchOrderIssueReason? selectedIssueReason,
    int? callAttempts,
    int? whatsappAttempts,
    bool? isProcessing,
    bool? tripStarted,
    bool? restoredFromSnapshot,
    bool? serviceUnavailable,
  }) {
    return BatchState(
      batch: clearBatch ? null : (batch ?? this.batch),
      offerStatus: offerStatus ?? this.offerStatus,
      pickupStatus: pickupStatus ?? this.pickupStatus,
      routeStatus: routeStatus ?? this.routeStatus,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      journeyStage: journeyStage ?? this.journeyStage,
      stageHistory: stageHistory ?? this.stageHistory,
      currentSequence: currentSequence ?? this.currentSequence,
      issueOrderId: clearIssueOrderId
          ? null
          : (issueOrderId ?? this.issueOrderId),
      selectedIssueReason: selectedIssueReason ?? this.selectedIssueReason,
      callAttempts: callAttempts ?? this.callAttempts,
      whatsappAttempts: whatsappAttempts ?? this.whatsappAttempts,
      isProcessing: isProcessing ?? this.isProcessing,
      tripStarted: tripStarted ?? this.tripStarted,
      restoredFromSnapshot: restoredFromSnapshot ?? this.restoredFromSnapshot,
      serviceUnavailable: serviceUnavailable ?? this.serviceUnavailable,
    );
  }
}

/// Fake batch source — `null` in production builds (governance §10 guard).
final batchServiceProvider = Provider<BatchService?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {
    // Widget tests may run before AppConfig initialization.
  }
  return FakeBatchService(latency: const Duration(milliseconds: 600));
});

/// Whether the fake batch fixture entry may be surfaced on the offers page.
///
/// `false` in release/profile builds and in the production environment, so the
/// fake batch UI keeps no reachable affordance in production (governance §10).
/// Tests override this provider to assert both visibility branches.
final batchFixtureEntryEnabledProvider = Provider<bool>(
  (ref) => kDebugMode && !AppConfig.isProduction,
);

class BatchController extends Notifier<BatchState> {
  @override
  BatchState build() => const BatchState();

  BatchService? get _service => ref.read(batchServiceProvider);

  // —— Offer ——

  /// Loads the fake offer. Safe to call from `build`-time navigation.
  Future<void> loadOffer({
    FakeBatchScenario scenario = FakeBatchScenario.fourOrders,
  }) async {
    if (state.isProcessing) return;
    final service = _service;
    if (service == null) {
      state = state.copyWith(
        serviceUnavailable: true,
        offerStatus: BatchOfferViewStatus.error,
        isProcessing: false,
      );
      return;
    }
    state = state.copyWith(
      offerStatus: BatchOfferViewStatus.loading,
      isProcessing: true,
      serviceUnavailable: false,
    );
    final result = await service.loadOffer(scenario);
    if (!ref.mounted) return;
    state = state.copyWith(
      offerStatus: result.status,
      batch: result.batch,
      clearBatch: result.batch == null,
      currentSequence: 1,
      isProcessing: false,
    );
  }

  /// Whole-batch acceptance. Partial acceptance does not exist.
  Future<void> acceptBatch() async {
    if (!state.canDecideOffer || !state.hasBatch) return;
    state = state.copyWith(
      offerStatus: BatchOfferViewStatus.acceptProcessing,
      isProcessing: true,
    );
    await _pause();
    if (!ref.mounted) return;
    final batch = state.batch!;
    state = state.copyWith(
      offerStatus: BatchOfferViewStatus.accepted,
      batch: batch.copyWith(
        orders: [
          for (final order in batch.orders)
            order.copyWith(state: BatchOrderState.preparing),
        ],
      ),
      pickupStatus: BatchPickupStatus.waiting,
      tripStarted: true,
      currentSequence: 1,
      isProcessing: false,
    );
  }

  /// Whole-batch rejection.
  Future<void> rejectBatch() async {
    if (!state.canDecideOffer) return;
    state = state.copyWith(
      offerStatus: BatchOfferViewStatus.rejectProcessing,
      isProcessing: true,
    );
    await _pause();
    if (!ref.mounted) return;
    state = state.copyWith(
      offerStatus: BatchOfferViewStatus.rejected,
      isProcessing: false,
    );
  }

  // —— Pickup ——

  /// Driver re-checks merchant preparation: waiting → partially → all ready.
  void refreshPickupStatus() {
    final batch = state.batch;
    if (batch == null || state.isProcessing) return;
    if (state.pickupStatus == BatchPickupStatus.waiting) {
      final readyCount = batch.orderCount >= 4 ? 2 : 1;
      state = state.copyWith(
        pickupStatus: BatchPickupStatus.partiallyReady,
        batch: batch.copyWith(
          orders: [
            for (final order in batch.orders)
              order.sequence <= readyCount
                  ? order.copyWith(state: BatchOrderState.readyForPickup)
                  : order,
          ],
        ),
      );
      return;
    }
    if (state.pickupStatus == BatchPickupStatus.partiallyReady) {
      state = state.copyWith(
        pickupStatus: BatchPickupStatus.allReady,
        batch: batch.copyWith(
          orders: [
            for (final order in batch.orders)
              order.isReadyForPickup
                  ? order
                  : order.copyWith(state: BatchOrderState.readyForPickup),
          ],
        ),
      );
    }
  }

  /// Opens the per-order verification step.
  void beginVerification() {
    if (state.batch == null) return;
    state = state.copyWith(pickupStatus: BatchPickupStatus.verification);
  }

  /// Confirms one package label. Independent per order.
  void verifyOrder(String orderId) {
    final batch = state.batch;
    final order = batch?.orderById(orderId);
    if (batch == null || order == null || state.isProcessing) return;
    if (order.isVerified) return;
    state = state.copyWith(
      pickupStatus: BatchPickupStatus.verification,
      batch: batch.withOrder(order.copyWith(state: BatchOrderState.verified)),
    );
  }

  /// Driver reports a label mismatch for one order.
  void reportVerificationMismatch(String orderId) {
    if (state.batch?.orderById(orderId) == null) return;
    state = state.copyWith(
      pickupStatus: BatchPickupStatus.verificationError,
      issueOrderId: orderId,
    );
  }

  void dismissVerificationError() {
    if (state.pickupStatus != BatchPickupStatus.verificationError) return;
    state = state.copyWith(
      pickupStatus: BatchPickupStatus.verification,
      clearIssueOrderId: true,
    );
  }

  /// Opens the distinct manual pickup confirmation surface (Figma 138:2714).
  ///
  /// Verification does not complete pickup; it only unlocks this step.
  void openManualPickupConfirmation() {
    final batch = state.batch;
    if (batch == null || !batch.canConfirmPickupManually) return;
    state = _withStage(
      state.copyWith(
        pickupStatus: BatchPickupStatus.awaitingManualConfirmation,
      ),
      BatchJourneyStage.pickupAwaitingManualConfirmation,
    );
  }

  /// Journey step 1 — the driver confirms the batch pickup manually.
  ///
  /// Re-entrant taps are dropped by the `isProcessing` guard, so the route
  /// only opens once, after this action actually succeeds.
  Future<void> confirmPickupManually() async {
    final batch = state.batch;
    if (batch == null || state.isProcessing) return;
    if (!batch.canConfirmPickupManually) return;
    state = state.copyWith(
      pickupStatus: BatchPickupStatus.processing,
      isProcessing: true,
    );
    await _pause();
    if (!ref.mounted) return;
    final picked = state.batch!;
    state = _withStage(
      state.copyWith(
        pickupStatus: BatchPickupStatus.pickupConfirmed,
        batch: picked.copyWith(
          orders: [
            for (final order in picked.orders)
              order.state == BatchOrderState.cancelled ||
                      order.state == BatchOrderState.expired
                  ? order
                  : order.copyWith(state: BatchOrderState.pickedUp),
          ],
        ),
        routeStatus: BatchRouteStatus.overview,
        currentSequence: picked.actionableStops.isEmpty
            ? picked.orders.first.sequence
            : picked.actionableStops.first.sequence,
        isProcessing: false,
      ),
      BatchJourneyStage.pickupConfirmedManually,
    );
  }

  // —— Route / stops ——

  /// Enters the first actionable stop from the route overview.
  void startRoute() {
    final batch = state.batch;
    if (batch == null || !state.isPickedUp) return;
    final first = batch.actionableStops.isEmpty
        ? null
        : batch.actionableStops.first.sequence;
    if (first == null) return;
    openStop(first);
  }

  /// Opens a stop by its stable sequence. Blocked until the batch has been
  /// picked up manually (journey rule 3).
  void openStop(int sequence) {
    final batch = state.batch;
    final order = batch?.orderBySequence(sequence);
    if (batch == null || order == null || !order.isActionable) return;
    if (!state.isPickedUp) return;
    final next = state
        .copyWith(
          currentSequence: sequence,
          batch: order.state == BatchOrderState.pickedUp
              ? batch.withOrder(
                  order.copyWith(state: BatchOrderState.headingToCustomer),
                )
              : batch,
          callAttempts: 0,
          whatsappAttempts: 0,
          restoredFromSnapshot: false,
        )
        .copyWith(routeStatus: _routeStatusFor(sequence));
    state = order.state == BatchOrderState.arrived
        ? next
        : _withStage(next, BatchJourneyStage.enRouteToCustomer);
  }

  /// Journey step 2 — arrival registered by the fake location signal.
  ///
  /// This is deliberately not reachable from any button, gesture or semantics
  /// action: only [FakeBatchLocationController] calls it, and in STEP 2C that
  /// controller is a presentation-only fake with no GPS, geofence or
  /// permission behind it.
  void registerAutomaticArrivalByLocation(int sequence) {
    final batch = state.batch;
    final order = batch?.orderBySequence(sequence);
    if (batch == null || order == null || !order.isActionable) return;
    if (!state.isPickedUp) return;
    if (order.state == BatchOrderState.arrived) return;
    final arrived = state.copyWith(
      currentSequence: sequence,
      batch: batch.withOrder(order.copyWith(state: BatchOrderState.arrived)),
      routeStatus: _routeStatusFor(sequence),
    );
    // Both contract stages are recorded: the arrival itself, then the state in
    // which the app waits for the driver's manual delivery confirmation.
    state = _withStage(
      _withStage(arrived, BatchJourneyStage.arrivedAutomaticallyByLocation),
      BatchJourneyStage.deliveryAwaitingManualConfirmation,
    );
  }

  /// Fake call action for the current stop — counts an attempt, dials nothing.
  void recordCallAttempt() {
    if (state.currentContactVisibility !=
        BatchCustomerContactVisibility.revealed) {
      return;
    }
    state = state.copyWith(callAttempts: state.callAttempts + 1);
  }

  /// Fake WhatsApp action for the current stop — no intent is ever launched.
  void recordWhatsappAttempt() {
    if (state.currentContactVisibility !=
        BatchCustomerContactVisibility.revealed) {
      return;
    }
    state = state.copyWith(whatsappAttempts: state.whatsappAttempts + 1);
  }

  /// Journey step 3 — the driver confirms delivery of the current order
  /// manually. Never called automatically, and never before the automatic
  /// arrival was registered.
  Future<void> confirmDeliveryManually() async {
    final batch = state.batch;
    final order = state.currentOrder;
    if (batch == null || order == null || state.isProcessing) return;
    if (!order.isActionable) return;
    if (!state.canConfirmDeliveryManually) return;
    final sequence = order.sequence;
    state = state.copyWith(
      routeStatus: BatchRouteStatus.processing,
      isProcessing: true,
    );
    await _pause();
    if (!ref.mounted) return;
    final service = _service;
    final synced = service?.syncsImmediately(sequence) ?? true;
    final current = state.batch!;
    final target = current.orderBySequence(sequence)!;
    final updated = current.withOrder(
      target.copyWith(
        state: synced
            ? BatchOrderState.delivered
            : BatchOrderState.deliveredPendingSync,
      ),
    );
    state = _withStage(
      state.copyWith(batch: updated, isProcessing: false),
      BatchJourneyStage.deliveredConfirmedManually,
    );
    if (!synced) {
      state = state.copyWith(routeStatus: BatchRouteStatus.offlineQueue);
      return;
    }
    _advanceAfterResolution();
  }

  /// Flushes the locally queued delivery update (still fake, still local).
  void retryQueuedSync() {
    final batch = state.batch;
    if (batch == null || state.isProcessing) return;
    final updated = batch.copyWith(
      orders: [
        for (final order in batch.orders)
          order.isPendingSync
              ? order.copyWith(state: BatchOrderState.delivered)
              : order,
      ],
    );
    state = state.copyWith(batch: updated);
    _advanceAfterResolution();
  }

  // —— Issue ——

  /// Opens the issue screen for one order only.
  void openIssue(String orderId) {
    if (state.batch?.orderById(orderId) == null) return;
    state = state.copyWith(
      routeStatus: BatchRouteStatus.deliveryIssue,
      issueOrderId: orderId,
      selectedIssueReason: BatchOrderIssueReason.none,
    );
  }

  void selectIssueReason(BatchOrderIssueReason reason) {
    if (state.issueOrderId == null) return;
    state = state.copyWith(selectedIssueReason: reason);
  }

  /// Applies the reported issue to that single order and continues the batch.
  Future<void> submitIssue() async {
    final batch = state.batch;
    final order = state.issueOrder;
    final reason = state.selectedIssueReason;
    if (batch == null || order == null || state.isProcessing) return;
    if (reason == BatchOrderIssueReason.none) return;
    state = state.copyWith(
      routeStatus: BatchRouteStatus.processing,
      isProcessing: true,
    );
    await _pause();
    if (!ref.mounted) return;
    final current = state.batch!;
    final target = current.orderById(order.orderId)!;
    final resolvedState = reason == BatchOrderIssueReason.merchantCancelled
        ? BatchOrderState.cancelled
        : BatchOrderState.customerUnavailable;
    state = state.copyWith(
      batch: current.withOrder(
        target.copyWith(state: resolvedState, issueReason: reason),
      ),
      routeStatus: reason == BatchOrderIssueReason.merchantCancelled
          ? BatchRouteStatus.orderCancelledContinue
          : BatchRouteStatus.customerUnavailable,
      isProcessing: false,
      clearIssueOrderId: true,
      selectedIssueReason: BatchOrderIssueReason.none,
    );
  }

  void cancelIssue() {
    if (state.issueOrderId == null &&
        state.routeStatus != BatchRouteStatus.deliveryIssue) {
      return;
    }
    state = state.copyWith(
      clearIssueOrderId: true,
      selectedIssueReason: BatchOrderIssueReason.none,
      routeStatus: _routeStatusFor(state.currentSequence),
    );
  }

  /// Moves to the next actionable stop after an issue or a queued delivery.
  void continueBatch() {
    if (state.batch == null) return;
    _advanceAfterResolution();
  }

  // —— Summary ——

  /// Closes the batch. Only allowed once every order is resolved.
  void finishBatch() {
    final batch = state.batch;
    if (batch == null || !batch.allResolved) return;
    state = state.copyWith(
      summaryStatus: batch.completedCount == batch.orderCount
          ? BatchSummaryStatus.completed
          : (batch.cancelledCount > 0
                ? BatchSummaryStatus.cancelledOrderIncluded
                : BatchSummaryStatus.partial),
    );
  }

  void showEarningsBreakdown() {
    if (state.batch == null) return;
    state = state.copyWith(summaryStatus: BatchSummaryStatus.earningsBreakdown);
  }

  void hideEarningsBreakdown() {
    if (state.summaryStatus != BatchSummaryStatus.earningsBreakdown) return;
    finishBatchStatusOnly();
  }

  /// Recomputes the summary headline without re-running the finish guard.
  void finishBatchStatusOnly() {
    final batch = state.batch;
    if (batch == null) return;
    state = state.copyWith(
      summaryStatus: batch.completedCount == batch.orderCount
          ? BatchSummaryStatus.completed
          : (batch.cancelledCount > 0
                ? BatchSummaryStatus.cancelledOrderIncluded
                : BatchSummaryStatus.partial),
    );
  }

  /// Marks the batch as handed back to Home.
  void returnHome() {
    state = state.copyWith(summaryStatus: BatchSummaryStatus.returnHome);
  }

  // —— Restart recovery (fake, in-memory) ——

  /// Marks the current fake state as restored from a snapshot.
  void markRestoredFromSnapshot() {
    if (state.batch == null) return;
    state = state.copyWith(
      restoredFromSnapshot: true,
      routeStatus: BatchRouteStatus.restoredAfterRestart,
    );
  }

  /// Resumes the restored batch at the stop it was interrupted on.
  void resumeAfterRestore() {
    if (state.batch == null) return;
    state = state.copyWith(
      restoredFromSnapshot: false,
      routeStatus: _routeStatusFor(state.currentSequence),
    );
  }

  // —— internals ——

  Future<void> _pause() async {
    final service = _service;
    if (service is FakeBatchService) {
      await Future<void>.delayed(service.latency);
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }

  /// Records a journey stage transition without ever rewriting history.
  BatchState _withStage(BatchState next, BatchJourneyStage stage) {
    return next.copyWith(
      journeyStage: stage,
      stageHistory: List<BatchJourneyStage>.unmodifiable([
        ...next.stageHistory,
        stage,
      ]),
    );
  }

  void _advanceAfterResolution() {
    final batch = state.batch;
    if (batch == null) return;
    final remaining = batch.actionableStops;
    if (remaining.isEmpty) {
      state = state.copyWith(
        routeStatus: BatchRouteStatus.overview,
        callAttempts: 0,
        whatsappAttempts: 0,
      );
      finishBatchStatusOnly();
      return;
    }
    final next = remaining.first.sequence;
    // The batch is still picked up; the next stop starts from the route
    // overview and only becomes "en route" when the driver opens it.
    state = state.copyWith(
      currentSequence: next,
      routeStatus: BatchRouteStatus.overview,
      journeyStage: BatchJourneyStage.pickupConfirmedManually,
      callAttempts: 0,
      whatsappAttempts: 0,
    );
  }

  BatchRouteStatus _routeStatusFor(int sequence) {
    final batch = state.batch;
    if (batch == null) return BatchRouteStatus.overview;
    final actionable = batch.actionableStops;
    final isLast =
        actionable.length == 1 && actionable.first.sequence == sequence;
    if (isLast) return BatchRouteStatus.finalStop;
    return switch (sequence) {
      1 => BatchRouteStatus.activeStop1,
      2 => BatchRouteStatus.activeStop2,
      _ => BatchRouteStatus.activeStop,
    };
  }
}

final batchControllerProvider = NotifierProvider<BatchController, BatchState>(
  BatchController.new,
);

/// Fake proximity signal for the current stop (STEP 2C).
///
/// This models what STEP 4 will later get from real tracking. Here it is a
/// timer over in-memory data: no GPS, no geofence, no permissions, no plugin.
enum FakeBatchLocationSignal { idle, approachingCustomer, atCustomer }

class FakeBatchLocationState {
  const FakeBatchLocationState({
    this.signal = FakeBatchLocationSignal.idle,
    this.sequence,
  });

  final FakeBatchLocationSignal signal;

  /// Stop the signal refers to, or `null` while idle.
  final int? sequence;

  bool get isTracking => signal != FakeBatchLocationSignal.idle;
}

/// How long the fake signal takes to report arrival once a stop is opened.
///
/// Tests override this to drive the transition deterministically.
final fakeBatchArrivalDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 4),
);

/// Presentation-only location controller. The driver never triggers arrival:
/// opening a stop starts the signal, and the signal reports the arrival.
class FakeBatchLocationController extends Notifier<FakeBatchLocationState> {
  Timer? _timer;

  @override
  FakeBatchLocationState build() {
    ref.onDispose(_cancel);
    return const FakeBatchLocationState();
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Starts tracking towards [sequence] and schedules the automatic arrival.
  void startApproach(int sequence) {
    if (state.signal == FakeBatchLocationSignal.approachingCustomer &&
        state.sequence == sequence) {
      return;
    }
    _cancel();
    state = FakeBatchLocationState(
      signal: FakeBatchLocationSignal.approachingCustomer,
      sequence: sequence,
    );
    _timer = Timer(ref.read(fakeBatchArrivalDelayProvider), () {
      reportArrival(sequence);
    });
  }

  /// Reports the arrival for [sequence]. Read-only from the driver's side.
  void reportArrival(int sequence) {
    _cancel();
    state = FakeBatchLocationState(
      signal: FakeBatchLocationSignal.atCustomer,
      sequence: sequence,
    );
    ref
        .read(batchControllerProvider.notifier)
        .registerAutomaticArrivalByLocation(sequence);
  }

  void reset() {
    _cancel();
    state = const FakeBatchLocationState();
  }
}

final fakeBatchLocationControllerProvider =
    NotifierProvider<FakeBatchLocationController, FakeBatchLocationState>(
      FakeBatchLocationController.new,
    );
