import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/auth_session/access_token_memory_cache.dart';
import 'package:saeq_driver/core/auth_session/auth_token_store.dart';
import 'package:saeq_driver/core/auth_session/device_identity_store.dart';
import 'package:saeq_driver/core/network/saeq_api_client.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/core/services/storage/secure_storage_service.dart';
import 'package:saeq_driver/features/auth/data/remote/http_auth_remote_data_source.dart';
import 'package:saeq_driver/features/auth/data/repositories/remote_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';

/// Regression tests for the stable `device.deviceId` fix
/// (fix/auth-stable-device-uuid): the OTP verify payload must carry a valid
/// UUID that is generated once, persisted, and reused — never the legacy
/// literal `saeq-driver-flutter`, and never a per-request value.

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

class _MemSecureStorage implements SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<void> deleteAll() async => data.clear();

  @override
  Future<bool> containsKey(String key) async => data.containsKey(key);

  @override
  Future<String?> getAccessToken() async => data['access_token'];

  @override
  Future<String?> getRefreshToken() async => data['refresh_token'];

  @override
  Future<void> clearAllAuthData() async => data.clear();
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

Map<String, dynamic> _tokenJson() {
  final now = DateTime.now().toUtc();
  return {
    'accessToken': 'access-1',
    'accessTokenExpiresAt': now.add(const Duration(hours: 1)).toIso8601String(),
    'refreshToken': 'refresh-1',
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

Map<String, dynamic> _challengeJson() {
  final now = DateTime.now().toUtc();
  return {
    'challengeId': '22222222-2222-4222-8222-222222222222',
    'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
    'resendAvailableAt': now
        .add(const Duration(seconds: 30))
        .toIso8601String(),
  };
}

/// Adapter that captures the decoded JSON body of every `/otp/verify`
/// request exactly as it would go over the wire.
class _CapturingAuthAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> verifyBodies = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Map<String, dynamic> responseJson;
    if (options.path.contains('/otp/request')) {
      responseJson = _challengeJson();
    } else if (options.path.contains('/otp/verify')) {
      final bytes = <int>[];
      if (requestStream != null) {
        await for (final chunk in requestStream) {
          bytes.addAll(chunk);
        }
      }
      final raw = bytes.isNotEmpty ? utf8.decode(bytes) : jsonEncode(options.data);
      verifyBodies.add(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      responseJson = _tokenJson();
    } else {
      throw StateError('Unexpected path: ${options.path}');
    }
    return ResponseBody.fromString(
      jsonEncode(responseJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

RemoteAuthenticationRepository _buildRepo({
  required _CapturingAuthAdapter adapter,
  required SecureStorageService storage,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:9'))
    ..httpClientAdapter = adapter;
  final cache = AccessTokenMemoryCache();
  late final RemoteAuthenticationRepository repo;
  final api = SaeqApiClient(
    baseUrl: 'http://127.0.0.1:9',
    accessTokenCache: cache,
    logger: _SilentLogger(),
    dio: dio,
    onUnauthorizedRefresh: () => repo.refreshTokensForClient(),
  );
  repo = RemoteAuthenticationRepository(
    remote: HttpAuthRemoteDataSource(api: api),
    sessionStorage: AuthSessionStorage(storage: storage, logger: _SilentLogger()),
    tokenStore: InMemoryAuthTokenStore(),
    accessTokenCache: cache,
    logger: _SilentLogger(),
    deviceIdentityStore: SecureDeviceIdentityStore(storage: storage),
  );
  return repo;
}

Future<void> _requestAndVerify(RemoteAuthenticationRepository repo) async {
  await repo.requestOtp('0512345678');
  await repo.verifyOtp(phoneNumber: '0512345678', otpCode: '123456');
}

void main() {
  group('stable device.deviceId in OTP verify', () {
    test('sent deviceId is a valid UUID v4 (not the legacy literal)', () async {
      final adapter = _CapturingAuthAdapter();
      final repo = _buildRepo(adapter: adapter, storage: _MemSecureStorage());

      await _requestAndVerify(repo);

      expect(adapter.verifyBodies, hasLength(1));
      final device = Map<String, dynamic>.from(
        adapter.verifyBodies.single['device'] as Map,
      );
      final deviceId = device['deviceId'] as String;
      expect(deviceId, isNot('saeq-driver-flutter'));
      expect(_uuidV4.hasMatch(deviceId), isTrue, reason: 'got: $deviceId');
    });

    test('deviceId is stable across repeated verify requests', () async {
      final adapter = _CapturingAuthAdapter();
      final repo = _buildRepo(adapter: adapter, storage: _MemSecureStorage());

      await _requestAndVerify(repo);
      await _requestAndVerify(repo);

      expect(adapter.verifyBodies, hasLength(2));
      final first = (adapter.verifyBodies[0]['device'] as Map)['deviceId'];
      final second = (adapter.verifyBodies[1]['device'] as Map)['deviceId'];
      expect(second, first);
    });

    test('persisted deviceId is reused after repository re-creation', () async {
      final storage = _MemSecureStorage();

      final adapter1 = _CapturingAuthAdapter();
      await _requestAndVerify(_buildRepo(adapter: adapter1, storage: storage));

      // Simulates an app restart: new repository over the same storage.
      final adapter2 = _CapturingAuthAdapter();
      await _requestAndVerify(_buildRepo(adapter: adapter2, storage: storage));

      final first = (adapter1.verifyBodies.single['device'] as Map)['deviceId'];
      final second =
          (adapter2.verifyBodies.single['device'] as Map)['deviceId'];
      expect(second, first);
      expect(storage.data[SecureDeviceIdentityStore.storageKey], first);
    });

    test('rest of the OTP verify payload is unchanged', () async {
      final adapter = _CapturingAuthAdapter();
      final repo = _buildRepo(adapter: adapter, storage: _MemSecureStorage());

      await _requestAndVerify(repo);

      final body = adapter.verifyBodies.single;
      expect(
        body.keys.toSet(),
        {'challengeId', 'otpCode', 'device'},
      );
      expect(body['challengeId'], '22222222-2222-4222-8222-222222222222');
      expect(body['otpCode'], '123456');
      final device = Map<String, dynamic>.from(body['device'] as Map);
      expect(device.keys.toSet(), {'deviceId', 'platform', 'appVersion'});
      expect(device['platform'], 'android');
      expect(device['appVersion'], '1.0.0');
    });
  });

  group('SecureDeviceIdentityStore', () {
    test('generates once, persists, and reuses across instances', () async {
      final storage = _MemSecureStorage();

      final store1 = SecureDeviceIdentityStore(storage: storage);
      final id1 = await store1.obtainDeviceId();
      expect(_uuidV4.hasMatch(id1), isTrue);
      expect(storage.data[SecureDeviceIdentityStore.storageKey], id1);

      expect(await store1.obtainDeviceId(), id1);

      final store2 = SecureDeviceIdentityStore(storage: storage);
      expect(await store2.obtainDeviceId(), id1);
    });

    test('replaces a legacy non-UUID stored value with a valid UUID', () async {
      final storage = _MemSecureStorage();
      storage.data[SecureDeviceIdentityStore.storageKey] =
          'saeq-driver-flutter';

      final id = await SecureDeviceIdentityStore(
        storage: storage,
      ).obtainDeviceId();

      expect(_uuidV4.hasMatch(id), isTrue);
      expect(storage.data[SecureDeviceIdentityStore.storageKey], id);
    });

    test('concurrent callers get a single generated value', () async {
      final store = SecureDeviceIdentityStore(storage: _MemSecureStorage());

      final results = await Future.wait([
        store.obtainDeviceId(),
        store.obtainDeviceId(),
        store.obtainDeviceId(),
      ]);

      expect(results.toSet(), hasLength(1));
    });
  });
}
