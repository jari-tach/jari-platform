/// Immutable work description shared by offers and assignments (PHASE 2.5).
///
/// This is **not** a lifecycle owner and must not be confused with an
/// unaccepted [DeliveryOffer] or with Drift's scaffold `DeliveryOrders` table
/// (ADR-020 / ADR-028). It carries safe display/snapshot fields only.
class DeliveryOrder {
  /// Creates a delivery order payload.
  ///
  /// Throws [ArgumentError] when [orderId] is empty.
  DeliveryOrder({
    required this.orderId,
    required this.pickupLabel,
    required this.dropoffLabel,
    this.merchantDisplayName,
    this.distanceMeters,
    this.etaMinutes,
    this.notes,
  }) {
    final id = orderId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(orderId, 'orderId', 'must be non-empty');
    }
    if (distanceMeters != null && distanceMeters! < 0) {
      throw ArgumentError.value(
        distanceMeters,
        'distanceMeters',
        'cannot be negative',
      );
    }
    if (etaMinutes != null && etaMinutes! < 0) {
      throw ArgumentError.value(etaMinutes, 'etaMinutes', 'cannot be negative');
    }
  }

  /// Stable order identity from Backend / Fake authority.
  final String orderId;

  /// Human-readable pickup summary (not a raw GPS dump requirement).
  final String pickupLabel;

  /// Human-readable dropoff summary.
  final String dropoffLabel;

  /// Optional merchant label when the Backend permits display.
  final String? merchantDisplayName;

  /// Optional rough distance in meters when provided by authority.
  final double? distanceMeters;

  /// Optional ETA in minutes when provided by authority.
  final int? etaMinutes;

  /// Optional non-sensitive notes for the driver.
  final String? notes;

  /// Returns a copy with selected fields replaced.
  DeliveryOrder copyWith({
    String? pickupLabel,
    String? dropoffLabel,
    String? merchantDisplayName,
    bool clearMerchantDisplayName = false,
    double? distanceMeters,
    bool clearDistanceMeters = false,
    int? etaMinutes,
    bool clearEtaMinutes = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return DeliveryOrder(
      orderId: orderId,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      dropoffLabel: dropoffLabel ?? this.dropoffLabel,
      merchantDisplayName: clearMerchantDisplayName
          ? null
          : (merchantDisplayName ?? this.merchantDisplayName),
      distanceMeters: clearDistanceMeters
          ? null
          : (distanceMeters ?? this.distanceMeters),
      etaMinutes: clearEtaMinutes ? null : (etaMinutes ?? this.etaMinutes),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOrder &&
          orderId == other.orderId &&
          pickupLabel == other.pickupLabel &&
          dropoffLabel == other.dropoffLabel &&
          merchantDisplayName == other.merchantDisplayName &&
          distanceMeters == other.distanceMeters &&
          etaMinutes == other.etaMinutes &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(
    orderId,
    pickupLabel,
    dropoffLabel,
    merchantDisplayName,
    distanceMeters,
    etaMinutes,
    notes,
  );

  @override
  String toString() =>
      'DeliveryOrder(orderId: $orderId, pickup: $pickupLabel, '
      'dropoff: $dropoffLabel)';
}
