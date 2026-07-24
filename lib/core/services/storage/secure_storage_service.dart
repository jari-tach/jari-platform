import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../logger/logger_service.dart';

// Convenience methods for common tokens
Future<void> saveAccessToken(FlutterSecureStorage storage, String token) => storage.write(key: 'access_token', value: token);
Future<String?> getAccessToken(FlutterSecureStorage storage) => storage.read(key: 'access_token');
Future<void> deleteAccessToken(FlutterSecureStorage storage) => storage.delete(key: 'access_token');

Future<void> saveRefreshToken(FlutterSecureStorage storage, String token) => storage.write(key: 'refresh_token', value: token);
Future<String?> getRefreshToken(FlutterSecureStorage storage) => storage.read(key: 'refresh_token');
Future<void> deleteRefreshToken(FlutterSecureStorage storage) => storage.delete(key: 'refresh_token');

Future<void> saveUserId(FlutterSecureStorage storage, String userId) => storage.write(key: 'user_id', value: userId);
Future<String?> getUserId(FlutterSecureStorage storage) => storage.read(key: 'user_id');
Future<void> deleteUserId(FlutterSecureStorage storage) => storage.delete(key: 'user_id');

Future<void> saveAuthSession(FlutterSecureStorage storage, String session) => storage.write(key: 'auth_session', value: session);
Future<String?> getAuthSession(FlutterSecureStorage storage) => storage.read(key: 'auth_session');
Future<void> deleteAuthSession(FlutterSecureStorage storage) => storage.delete(key: 'auth_session');

Future<void> clearAllAuthData(FlutterSecureStorage storage) async {
  await deleteAccessToken(storage);
  await deleteRefreshToken(storage);
  await deleteUserId(storage);
  await deleteAuthSession(storage);
}

/// Secure storage service for sensitive data
///
/// Uses flutter_secure_storage for:
/// - Access tokens
/// - Refresh tokens
/// - User credentials
/// - Sensitive configuration
///
/// SharedPreferences (via AppPreferences) should be used for:
/// - UI preferences
/// - Theme
/// - Locale
/// - Onboarding status
abstract class SecureStorageService {
  Future<void> init();
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);

  // Token/session helpers required by current call sites
  // (security_interceptors.dart, app_service_registry.dart).
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAllAuthData();
}

class SecureStorageServiceImpl implements SecureStorageService {
  final FlutterSecureStorage _storage;
  final LoggerService _logger;

  SecureStorageServiceImpl({required LoggerService logger})
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        ),
        _logger = logger;

  @override
  Future<void> init() async {
    _logger.info('SecureStorageService: Initialized');
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _logger.debug('SecureStorageService: Written key=$key');
    } catch (e, stackTrace) {
      _logger.error('SecureStorageService: Failed to write key=$key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      _logger.debug('SecureStorageService: Read key=$key, exists=${value != null}');
      return value;
    } catch (e, stackTrace) {
      _logger.error('SecureStorageService: Failed to read key=$key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      _logger.debug('SecureStorageService: Deleted key=$key');
    } catch (e, stackTrace) {
      _logger.error('SecureStorageService: Failed to delete key=$key', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _logger.info('SecureStorageService: Deleted all keys');
    } catch (e, stackTrace) {
      _logger.error('SecureStorageService: Failed to delete all', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      _logger.error('SecureStorageService: Failed to check key=$key', e);
      return false;
    }
  }

  // Convenience methods for common tokens
  Future<void> saveAccessToken(String token) => write('access_token', token);
  @override
  Future<String?> getAccessToken() => read('access_token');
  Future<void> deleteAccessToken() => delete('access_token');

  Future<void> saveRefreshToken(String token) => write('refresh_token', token);
  @override
  Future<String?> getRefreshToken() => read('refresh_token');
  Future<void> deleteRefreshToken() => delete('refresh_token');

  Future<void> saveUserId(String userId) => write('user_id', userId);
  Future<String?> getUserId() => read('user_id');
  Future<void> deleteUserId() => delete('user_id');

  Future<void> saveAuthSession(String session) => write('auth_session', session);
  Future<String?> getAuthSession() => read('auth_session');
  Future<void> deleteAuthSession() => delete('auth_session');

  @override
  Future<void> clearAllAuthData() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserId();
    await deleteAuthSession();
    _logger.info('SecureStorageService: Cleared all auth data');
  }
}