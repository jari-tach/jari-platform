import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';

void main() {
  group('DeliveryStatus', () {
    test('exposes PHASE 2.5 and reserved 2.6 values', () {
      expect(
        DeliveryStatus.values,
        containsAll(<DeliveryStatus>[
          DeliveryStatus.accepted,
          DeliveryStatus.pickedUp,
          DeliveryStatus.delivered,
          DeliveryStatus.cancelled,
        ]),
      );
      expect(DeliveryStatus.accepted.name, 'accepted');
    });
  });
}
