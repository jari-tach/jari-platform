import 'dart:async';

import '../../../../core/auth_session/access_token_memory_cache.dart';
import '../../../../core/auth_session/auth_token_store.dart';
import '../../../../core/auth_session/device_identity_store.dart';
import '../../../../core/network/idempotency_key_factory.dart';
import '../../../../core/network/remote_error_classification.dart';
import '../../../../core/network/remote_error_mapper.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../domain/entities/auth_error.dart';
import '../../domain/entities/authentication_status.dart';
import '../../domain/entities/driver_session.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../../domain/saudi_phone_normalizer.dart';
import '../session/auth_session_storage.dart';
import '../models/token_response_wire.dart';
import '../remote/auth_remote_data_source.dart';

String? _toE164(String local05) {
  if (!RegExp(r'^05\d{8}$').hasMatch(local05)) return null;
  return '+966${local05.substring(1)}';
}

/// Remote [AuthenticationRepository] against contracts-v0.1.0.
final class RemoteAuthenticationRepository implements AuthenticationRepository {
  RemoteAuthenticationRepository({
    required this._remote,
    required this._sessionStorage,
    required this._tokenStore,
    required this._accessTokenCache,
    required this._logger,
    IdempotencyKeyFactory? idempotencyKeyFactory,
    RemoteErrorMapper? errorMapper,
    DeviceIdentityStore? deviceIdentityStore,
    this._locale = 'ar-SA',
  }) : _idempotencyKeys = idempotencyKeyFactory ?? IdempotencyKeyFactory(),
       _errorMapper = errorMapper ?? const RemoteErrorMapper(),
       _deviceIdentity = deviceIdentityStore ?? InMemoryDeviceIdentityStore();

  final AuthRemoteDataSource _remote;
  final AuthSessionStorage _sessionStorage;
  final AuthTokenStore _tokenStore;
  final AccessTokenMemoryCache _accessTokenCache;
  final LoggerService _logger;
  final IdempotencyKeyFactory _idempotencyKeys;
  final RemoteErrorMapper _errorMapper;
  final DeviceIdentityStore _deviceIdentity;
  final String _locale;

  DriverSession? _currentSession;
  final StreamController<AuthenticationStatus> _statusController =
      StreamController<AuthenticationStatus>.broadcast();

  String? _pendingChallengeId;
  String? _pendingPhone;
  DateTime? _otpResendAvailableAt;

  Future<DriverSession?>? _refreshInFlight;

  @override
  DateTime? get otpResendAvailableAt => _otpResendAvailableAt;

  @override
  DriverSession? get currentSession => _currentSession;

  @override
  Stream<AuthenticationStatus> get authStateChanges => _statusController.stream;

  /// Used by [SaeqApiClient] single-flight 401 handling.
  Future<bool> refreshTokensForClient() async {
    try {
      final session = await refreshSession();
      return session != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DriverSession?> restoreSession() async {
    try {
      final stored = await _sessionStorage.readSession();
      final refresh = await _tokenStore.readRefreshToken();
      if (stored == null || refresh == null || stored.isExpired) {
        await _clearLocal();
        _emit(AuthenticationStatus.unauthenticated);
        return null;
      }
      _currentSession = stored;
      // Access token is memory-only; force refresh on restore.
      final refreshed = await refreshSession();
      return refreshed;
    } on AuthError {
      rethrow;
    } catch (e, st) {
      _logger.error('restoreSession failed', e, st);
      throw const SecureStorageFailureError();
    }
  }

  @override
  Future<DriverSession> signIn(String phoneNumber) async {
    await requestOtp(phoneNumber);
    throw const IncompleteOtpError(
      'OTP verification is required. Call verifyOtp.',
    );
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    final normalized = normalizeSaudiPhoneNumber(phoneNumber);
    if (normalized == null) {
      throw const InvalidPhoneNumberError();
    }
    final e164 = _toE164(normalized);
    if (e164 == null) {
      throw const InvalidPhoneNumberError();
    }
    try {
      final challenge = await _remote.requestOtp(
        phoneNumber: e164,
        locale: _locale,
      );
      _pendingChallengeId = challenge.challengeId;
      _pendingPhone = normalized;
      _otpResendAvailableAt = challenge.resendAvailableAt;
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<DriverSession> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final normalized = normalizeSaudiPhoneNumber(phoneNumber);
    if (normalized == null) {
      throw const InvalidPhoneNumberError();
    }
    final challengeId = _pendingChallengeId;
    if (challengeId == null || _pendingPhone != normalized) {
      throw const ExpiredOtpError();
    }
    if (otpCode.trim().length < 4) {
      throw const IncompleteOtpError();
    }

    try {
      // Stable per-install UUID: generated once, persisted, reused for
      // every verification (backend enforces @IsUUID on device.deviceId).
      final deviceId = await _deviceIdentity.obtainDeviceId();
      final tokens = await _remote.verifyOtp(
        challengeId: challengeId,
        otpCode: otpCode.trim(),
        idempotencyKey: _idempotencyKeys.next(),
        device: {
          'deviceId': deviceId,
          'platform': 'android',
          'appVersion': '1.0.0',
        },
      );
      return _applyTokens(tokens, phoneFallback: normalized);
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<DriverSession?> refreshSession() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final future = () async {
      try {
        final refresh = await _tokenStore.readRefreshToken();
        if (refresh == null || refresh.isEmpty) {
          await _clearLocal();
          _emit(AuthenticationStatus.unauthenticated);
          return null;
        }
        final tokens = await _remote.refreshToken(
          refreshToken: refresh,
          idempotencyKey: _idempotencyKeys.next(),
        );
        return _applyTokens(
          tokens,
          phoneFallback: _currentSession?.phoneNumber ?? '',
        );
      } catch (e) {
        final mapped = _mapError(e);
        if (mapped is SessionExpiredError ||
            mapped is NetworkUnavailableAuthError) {
          if (mapped is SessionExpiredError) {
            await _clearLocal();
            _emit(AuthenticationStatus.unauthenticated);
          }
        }
        throw mapped;
      } finally {
        _refreshInFlight = null;
      }
    }();

    _refreshInFlight = future;
    return future;
  }

  @override
  void clearOtpChallenge() {
    _pendingChallengeId = null;
    _pendingPhone = null;
    _otpResendAvailableAt = null;
  }

  @override
  Future<void> signOut() async {
    final refresh = await _tokenStore.readRefreshToken();
    if (refresh != null) {
      try {
        await _remote.logout(
          refreshToken: refresh,
          idempotencyKey: _idempotencyKeys.next(),
        );
      } catch (_) {
        // Local logout still proceeds.
      }
    }
    await _clearLocal();
    _emit(AuthenticationStatus.unauthenticated);
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }

  Future<DriverSession> _applyTokens(
    TokenResponseWire tokens, {
    required String phoneFallback,
  }) async {
    final session = DriverSession(
      driverId: tokens.driver.driverId,
      phoneNumber: phoneFallback.isNotEmpty
          ? phoneFallback
          : tokens.driver.phoneMasked,
      sessionToken: tokens.accessToken,
      expiresAt: tokens.accessTokenExpiresAt,
    );
    await _tokenStore.saveRefreshToken(tokens.refreshToken);
    _accessTokenCache.setAccessToken(tokens.accessToken);
    await _sessionStorage.saveSession(session);
    _currentSession = session;
    clearOtpChallenge();
    _emit(AuthenticationStatus.authenticated);
    return session;
  }

  Future<void> _clearLocal() async {
    _currentSession = null;
    _accessTokenCache.clear();
    clearOtpChallenge();
    await _tokenStore.clearAll();
    await _sessionStorage.clearSession();
  }

  void _emit(AuthenticationStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  AuthError _mapError(Object error) {
    if (error is AuthError) return error;
    if (error is FormatException) {
      return const ContractViolationAuthError();
    }

    final classification = _errorMapper.classify(error);
    final envelope = _errorMapper.envelopeOf(error);

    switch (envelope?.code) {
      case 'OTP_INVALID':
        return const InvalidOtpError();
      case 'OTP_RATE_LIMITED':
        return const OtpRateLimitedError();
      case 'TOKEN_EXPIRED':
      case 'TOKEN_REVOKED':
      case 'UNAUTHORIZED':
        return const SessionExpiredError();
      case 'VALIDATION_ERROR':
        return const InvalidPhoneNumberError();
      case 'FORBIDDEN':
        return const ForbiddenAuthError();
      case 'RATE_LIMITED':
        return const RateLimitedAuthError();
      case 'INTERNAL_ERROR':
        return const ServerUnavailableAuthError();
    }

    switch (classification) {
      case RemoteErrorClassification.networkUnavailable:
        return const NetworkUnavailableAuthError();
      case RemoteErrorClassification.requestTimeout:
        return const RequestTimeoutAuthError();
      case RemoteErrorClassification.serverUnavailable:
        return const ServerUnavailableAuthError();
      case RemoteErrorClassification.sessionExpired:
      case RemoteErrorClassification.unauthorized:
        return const SessionExpiredError();
      case RemoteErrorClassification.forbidden:
        return const ForbiddenAuthError();
      case RemoteErrorClassification.rateLimited:
        return const RateLimitedAuthError();
      case RemoteErrorClassification.validation:
        return const InvalidPhoneNumberError();
      case RemoteErrorClassification.conflict:
        return const ConflictAuthError();
      case RemoteErrorClassification.contractViolation:
        return const ContractViolationAuthError();
      case RemoteErrorClassification.notFound:
      case RemoteErrorClassification.unknown:
        return const UnexpectedAuthError();
    }
  }
}
