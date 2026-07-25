/// Connectivity change signal for domain orchestration (no device listeners).
class AvailabilityConnectivityChange {
  AvailabilityConnectivityChange({
    required this.driverId,
    required this.isOnline,
    required this.changedAt,
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
  final bool isOnline;
  final DateTime changedAt;
  final String? correlationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityConnectivityChange &&
          driverId == other.driverId &&
          isOnline == other.isOnline &&
          changedAt == other.changedAt &&
          correlationId == other.correlationId;

  @override
  int get hashCode => Object.hash(driverId, isOnline, changedAt, correlationId);
}
