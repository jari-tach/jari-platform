/// Redacts sensitive values from structured log maps.
final class HttpLogRedactor {
  static const _sensitiveHeaderKeys = {'authorization', 'idempotency-key'};

  static const _sensitiveBodyKeys = {
    'accessToken',
    'refreshToken',
    'otpCode',
    'otp',
    'password',
    'authorization',
  };

  Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    final out = <String, dynamic>{};
    headers.forEach((key, value) {
      if (_sensitiveHeaderKeys.contains(key.toLowerCase())) {
        out[key] = '***';
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  Object? redactBody(Object? body) {
    if (body is Map) {
      final out = <String, dynamic>{};
      body.forEach((key, value) {
        final k = key.toString();
        if (_sensitiveBodyKeys.contains(k)) {
          out[k] = '***';
        } else if (value is Map || value is List) {
          out[k] = redactBody(value);
        } else {
          out[k] = value;
        }
      });
      return out;
    }
    if (body is List) {
      return body.map(redactBody).toList();
    }
    return body;
  }

  bool containsSensitivePlaintext(String text) {
    final lower = text.toLowerCase();
    return lower.contains('bearer ') ||
        lower.contains('synthetic-access-token') == false &&
            (lower.contains('accessToken'.toLowerCase()) &&
                text.contains('eyJ'));
  }
}
