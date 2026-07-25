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
import '../session/auth_session_storage.dart';

/// PHASE 2.2/2.3 mock authentication repository.
///
/// Security:
/// - Hard release guard: [kReleaseMode] always throws — not injectable.
/// - Production environments blocked via [FakeAuthPolicy] /
///   [isProductionEnvironment] (injectable for Production-denial tests only).
/// - No Dart-define / request / UI bypass for Release.
class FakeAuthenticationRepository implements AuthenticationRepository {
  FakeAuthenticationRepository({
    required AuthSessionStorage sessionStorage,
    required LoggerService logger,
    bool Function() isProductionEnvironment = _defaultIsProductionEnvironment,
    Duration signInDelay = const Duration(milliseconds: 300),
  }) : _sessionStorage = sessionStorage,
       _logger = logger,
       _signInDelay = signInDelay {
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

  final AuthSessionStorage _sessionStorage;
  final LoggerService _logger;
  final Duration _signInDelay;

  DriverSession? _currentSession;
  final StreamController<AuthenticationStatus> _statusController =
      StreamController<AuthenticationStatus>.broadcast();

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
      _logger.error(
        'FakeAuthenticationRepository: failed to clear stored session',
        error,
        stackTrace,
      );
    }
  }

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
