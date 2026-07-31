/// Authentication error taxonomy (PHASE 2.2).
///
/// `message` is an internal, generic, English description safe for logs
/// (never a raw stack trace or sensitive value). UI-facing localized text
/// is resolved separately by the presentation layer (see
/// `AppLocalizations` + `login_screen.dart`), keeping this domain type free
/// of UI/localization concerns.
sealed class AuthError implements Exception {
  const AuthError(this.message);

  final String message;

  @override
  String toString() => '[$runtimeType] $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

/// The phone number failed local format validation.
final class InvalidPhoneNumberError extends AuthError {
  const InvalidPhoneNumberError([super.message = 'Invalid phone number.']);
}

/// The (fake) sign-in attempt was rejected.
final class AuthenticationRejectedError extends AuthError {
  const AuthenticationRejectedError([super.message = 'Sign-in was rejected.']);
}

/// A previously valid session has expired.
final class SessionExpiredError extends AuthError {
  const SessionExpiredError([super.message = 'Session has expired.']);
}

/// Stored session data could not be parsed/validated.
final class CorruptedSessionError extends AuthError {
  const CorruptedSessionError([super.message = 'Stored session is corrupted.']);
}

/// The secure storage layer failed to read/write/delete session data.
final class SecureStorageFailureError extends AuthError {
  const SecureStorageFailureError([
    super.message = 'Secure storage operation failed.',
  ]);
}

/// The OTP code did not match the pending challenge.
final class InvalidOtpError extends AuthError {
  const InvalidOtpError([super.message = 'Invalid OTP code.']);
}

/// The OTP challenge expired before verification.
final class ExpiredOtpError extends AuthError {
  const ExpiredOtpError([super.message = 'OTP code has expired.']);
}

/// OTP was requested again before the resend cooldown elapsed.
final class OtpRateLimitedError extends AuthError {
  const OtpRateLimitedError([super.message = 'OTP resend is rate limited.']);
}

/// The OTP input is incomplete (e.g. fewer than required digits).
final class IncompleteOtpError extends AuthError {
  const IncompleteOtpError([super.message = 'OTP code is incomplete.']);
}

/// Network is unavailable (not GNSS / GPS).
final class NetworkUnavailableAuthError extends AuthError {
  const NetworkUnavailableAuthError([
    super.message = 'Network is unavailable.',
  ]);
}

/// Request timed out.
final class RequestTimeoutAuthError extends AuthError {
  const RequestTimeoutAuthError([super.message = 'Request timed out.']);
}

/// Backend is unavailable (5xx / INTERNAL_ERROR).
final class ServerUnavailableAuthError extends AuthError {
  const ServerUnavailableAuthError([
    super.message = 'Authentication service is unavailable.',
  ]);
}

/// Caller is forbidden.
final class ForbiddenAuthError extends AuthError {
  const ForbiddenAuthError([super.message = 'Access is forbidden.']);
}

/// Conflict / idempotency / assignment conflict family.
final class ConflictAuthError extends AuthError {
  const ConflictAuthError([super.message = 'Authentication conflict.']);
}

/// Rate limited.
final class RateLimitedAuthError extends AuthError {
  const RateLimitedAuthError([super.message = 'Too many requests.']);
}

/// Response violated the pinned API contract.
final class ContractViolationAuthError extends AuthError {
  const ContractViolationAuthError([
    super.message = 'Authentication response was invalid.',
  ]);
}

/// Anything else. Never expose the underlying technical detail to the user.
final class UnexpectedAuthError extends AuthError {
  const UnexpectedAuthError([
    super.message = 'Unexpected authentication error.',
  ]);
}
