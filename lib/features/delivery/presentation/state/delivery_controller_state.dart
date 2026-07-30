import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/failures/delivery_failure.dart';

/// Application lifecycle for [DeliveryController].
enum DeliveryViewStatus { initial, loading, ready, processing, failure }

/// In-flight user/system command while retaining last ready payloads.
enum DeliveryProcessingAction {
  none,
  accepting,
  rejecting,
  refreshing,
  advancing,
  verifying,
  completing,
}

/// Immutable UI-consumable delivery state (PHASE 2.5 presentation).
///
/// No BuildContext, localization, datasources, or storage types.
class DeliveryControllerState {
  const DeliveryControllerState({
    required this.status,
    this.offers = const [],
    this.activeOffer,
    this.activeAssignment,
    this.lastAcceptedAssignment,
    this.failure,
    this.processingAction = DeliveryProcessingAction.none,
    this.isInitialized = false,
    this.isRestored = false,
    this.boundDriverId,
  });

  const DeliveryControllerState.initial()
    : this(status: DeliveryViewStatus.initial);

  const DeliveryControllerState.loading({String? boundDriverId})
    : this(status: DeliveryViewStatus.loading, boundDriverId: boundDriverId);

  factory DeliveryControllerState.ready({
    required List<DeliveryOffer> offers,
    DeliveryOffer? activeOffer,
    DeliveryAssignment? activeAssignment,
    DeliveryAssignment? lastAcceptedAssignment,
    String? boundDriverId,
    bool isRestored = false,
  }) {
    final resolvedOffer = activeOffer ?? (offers.isEmpty ? null : offers.first);
    return DeliveryControllerState(
      status: DeliveryViewStatus.ready,
      offers: List<DeliveryOffer>.unmodifiable(offers),
      activeOffer: resolvedOffer,
      activeAssignment: activeAssignment,
      lastAcceptedAssignment: lastAcceptedAssignment,
      isInitialized: true,
      isRestored: isRestored,
      boundDriverId: boundDriverId,
      processingAction: DeliveryProcessingAction.none,
    );
  }

  factory DeliveryControllerState.processing({
    required DeliveryProcessingAction action,
    required List<DeliveryOffer> offers,
    DeliveryOffer? activeOffer,
    DeliveryAssignment? activeAssignment,
    DeliveryAssignment? lastAcceptedAssignment,
    String? boundDriverId,
  }) {
    final resolvedOffer = activeOffer ?? (offers.isEmpty ? null : offers.first);
    return DeliveryControllerState(
      status: DeliveryViewStatus.processing,
      offers: List<DeliveryOffer>.unmodifiable(offers),
      activeOffer: resolvedOffer,
      activeAssignment: activeAssignment,
      lastAcceptedAssignment: lastAcceptedAssignment,
      isInitialized: true,
      boundDriverId: boundDriverId,
      processingAction: action,
    );
  }

  factory DeliveryControllerState.failure({
    required DeliveryFailure failure,
    List<DeliveryOffer> offers = const [],
    DeliveryOffer? activeOffer,
    DeliveryAssignment? activeAssignment,
    DeliveryAssignment? lastAcceptedAssignment,
    bool isInitialized = true,
    String? boundDriverId,
  }) {
    final resolvedOffer = activeOffer ?? (offers.isEmpty ? null : offers.first);
    return DeliveryControllerState(
      status: DeliveryViewStatus.failure,
      failure: failure,
      offers: List<DeliveryOffer>.unmodifiable(offers),
      activeOffer: resolvedOffer,
      activeAssignment: activeAssignment,
      lastAcceptedAssignment: lastAcceptedAssignment,
      isInitialized: isInitialized,
      boundDriverId: boundDriverId,
    );
  }

  final DeliveryViewStatus status;
  final List<DeliveryOffer> offers;
  final DeliveryOffer? activeOffer;
  final DeliveryAssignment? activeAssignment;
  final DeliveryAssignment? lastAcceptedAssignment;
  final DeliveryFailure? failure;
  final DeliveryProcessingAction processingAction;
  final bool isInitialized;
  final bool isRestored;
  final String? boundDriverId;

  bool get isLoading => status == DeliveryViewStatus.loading;

  bool get isProcessing => status == DeliveryViewStatus.processing;

  bool get isEmpty =>
      isInitialized &&
      !isLoading &&
      activeOffer == null &&
      offers.isEmpty &&
      activeAssignment == null;

  bool get hasOffer => activeOffer != null;

  bool get hasActiveAssignment => activeAssignment != null;

  bool get canAccept =>
      isInitialized &&
      !isProcessing &&
      !isLoading &&
      activeOffer != null &&
      activeAssignment == null;

  bool get canReject => canAccept;

  bool get canRefresh => isInitialized && !isProcessing && !isLoading;

  DeliveryControllerState copyWith({
    DeliveryViewStatus? status,
    List<DeliveryOffer>? offers,
    DeliveryOffer? activeOffer,
    bool clearActiveOffer = false,
    DeliveryAssignment? activeAssignment,
    bool clearActiveAssignment = false,
    DeliveryAssignment? lastAcceptedAssignment,
    bool clearLastAcceptedAssignment = false,
    DeliveryFailure? failure,
    bool clearFailure = false,
    DeliveryProcessingAction? processingAction,
    bool? isInitialized,
    bool? isRestored,
    String? boundDriverId,
    bool clearBoundDriverId = false,
  }) {
    return DeliveryControllerState(
      status: status ?? this.status,
      offers: offers ?? this.offers,
      activeOffer: clearActiveOffer ? null : (activeOffer ?? this.activeOffer),
      activeAssignment: clearActiveAssignment
          ? null
          : (activeAssignment ?? this.activeAssignment),
      lastAcceptedAssignment: clearLastAcceptedAssignment
          ? null
          : (lastAcceptedAssignment ?? this.lastAcceptedAssignment),
      failure: clearFailure ? null : (failure ?? this.failure),
      processingAction: processingAction ?? this.processingAction,
      isInitialized: isInitialized ?? this.isInitialized,
      isRestored: isRestored ?? this.isRestored,
      boundDriverId: clearBoundDriverId
          ? null
          : (boundDriverId ?? this.boundDriverId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryControllerState &&
          status == other.status &&
          _listEquals(offers, other.offers) &&
          activeOffer == other.activeOffer &&
          activeAssignment == other.activeAssignment &&
          lastAcceptedAssignment == other.lastAcceptedAssignment &&
          failure == other.failure &&
          processingAction == other.processingAction &&
          isInitialized == other.isInitialized &&
          isRestored == other.isRestored &&
          boundDriverId == other.boundDriverId;

  @override
  int get hashCode => Object.hash(
    status,
    Object.hashAll(offers),
    activeOffer,
    activeAssignment,
    lastAcceptedAssignment,
    failure,
    processingAction,
    isInitialized,
    isRestored,
    boundDriverId,
  );

  static bool _listEquals(List<DeliveryOffer> a, List<DeliveryOffer> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
