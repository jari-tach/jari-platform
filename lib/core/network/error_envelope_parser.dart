import 'remote_error_classification.dart';

/// Parsed Backend ErrorEnvelope (contracts-v0.1.0).
final class ErrorEnvelope {
  const ErrorEnvelope({
    required this.code,
    required this.message,
    required this.requestId,
    required this.retryable,
    required this.details,
  });

  final String code;
  final String message;
  final String requestId;
  final bool retryable;
  final Map<String, dynamic> details;

  factory ErrorEnvelope.fromJson(Map<String, dynamic> json) {
    final code = json['code'];
    final message = json['message'];
    final requestId = json['requestId'];
    final retryable = json['retryable'];
    final details = json['details'];

    if (code is! String || code.isEmpty) {
      throw const FormatException('ErrorEnvelope: missing code');
    }
    if (message is! String || message.isEmpty) {
      throw const FormatException('ErrorEnvelope: missing message');
    }
    if (requestId is! String || requestId.isEmpty) {
      throw const FormatException('ErrorEnvelope: missing requestId');
    }
    if (retryable is! bool) {
      throw const FormatException('ErrorEnvelope: missing retryable');
    }

    return ErrorEnvelope(
      code: code,
      message: message,
      requestId: requestId,
      retryable: retryable,
      details: details is Map<String, dynamic> ? details : <String, dynamic>{},
    );
  }

  RemoteErrorClassification toClassification() {
    switch (code) {
      case 'UNAUTHORIZED':
      case 'TOKEN_EXPIRED':
      case 'TOKEN_REVOKED':
        return RemoteErrorClassification.sessionExpired;
      case 'FORBIDDEN':
      case 'CUSTOMER_CONTACT_NOT_AVAILABLE':
        return RemoteErrorClassification.forbidden;
      case 'VALIDATION_ERROR':
      case 'OTP_INVALID':
        return RemoteErrorClassification.validation;
      case 'RESOURCE_NOT_FOUND':
        return RemoteErrorClassification.notFound;
      case 'OTP_RATE_LIMITED':
      case 'RATE_LIMITED':
        return RemoteErrorClassification.rateLimited;
      case 'OFFER_EXPIRED':
      case 'OFFER_ALREADY_ACCEPTED':
      case 'ACTIVE_ASSIGNMENT_CONFLICT':
      case 'INVALID_DELIVERY_TRANSITION':
      case 'AGGREGATE_VERSION_CONFLICT':
      case 'IDEMPOTENCY_CONFLICT':
        return RemoteErrorClassification.conflict;
      case 'INTERNAL_ERROR':
        return RemoteErrorClassification.serverUnavailable;
      default:
        return RemoteErrorClassification.contractViolation;
    }
  }
}

/// Parses ErrorEnvelope JSON; throws [FormatException] on contract violation.
final class ErrorEnvelopeParser {
  const ErrorEnvelopeParser();

  ErrorEnvelope parse(Object? raw) {
    if (raw is! Map) {
      throw const FormatException('ErrorEnvelope: body is not an object');
    }
    return ErrorEnvelope.fromJson(Map<String, dynamic>.from(raw));
  }

  ErrorEnvelope? tryParse(Object? raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }
}
