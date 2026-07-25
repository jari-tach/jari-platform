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

/// Anything else. Never expose the underlying technical detail to the user.
final class UnexpectedAuthError extends AuthError {
  const UnexpectedAuthError([
    super.message = 'Unexpected authentication error.',
  ]);
}
