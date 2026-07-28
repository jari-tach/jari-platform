import '../../domain/entities/auth_error.dart';
import '../../domain/entities/authentication_status.dart';
import '../../domain/entities/driver_session.dart';
import '../../domain/entities/session_lifecycle.dart';

/// Presentation-layer authentication lifecycle (PHASE 2.2 + 2.3 + OTP Inc 4).
enum AuthControllerStatus {
  /// Controller created, restoration not started yet.
  initial,

  /// Attempting to load a previously-saved session.
  restoring,

  /// No valid session; user must sign in.
  unauthenticated,

  /// A sign-in attempt is in flight.
  authenticating,

  /// An OTP request is in flight.
  requestingOtp,

  /// OTP was sent; awaiting user entry on the OTP screen.
  otpRequested,

  /// OTP verification is in flight.
  verifyingOtp,

  /// A valid session exists.
  authenticated,

  /// A sign-out is in flight.
  signingOut,

  /// A previously valid session expired.
  expired,

  /// The last operation (restore or sign-in) failed with [error].
  failure,
}

/// Immutable authentication state exposed by [AuthController].
class AuthControllerState {
  const AuthControllerState._({
    required this.status,
    this.session,
    this.error,
    this.pendingPhone,
    this.resendAvailableAt,
  });

  const AuthControllerState.initial()
    : this._(status: AuthControllerStatus.initial);

  const AuthControllerState.restoring()
    : this._(status: AuthControllerStatus.restoring);

  const AuthControllerState.unauthenticated()
    : this._(status: AuthControllerStatus.unauthenticated);

  const AuthControllerState.authenticating()
    : this._(status: AuthControllerStatus.authenticating);

  const AuthControllerState.requestingOtp()
    : this._(status: AuthControllerStatus.requestingOtp);

  const AuthControllerState.otpRequested({
    required String pendingPhone,
    required DateTime resendAvailableAt,
    AuthError? error,
  }) : this._(
         status: AuthControllerStatus.otpRequested,
         pendingPhone: pendingPhone,
         resendAvailableAt: resendAvailableAt,
         error: error,
       );

  const AuthControllerState.verifyingOtp({
    required String pendingPhone,
    required DateTime resendAvailableAt,
  }) : this._(
         status: AuthControllerStatus.verifyingOtp,
         pendingPhone: pendingPhone,
         resendAvailableAt: resendAvailableAt,
       );

  const AuthControllerState.authenticated(DriverSession session)
    : this._(status: AuthControllerStatus.authenticated, session: session);

  const AuthControllerState.signingOut()
    : this._(status: AuthControllerStatus.signingOut);

  const AuthControllerState.expired([AuthError? error])
    : this._(
        status: AuthControllerStatus.expired,
        error: error ?? const SessionExpiredError(),
      );

  const AuthControllerState.failure(AuthError error, {DriverSession? session})
    : this._(
        status: AuthControllerStatus.failure,
        error: error,
        session: session,
      );

  final AuthControllerStatus status;

  /// Non-null when [status] is [AuthControllerStatus.authenticated], or when
  /// [status] is [AuthControllerStatus.failure] after a sign-out clear failure
  /// (session may still be valid in secure storage).
  final DriverSession? session;

  /// Non-null when [status] is [AuthControllerStatus.failure] or [expired].
  final AuthError? error;

  /// Phone awaiting OTP verification during the OTP flow.
  final String? pendingPhone;

  /// Earliest time the user may request another OTP.
  final DateTime? resendAvailableAt;

  bool get isAuthenticated => status == AuthControllerStatus.authenticated;

  bool get isOtpFlowActive =>
      status == AuthControllerStatus.requestingOtp ||
      status == AuthControllerStatus.otpRequested ||
      status == AuthControllerStatus.verifyingOtp;

  /// Masked phone safe for OTP screen display.
  String? get maskedPendingPhone {
    final phone = pendingPhone;
    if (phone == null) return null;
    return DriverSession(
      driverId: 'mask',
      phoneNumber: phone,
      sessionToken: 'mask',
    ).maskedPhoneNumber;
  }

  /// Remaining resend cooldown, or zero when resend is allowed.
  Duration get resendCooldownRemaining {
    final availableAt = resendAvailableAt;
    if (availableAt == null) return Duration.zero;
    final remaining = availableAt.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  /// True while a sign-in, OTP, or sign-out request is in flight.
  bool get isBusy =>
      status == AuthControllerStatus.authenticating ||
      status == AuthControllerStatus.requestingOtp ||
      status == AuthControllerStatus.verifyingOtp ||
      status == AuthControllerStatus.signingOut;

  /// Collapses the richer FSM down to the 3-value signal routing needs.
  AuthenticationStatus get routingStatus {
    switch (status) {
      case AuthControllerStatus.authenticated:
        return AuthenticationStatus.authenticated;
      case AuthControllerStatus.unauthenticated:
      case AuthControllerStatus.expired:
      case AuthControllerStatus.otpRequested:
        return AuthenticationStatus.unauthenticated;
      case AuthControllerStatus.failure:
        if (session != null) {
          return AuthenticationStatus.authenticated;
        }
        return AuthenticationStatus.unauthenticated;
      case AuthControllerStatus.initial:
      case AuthControllerStatus.restoring:
      case AuthControllerStatus.authenticating:
      case AuthControllerStatus.requestingOtp:
      case AuthControllerStatus.verifyingOtp:
      case AuthControllerStatus.signingOut:
        return AuthenticationStatus.unknown;
    }
  }

  /// Explicit lifecycle view required by PHASE 2.3 (does not expose Fake Auth).
  SessionLifecycle get sessionLifecycle {
    switch (status) {
      case AuthControllerStatus.initial:
      case AuthControllerStatus.restoring:
      case AuthControllerStatus.signingOut:
        return SessionLifecycle.unknown;
      case AuthControllerStatus.unauthenticated:
        return SessionLifecycle.unauthenticated;
      case AuthControllerStatus.authenticating:
      case AuthControllerStatus.requestingOtp:
      case AuthControllerStatus.otpRequested:
      case AuthControllerStatus.verifyingOtp:
        return SessionLifecycle.authenticating;
      case AuthControllerStatus.authenticated:
        return SessionLifecycle.authenticated;
      case AuthControllerStatus.expired:
        return SessionLifecycle.expired;
      case AuthControllerStatus.failure:
        return SessionLifecycle.failed;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthControllerState &&
          status == other.status &&
          session == other.session &&
          error == other.error &&
          pendingPhone == other.pendingPhone &&
          resendAvailableAt == other.resendAvailableAt;

  @override
  int get hashCode =>
      Object.hash(status, session, error, pendingPhone, resendAvailableAt);

  @override
  String toString() =>
      'AuthControllerState(status: $status, session: $session, error: $error, '
      'pendingPhone: ${maskedPendingPhone ?? pendingPhone}, '
      'resendAvailableAt: $resendAvailableAt)';
}
