import '../../domain/entities/realtime_connection_status.dart';

/// Presentation state for the quiet realtime connection banner.
final class RealtimeControllerState {
  const RealtimeControllerState({required this.status, this.driverId});

  const RealtimeControllerState.idle()
    : status = RealtimeConnectionStatus.idle,
      driverId = null;

  final RealtimeConnectionStatus status;
  final String? driverId;

  bool get showBanner => switch (status) {
    RealtimeConnectionStatus.reconnecting ||
    RealtimeConnectionStatus.degraded ||
    RealtimeConnectionStatus.catchingUp => true,
    RealtimeConnectionStatus.idle ||
    RealtimeConnectionStatus.connected ||
    RealtimeConnectionStatus.stopped => false,
  };

  RealtimeControllerState copyWith({
    RealtimeConnectionStatus? status,
    String? driverId,
    bool clearDriverId = false,
  }) {
    return RealtimeControllerState(
      status: status ?? this.status,
      driverId: clearDriverId ? null : (driverId ?? this.driverId),
    );
  }
}
