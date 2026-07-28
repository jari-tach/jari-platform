/// Driver-facing active-delivery workflow stages (PHASE 2.6 Increment 2).
///
/// Distinct from coarse [DeliveryStatus] — stages drive UI CTAs while status
/// tracks pickup/delivery operational milestones for persistence/sync.
enum DriverWorkflowStage {
  /// Post-accept; ready to start trip to pickup.
  assigned,

  /// En route to merchant / pickup.
  navToPickup,

  /// Arrived at pickup location.
  arrivedPickup,

  /// Waiting for order handoff.
  waitingPickup,

  /// Pickup confirmed (maps to [DeliveryStatus.pickedUp]).
  collected,

  /// En route to customer.
  navToCustomer,

  /// Arrived at customer.
  arrivedCustomer,

  /// Delivery code / confirmation in progress.
  verifying,

  /// Delivery confirmed (maps to [DeliveryStatus.delivered]).
  delivered,

  /// End-of-trip summary before clearing local assignment.
  summary,

  /// Driver reported an issue; resume via [DeliveryAssignment.resumeAfterIssueStage].
  issueOpen,
}
