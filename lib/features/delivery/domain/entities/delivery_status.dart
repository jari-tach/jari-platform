/// Operational status of an accepted delivery (PHASE 2.5 / future 2.6).
///
/// PHASE 2.5 creates assignments in [accepted] only. Pickup and delivery
/// confirmation transitions belong to PHASE 2.6 (ADR-021).
enum DeliveryStatus {
  /// Driver accepted; assignment is active (PHASE 2.5 terminal success).
  accepted,

  /// Reserved for PHASE 2.6 — pickup confirmed.
  pickedUp,

  /// Reserved for PHASE 2.6 — delivery confirmed.
  delivered,

  /// Assignment cancelled after accept (system/merchant; later phases).
  cancelled,
}
