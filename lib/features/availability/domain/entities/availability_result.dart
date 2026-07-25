import '../failures/availability_failure.dart';

/// Narrow availability-domain result (no project-wide Result type exists).
///
/// Success carries a value (or [void] via [AvailabilitySuccess.unit]).
/// Expected business and infra denials use typed [AvailabilityFailure].
sealed class AvailabilityResult<T> {
  const AvailabilityResult();

  bool get isSuccess => this is AvailabilitySuccess<T>;
  bool get isFailure => this is AvailabilityFailureResult<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AvailabilityFailure error) onFailure,
  }) {
    final self = this;
    return switch (self) {
      AvailabilitySuccess<T>(:final value) => success(value),
      AvailabilityFailureResult<T>(:final failure) => onFailure(failure),
    };
  }

  T? get valueOrNull => switch (this) {
    AvailabilitySuccess<T>(:final value) => value,
    AvailabilityFailureResult<T>() => null,
  };

  AvailabilityFailure? get failureOrNull => switch (this) {
    AvailabilitySuccess<T>() => null,
    AvailabilityFailureResult<T>(:final failure) => failure,
  };
}

final class AvailabilitySuccess<T> extends AvailabilityResult<T> {
  const AvailabilitySuccess(this.value);

  /// Success with no payload (`Future<AvailabilityResult<void>>`).
  static AvailabilityResult<void> unit() => AvailabilitySuccess<void>(null);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilitySuccess<T> && value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class AvailabilityFailureResult<T> extends AvailabilityResult<T> {
  const AvailabilityFailureResult(this.failure);

  final AvailabilityFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityFailureResult<T> && failure == other.failure;

  @override
  int get hashCode => Object.hash(runtimeType, failure);
}
