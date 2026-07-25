import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../logger/logger_service.dart';
import 'app_exception.dart';
import 'app_failure.dart';

/// Global error handler for the application
///
/// Handles:
/// - Flutter framework errors
/// - Platform errors
/// - Uncaught exceptions
/// - Riverpod errors
class AppErrorHandler {
  final LoggerService _logger;

  // Stream controllers for error events
  final StreamController<AppException> _exceptionController =
      StreamController<AppException>.broadcast();
  final StreamController<AppFailure> _failureController =
      StreamController<AppFailure>.broadcast();

  AppErrorHandler({required this._logger});

  /// Initialize global error handlers
  void init() {
    _logger.info('AppErrorHandler: Initializing global error handlers');

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    // Handle uncaught async errors
    runZonedGuarded(() {}, (error, stackTrace) {
      _handleZoneError(error, stackTrace);
    });

    _logger.info('AppErrorHandler: Global error handlers initialized');
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final exception = UnknownException(
      details.exceptionAsString(),
      stackTrace: details.stack,
    );

    _logger.error(
      'AppErrorHandler: Flutter error',
      details.exception,
      details.stack,
      {'library': details.library, 'context': details.context?.toString()},
    );

    _exceptionController.add(exception);
  }

  /// Handle platform errors
  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    final exception = UnknownException(
      error.toString(),
      stackTrace: stackTrace,
    );

    _logger.error('AppErrorHandler: Platform error', error, stackTrace);
    _exceptionController.add(exception);

    return true;
  }

  /// Handle zone errors
  void _handleZoneError(Object error, StackTrace stackTrace) {
    final exception = UnknownException(
      error.toString(),
      stackTrace: stackTrace,
    );

    _logger.fatal('AppErrorHandler: Zone error', error, stackTrace);
    _exceptionController.add(exception);
  }

  /// Handle Dio errors
  void handleDioError(DioException error) {
    final exception = _mapDioErrorToException(error);

    _logger.error('AppErrorHandler: Dio error', error, error.stackTrace, {
      'statusCode': error.response?.statusCode,
      'url': error.requestOptions.uri.toString(),
    });

    _exceptionController.add(exception);
  }

  /// Map Dio error to AppException
  AppException _mapDioErrorToException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timeout',
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data?['message'] ?? 'Unknown error';

        return ServerException(
          message,
          statusCode: statusCode,
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.cancel:
        return UnknownException(
          'Request cancelled',
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'No internet connection',
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.badCertificate:
        return UnknownException(
          'SSL certificate error',
          stackTrace: error.stackTrace,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownException(
          error.message ?? 'Unknown error',
          stackTrace: error.stackTrace,
        );
    }
  }

  /// Convert exception to failure
  AppFailure mapExceptionToFailure(AppException exception) {
    _logger.debug('AppErrorHandler: Mapping exception to failure');

    return switch (exception) {
      NetworkException() => NetworkFailure(exception.message),
      ServerException() => ServerFailure(
        exception.message,
        statusCode: exception.statusCode,
      ),
      AuthException() => UnauthenticatedFailure(exception.message),
      ValidationException() => ValidationFailure(exception.message),
      CacheException() => CacheFailure(exception.message),
      SerializationException() => UnknownFailure(exception.message),
      UnknownException() => UnknownFailure(exception.message),
    };
  }

  /// Stream of exceptions
  Stream<AppException> get exceptionStream => _exceptionController.stream;

  /// Stream of failures
  Stream<AppFailure> get failureStream => _failureController.stream;

  /// Dispose resources
  Future<void> dispose() async {
    await _exceptionController.close();
    await _failureController.close();
    _logger.info('AppErrorHandler: Disposed');
  }
}

/// Error handler provider
final appErrorHandlerProvider = Provider<AppErrorHandler>((ref) {
  final logger = ref.watch(loggerServiceProvider);
  final handler = AppErrorHandler(logger: logger);

  // Initialize on creation
  handler.init();

  // Dispose when provider is disposed
  ref.onDispose(() => handler.dispose());

  return handler;
});
