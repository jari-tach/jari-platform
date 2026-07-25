/// Operational availability status (PHASE 2.4 / ADR-015).
enum AvailabilityStatus { offline, unavailable, available, busy }

/// Who last drove an availability change.
enum AvailabilitySource {
  localUserAction,
  system,
  server,
  restoredLocalState,
  connectivityPolicy,
}

/// Actor requesting a transition (ADR-015).
enum AvailabilityActor { driver, system, backend, connectivity }
