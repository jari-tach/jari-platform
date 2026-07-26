/// Offer decision-window states (PHASE 2.5 / ADR-021).
///
/// Distinct from [DeliveryStatus], which describes post-accept operational
/// progress owned partly by PHASE 2.6.
enum DeliveryOfferStatus {
  /// No active offer for the driver session.
  none,

  /// Offer is visible and actionable.
  offered,

  /// Accept request is in flight (local processing).
  accepting,

  /// Reject request is in flight (local processing).
  rejecting,

  /// Terminal: accept succeeded and an assignment exists.
  accepted,

  /// Terminal: driver rejected the offer.
  rejected,

  /// Terminal: offer window ended (server/local presentation of expiry).
  expired,

  /// Terminal: another driver took the work (409-class).
  takenByOther,

  /// Terminal: system/merchant cancelled during the offer window.
  cancelled,

  /// Recoverable presentation failure; not an ownership claim.
  failed,
}

/// Whether this offer status may still change via driver or system action.
extension DeliveryOfferStatusX on DeliveryOfferStatus {
  /// Non-terminal decision or processing states.
  bool get isActive => switch (this) {
    DeliveryOfferStatus.offered ||
    DeliveryOfferStatus.accepting ||
    DeliveryOfferStatus.rejecting => true,
    _ => false,
  };

  /// Terminal outcomes that clear the decision window.
  bool get isTerminal => switch (this) {
    DeliveryOfferStatus.accepted ||
    DeliveryOfferStatus.rejected ||
    DeliveryOfferStatus.expired ||
    DeliveryOfferStatus.takenByOther ||
    DeliveryOfferStatus.cancelled => true,
    DeliveryOfferStatus.none ||
    DeliveryOfferStatus.offered ||
    DeliveryOfferStatus.accepting ||
    DeliveryOfferStatus.rejecting ||
    DeliveryOfferStatus.failed => false,
  };
}
