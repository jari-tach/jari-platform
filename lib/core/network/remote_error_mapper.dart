import 'package:dio/dio.dart';

import 'error_envelope_parser.dart';
import 'remote_error_classification.dart';

/// Maps Dio failures to [RemoteErrorClassification].
///
/// Location/GNSS failures are out of scope here — callers must not pass them.
final class RemoteErrorMapper {
  const RemoteErrorMapper({this.envelopeParser = const ErrorEnvelopeParser()});

  final ErrorEnvelopeParser envelopeParser;

  RemoteErrorClassification classify(Object error) {
    if (error is! DioException) {
      return RemoteErrorClassification.unknown;
    }

    final envelope = envelopeParser.tryParse(error.response?.data);
    if (envelope != null) {
      return envelope.toClassification();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return RemoteErrorClassification.requestTimeout;
      case DioExceptionType.connectionError:
        return RemoteErrorClassification.networkUnavailable;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 401) return RemoteErrorClassification.sessionExpired;
        if (status == 403) return RemoteErrorClassification.forbidden;
        if (status == 404) return RemoteErrorClassification.notFound;
        if (status == 409) return RemoteErrorClassification.conflict;
        if (status == 429) return RemoteErrorClassification.rateLimited;
        if (status >= 500) {
          return RemoteErrorClassification.serverUnavailable;
        }
        return RemoteErrorClassification.unknown;
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return RemoteErrorClassification.unknown;
    }
  }

  ErrorEnvelope? envelopeOf(Object error) {
    if (error is! DioException) return null;
    return envelopeParser.tryParse(error.response?.data);
  }
}
