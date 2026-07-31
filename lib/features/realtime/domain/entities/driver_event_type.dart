/// Contract `EventType` taxonomy from contracts-v0.2.0 (STEP 6-A).
///
/// Unknown wire values must be ignored safely for forward compatibility —
/// never throw, never invent new names.
enum DriverEventType {
  offerCreated('offer.created'),
  offerAccepted('offer.accepted'),
  offerRejected('offer.rejected'),
  offerExpired('offer.expired'),
  deliveryStateChanged('delivery.state_changed'),
  deliveryCancelled('delivery.cancelled'),
  driverAvailabilityChanged('driver.availability_changed'),
  systemResyncRequired('system.resync_required');

  const DriverEventType(this.wireValue);

  final String wireValue;

  /// Parses a wire string. Returns `null` for unknown future values.
  static DriverEventType? tryParse(String raw) {
    for (final value in DriverEventType.values) {
      if (value.wireValue == raw) return value;
    }
    return null;
  }

  /// Whether this event type signals that the offers list may have changed.
  bool get invalidatesOffers => switch (this) {
    DriverEventType.offerCreated ||
    DriverEventType.offerAccepted ||
    DriverEventType.offerRejected ||
    DriverEventType.offerExpired => true,
    DriverEventType.deliveryStateChanged ||
    DriverEventType.deliveryCancelled ||
    DriverEventType.driverAvailabilityChanged ||
    DriverEventType.systemResyncRequired => false,
  };
}
