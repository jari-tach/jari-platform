import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/network/remote_error_classification.dart';
import 'package:saeq_driver/core/network/remote_error_mapper.dart';

DioException _dio({required DioExceptionType type, int? status, Object? data}) {
  return DioException(
    requestOptions: RequestOptions(path: '/v1/test'),
    type: type,
    response: status == null
        ? null
        : Response(
            requestOptions: RequestOptions(path: '/v1/test'),
            statusCode: status,
            data: data,
          ),
  );
}

void main() {
  const mapper = RemoteErrorMapper();

  group('RemoteErrorMapper', () {
    test('maps connection error to networkUnavailable', () {
      expect(
        mapper.classify(_dio(type: DioExceptionType.connectionError)),
        RemoteErrorClassification.networkUnavailable,
      );
    });

    test('maps timeout to requestTimeout', () {
      expect(
        mapper.classify(_dio(type: DioExceptionType.receiveTimeout)),
        RemoteErrorClassification.requestTimeout,
      );
    });

    test('maps TOKEN_EXPIRED envelope to sessionExpired', () {
      expect(
        mapper.classify(
          _dio(
            type: DioExceptionType.badResponse,
            status: 401,
            data: {
              'code': 'TOKEN_EXPIRED',
              'message': 'expired',
              'requestId': 'r1',
              'retryable': false,
              'details': <String, dynamic>{},
            },
          ),
        ),
        RemoteErrorClassification.sessionExpired,
      );
    });

    test('maps OTP_RATE_LIMITED to rateLimited', () {
      expect(
        mapper.classify(
          _dio(
            type: DioExceptionType.badResponse,
            status: 429,
            data: {
              'code': 'OTP_RATE_LIMITED',
              'message': 'slow down',
              'requestId': 'r2',
              'retryable': true,
              'details': <String, dynamic>{},
            },
          ),
        ),
        RemoteErrorClassification.rateLimited,
      );
    });

    test('maps 500 to serverUnavailable', () {
      expect(
        mapper.classify(_dio(type: DioExceptionType.badResponse, status: 500)),
        RemoteErrorClassification.serverUnavailable,
      );
    });

    test('GNSS-style FormatException is unknown (not network offline)', () {
      expect(
        mapper.classify(const FormatException('GNSS timeout')),
        RemoteErrorClassification.unknown,
      );
    });
  });
}
