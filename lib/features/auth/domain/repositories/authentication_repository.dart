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
  Future<DriverSession> signIn(String phoneNumber);

  /// Clears the current session. Must be safe to call even when already
  /// signed out, and must never throw.
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
