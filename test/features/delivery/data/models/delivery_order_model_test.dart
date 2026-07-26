import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_order_model.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  group('DeliveryOrderModel', () {
    test('entity ↔ model round-trip', () {
      final entity = sampleOrder();
      final model = DeliveryOrderModel.fromEntity(entity);
      expect(model.toEntity(), entity);
    });

    test('JSON round-trip', () {
      final model = DeliveryOrderModel.fromEntity(sampleOrder());
      final decoded = DeliveryOrderModel.fromJson(model.toJson());
      expect(decoded, model);
    });

    test('invalid required fields throw FormatException', () {
      expect(
        () => DeliveryOrderModel.fromJson({'orderId': '', 'pickupLabel': 'a'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DeliveryOrderModel.fromJson({
          'orderId': 'ord-1',
          'pickupLabel': 1,
          'dropoffLabel': 'b',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DeliveryOrderModel.fromJson({
          'orderId': 'ord-1',
          'pickupLabel': 'a',
          'dropoffLabel': 'b',
          'distanceMeters': 'bad',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('equality', () {
      final a = DeliveryOrderModel.fromEntity(sampleOrder());
      final b = DeliveryOrderModel.fromEntity(sampleOrder());
      expect(a, equals(b));
    });
  });
}
