/// Coarse-grained authentication signal.
///
/// This is intentionally small: it exists to answer one question ("is the
/// current user allowed into protected routes?"), not to describe UI/loading
/// nuances. Transient states (restoring, authenticating, signing out,
/// input/network failures) belong to the presentation-layer controller
/// state (see `AuthControllerState`), not here.
enum AuthenticationStatus {
  /// The session has not been resolved yet (e.g. restoration in progress).
  /// Routing must never redirect based on this value alone.
  unknown,

  /// A valid, non-expired driver session exists.
  authenticated,

  /// No valid driver session exists.
  unauthenticated,
}
