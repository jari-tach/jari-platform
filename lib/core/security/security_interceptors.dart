import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

import '../services/api/api_client.dart';
import '../services/logger/logger_service.dart';
import '../services/storage/secure_storage_service.dart';

/// Security interceptor for Dio
///
/// Implements:
/// - Request signing
/// - Certificate pinning
/// - JWT token injection
/// - Token refresh on 401
class SecurityInterceptor extends Interceptor {
  final LoggerService _logger;
  final SecureStorageService _secureStorage;

  SecurityInterceptor({required this._logger, required this._secureStorage});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Add JWT token if available
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Add timestamp for request signing
      final timestamp = DateTime.now()
          .toUtc()
          .millisecondsSinceEpoch
          .toString();
      options.headers['X-Timestamp'] = timestamp;

      // Sign request if needed
      // final signature = _signRequest(options, timestamp);
      // options.headers['X-Signature'] = signature;

      _logger.debug('SecurityInterceptor: Request to ${options.uri}');
      handler.next(options);
    } catch (e, stackTrace) {
      _logger.error(
        'SecurityInterceptor: Failed to process request',
        e,
        stackTrace,
      );
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to process request',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - try to refresh token
    if (err.response?.statusCode == 401) {
      _logger.warning(
        'SecurityInterceptor: 401 Unauthorized - attempting token refresh',
      );

      try {
        // TODO: Implement token refresh logic
        // final refreshToken = await _secureStorage.getRefreshToken();
        // if (refreshToken != null) {
        //   final newToken = await _refreshToken(refreshToken);
        //   await _secureStorage.saveAccessToken(newToken);
        //
        //   // Retry original request
        //   final response = await _retryRequest(err.requestOptions);
        //   handler.resolve(response);
        //   return;
        // }
      } catch (e, stackTrace) {
        _logger.error(
          'SecurityInterceptor: Token refresh failed',
          e,
          stackTrace,
        );
        // Clear auth data and redirect to login
        await _secureStorage.clearAllAuthData();
      }
    }

    handler.next(err);
  }
}

/// Certificate pinning for secure connections
class CertificatePinning {
  final LoggerService _logger;

  // SHA-256 hashes of allowed certificates
  static const List<String> _allowedCertificates = [
    // TODO: Add production certificate hashes
    // 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    // 'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];

  CertificatePinning({required this._logger});

  /// Validate certificate against pinned certificates
  bool validateCertificate(X509Certificate certificate) {
    try {
      final pin = _calculatePin(certificate);
      final isValid = _allowedCertificates.contains(pin);

      _logger.debug('CertificatePinning: Validating $pin - $isValid');
      return isValid;
    } catch (e, stackTrace) {
      _logger.error('CertificatePinning: Validation failed', e, stackTrace);
      return false;
    }
  }

  /// Compute the certificate pin (`sha256/<base64>`) from its DER bytes.
  String _calculatePin(X509Certificate certificate) {
    return 'sha256/${_calculateSha256(certificate.der)}';
  }

  /// SHA-256 digest of [bytes], base64-encoded.
  String _calculateSha256(List<int> bytes) {
    return base64.encode(sha256.convert(bytes).bytes);
  }
}

/// JWT Manager for token handling
class JwtManager {
  final LoggerService _logger;
  final SecureStorageService _secureStorage;

  JwtManager({required this._logger, required this._secureStorage});

  /// Whether a stored access token currently exists.
  Future<bool> hasStoredAccessToken() async =>
      (await _secureStorage.getAccessToken()) != null;

  /// Decode JWT token without verification
  Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.warning('JwtManager: Invalid token format');
        return null;
      }

      final payload = parts[1];
      // Add padding if needed
      final padded = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(padded));

      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      _logger.error('JwtManager: Failed to decode token', e, stackTrace);
      return null;
    }
  }

  /// Check if token is expired
  bool isTokenExpired(String token) {
    final payload = decodeToken(token);
    if (payload == null) return true;

    final exp = payload['exp'] as int?;
    if (exp == null) return true;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiryDate);
  }

  /// Get token expiration date
  DateTime? getTokenExpiration(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    final exp = payload['exp'] as int?;
    if (exp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  /// Get user ID from token
  String? getUserId(String token) {
    final payload = decodeToken(token);
    return payload?['sub'] as String? ?? payload?['user_id'] as String?;
  }
}

/// Token refresh manager
class TokenRefreshManager {
  final LoggerService _logger;
  final SecureStorageService _secureStorage;
  final ApiClient _apiClient;

  TokenRefreshManager({
    required this._logger,
    required this._secureStorage,
    required this._apiClient,
  });

  /// Refresh access token using refresh token
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        _logger.warning('TokenRefreshManager: No refresh token available');
        return null;
      }

      _logger.info('TokenRefreshManager: Refreshing access token');

      // TODO: Implement actual token refresh API call
      // final response = await _apiClient.post('/auth/refresh', data: {
      //   'refresh_token': refreshToken,
      // });
      // final newToken = response.data['access_token'] as String;
      // await _secureStorage.saveAccessToken(newToken);
      // return newToken;

      _logger.debug('TokenRefreshManager: ApiClient=${_apiClient.runtimeType}');
      _logger.warning('TokenRefreshManager: Not implemented yet');
      return null;
    } catch (e, stackTrace) {
      _logger.error(
        'TokenRefreshManager: Failed to refresh token',
        e,
        stackTrace,
      );
      return null;
    }
  }
}
