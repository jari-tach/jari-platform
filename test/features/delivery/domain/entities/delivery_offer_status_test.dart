import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';

void main() {
  group('DeliveryOfferStatus', () {
    test('isActive covers offered/accepting/rejecting only', () {
      expect(DeliveryOfferStatus.offered.isActive, isTrue);
      expect(DeliveryOfferStatus.accepting.isActive, isTrue);
      expect(DeliveryOfferStatus.rejecting.isActive, isTrue);
      expect(DeliveryOfferStatus.none.isActive, isFalse);
      expect(DeliveryOfferStatus.accepted.isActive, isFalse);
      expect(DeliveryOfferStatus.failed.isActive, isFalse);
    });

    test('isTerminal covers terminal outcomes only', () {
      expect(DeliveryOfferStatus.accepted.isTerminal, isTrue);
      expect(DeliveryOfferStatus.rejected.isTerminal, isTrue);
      expect(DeliveryOfferStatus.expired.isTerminal, isTrue);
      expect(DeliveryOfferStatus.takenByOther.isTerminal, isTrue);
      expect(DeliveryOfferStatus.cancelled.isTerminal, isTrue);
      expect(DeliveryOfferStatus.failed.isTerminal, isFalse);
      expect(DeliveryOfferStatus.offered.isTerminal, isFalse);
      expect(DeliveryOfferStatus.none.isTerminal, isFalse);
    });
  });
}
