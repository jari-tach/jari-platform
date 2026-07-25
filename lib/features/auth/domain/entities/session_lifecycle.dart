/// Coarse session lifecycle for UI/orchestration (PHASE 2.3).
///
/// Maps onto [AuthControllerStatus] / routing without coupling widgets to
/// Fake Auth internals.
enum SessionLifecycle {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  expired,
  failed,
}
