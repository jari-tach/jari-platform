import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'app_failure.dart';
import '../logger/logger_service.dart';

/// Centralized error handler that converts [AppException]s to [AppFailure]s
/// and handles unexpected errors gracefully.
final class AppErrorHandler {
  const AppErrorHandler({required LoggerService logger}) : _logger = logger;

  final LoggerService _logger;

  /// Converts an [AppException] to the corresponding [AppFailure].
  AppFailure mapExceptionToFailure(AppException exception) {
    return switch (exception) {
      NetworkException e => NetworkFailure(e.message, code: e.code),
      ServerException e => ServerFailure(e.message, code: e.code, statusCode: e.statusCode),
      AuthException e => UnauthenticatedFailure(e.message),
      ValidationException e => ValidationFailure(e.message, code: e.code, errors: e.errors),
      CacheException e => CacheFailure(e.message, code: e.code),
      SerializationException e => UnknownFailure(e.message, code: e.code, originalError: e),
      UnknownException e => UnknownFailure(e.message, code: e.code, originalError: e.originalError),
    };
  }

  /// Converts a generic [Exception] or [Error] to an [AppFailure].
  /// This is the top-level handler for unexpected errors.
  AppFailure handleUnexpectedError(Object error, [StackTrace? stackTrace]) {
    _logger.error(
      'Unexpected error occurred',
      error: error,
      stackTrace: stackTrace,
    );

    if (error is AppException) {
      return mapExceptionToFailure(error);
    }

    if (error is DioException) {
      return _mapDioExceptionToFailure(error);
    }

    if (error is FormatException) {
      return const UnknownFailure('Invalid data format');
    }

    return UnknownFailure(
      error.toString(),
      originalError: error,
    );
  }

  /// Maps a [DioException] to the appropriate [AppFailure].
  AppFailure _mapDioExceptionToFailure(DioException error) {
    _logger.error('DioException occurred', error: error, data: {
      'type': error.type.name,
      'statusCode': error.response?.statusCode,
      'uri': error.requestOptions.uri.toString(),
    });

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const TimeoutFailure(),
      DioExceptionType.connectionError =>
        const NetworkFailure('No internet connection'),
      DioExceptionType.badResponse =>
        _mapStatusCodeToFailure(error.response?.statusCode, error),
      DioExceptionType.cancel =>
        const NetworkFailure('Request was cancelled'),
      DioExceptionType.badCertificate =>
        const NetworkFailure('Invalid SSL certificate'),
      _ => UnknownFailure(error.message ?? 'Unknown network error'),
    };
  }

  /// Maps HTTP status codes to [AppFailure]s.
  AppFailure _mapStatusCodeToFailure(int? statusCode, DioException error) {
    if (statusCode == null) {
      return UnknownFailure(
        _extractErrorMessage(error) ?? 'No status code',
        code: 'NO_STATUS_CODE',
      );
    }

    return switch (statusCode) {
      400 => ValidationFailure(
          _extractErrorMessage(error) ?? 'Bad request',
          code: 'BAD_REQUEST',
        ),
      401 => const UnauthenticatedFailure(),
      403 => const UnauthorizedFailure(),
      404 => NotFoundFailure(
          _extractErrorMessage(error) ?? 'Resource not found',
          code: 'NOT_FOUND',
        ),
      409 => ValidationFailure(
          _extractErrorMessage(error) ?? 'Conflict',
          code: 'CONFLICT',
        ),
      422 => ValidationFailure(
          _extractErrorMessage(error) ?? 'Validation failed',
          code: 'VALIDATION_ERROR',
        ),
      429 => const TimeoutFailure('Too many requests'),
      >= 500 => ServerFailure(
          _extractErrorMessage(error) ?? 'Server error',
          code: 'SERVER_ERROR',
          statusCode: statusCode,
        ),
      _ => UnknownFailure(
          _extractErrorMessage(error) ?? 'Unexpected error',
          code: 'UNEXPECTED',
        ),
    };
  }

  /// Extracts the error message from a [DioException] response body.
  String? _extractErrorMessage(DioException error) {
    try {
      final data = error.response?.data;
      if (data is Map) {
        return data['message'] as String? ??
            data['error'] as String? ??
            data['error_description'] as String?;
      }
      if (data is String) return data;
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }
}