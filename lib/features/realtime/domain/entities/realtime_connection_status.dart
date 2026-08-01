/// Quiet connection status for the driver UI (STEP 6-B).
///
/// Presentation must not spam Snackbars — a single quiet banner is enough.
enum RealtimeConnectionStatus {
  /// Channel not started (unauthenticated / torn down).
  idle,

  /// SSE stream is healthy.
  connected,

  /// Reconnecting with exponential backoff (still preferring SSE).
  reconnecting,

  /// SSE failed; polling fallback is the active transport.
  degraded,

  /// Foreground catch-up via polling after background/resume.
  catchingUp,

  /// Session ended or channel permanently stopped.
  stopped,
}
