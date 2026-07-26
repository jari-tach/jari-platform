import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

void main() {
  group('DeliveryResult', () {
    test('success exposes value helpers', () {
      const result = DeliverySuccess<int>(7);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
      expect(result.when(success: (v) => v * 2, onFailure: (_) => -1), 14);
    });

    test('failure exposes typed failure helpers', () {
      const failure = DeliveryOfferNotFound();
      const result = DeliveryFailureResult<int>(failure);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
      expect(
        result.when(success: (_) => 'ok', onFailure: (f) => f.code),
        'delivery.offer_not_found',
      );
    });

    test('unit success and equality', () {
      final a = DeliverySuccess.unit();
      final b = DeliverySuccess.unit();
      expect(a, equals(b));
      expect(
        const DeliveryFailureResult<void>(DeliveryUnknownFailure()),
        equals(const DeliveryFailureResult<void>(DeliveryUnknownFailure())),
      );
    });
  });
}
