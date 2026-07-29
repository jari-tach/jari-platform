/// Presentation-only view data for the STEP 2C Multi-Order Batch fake UI.
///
/// Nothing here is a production entity: there is no persistence, no backend
/// contract, no customer PII and no phone number. Every label a driver reads is
/// resolved from `AppLocalizations`; these records only carry synthetic
/// identifiers, sequences, distances and fake money.
library;

/// Independent per-order lifecycle inside a batch (P27 handoff 115:1435).
///
/// One order changing state never changes another order's state.
enum BatchOrderState {
  offered,
  preparing,
  readyForPickup,
  pickedUp,
  verified,
  headingToCustomer,
  arrived,
  delivered,
  deliveredPendingSync,
  customerUnavailable,
  cancelled,
  expired,
}

/// Mandatory driver journey contract (Figma 150:427 §1 and 39:35).
///
/// Pickup and delivery are confirmed manually by the driver; arrival at the
/// customer is a read-only state produced by location tracking. In STEP 2C the
/// location signal is a fake, presentation-only provider — never real GPS.
enum BatchJourneyStage {
  /// Every required order is ready and verified; the manual pickup action is
  /// armed but the batch has not been picked up yet.
  pickupAwaitingManualConfirmation,

  /// The driver pressed the manual pickup confirmation and it succeeded.
  pickupConfirmedManually,

  /// Driving to the current customer. Contact details stay locked.
  enRouteToCustomer,

  /// Arrival registered by the (fake) location signal. Read-only: there is no
  /// button, gesture or semantics action that means "I arrived".
  arrivedAutomaticallyByLocation,

  /// Arrival is registered and the manual delivery confirmation is armed.
  deliveryAwaitingManualConfirmation,

  /// The driver pressed the manual delivery confirmation and it succeeded.
  deliveredConfirmedManually,
}

/// Customer contact disclosure states (Figma 119:366 / 119:377 / 119:397).
enum BatchCustomerContactVisibility { locked, revealed, closed }

/// Why an order left the happy path. Rendered as text, never color alone.
enum BatchOrderIssueReason {
  none,
  customerUnavailable,
  merchantCancelled,
  addressUnreachable,
}

/// A single order inside the batch.
///
/// [sequence] is the stable stop order and always starts at 1. It never
/// changes once the batch is accepted, even when an order is cancelled.
class BatchOrderViewData {
  const BatchOrderViewData({
    required this.orderId,
    required this.sequence,
    required this.labelIndex,
    required this.distanceKm,
    required this.earningsSar,
    required this.state,
    this.issueReason = BatchOrderIssueReason.none,
  });

  /// Synthetic fixture identifier (e.g. `B-2031`). Never shown unmasked.
  final String orderId;

  /// Stable 1-based stop order.
  final int sequence;

  /// Index into the localized synthetic label set (first name + district).
  ///
  /// Customer wording never lives in view data: the screen resolves it from
  /// `AppLocalizations`, so no name or area string is hardcoded here.
  final int labelIndex;

  final double distanceKm;
  final double earningsSar;
  final BatchOrderState state;
  final BatchOrderIssueReason issueReason;

  /// Partially masked identifier — privacy rule: the driver sees enough to
  /// match a package label, never the full platform identifier.
  ///
  /// `B-2031` → `B-••31`.
  String get maskedOrderId {
    final separator = orderId.indexOf('-');
    final prefix = separator < 0 ? '' : orderId.substring(0, separator + 1);
    final body = separator < 0 ? orderId : orderId.substring(separator + 1);
    if (body.length <= 2) return '$prefix$body';
    final visible = body.substring(body.length - 2);
    return '$prefix${'•' * (body.length - 2)}$visible';
  }

  /// Terminal for batch progress: the stop no longer needs driver action.
  bool get isResolved => switch (state) {
    BatchOrderState.delivered ||
    BatchOrderState.deliveredPendingSync ||
    BatchOrderState.customerUnavailable ||
    BatchOrderState.cancelled ||
    BatchOrderState.expired => true,
    _ => false,
  };

  /// Counted as earned money in the fake summary.
  bool get isCompleted =>
      state == BatchOrderState.delivered ||
      state == BatchOrderState.deliveredPendingSync;

  /// Cancelled stops are excluded from the actionable stop list.
  bool get isActionable => !isResolved && state != BatchOrderState.cancelled;

  bool get isReadyForPickup =>
      state == BatchOrderState.readyForPickup ||
      state == BatchOrderState.pickedUp ||
      state == BatchOrderState.verified;

  bool get isVerified => state == BatchOrderState.verified;

  bool get isPendingSync => state == BatchOrderState.deliveredPendingSync;

  BatchOrderViewData copyWith({
    BatchOrderState? state,
    BatchOrderIssueReason? issueReason,
  }) {
    return BatchOrderViewData(
      orderId: orderId,
      sequence: sequence,
      labelIndex: labelIndex,
      distanceKm: distanceKm,
      earningsSar: earningsSar,
      state: state ?? this.state,
      issueReason: issueReason ?? this.issueReason,
    );
  }
}

/// Whole-batch offer aggregate (Figma 115:412 / 115:461).
///
/// v1 rules: one store, one pickup, 2–4 orders, whole-batch accept or reject.
class BatchOfferViewData {
  const BatchOfferViewData({
    required this.batchId,
    required this.orders,
    required this.totalDistanceKm,
    required this.etaMinutes,
    required this.totalEarningsSar,
    this.remainingSeconds = 0,
  });

  /// Synthetic batch identifier (e.g. `B-778`).
  final String batchId;

  /// Ordered by [BatchOrderViewData.sequence], ascending and stable.
  final List<BatchOrderViewData> orders;

  final double totalDistanceKm;
  final int etaMinutes;
  final double totalEarningsSar;

  /// Fake acceptance window. `0` renders the expired `00:00` metric.
  final int remainingSeconds;

  int get orderCount => orders.length;

  /// v1 batch size guard: minimum 2, maximum 4.
  bool get isWithinBatchSizeLimits => orderCount >= 2 && orderCount <= 4;

  int get readyCount => orders.where((o) => o.isReadyForPickup).length;

  int get verifiedCount => orders.where((o) => o.isVerified).length;

  int get completedCount => orders.where((o) => o.isCompleted).length;

  int get resolvedCount => orders.where((o) => o.isResolved).length;

  int get cancelledCount =>
      orders.where((o) => o.state == BatchOrderState.cancelled).length;

  int get unavailableCount => orders
      .where((o) => o.state == BatchOrderState.customerUnavailable)
      .length;

  /// Progress derives from resolved orders, never from screen index.
  double get progressFraction =>
      orderCount == 0 ? 0 : resolvedCount / orderCount;

  /// Actionable stops in stable sequence order; cancelled stops excluded.
  List<BatchOrderViewData> get actionableStops =>
      orders.where((o) => o.isActionable).toList(growable: false);

  bool get allResolved => orders.every((o) => o.isResolved);

  bool get allReadyForPickup => orders.every((o) => o.isReadyForPickup);

  bool get allVerified => orders.every((o) => o.isVerified);

  /// Orders the driver still has to carry: cancelled and expired stops drop
  /// out of the pickup gate instead of blocking the whole batch.
  List<BatchOrderViewData> get requiredOrders => orders
      .where(
        (o) =>
            o.state != BatchOrderState.cancelled &&
            o.state != BatchOrderState.expired,
      )
      .toList(growable: false);

  bool get allRequiredReadyForPickup =>
      requiredOrders.every((o) => o.isReadyForPickup);

  bool get allRequiredVerified => requiredOrders.every((o) => o.isVerified);

  /// Journey rule 1: the route cannot start before every required order is
  /// both ready and verified. Verification alone never completes pickup.
  bool get canConfirmPickupManually =>
      requiredOrders.isNotEmpty &&
      allRequiredReadyForPickup &&
      allRequiredVerified;

  /// Fake money actually earned: completed orders only.
  double get earnedSar => orders
      .where((o) => o.isCompleted)
      .fold<double>(0, (sum, o) => sum + o.earningsSar);

  BatchOrderViewData? orderBySequence(int sequence) {
    for (final order in orders) {
      if (order.sequence == sequence) return order;
    }
    return null;
  }

  BatchOrderViewData? orderById(String orderId) {
    for (final order in orders) {
      if (order.orderId == orderId) return order;
    }
    return null;
  }

  BatchOfferViewData copyWith({
    List<BatchOrderViewData>? orders,
    int? remainingSeconds,
  }) {
    return BatchOfferViewData(
      batchId: batchId,
      orders: orders ?? this.orders,
      totalDistanceKm: totalDistanceKm,
      etaMinutes: etaMinutes,
      totalEarningsSar: totalEarningsSar,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  /// Replaces one order without touching the others (rule 5).
  BatchOfferViewData withOrder(BatchOrderViewData replacement) {
    return copyWith(
      orders: [
        for (final order in orders)
          if (order.orderId == replacement.orderId) replacement else order,
      ],
    );
  }
}

/// Pickup readiness + verification view (Figma 115:581 / 115:637 / 115:693).
class BatchPickupViewData {
  const BatchPickupViewData({required this.batch});

  final BatchOfferViewData batch;

  int get readyCount => batch.readyCount;
  int get verifiedCount => batch.verifiedCount;
  int get orderCount => batch.orderCount;
  bool get allReady => batch.allReadyForPickup;
  bool get allVerified => batch.allVerified;

  /// First order still awaiting a verification scan, in stable order.
  BatchOrderViewData? get nextUnverified {
    for (final order in batch.orders) {
      if (!order.isVerified) return order;
    }
    return null;
  }
}

/// Current customer stop (Figma 115:786 / 115:837 / 115:955).
///
/// Privacy: exposes only the current order plus a generic hint about the next
/// stop. It never carries the next customer's address or identity.
class BatchStopViewData {
  const BatchStopViewData({
    required this.batch,
    required this.sequence,
    required this.order,
    this.nextSequence,
  });

  final BatchOfferViewData batch;
  final int sequence;
  final BatchOrderViewData order;

  /// Sequence of the following actionable stop, or `null` when this is last.
  final int? nextSequence;

  bool get isFinalStop => nextSequence == null;

  int get resolvedCount => batch.resolvedCount;
  int get orderCount => batch.orderCount;
}

/// Current-stop customer contact (Figma 119:406 and its three variants).
///
/// Privacy: the card is built for exactly one order — the current stop. It
/// carries a label index, never another customer's data, and the phone number
/// it resolves is a synthetic fixture value.
class BatchCustomerContactViewData {
  const BatchCustomerContactViewData({
    required this.visibility,
    required this.labelIndex,
    this.callAttempts = 0,
    this.whatsappAttempts = 0,
  });

  final BatchCustomerContactVisibility visibility;
  final int labelIndex;
  final int callAttempts;
  final int whatsappAttempts;

  bool get isRevealed => visibility == BatchCustomerContactVisibility.revealed;

  bool get isClosed => visibility == BatchCustomerContactVisibility.closed;

  int get totalAttempts => callAttempts + whatsappAttempts;
}

/// Batch closing summary (Figma 115:1142 / 115:1196).
class BatchSummaryViewData {
  const BatchSummaryViewData({required this.batch});

  final BatchOfferViewData batch;

  List<BatchOrderViewData> get completedOrders =>
      batch.orders.where((o) => o.isCompleted).toList(growable: false);

  List<BatchOrderViewData> get incompleteOrders =>
      batch.orders.where((o) => !o.isCompleted).toList(growable: false);

  int get completedCount => batch.completedCount;
  int get unavailableCount => batch.unavailableCount;
  int get cancelledCount => batch.cancelledCount;
  double get totalEarnedSar => batch.earnedSar;
  bool get includesCancelledOrder => batch.cancelledCount > 0;
  bool get isFullyCompleted => completedCount == batch.orderCount;
}
