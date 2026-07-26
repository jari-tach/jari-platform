/// Input for rejecting a [DeliveryOffer] (PHASE 2.5).
class RejectDeliveryOfferRequest {
  /// Creates a reject request.
  ///
  /// Throws [ArgumentError] when identity fields are empty.
  RejectDeliveryOfferRequest({
    required this.driverId,
    required this.offerId,
    this.idempotencyKey,
    this.reasonCode,
    this.correlationId,
    this.connectivityOnline = true,
  }) {
    final did = driverId.trim();
    if (did.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    final oid = offerId.trim();
    if (oid.isEmpty) {
      throw ArgumentError.value(offerId, 'offerId', 'must be non-empty');
    }
    if (idempotencyKey != null && idempotencyKey!.trim().isEmpty) {
      throw ArgumentError.value(
        idempotencyKey,
        'idempotencyKey',
        'when present must be non-empty',
      );
    }
    if (reasonCode != null && reasonCode!.trim().isEmpty) {
      throw ArgumentError.value(
        reasonCode,
        'reasonCode',
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

  /// Optional idempotency key when networked reject is retried.
  final String? idempotencyKey;

  /// Optional machine reason code (not free-form PII).
  final String? reasonCode;

  final String? correlationId;

  /// Connectivity fact; reject may proceed offline without creating assignment.
  final bool connectivityOnline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RejectDeliveryOfferRequest &&
          driverId == other.driverId &&
          offerId == other.offerId &&
          idempotencyKey == other.idempotencyKey &&
          reasonCode == other.reasonCode &&
          correlationId == other.correlationId &&
          connectivityOnline == other.connectivityOnline;

  @override
  int get hashCode => Object.hash(
    driverId,
    offerId,
    idempotencyKey,
    reasonCode,
    correlationId,
    connectivityOnline,
  );
}
