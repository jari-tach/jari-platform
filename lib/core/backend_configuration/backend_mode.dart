/// Backend selection for SAEQ Driver (STEP 5C).
///
/// Resolved only from build-time `--dart-define=SAEQ_BACKEND_MODE`.
enum BackendMode {
  fake,
  remote;

  /// Empty/null means missing → Fake (allowed in debug only; sealed builds
  /// reject Fake afterward in [BackendConfiguration.resolve]).
  static BackendMode parse(String? raw) {
    final trimmed = (raw ?? '').trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == 'fake') {
      return BackendMode.fake;
    }
    if (trimmed == 'remote') {
      return BackendMode.remote;
    }
    throw StateError('Invalid SAEQ_BACKEND_MODE. Allowed: fake|remote.');
  }
}
