import 'delivery_offer_status.dart';
import 'delivery_order.dart';

/// Time-bounded invitation for a driver to accept work (ADR-020 / ADR-021).
///
/// Never implies [DeliveryAssignment] ownership or availability `busy`.
class DeliveryOffer {
  /// Creates an immutable delivery offer.
  ///
  /// Throws [ArgumentError] when identity fields are empty or the expiry
  /// window is inverted.
  DeliveryOffer({
    required this.offerId,
    required this.driverId,
    required this.status,
    required this.order,
    required this.issuedAt,
    required this.expiresAt,
    this.revision,
    this.correlationId,
  }) {
    final oid = offerId.trim();
    if (oid.isEmpty) {
      throw ArgumentError.value(offerId, 'offerId', 'must be non-empty');
    }
    final did = driverId.trim();
    if (did.isEmpty) {
      throw ArgumentError.value(driverId, 'driverId', 'must be non-empty');
    }
    if (expiresAt.isBefore(issuedAt)) {
      throw ArgumentError('expiresAt must be on or after issuedAt');
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

  /// Stable offer identity from Backend / Fake authority.
  final String offerId;

  /// Must match the authenticated session driver id.
  final String driverId;

  /// Decision-window status (ADR-021).
  final DeliveryOfferStatus status;

  /// Safe work summary payload (not lifecycle ownership).
  final DeliveryOrder order;

  /// Authority-preferred issuance timestamp.
  final DateTime issuedAt;

  /// Authority-preferred expiry timestamp.
  final DateTime expiresAt;

  /// Opaque conflict / concurrency token when provided.
  final String? revision;

  /// Optional tracing correlation id.
  final String? correlationId;

  /// Whether the offer window has passed [at] (presentation aid; server wins).
  bool isExpiredAt(DateTime at) => !at.isBefore(expiresAt);

  /// Returns a copy with selected fields replaced.
  ///
  /// [offerId] and [driverId] are sovereign and cannot change.
  DeliveryOffer copyWith({
    DeliveryOfferStatus? status,
    DeliveryOrder? order,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? revision,
    bool clearRevision = false,
    String? correlationId,
    bool clearCorrelationId = false,
  }) {
    return DeliveryOffer(
      offerId: offerId,
      driverId: driverId,
      status: status ?? this.status,
      order: order ?? this.order,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revision: clearRevision ? null : (revision ?? this.revision),
      correlationId: clearCorrelationId
          ? null
          : (correlationId ?? this.correlationId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOffer &&
          offerId == other.offerId &&
          driverId == other.driverId &&
          status == other.status &&
          order == other.order &&
          issuedAt == other.issuedAt &&
          expiresAt == other.expiresAt &&
          revision == other.revision &&
          correlationId == other.correlationId;

  @override
  int get hashCode => Object.hash(
    offerId,
    driverId,
    status,
    order,
    issuedAt,
    expiresAt,
    revision,
    correlationId,
  );

  @override
  String toString() =>
      'DeliveryOffer(offerId: $offerId, driverId: $driverId, status: $status)';
}
