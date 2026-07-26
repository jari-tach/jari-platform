import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

void main() {
  group('DeliveryFailure', () {
    test('each failure exposes stable unique machine-readable code', () {
      final samples = <DeliveryFailure>[
        const DeliveryUnauthenticated(),
        const DeliveryOfflineAcceptDenied(),
        const DeliveryNotAvailable(),
        const DeliveryOfferNotFound(),
        const DeliveryOfferExpired(),
        const DeliveryOfferTaken(),
        const DeliveryConflict(),
        const InvalidDeliveryOfferTransition(),
        const DeliveryActiveOfferConflict(),
        const DeliveryActiveAssignmentExists(),
        const DeliveryPersistenceFailure(),
        const DeliverySecurityPolicyDenied(),
        const DeliveryAvailabilityBindFailure(),
        const DeliveryUnknownFailure(),
      ];

      final codes = samples.map((f) => f.code).toSet();
      expect(codes.length, samples.length);
      for (final failure in samples) {
        expect(failure.code, startsWith('delivery.'));
        expect(failure.toString(), contains(failure.code));
      }
    });

    test('equality uses runtime type, code, and message', () {
      expect(
        const DeliveryUnknownFailure('a'),
        isNot(equals(const DeliveryUnknownFailure('b'))),
      );
      expect(
        const DeliveryUnknownFailure(),
        equals(const DeliveryUnknownFailure()),
      );
    });
  });
}
