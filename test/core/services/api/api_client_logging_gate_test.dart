import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/services/api/api_interceptors.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';

class _CapturingLogger implements LoggerService {
  final metadata = <Map<String, dynamic>?>[];

  @override
  LogLevel level = LogLevel.debug;

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    this.metadata.add(metadata);
  }

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}
}

void main() {
  test('LoggingInterceptor redacts Authorization and never logs raw token', () {
    final logger = _CapturingLogger();
    final interceptor = LoggingInterceptor(logger: logger);
    final options = RequestOptions(
      path: '/v1/secure',
      baseUrl: 'https://example.com',
      headers: const {'Authorization': 'Bearer super-secret-token'},
    );

    interceptor.onRequest(options, RequestInterceptorHandler());

    expect(logger.metadata, isNotEmpty);
    final headers = logger.metadata.single!['headers'] as Map;
    expect(headers['Authorization'], '***');
    expect(jsonEncode(logger.metadata), isNot(contains('super-secret-token')));
  });
}
