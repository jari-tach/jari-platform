import 'driver_availability.dart';

/// Explicit reconciliation request (contract only — no engine in Increment 2).
class AvailabilityReconciliationRequest {
  AvailabilityReconciliationRequest({
    required this.driverId,
    required this.requestedAt,
    this.localState,
    this.lastKnownRevision,
    this.correlationId,
  }) {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    if (lastKnownRevision != null && lastKnownRevision! < 0) {
      throw ArgumentError.value(
        lastKnownRevision,
        'lastKnownRevision',
        'cannot be negative',
      );
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
  final DateTime requestedAt;
  final DriverAvailability? localState;
  final int? lastKnownRevision;
  final String? correlationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityReconciliationRequest &&
          driverId == other.driverId &&
          requestedAt == other.requestedAt &&
          localState == other.localState &&
          lastKnownRevision == other.lastKnownRevision &&
          correlationId == other.correlationId;

  @override
  int get hashCode => Object.hash(
    driverId,
    requestedAt,
    localState,
    lastKnownRevision,
    correlationId,
  );
}
