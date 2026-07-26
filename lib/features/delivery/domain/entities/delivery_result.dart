import '../failures/delivery_failure.dart';

/// Narrow delivery-domain result (mirrors availability result pattern).
sealed class DeliveryResult<T> {
  const DeliveryResult();

  bool get isSuccess => this is DeliverySuccess<T>;
  bool get isFailure => this is DeliveryFailureResult<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(DeliveryFailure error) onFailure,
  }) {
    final self = this;
    return switch (self) {
      DeliverySuccess<T>(:final value) => success(value),
      DeliveryFailureResult<T>(:final failure) => onFailure(failure),
    };
  }

  T? get valueOrNull => switch (this) {
    DeliverySuccess<T>(:final value) => value,
    DeliveryFailureResult<T>() => null,
  };

  DeliveryFailure? get failureOrNull => switch (this) {
    DeliverySuccess<T>() => null,
    DeliveryFailureResult<T>(:final failure) => failure,
  };
}

/// Successful delivery-domain outcome.
final class DeliverySuccess<T> extends DeliveryResult<T> {
  const DeliverySuccess(this.value);

  /// Success with no payload (`Future<DeliveryResult<void>>`).
  static DeliveryResult<void> unit() => const DeliverySuccess<void>(null);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliverySuccess<T> && value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// Failed delivery-domain outcome with a typed [DeliveryFailure].
final class DeliveryFailureResult<T> extends DeliveryResult<T> {
  const DeliveryFailureResult(this.failure);

  final DeliveryFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryFailureResult<T> && failure == other.failure;

  @override
  int get hashCode => Object.hash(runtimeType, failure);
}
