/// Logout-time local availability invalidation request.
class LogoutAvailabilityRequest {
  LogoutAvailabilityRequest({
    required this.driverId,
    required this.logoutAt,
    required this.connectivityOnline,
    this.correlationId,
  }) {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    if (correlationId != null && correlationId!.trim().isEmpty) {
      throw ArgumentError.value(
        correlationId,
        'correlationId',
        'when present must be non-empty',
      );
    }
  }

  final String driverId;
  final DateTime logoutAt;
  final bool connectivityOnline;
  final String? correlationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogoutAvailabilityRequest &&
          driverId == other.driverId &&
          logoutAt == other.logoutAt &&
          connectivityOnline == other.connectivityOnline &&
          correlationId == other.correlationId;

  @override
  int get hashCode =>
      Object.hash(driverId, logoutAt, connectivityOnline, correlationId);
}
