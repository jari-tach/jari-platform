/// Lightweight origin marker for a [DriverProfile] (PHASE 2.3).
///
/// Domain/in-memory only — not persisted in Drift and never treated as
/// verified production provenance. Backend remains the source of truth.
enum DriverProfileProvenance {
  /// Non-production trial synthesis only.
  trialSynthetic,

  /// Origin not established (e.g. local cache row without marker).
  unknown,
}
