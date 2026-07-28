import '../entities/authentication_status.dart';
import '../entities/driver_session.dart';

/// Authentication contract for SAEQ Driver.
///
/// Independent of UI and of any concrete backend/storage implementation.
/// PHASE 2.2 ships only [FakeAuthenticationRepository]; a future phase can
/// add a remote implementation behind this same contract without touching
/// callers (controller, router).
abstract class AuthenticationRepository {
  /// Attempts to load a previously-saved session (e.g. at app startup).
  ///
  /// Returns `null` when no session exists, the stored session is corrupted,
  /// or it has expired. Implementations must never throw for these
  /// "normal" cases — see individual [AuthError] subtypes for the failures
  /// that ARE allowed to throw (e.g. [SecureStorageFailureError]).
  Future<DriverSession?> restoreSession();

  /// Trial sign-in. Throws an [AuthError] (never a raw platform exception)
  /// on failure.
  ///
  /// Kept for backward compatibility with existing callers/tests. New UI
  /// should prefer [requestOtp] + [verifyOtp].
  Future<DriverSession> signIn(String phoneNumber);

  /// Sends an OTP challenge to [phoneNumber].
  ///
  /// Fake Alpha: validates local phone format, stores a short-lived in-memory
  /// challenge only (never persisted, never logged). Production will call a
  /// remote auth API behind the same contract; certificate pinning remains a
  /// production gate (not implemented in Fake Alpha).
  Future<void> requestOtp(String phoneNumber);

  /// Verifies the OTP [otpCode] for [phoneNumber] and returns a session on
  /// success.
  ///
  /// Fake Alpha: compares against a deterministic trial code in memory only.
  /// OTP values must never be logged or written to secure storage.
  Future<DriverSession> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  });

  /// Refreshes the current session when supported.
  ///
  /// Fake Alpha: returns [currentSession] when still valid, otherwise `null`.
  /// May throw [SessionExpiredError] when a refresh is attempted on an
  /// expired session (Fake returns `null` instead).
  Future<DriverSession?> refreshSession();

  /// Clears any in-flight OTP challenge without affecting an authenticated
  /// session.
  void clearOtpChallenge();

  /// Earliest time a new OTP may be requested for the current challenge.
  /// `null` when no challenge is pending.
  DateTime? get otpResendAvailableAt;

  /// Clears the current session. Safe to call when already signed out.
  ///
  /// Throws [SecureStorageFailureError] when secure storage cannot be cleared
  /// during an intentional logout (tokens may remain).
  Future<void> signOut();

  /// The last known session, kept in memory after [restoreSession] or
  /// [signIn]. `null` when signed out.
  DriverSession? get currentSession;

  /// Broadcast stream of coarse-grained authentication status changes.
  /// Lets the state be observed without any Flutter/Riverpod binding,
  /// which keeps this contract unit-testable in plain Dart.
  Stream<AuthenticationStatus> get authStateChanges;

  /// Releases any resources (e.g. stream controllers) held by the
  /// implementation. Safe to call more than once.
  Future<void> dispose();
}
