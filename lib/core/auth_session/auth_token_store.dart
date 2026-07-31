import '../services/storage/secure_storage_service.dart';

/// Secure persistence for refresh tokens (and optional access token backup).
abstract interface class AuthTokenStore {
  Future<void> saveRefreshToken(String token);
  Future<String?> readRefreshToken();
  Future<void> clearRefreshToken();
  Future<void> clearAll();
}

final class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({required this._storage});

  static const _refreshKey = 'saeq_refresh_token_v1';

  final SecureStorageService _storage;

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(_refreshKey, token);

  @override
  Future<String?> readRefreshToken() => _storage.read(_refreshKey);

  @override
  Future<void> clearRefreshToken() => _storage.delete(_refreshKey);

  @override
  Future<void> clearAll() => clearRefreshToken();
}

/// In-memory token store for unit tests.
final class InMemoryAuthTokenStore implements AuthTokenStore {
  String? _refresh;

  @override
  Future<void> saveRefreshToken(String token) async => _refresh = token;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> clearRefreshToken() async => _refresh = null;

  @override
  Future<void> clearAll() async => _refresh = null;
}
