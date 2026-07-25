import '../../domain/entities/auth_error.dart';
import '../../domain/entities/authentication_status.dart';
import '../../domain/entities/driver_session.dart';

/// Presentation-layer authentication lifecycle (PHASE 2.2, Phase 6 spec).
///
/// Richer than [AuthenticationStatus] on purpose: routing only needs
/// unknown/authenticated/unauthenticated, but the Login screen also needs
/// to distinguish "restoring", "authenticating" and "signingOut" to drive
/// loading indicators and to prevent duplicate submissions.
enum AuthControllerStatus {
  /// Controller created, restoration not started yet.
  initial,

  /// Attempting to load a previously-saved session.
  restoring,

  /// No valid session; user must sign in.
  unauthenticated,

  /// A sign-in attempt is in flight.
  authenticating,

  /// A valid session exists.
  authenticated,

  /// A sign-out is in flight.
  signingOut,

  /// The last operation (restore or sign-in) failed with [error].
  failure,
}

/// Immutable authentication state exposed by [AuthController].
class AuthControllerState {
  const AuthControllerState._({required this.status, this.session, this.error});

  const AuthControllerState.initial()
    : this._(status: AuthControllerStatus.initial);

  const AuthControllerState.restoring()
    : this._(status: AuthControllerStatus.restoring);

  const AuthControllerState.unauthenticated()
    : this._(status: AuthControllerStatus.unauthenticated);

  const AuthControllerState.authenticating()
    : this._(status: AuthControllerStatus.authenticating);

  const AuthControllerState.authenticated(DriverSession session)
    : this._(status: AuthControllerStatus.authenticated, session: session);

  const AuthControllerState.signingOut()
    : this._(status: AuthControllerStatus.signingOut);

  const AuthControllerState.failure(AuthError error)
    : this._(status: AuthControllerStatus.failure, error: error);

  final AuthControllerStatus status;

  /// Non-null only when [status] is [AuthControllerStatus.authenticated].
  final DriverSession? session;

  /// Non-null only when [status] is [AuthControllerStatus.failure].
  final AuthError? error;

  bool get isAuthenticated => status == AuthControllerStatus.authenticated;

  /// True while a sign-in or sign-out request is in flight — used by the
  /// Login screen to disable duplicate submissions.
  bool get isBusy =>
      status == AuthControllerStatus.authenticating ||
      status == AuthControllerStatus.signingOut;

  /// Collapses the richer FSM down to the 3-value signal routing needs.
  /// `initial`/`restoring`/`authenticating`/`signingOut` all map to
  /// `unknown` so the router never redirects mid-transition (avoids
  /// redirect loops and flicker).
  AuthenticationStatus get routingStatus {
    switch (status) {
      case AuthControllerStatus.authenticated:
        return AuthenticationStatus.authenticated;
      case AuthControllerStatus.unauthenticated:
      case AuthControllerStatus.failure:
        return AuthenticationStatus.unauthenticated;
      case AuthControllerStatus.initial:
      case AuthControllerStatus.restoring:
      case AuthControllerStatus.authenticating:
      case AuthControllerStatus.signingOut:
        return AuthenticationStatus.unknown;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthControllerState &&
          status == other.status &&
          session == other.session &&
          error == other.error;

  @override
  int get hashCode => Object.hash(status, session, error);

  @override
  String toString() =>
      'AuthControllerState(status: $status, session: $session, error: $error)';
}
