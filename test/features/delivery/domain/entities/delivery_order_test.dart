import 'package:flutter_test/flutter_test.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  group('DeliveryOrder', () {
    test('equality holds for identical field values', () {
      final a = sampleOrder();
      final b = sampleOrder();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith preserves sovereign orderId and clears optionals', () {
      final original = sampleOrder();
      final changed = original.copyWith(
        pickupLabel: 'New Pickup',
        clearMerchantDisplayName: true,
        clearDistanceMeters: true,
        clearEtaMinutes: true,
        clearNotes: true,
      );
      expect(changed.orderId, original.orderId);
      expect(changed.pickupLabel, 'New Pickup');
      expect(changed.merchantDisplayName, isNull);
      expect(changed.distanceMeters, isNull);
      expect(changed.etaMinutes, isNull);
      expect(changed.notes, isNull);
      expect(original, isNot(equals(changed)));
    });

    test('rejects empty orderId', () {
      expect(() => sampleOrder(orderId: '  '), throwsA(isA<ArgumentError>()));
    });

    test('rejects negative distance and eta', () {
      expect(
        () => sampleOrder(distanceMeters: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => sampleOrder(etaMinutes: -1), throwsA(isA<ArgumentError>()));
    });
  });
}
