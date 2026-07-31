import 'dart:async';

import 'package:dio/dio.dart';

import '../auth_session/access_token_memory_cache.dart';
import '../services/logger/logger_service.dart';
import 'http_log_redactor.dart';
import 'request_id_factory.dart';

typedef TokenRefreshCallback = Future<bool> Function();

/// SAEQ Driver HTTP client for STEP 5C (separate from protected [ApiClient]).
final class SaeqApiClient {
  SaeqApiClient({
    required String baseUrl,
    required AccessTokenMemoryCache accessTokenCache,
    required LoggerService logger,
    RequestIdFactory? requestIdFactory,
    TokenRefreshCallback? onUnauthorizedRefresh,
    Dio? dio,
    HttpLogRedactor? redactor,
  }) : _accessTokenCache = accessTokenCache,
       _logger = logger,
       _requestIdFactory = requestIdFactory ?? RequestIdFactory(),
       _onUnauthorizedRefresh = onUnauthorizedRefresh,
       _redactor = redactor ?? HttpLogRedactor(),
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
               headers: const {
                 'Content-Type': 'application/json',
                 'Accept': 'application/json',
               },
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Request-Id'] ??= _requestIdFactory.next();
          final skipAuth = options.extra['skip_auth'] == true;
          if (skipAuth) {
            options.headers.remove('Authorization');
          } else {
            final token = _accessTokenCache.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          _logger.debug(
            'SAEQ HTTP ${options.method} ${options.path}',
            null,
            null,
            {
              'headers': _redactor.redactHeaders(
                Map<String, dynamic>.from(options.headers),
              ),
              if (options.data != null)
                'body': _redactor.redactBody(options.data),
            },
          );
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              _onUnauthorizedRefresh != null &&
              error.requestOptions.extra['saeq_retried'] != true) {
            final failedAuth = error.requestOptions.headers['Authorization']
                ?.toString();
            final currentToken = _accessTokenCache.accessToken;
            final alreadyRefreshed =
                currentToken != null &&
                currentToken.isNotEmpty &&
                failedAuth != 'Bearer $currentToken';

            final refreshed = alreadyRefreshed || await _singleFlightRefresh();
            if (refreshed) {
              final req = error.requestOptions;
              req.extra['saeq_retried'] = true;
              final token = _accessTokenCache.accessToken;
              if (token != null && token.isNotEmpty) {
                req.headers['Authorization'] = 'Bearer $token';
              } else {
                req.headers.remove('Authorization');
              }
              try {
                // Retry on an interceptor-free Dio that shares the live adapter
                // (tests often replace httpClientAdapter after construction).
                final retryDio = Dio(_dio.options)
                  ..httpClientAdapter = _dio.httpClientAdapter;
                final response = await retryDio.fetch<dynamic>(req);
                handler.resolve(response);
                return;
              } catch (_) {
                // Fall through to original error.
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final AccessTokenMemoryCache _accessTokenCache;
  final LoggerService _logger;
  final RequestIdFactory _requestIdFactory;
  final TokenRefreshCallback? _onUnauthorizedRefresh;
  final HttpLogRedactor _redactor;

  Future<bool>? _refreshInFlight;

  Future<bool> _singleFlightRefresh() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final future = () async {
      try {
        return await (_onUnauthorizedRefresh?.call() ?? Future.value(false));
      } finally {
        _refreshInFlight = null;
      }
    }();
    _refreshInFlight = future;
    return future;
  }

  Future<Response<T>> request<T>({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    bool authenticated = true,
  }) {
    return _dio.request<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        method: method,
        headers: {
          if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
          if (!authenticated) 'Authorization': null,
        },
        extra: {if (!authenticated) 'skip_auth': true},
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => request<T>(method: 'GET', path: path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
    bool authenticated = true,
  }) => request<T>(
    method: 'POST',
    path: path,
    data: data,
    idempotencyKey: idempotencyKey,
    authenticated: authenticated,
  );

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
  }) => request<T>(
    method: 'PUT',
    path: path,
    data: data,
    idempotencyKey: idempotencyKey,
  );

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
  }) => request<T>(
    method: 'PATCH',
    path: path,
    data: data,
    idempotencyKey: idempotencyKey,
  );
}
