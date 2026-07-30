/// Immutable work description shared by offers and assignments (PHASE 2.5).
///
/// This is **not** a lifecycle owner and must not be confused with an
/// unaccepted [DeliveryOffer] or with Drift's scaffold `DeliveryOrders` table
/// (ADR-020 / ADR-028). It carries safe display/snapshot fields only.
///
/// Optional WGS84 coordinates (STEP 4 / ADR-029) are local Fake/device geofence
/// fixtures — not a Backend schema claim.
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
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
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
    _validatePair('pickup', pickupLatitude, pickupLongitude);
    _validatePair('dropoff', dropoffLatitude, dropoffLongitude);
  }

  static void _validatePair(String label, double? lat, double? lon) {
    if ((lat == null) != (lon == null)) {
      throw ArgumentError('$label latitude/longitude must both be set or null');
    }
    if (lat != null && (lat < -90 || lat > 90 || !lat.isFinite)) {
      throw ArgumentError.value(lat, '${label}Latitude', 'invalid');
    }
    if (lon != null && (lon < -180 || lon > 180 || !lon.isFinite)) {
      throw ArgumentError.value(lon, '${label}Longitude', 'invalid');
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

  /// Optional pickup WGS84 latitude (local Fake / STEP 4 geofence).
  final double? pickupLatitude;

  /// Optional pickup WGS84 longitude.
  final double? pickupLongitude;

  /// Optional dropoff WGS84 latitude (customer geofence target).
  final double? dropoffLatitude;

  /// Optional dropoff WGS84 longitude.
  final double? dropoffLongitude;

  bool get hasPickupCoordinates =>
      pickupLatitude != null && pickupLongitude != null;

  bool get hasDropoffCoordinates =>
      dropoffLatitude != null && dropoffLongitude != null;

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
    double? pickupLatitude,
    double? pickupLongitude,
    bool clearPickupCoordinates = false,
    double? dropoffLatitude,
    double? dropoffLongitude,
    bool clearDropoffCoordinates = false,
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
      pickupLatitude: clearPickupCoordinates
          ? null
          : (pickupLatitude ?? this.pickupLatitude),
      pickupLongitude: clearPickupCoordinates
          ? null
          : (pickupLongitude ?? this.pickupLongitude),
      dropoffLatitude: clearDropoffCoordinates
          ? null
          : (dropoffLatitude ?? this.dropoffLatitude),
      dropoffLongitude: clearDropoffCoordinates
          ? null
          : (dropoffLongitude ?? this.dropoffLongitude),
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
          notes == other.notes &&
          pickupLatitude == other.pickupLatitude &&
          pickupLongitude == other.pickupLongitude &&
          dropoffLatitude == other.dropoffLatitude &&
          dropoffLongitude == other.dropoffLongitude;

  @override
  int get hashCode => Object.hash(
    orderId,
    pickupLabel,
    dropoffLabel,
    merchantDisplayName,
    distanceMeters,
    etaMinutes,
    notes,
    pickupLatitude,
    pickupLongitude,
    dropoffLatitude,
    dropoffLongitude,
  );

  @override
  String toString() =>
      'DeliveryOrder(orderId: $orderId, pickup: $pickupLabel, '
      'dropoff: $dropoffLabel)';
}
