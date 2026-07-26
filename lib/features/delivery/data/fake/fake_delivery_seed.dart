import '../../domain/entities/delivery_offer_status.dart';
import '../../domain/entities/delivery_status.dart';
import '../models/delivery_assignment_model.dart';
import '../models/delivery_offer_model.dart';
import '../models/delivery_order_model.dart';

/// Deterministic seed configuration for [FakeDeliveryRemoteDataSource].
///
/// Same [key] + inputs always yield the same offer / assignment identities.
/// No I/O and no global state.
class FakeDeliverySeed {
  /// Creates immutable seed options.
  const FakeDeliverySeed({
    this.key = defaultKey,
    this.offerTtl = const Duration(minutes: 2),
    this.autoIssueOnFetch = true,
  });

  /// Default deterministic seed key (PHASE 2.6 Fake remote).
  static const defaultKey = 'saeq-delivery-fake-v1';

  /// Opaque seed material mixed into all generated ids.
  final String key;

  /// Offer decision window length from issuance time.
  final Duration offerTtl;

  /// When true, [FakeDeliveryRemoteDataSource.fetchOffers] mints an offer if
  /// the driver has none active.
  final bool autoIssueOnFetch;

  /// Stable hex token derived from [key] and [parts].
  String token(List<String> parts) {
    final material = <String>[key, ...parts].join('|');
    return _fnv1a32(material).toRadixString(16).padLeft(8, '0');
  }

  /// Builds a deterministic offer model for [driverId] at sequence [sequence].
  DeliveryOfferModel buildOffer({
    required String driverId,
    required int sequence,
    required DateTime now,
  }) {
    final issuedAt = now.toUtc();
    final expiresAt = issuedAt.add(offerTtl);
    final seq = sequence.toString();
    final offerId = 'off-${token(['offer', driverId, seq])}';
    final orderId = 'ord-${token(['order', driverId, seq])}';
    final revision = 'rev-${token(['revision', driverId, seq])}';
    final correlationId = 'corr-${token(['correlation', driverId, seq])}';

    // Deterministic labels from token nibbles (stable, non-PII).
    final placeToken = token(['place', driverId, seq]);
    final pickupLabel = 'Pickup $placeToken';
    final dropoffLabel = 'Dropoff $placeToken';
    final merchantDisplayName = 'Merchant $placeToken';

    // Distance / ETA derived from token for realism without randomness.
    final numeric = int.parse(placeToken.substring(0, 4), radix: 16);
    final distanceMeters = 500.0 + (numeric % 4500);
    final etaMinutes = 5 + (numeric % 40);

    return DeliveryOfferModel(
      offerId: offerId,
      driverId: driverId,
      status: DeliveryOfferStatus.offered.name,
      order: DeliveryOrderModel(
        orderId: orderId,
        pickupLabel: pickupLabel,
        dropoffLabel: dropoffLabel,
        merchantDisplayName: merchantDisplayName,
        distanceMeters: distanceMeters,
        etaMinutes: etaMinutes,
        notes: 'fake-seed:$key',
      ),
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      revision: revision,
      correlationId: correlationId,
    );
  }

  /// Builds a server-style assignment from an accepted [offer].
  DeliveryAssignmentModel buildAssignment({
    required DeliveryOfferModel offer,
    required DateTime acceptedAt,
  }) {
    final at = acceptedAt.toUtc();
    final assignmentId =
        'asg-${token(['assignment', offer.offerId, offer.driverId])}';
    final serverRevision =
        'srev-${token(['server-revision', offer.offerId, at.toIso8601String()])}';

    return DeliveryAssignmentModel(
      assignmentId: assignmentId,
      offerId: offer.offerId,
      driverId: offer.driverId,
      status: DeliveryStatus.accepted.name,
      order: offer.order,
      acceptedAt: at,
      serverRevision: serverRevision,
      workflowStage: 'assigned',
    );
  }

  /// 32-bit FNV-1a — stable across processes (unlike [Object.hashCode]).
  static int _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
