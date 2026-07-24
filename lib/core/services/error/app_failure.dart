/// Base class for domain-layer failures.
/// Failures represent error states that the UI/presentation layer can handle.
sealed class AppFailure {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => '[$runtimeType] $message${code != null ? ' (code: $code)' : ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);
}

/// Network connectivity failure
final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code});
}

/// Server-side failure (5xx, bad gateway)
final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.code, this.statusCode});

  final int? statusCode;
}

/// Authentication failure (401 Unauthorized)
final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure([String message = 'Unauthenticated'])
      : super(message);
}

/// Authorization failure (403 Forbidden)
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([String message = 'Forbidden'])
      : super(message);
}

/// Input/business validation failure
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.code, this.errors});

  final Map<String, String>? errors;
}

/// Resource not found failure (404)
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message, {super.code});
}

/// Cache/storage failure
final class CacheFailure extends AppFailure {
  const CacheFailure(super.message, {super.code});
}

/// Timeout failure
final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([String message = 'Request timed out'])
      : super(message);
}

/// Unknown/unexpected failure
final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.code, this.originalError});

  final Object? originalError;
}