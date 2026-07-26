import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  group('DeliveryOffer', () {
    test('equality and hashCode', () {
      final a = sampleOffer();
      final b = sampleOffer();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith cannot change sovereign ids', () {
      final offer = sampleOffer();
      final next = offer.copyWith(
        status: DeliveryOfferStatus.accepting,
        clearRevision: true,
        clearCorrelationId: true,
      );
      expect(next.offerId, offer.offerId);
      expect(next.driverId, offer.driverId);
      expect(next.status, DeliveryOfferStatus.accepting);
      expect(next.revision, isNull);
      expect(next.correlationId, isNull);
      expect(offer, isNot(equals(next)));
    });

    test('isExpiredAt uses exclusive before semantics', () {
      final offer = sampleOffer(expiresAt: deliveryExpiresAt);
      expect(offer.isExpiredAt(deliveryExpiresAt), isTrue);
      expect(
        offer.isExpiredAt(
          deliveryExpiresAt.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('rejects empty identity and inverted expiry window', () {
      expect(() => sampleOffer(offerId: ''), throwsA(isA<ArgumentError>()));
      expect(() => sampleOffer(driverId: ' '), throwsA(isA<ArgumentError>()));
      expect(
        () => sampleOffer(
          issuedAt: deliveryExpiresAt,
          expiresAt: deliveryIssuedAt,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => sampleOffer(revision: '  '), throwsA(isA<ArgumentError>()));
    });
  });
}
