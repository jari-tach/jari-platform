import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../logger/logger_service.dart';
import 'api_interceptors.dart';

/// Configured HTTP client for the Saeq API.
///
/// Wraps [Dio] with pre-configured interceptors for auth, logging, and retry.
final class ApiClient {
  ApiClient({
    required LoggerService logger,
    String? Function()? tokenProvider,
  }) : _dio = _createDio(logger, tokenProvider);

  final Dio _dio;

  static Dio _createDio(LoggerService logger, String? Function()? tokenProvider) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseApiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': 'ar',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider: tokenProvider ?? () => null),
      LoggingInterceptor(logger: logger),
      RetryInterceptor(),
    ]);

    return dio;
  }

  /// Perform a GET request.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform a POST request.
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform a PUT request.
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform a PATCH request.
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Perform a DELETE request.
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Access the underlying Dio instance for advanced use cases.
  Dio get dio => _dio;
}