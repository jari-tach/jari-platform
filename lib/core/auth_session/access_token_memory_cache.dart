/// In-memory access token for synchronous Authorization headers.
final class AccessTokenMemoryCache {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = (token == null || token.isEmpty) ? null : token;
  }

  void clear() => _accessToken = null;
}
