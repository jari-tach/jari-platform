import 'package:dio/dio.dart';

import '../logger/logger_service.dart';

/// Interceptor that logs all HTTP requests and responses.
final class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({required LoggerService logger}) : _logger = logger;

  final LoggerService _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug(
      'HTTP ${options.method} ${options.uri}',
      null,
      null,
      {
        'headers': options.headers,
        if (options.data != null) 'body': options.data,
      },
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.debug(
      'HTTP ${response.statusCode} ${response.requestOptions.uri}',
      null,
      null,
      {
        'statusCode': response.statusCode,
        if (response.data != null) 'body': response.data,
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.error(
      'HTTP ${err.response?.statusCode ?? 'ERROR'} ${err.requestOptions.uri}',
      err,
      err.stackTrace,
      {
        'type': err.type.name,
        'statusCode': err.response?.statusCode,
        'response': err.response?.data,
      },
    );
    handler.next(err);
  }
}

/// Interceptor that adds authentication headers to requests.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenProvider});

  /// Function that returns the current access token.
  final String? Function() tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Interceptor that retries failed requests on specific conditions.
final class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  final int maxRetries;
  final Duration retryDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_shouldRetry(err) && _getRetryCount(err) < maxRetries) {
      final retryCount = _getRetryCount(err) + 1;
      _setRetryCount(err.requestOptions, retryCount);

      Future.delayed(retryDelay * retryCount, () async {
        try {
          final response = await _retryRequest(err.requestOptions);
          handler.resolve(response);
        } catch (retryError) {
          handler.next(err);
        }
      });
    } else {
      handler.next(err);
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions options) async {
    final dio = Dio();
    return dio.fetch<dynamic>(options);
  }

  bool _shouldRetry(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        err.response?.statusCode != null && err.response!.statusCode! >= 500,
      _ => false,
    };
  }

  int _getRetryCount(DioException err) {
    return err.requestOptions.extra['retryCount'] as int? ?? 0;
  }

  void _setRetryCount(RequestOptions options, int count) {
    options.extra['retryCount'] = count;
  }
}

