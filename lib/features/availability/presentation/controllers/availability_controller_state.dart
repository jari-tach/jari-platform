import '../../domain/entities/availability_status.dart';
import '../../domain/entities/driver_availability.dart';
import '../../domain/failures/availability_failure.dart';

/// Application lifecycle for [AvailabilityController].
enum AvailabilityViewStatus { initial, loading, ready, processing, failure }

/// Immutable UI-consumable availability state (PHASE 2.4 Increment 4).
///
/// No BuildContext, localization, or storage types.
class AvailabilityControllerState {
  const AvailabilityControllerState({
    required this.status,
    this.current,
    this.lastStable,
    this.failure,
    this.isInitialized = false,
    this.isRestored = false,
    this.boundDriverId,
  });

  const AvailabilityControllerState.initial()
    : this(status: AvailabilityViewStatus.initial);

  const AvailabilityControllerState.loading({String? boundDriverId})
    : this(
        status: AvailabilityViewStatus.loading,
        boundDriverId: boundDriverId,
      );

  factory AvailabilityControllerState.ready({
    required DriverAvailability current,
    DriverAvailability? lastStable,
    bool isRestored = false,
    String? boundDriverId,
  }) => AvailabilityControllerState(
    status: AvailabilityViewStatus.ready,
    current: current,
    lastStable: lastStable ?? current,
    isInitialized: true,
    isRestored: isRestored,
    boundDriverId: boundDriverId ?? current.driverId,
  );

  factory AvailabilityControllerState.processing({
    required DriverAvailability? current,
    DriverAvailability? lastStable,
    bool isRestored = false,
    String? boundDriverId,
  }) => AvailabilityControllerState(
    status: AvailabilityViewStatus.processing,
    current: current,
    lastStable: lastStable ?? current,
    isInitialized: true,
    isRestored: isRestored,
    boundDriverId: boundDriverId ?? current?.driverId,
  );

  factory AvailabilityControllerState.failure({
    required AvailabilityFailure failure,
    DriverAvailability? current,
    DriverAvailability? lastStable,
    bool isInitialized = true,
    bool isRestored = false,
    String? boundDriverId,
  }) => AvailabilityControllerState(
    status: AvailabilityViewStatus.failure,
    failure: failure,
    current: current,
    lastStable: lastStable ?? current,
    isInitialized: isInitialized,
    isRestored: isRestored,
    boundDriverId: boundDriverId ?? current?.driverId,
  );

  final AvailabilityViewStatus status;
  final DriverAvailability? current;
  final DriverAvailability? lastStable;
  final AvailabilityFailure? failure;
  final bool isInitialized;
  final bool isRestored;
  final String? boundDriverId;

  bool get isProcessing => status == AvailabilityViewStatus.processing;

  bool get isConfirmedAvailable => current?.isConfirmedAvailable ?? false;

  bool get isPendingConfirmation {
    final value = current;
    if (value == null) return false;
    return value.status == AvailabilityStatus.available &&
        (value.pendingSync ||
            value.source == AvailabilitySource.restoredLocalState ||
            value.lastConfirmedAt == null);
  }

  bool get isRestoredUnconfirmedAvailable =>
      current?.isRestoredUnconfirmedAvailable ?? false;

  bool get isBusy => current?.status == AvailabilityStatus.busy;

  bool get isOffline => current?.status == AvailabilityStatus.offline;

  bool get canRequestAvailable =>
      isInitialized &&
      !isProcessing &&
      !isBusy &&
      !isOffline &&
      current != null &&
      current!.status != AvailabilityStatus.available;

  bool get canRequestUnavailable =>
      isInitialized &&
      !isProcessing &&
      !isBusy &&
      current?.status == AvailabilityStatus.available;

  AvailabilityControllerState copyWith({
    AvailabilityViewStatus? status,
    DriverAvailability? current,
    DriverAvailability? lastStable,
    AvailabilityFailure? failure,
    bool clearFailure = false,
    bool? isInitialized,
    bool? isRestored,
    String? boundDriverId,
    bool clearBoundDriverId = false,
  }) {
    return AvailabilityControllerState(
      status: status ?? this.status,
      current: current ?? this.current,
      lastStable: lastStable ?? this.lastStable,
      failure: clearFailure ? null : (failure ?? this.failure),
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
      other is AvailabilityControllerState &&
          status == other.status &&
          current == other.current &&
          lastStable == other.lastStable &&
          failure == other.failure &&
          isInitialized == other.isInitialized &&
          isRestored == other.isRestored &&
          boundDriverId == other.boundDriverId;

  @override
  int get hashCode => Object.hash(
    status,
    current,
    lastStable,
    failure,
    isInitialized,
    isRestored,
    boundDriverId,
  );
}
