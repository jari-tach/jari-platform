import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_offer_model.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  group('DeliveryOfferModel', () {
    test('entity ↔ model round-trip for all offer statuses', () {
      for (final status in DeliveryOfferStatus.values) {
        final entity = sampleOffer(status: status);
        final round = DeliveryOfferModel.fromEntity(entity).toEntity();
        expect(round, entity, reason: status.name);
      }
    });

    test('JSON round-trip', () {
      final model = DeliveryOfferModel.fromEntity(sampleOffer());
      final decoded = DeliveryOfferModel.fromJson(model.toJson());
      expect(decoded, model);
      expect(decoded.toEntity(), sampleOffer());
    });

    test('invalid JSON enum value fails on toEntity', () {
      final json = DeliveryOfferModel.fromEntity(sampleOffer()).toJson()
        ..['status'] = 'teleporting';
      final model = DeliveryOfferModel.fromJson(json);
      expect(() => model.toEntity(), throwsA(isA<FormatException>()));
    });

    test('malformed timestamps and missing fields throw FormatException', () {
      expect(
        () => DeliveryOfferModel.fromJson({
          'offerId': 'off-1',
          'driverId': 'drv-1',
          'status': 'offered',
          'order': DeliveryOrderModelJson.sample,
          'issuedAt': 'not-a-date',
          'expiresAt': deliveryExpiresAt.toIso8601String(),
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DeliveryOfferModel.fromJson({
          'offerId': '',
          'driverId': 'drv-1',
          'status': 'offered',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

/// Tiny nested order JSON helper for invalid-offer cases.
class DeliveryOrderModelJson {
  static Map<String, dynamic> get sample => {
    'orderId': 'ord-1',
    'pickupLabel': 'Pickup A',
    'dropoffLabel': 'Dropoff B',
  };
}
