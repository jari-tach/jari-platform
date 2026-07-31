import 'access_token_memory_cache.dart';
import 'auth_token_store.dart';

/// Session boundary: refresh-token store + in-memory access token.
///
/// Presentation must never touch [AuthTokenStore] or the memory cache directly.
final class SessionRepository {
  SessionRepository({
    required AuthTokenStore tokenStore,
    required AccessTokenMemoryCache accessTokenCache,
  }) : _tokenStore = tokenStore,
       _accessTokenCache = accessTokenCache;

  final AuthTokenStore _tokenStore;
  final AccessTokenMemoryCache _accessTokenCache;

  AuthTokenStore get tokenStore => _tokenStore;
  AccessTokenMemoryCache get accessTokenCache => _accessTokenCache;

  Future<void> clearAll() async {
    _accessTokenCache.clear();
    await _tokenStore.clearAll();
  }
}
