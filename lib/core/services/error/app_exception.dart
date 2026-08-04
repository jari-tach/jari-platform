/// Base exception class for all application-specific exceptions.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      '[$runtimeType] $message${code != null ? ' (code: $code)' : ''}';
}

/// Network-related exceptions (timeout, no internet, etc.)
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.stackTrace});
}

/// Server-side exceptions (5xx, bad gateway, etc.)
final class ServerException extends AppException {
  const ServerException(
    super.message, {
    super.code,
    super.stackTrace,
    this.statusCode,
  });

  final int? statusCode;
}

/// Authentication/authorization exceptions (401, 403, etc.)
final class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.stackTrace});
}

/// Validation exceptions (invalid input, business rule violations)
final class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.stackTrace,
    this.errors,
  });

  final Map<String, String>? errors;
}

/// Cache/storage exceptions
final class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.stackTrace});
}

/// Serialization/parsing exceptions
final class SerializationException extends AppException {
  const SerializationException(
    super.message, {
    super.code,
    super.stackTrace,
    this.rawData,
  });

  final String? rawData;
}

/// Unknown/unexpected exceptions
final class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.code,
    super.stackTrace,
    this.originalError,
  });

  final Object? originalError;
}
