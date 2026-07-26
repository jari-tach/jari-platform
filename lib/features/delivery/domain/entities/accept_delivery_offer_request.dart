/// Input for accepting a [DeliveryOffer] (PHASE 2.5).
///
/// Carries explicit preconditions so use cases do not invent eligibility or
/// connectivity facts (ADR-024 / availability default-deny posture).
class AcceptDeliveryOfferRequest {
  /// Creates an accept request.
  ///
  /// Throws [ArgumentError] when identity or idempotency fields are empty.
  AcceptDeliveryOfferRequest({
    required this.driverId,
    required this.offerId,
    required this.idempotencyKey,
    required this.connectivityOnline,
    required this.isConfirmedAvailable,
    this.revision,
    this.correlationId,
    this.hasActiveAssignment = false,
  }) {
    final did = driverId.trim();
    if (did.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    final oid = offerId.trim();
    if (oid.isEmpty) {
      throw ArgumentError.value(offerId, 'offerId', 'must be non-empty');
    }
    final key = idempotencyKey.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(
        idempotencyKey,
        'idempotencyKey',
        'must be non-empty',
      );
    }
    if (revision != null && revision!.trim().isEmpty) {
      throw ArgumentError.value(
        revision,
        'revision',
        'when present must be non-empty',
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
  final String offerId;

  /// Client-generated idempotency key for accept (roadmap / ADR security).
  final String idempotencyKey;

  /// Current connectivity fact from NetworkMonitor (not invented here).
  final bool connectivityOnline;

  /// Whether availability is **confirmed** available (not restored-unconfirmed).
  final bool isConfirmedAvailable;

  /// Optional offer revision for conflict detection.
  final String? revision;

  final String? correlationId;

  /// When true, accept must be denied (MVP one active delivery).
  final bool hasActiveAssignment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AcceptDeliveryOfferRequest &&
          driverId == other.driverId &&
          offerId == other.offerId &&
          idempotencyKey == other.idempotencyKey &&
          connectivityOnline == other.connectivityOnline &&
          isConfirmedAvailable == other.isConfirmedAvailable &&
          revision == other.revision &&
          correlationId == other.correlationId &&
          hasActiveAssignment == other.hasActiveAssignment;

  @override
  int get hashCode => Object.hash(
    driverId,
    offerId,
    idempotencyKey,
    connectivityOnline,
    isConfirmedAvailable,
    revision,
    correlationId,
    hasActiveAssignment,
  );
}
