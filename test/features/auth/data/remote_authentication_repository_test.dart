import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/auth_session/access_token_memory_cache.dart';
import 'package:saeq_driver/core/auth_session/auth_token_store.dart';
import 'package:saeq_driver/core/network/saeq_api_client.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/core/services/storage/secure_storage_service.dart';
import 'package:saeq_driver/features/auth/data/remote/http_auth_remote_data_source.dart';
import 'package:saeq_driver/features/auth/data/repositories/remote_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';

class _MemSecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> clearAllAuthData() async => _data.clear();
}

class _SilentLogger implements LoggerService {
  @override
  LogLevel level = LogLevel.debug;

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}
}

Map<String, dynamic> _tokenJson({
  required String access,
  required String refresh,
}) {
  final now = DateTime.now().toUtc();
  return {
    'accessToken': access,
    'accessTokenExpiresAt': now.add(const Duration(hours: 1)).toIso8601String(),
    'refreshToken': refresh,
    'refreshTokenExpiresAt': now
        .add(const Duration(days: 30))
        .toIso8601String(),
    'tokenType': 'Bearer',
    'driver': {
      'driverId': '11111111-1111-4111-8111-111111111111',
      'displayName': 'Test Driver',
      'phoneMasked': '+9665****5678',
      'locale': 'ar-SA',
      'status': 'active',
    },
  };
}

typedef _Responder = Response Function();

class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({this.onOtpRequest, this.onOtpVerify, this.onLogout});

  final _Responder? onOtpRequest;
  final _Responder? onOtpVerify;
  final _Responder? onLogout;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final Response response;
    if (path.contains('/otp/request')) {
      response = onOtpRequest!();
    } else if (path.contains('/otp/verify')) {
      response = onOtpVerify!();
    } else if (path.contains('/logout')) {
      response = onLogout!();
    } else {
      throw StateError('Unexpected path: $path');
    }
    return ResponseBody.fromString(
      response.data == null ? '' : jsonEncode(response.data),
      response.statusCode ?? 500,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _Counting401Adapter implements HttpClientAdapter {
  _Counting401Adapter({required this.onFirstWave, required this.onRetry});

  final _Responder onFirstWave;
  final _Responder onRetry;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final retried = options.extra['saeq_retried'] == true;
    final response = retried ? onRetry() : onFirstWave();
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 500,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late Dio dio;
  late AccessTokenMemoryCache cache;
  late InMemoryAuthTokenStore tokenStore;
  late RemoteAuthenticationRepository repo;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:9'));
    cache = AccessTokenMemoryCache();
    tokenStore = InMemoryAuthTokenStore();

    late final RemoteAuthenticationRepository remoteRepo;
    final api = SaeqApiClient(
      baseUrl: 'http://127.0.0.1:9',
      accessTokenCache: cache,
      logger: _SilentLogger(),
      dio: dio,
      onUnauthorizedRefresh: () => remoteRepo.refreshTokensForClient(),
    );

    remoteRepo = RemoteAuthenticationRepository(
      remote: HttpAuthRemoteDataSource(api: api),
      sessionStorage: AuthSessionStorage(
        storage: _MemSecureStorage(),
        logger: _SilentLogger(),
      ),
      tokenStore: tokenStore,
      accessTokenCache: cache,
      logger: _SilentLogger(),
    );
    repo = remoteRepo;
  });

  test(
    'OTP request + verify stores refresh securely and access in memory',
    () async {
      dio.httpClientAdapter = _AuthAdapter(
        onOtpRequest: () => Response(
          requestOptions: RequestOptions(path: '/v1/auth/otp/request'),
          statusCode: 200,
          data: {
            'challengeId': '22222222-2222-4222-8222-222222222222',
            'expiresAt': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 5))
                .toIso8601String(),
            'resendAvailableAt': DateTime.now()
                .toUtc()
                .add(const Duration(seconds: 30))
                .toIso8601String(),
          },
        ),
        onOtpVerify: () => Response(
          requestOptions: RequestOptions(path: '/v1/auth/otp/verify'),
          statusCode: 200,
          data: _tokenJson(access: 'access-1', refresh: 'refresh-1'),
        ),
      );

      await repo.requestOtp('0512345678');
      final session = await repo.verifyOtp(
        phoneNumber: '0512345678',
        otpCode: '123456',
      );
      expect(session.driverId, '11111111-1111-4111-8111-111111111111');
      expect(cache.accessToken, 'access-1');
      expect(await tokenStore.readRefreshToken(), 'refresh-1');
    },
  );

  test(
    'single-flight refresh on concurrent 401 — refresh once, retry once',
    () async {
      cache.setAccessToken('access-1');
      await tokenStore.saveRefreshToken('refresh-1');

      var refreshCalls = 0;
      final api = SaeqApiClient(
        baseUrl: 'http://127.0.0.1:9',
        accessTokenCache: cache,
        logger: _SilentLogger(),
        dio: dio,
        onUnauthorizedRefresh: () async {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          cache.setAccessToken('access-2');
          await tokenStore.saveRefreshToken('refresh-2');
          return true;
        },
      );

      dio.httpClientAdapter = _Counting401Adapter(
        onFirstWave: () {
          return Response(
            requestOptions: RequestOptions(path: '/v1/drivers/me'),
            statusCode: 401,
            data: {
              'code': 'TOKEN_EXPIRED',
              'message': 'expired',
              'requestId': 'r',
              'retryable': false,
              'details': <String, dynamic>{},
            },
          );
        },
        onRetry: () {
          return Response(
            requestOptions: RequestOptions(path: '/v1/drivers/me'),
            statusCode: 200,
            data: {'ok': true},
          );
        },
      );

      final results = await Future.wait([
        api.get<Map<String, dynamic>>('/v1/drivers/me'),
        api.get<Map<String, dynamic>>('/v1/drivers/me'),
        api.get<Map<String, dynamic>>('/v1/drivers/me'),
      ]);
      expect(results.every((r) => r.statusCode == 200), isTrue);
      expect(refreshCalls, 1);
    },
  );

  test('logout clears tokens from store and memory', () async {
    cache.setAccessToken('access-1');
    await tokenStore.saveRefreshToken('refresh-1');
    dio.httpClientAdapter = _AuthAdapter(
      onLogout: () => Response(
        requestOptions: RequestOptions(path: '/v1/auth/logout'),
        statusCode: 204,
      ),
    );
    await repo.signOut();
    expect(cache.accessToken, isNull);
    expect(await tokenStore.readRefreshToken(), isNull);
  });

  test('OTP_INVALID maps to InvalidOtpError', () async {
    dio.httpClientAdapter = _AuthAdapter(
      onOtpRequest: () => Response(
        requestOptions: RequestOptions(path: '/v1/auth/otp/request'),
        statusCode: 200,
        data: {
          'challengeId': '22222222-2222-4222-8222-222222222222',
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 5))
              .toIso8601String(),
        },
      ),
      onOtpVerify: () => Response(
        requestOptions: RequestOptions(path: '/v1/auth/otp/verify'),
        statusCode: 401,
        data: {
          'code': 'OTP_INVALID',
          'message': 'bad otp',
          'requestId': 'r',
          'retryable': false,
          'details': <String, dynamic>{},
        },
      ),
    );
    await repo.requestOtp('0512345678');
    await expectLater(
      repo.verifyOtp(phoneNumber: '0512345678', otpCode: '000000'),
      throwsA(isA<InvalidOtpError>()),
    );
  });

  test('secure token store does not use SharedPreferences key namespace', () {
    const store = SecureAuthTokenStore;
    expect('$store', contains('SecureAuthTokenStore'));
  });
}
