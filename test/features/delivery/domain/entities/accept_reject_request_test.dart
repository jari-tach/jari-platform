import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/accept_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/entities/reject_delivery_offer_request.dart';

void main() {
  group('AcceptDeliveryOfferRequest', () {
    test('equality and immutability of fields', () {
      final a = AcceptDeliveryOfferRequest(
        driverId: 'drv-1',
        offerId: 'off-1',
        idempotencyKey: 'idem-1',
        connectivityOnline: true,
        isConfirmedAvailable: true,
        revision: 'rev-1',
        correlationId: 'corr-1',
      );
      final b = AcceptDeliveryOfferRequest(
        driverId: 'drv-1',
        offerId: 'off-1',
        idempotencyKey: 'idem-1',
        connectivityOnline: true,
        isConfirmedAvailable: true,
        revision: 'rev-1',
        correlationId: 'corr-1',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.hasActiveAssignment, isFalse);
    });

    test('rejects empty required fields', () {
      expect(
        () => AcceptDeliveryOfferRequest(
          driverId: ' ',
          offerId: 'off-1',
          idempotencyKey: 'idem-1',
          connectivityOnline: true,
          isConfirmedAvailable: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AcceptDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: '',
          idempotencyKey: 'idem-1',
          connectivityOnline: true,
          isConfirmedAvailable: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AcceptDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: 'off-1',
          idempotencyKey: ' ',
          connectivityOnline: true,
          isConfirmedAvailable: true,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('RejectDeliveryOfferRequest', () {
    test('equality and defaults', () {
      final a = RejectDeliveryOfferRequest(
        driverId: 'drv-1',
        offerId: 'off-1',
        reasonCode: 'too_far',
      );
      final b = RejectDeliveryOfferRequest(
        driverId: 'drv-1',
        offerId: 'off-1',
        reasonCode: 'too_far',
      );
      expect(a, equals(b));
      expect(a.connectivityOnline, isTrue);
    });

    test('rejects empty identity and blank optional strings', () {
      expect(
        () => RejectDeliveryOfferRequest(driverId: '', offerId: 'off-1'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RejectDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: 'off-1',
          idempotencyKey: ' ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
