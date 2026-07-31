/// Classification of remote/API failures for STEP 5C.
///
/// GNSS / GPS domain failures must NEVER be mapped to [networkUnavailable].
enum RemoteErrorClassification {
  networkUnavailable,
  requestTimeout,
  serverUnavailable,
  unauthorized,
  forbidden,
  validation,
  conflict,
  rateLimited,
  notFound,
  sessionExpired,
  contractViolation,
  unknown,
}
