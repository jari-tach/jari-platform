import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/auth_error.dart';
import '../../domain/entities/authentication_status.dart';
import '../../domain/entities/driver_session.dart';
import '../../domain/policies/fake_auth_policy.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/saudi_phone_normalizer.dart';
import '../session/auth_session_storage.dart';

/// PHASE 2.2/2.3 mock authentication repository.
///
/// **Never for production.** Fake Alpha OTP (`246810`) exists only for
/// development and automated tests. It is held in memory only — never logged,
/// never written to secure storage, and never exposed via a public API.
///
/// Security:
/// - Hard release guard: [kReleaseMode] always throws — not injectable.
/// - Production environments blocked via [FakeAuthPolicy] /
///   [isProductionEnvironment] (injectable for Production-denial tests only).
/// - No Dart-define / request / UI bypass for Release.
/// - Production certificate pinning remains a production gate (not implemented).
class FakeAuthenticationRepository implements AuthenticationRepository {
  FakeAuthenticationRepository({
    required this.sessionStorage,
    required this.logger,
    bool Function() isProductionEnvironment = _defaultIsProductionEnvironment,
    this.signInDelay = const Duration(milliseconds: 300),
    this.otpRequestDelay = const Duration(milliseconds: 300),
  }) {
    // HARD RELEASE GUARD — not injectable, not overridable.
    if (kReleaseMode) {
      throw StateError(
        'Fake authentication is not permitted in release builds.',
      );
    }

    final decision = FakeAuthPolicy.evaluate(
      isReleaseMode: false,
      isProductionEnvironment: isProductionEnvironment(),
    );
    if (!decision.allowed) {
      throw StateError(
        'FakeAuthenticationRepository denied by ${decision.policyVersion}: '
        '${decision.reasonCodes.join(',')}',
      );
    }
  }

  static bool _defaultIsProductionEnvironment() => AppConfig.isProduction;

  /// Fake Alpha trial OTP — NEVER log, persist, or expose via public API.
  static const String _fakeTrialOtp = '246810';

  static const Duration _otpExpiry = Duration(minutes: 5);
  static const Duration _resendCooldown = Duration(seconds: 30);

  final AuthSessionStorage sessionStorage;
  final LoggerService logger;
  final Duration signInDelay;
  final Duration otpRequestDelay;

  DriverSession? _currentSession;
  final StreamController<AuthenticationStatus> _statusController =
      StreamController<AuthenticationStatus>.broadcast();

  AuthError? _forcedSignInFailure;
  bool _forceSessionExpired = false;
  bool _failNextSessionClear = false;

  Future<DriverSession?>? _refreshInFlight;

  String? _pendingPhone;
  DateTime? _pendingIssuedAt;
  DateTime? _otpResendAvailableAt;

  DateTime Function() _now = DateTime.now;

  @visibleForTesting
  void debugSetNow(DateTime Function() now) {
    _now = now;
  }

  @visibleForTesting
  void debugAdvancePendingIssuedAt(Duration amount) {
    if (_pendingIssuedAt != null) {
      _pendingIssuedAt = _pendingIssuedAt!.subtract(amount);
    }
  }

  @visibleForTesting
  void debugSimulateNextSignInFailure(AuthError error) {
    _forcedSignInFailure = error;
  }

  @visibleForTesting
  void debugForceSessionExpired(bool expired) {
    _forceSessionExpired = expired;
  }

  @visibleForTesting
  void debugFailNextSessionClear() {
    _failNextSessionClear = true;
  }

  @override
  DateTime? get otpResendAvailableAt => _otpResendAvailableAt;

  @override
  DriverSession? get currentSession => _currentSession;

  @override
  Stream<AuthenticationStatus> get authStateChanges => _statusController.stream;

  @override
  Future<DriverSession?> restoreSession() async {
    final DriverSession? stored;
    try {
      stored = await sessionStorage.readSession();
    } catch (error, stackTrace) {
      logger.error(
        'FakeAuthenticationRepository: restoreSession failed',
        error,
        stackTrace,
      );
      _currentSession = null;
      _statusController.add(AuthenticationStatus.unauthenticated);
      return null;
    }

    if (stored == null) {
      _currentSession = null;
      _statusController.add(AuthenticationStatus.unauthenticated);
      return null;
    }

    if (_forceSessionExpired || stored.isExpired) {
      logger.info(
        'FakeAuthenticationRepository: stored session expired, clearing',
      );
      await _clearStoredSessionSafely();
      _currentSession = null;
      _statusController.add(AuthenticationStatus.unauthenticated);
      return null;
    }

    _currentSession = stored;
    _statusController.add(AuthenticationStatus.authenticated);
    return stored;
  }

  @override
  Future<DriverSession> signIn(String phoneNumber) async {
    if (_forcedSignInFailure != null) {
      final forced = _forcedSignInFailure!;
      _forcedSignInFailure = null;
      throw forced;
    }

    final normalizedPhone = _normalizePhoneOrThrow(phoneNumber);

    if (signInDelay > Duration.zero) {
      await Future<void>.delayed(signInDelay);
    }

    final session = _buildSession(normalizedPhone);

    try {
      await sessionStorage.saveSession(session);
    } catch (error, stackTrace) {
      logger.error(
        'FakeAuthenticationRepository: failed to persist session after sign-in',
        error,
        stackTrace,
      );
      throw const SecureStorageFailureError();
    }

    _currentSession = session;
    _statusController.add(AuthenticationStatus.authenticated);
    return session;
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    if (_forcedSignInFailure != null) {
      final forced = _forcedSignInFailure!;
      _forcedSignInFailure = null;
      throw forced;
    }

    final normalizedPhone = _normalizePhoneOrThrow(phoneNumber);

    final now = _now();
    if (_otpResendAvailableAt != null && now.isBefore(_otpResendAvailableAt!)) {
      throw const OtpRateLimitedError();
    }

    if (otpRequestDelay > Duration.zero) {
      await Future<void>.delayed(otpRequestDelay);
    }

    _pendingPhone = normalizedPhone;
    _pendingIssuedAt = now;
    _otpResendAvailableAt = now.add(_resendCooldown);

    logger.info(
      'FakeAuthenticationRepository: OTP challenge issued for pending phone',
    );
  }

  @override
  Future<DriverSession> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    if (otpCode.length < 6) {
      throw const IncompleteOtpError();
    }

    if (_pendingPhone == null || _pendingIssuedAt == null) {
      throw const ExpiredOtpError();
    }

    final normalizedPhone = _normalizePhoneOrThrow(phoneNumber);

    if (_pendingPhone != normalizedPhone) {
      throw const InvalidOtpError();
    }

    final now = _now();
    if (now.difference(_pendingIssuedAt!) > _otpExpiry) {
      _clearPendingOtpState();
      throw const ExpiredOtpError();
    }

    if (otpCode != _fakeTrialOtp) {
      throw const InvalidOtpError();
    }

    final session = _buildSession(normalizedPhone);

    try {
      await sessionStorage.saveSession(session);
    } catch (error, stackTrace) {
      logger.error(
        'FakeAuthenticationRepository: failed to persist session after OTP verify',
        error,
        stackTrace,
      );
      throw const SecureStorageFailureError();
    }

    _clearPendingOtpState();
    _currentSession = session;
    _statusController.add(AuthenticationStatus.authenticated);
    return session;
  }

  @override
  Future<DriverSession?> refreshSession() {
    return _refreshInFlight ??= _refreshSessionBody().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<DriverSession?> _refreshSessionBody() async {
    final session = _currentSession;
    if (session == null) {
      return null;
    }

    if (_forceSessionExpired || session.isExpired) {
      await _clearStoredSessionSafely();
      _currentSession = null;
      _statusController.add(AuthenticationStatus.unauthenticated);
      return null;
    }

    return session;
  }

  @override
  void clearOtpChallenge() {
    _clearPendingOtpState();
  }

  @override
  Future<void> signOut() async {
    _clearPendingOtpState();
    await _clearStoredSessionStrict();
    _currentSession = null;
    _statusController.add(AuthenticationStatus.unauthenticated);
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }

  void _clearPendingOtpState() {
    _pendingPhone = null;
    _pendingIssuedAt = null;
    _otpResendAvailableAt = null;
  }

  Future<void> _clearStoredSessionSafely() async {
    try {
      await sessionStorage.clearSession();
    } catch (error, stackTrace) {
      logger.error(
        'FakeAuthenticationRepository: failed to clear stored session',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _clearStoredSessionStrict() async {
    if (_failNextSessionClear) {
      _failNextSessionClear = false;
      throw const SecureStorageFailureError();
    }

    try {
      await sessionStorage.clearSession();
    } catch (error, stackTrace) {
      logger.error(
        'FakeAuthenticationRepository: failed to clear stored session',
        error,
        stackTrace,
      );
      throw const SecureStorageFailureError();
    }
  }

  static String _normalizePhoneOrThrow(String phoneNumber) {
    final normalized = normalizeSaudiPhoneNumber(phoneNumber);
    if (normalized == null) {
      throw const InvalidPhoneNumberError();
    }
    return normalized;
  }

  DriverSession _buildSession(String phoneNumber) {
    return DriverSession(
      driverId: 'fake-${phoneNumber.hashCode.toUnsigned(31)}',
      phoneNumber: phoneNumber,
      sessionToken: _generateFakeSessionToken(),
      expiresAt: _now().add(const Duration(hours: 12)),
    );
  }

  static String _generateFakeSessionToken() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }
}
