/// Backend selection for SAEQ Driver (STEP 5C).
///
/// Resolved only from build-time `--dart-define=SAEQ_BACKEND_MODE`.
enum BackendMode {
  fake,
  remote;

  static BackendMode parse(String? raw) {
    switch ((raw ?? 'fake').trim().toLowerCase()) {
      case 'remote':
        return BackendMode.remote;
      case 'fake':
        return BackendMode.fake;
      default:
        throw StateError(
          'Invalid SAEQ_BACKEND_MODE="$raw". Allowed: fake|remote.',
        );
    }
  }
}
