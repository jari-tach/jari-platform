import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/auth_error.dart';
import '../../domain/entities/authentication_status.dart';
import '../../domain/entities/driver_session.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../session/auth_session_storage.dart';

/// PHASE 2.2 mock authentication repository.
///
/// - No network call, no real OTP/SMS provider, no production backend.
/// - Accepts a trial Saudi-style local mobile number (`05XXXXXXXX`).
/// - Persists a trial session via [AuthSessionStorage] (which uses the
///   existing [SecureStorageService] under the hood).
///
/// Production guard: the constructor throws [StateError] if
/// [isProductionEnvironment] reports `true`, so this implementation can
/// never silently run in a production build. Callers (see
/// `AppServiceRegistry`) treat that as a non-critical bootstrap failure,
/// consistent with PHASE 2.1's policy — it is logged loudly, not hidden.
class FakeAuthenticationRepository implements AuthenticationRepository {
  FakeAuthenticationRepository({
    required AuthSessionStorage sessionStorage,
    required LoggerService logger,
    bool Function() isProductionEnvironment = _defaultIsProductionEnvironment,
    Duration signInDelay = const Duration(milliseconds: 300),
  }) : _sessionStorage = sessionStorage,
       _logger = logger,
       _signInDelay = signInDelay {
    if (isProductionEnvironment()) {
      throw StateError(
        'FakeAuthenticationRepository must never run when AppConfig.isProduction '
        'is true. This PHASE 2.2 implementation has no real backend, OTP, or '
        'security guarantees.',
      );
    }
  }

  static bool _defaultIsProductionEnvironment() => AppConfig.isProduction;

  final AuthSessionStorage _sessionStorage;
  final LoggerService _logger;
  final Duration _signInDelay;

  DriverSession? _currentSession;
  final StreamController<AuthenticationStatus> _statusController =
      StreamController<AuthenticationStatus>.broadcast();

  // --- Test-only simulation hooks -----------------------------------
  // Manual fakes only (no mocking package added). Restricted to tests via
  // @visibleForTesting; production/UI code must never call these.
  AuthError? _forcedSignInFailure;
  bool _forceSessionExpired = false;

  @visibleForTesting
  void debugSimulateNextSignInFailure(AuthError error) {
    _forcedSignInFailure = error;
  }

  @visibleForTesting
  void debugForceSessionExpired(bool expired) {
    _forceSessionExpired = expired;
  }
  // --------------------------------------------------------------------

  @override
  DriverSession? get currentSession => _currentSession;

  @override
  Stream<AuthenticationStatus> get authStateChanges => _statusController.stream;

  @override
  Future<DriverSession?> restoreSession() async {
    final DriverSession? stored;
    try {
      stored = await _sessionStorage.readSession();
    } catch (error, stackTrace) {
      // AuthSessionStorage already handles corruption internally and
      // should not throw; this is defense-in-depth only.
      _logger.error(
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
      _logger.info(
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

    if (!_isValidTrialPhoneNumber(phoneNumber)) {
      throw const InvalidPhoneNumberError();
    }

    // Simulate a short local round trip. No network call is made.
    // Tests may inject Duration.zero via [signInDelay] to avoid fake-clock
    // wait overhead; the production/runtime default remains 300ms.
    if (_signInDelay > Duration.zero) {
      await Future<void>.delayed(_signInDelay);
    }

    final session = DriverSession(
      driverId: 'fake-${phoneNumber.hashCode.toUnsigned(31)}',
      phoneNumber: phoneNumber,
      sessionToken: _generateFakeSessionToken(),
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );

    try {
      await _sessionStorage.saveSession(session);
    } catch (error, stackTrace) {
      _logger.error(
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
  Future<void> signOut() async {
    await _clearStoredSessionSafely();
    _currentSession = null;
    _statusController.add(AuthenticationStatus.unauthenticated);
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }

  Future<void> _clearStoredSessionSafely() async {
    try {
      await _sessionStorage.clearSession();
    } catch (error, stackTrace) {
      // Sign-out/expiry cleanup must never crash the app even if the
      // storage layer fails.
      _logger.error(
        'FakeAuthenticationRepository: failed to clear stored session',
        error,
        stackTrace,
      );
    }
  }

  /// Trial validation rule only: Saudi-style local mobile format
  /// (`05` + 8 digits = 10 digits total). Documented, not a production
  /// phone-number validation policy.
  static bool _isValidTrialPhoneNumber(String input) =>
      RegExp(r'^05\d{8}$').hasMatch(input);

  static String _generateFakeSessionToken() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }
}
