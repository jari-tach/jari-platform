import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';

import '../../helpers/delivery_fixtures.dart';
import '../../helpers/fake_delivery_offer_repository.dart';

void main() {
  group('GetDeliveryOffers', () {
    test('returns repository offers enforced to one active', () async {
      final repo = FakeDeliveryOfferRepository(
        offers: [
          sampleOffer(offerId: 'off-1'),
          sampleOffer(offerId: 'off-2', status: DeliveryOfferStatus.accepting),
        ],
      );
      final result = await GetDeliveryOffers(repo)(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull!.single.offerId, 'off-1');
      expect(repo.getCallCount, 1);
      repo.dispose();
    });

    test('empty driverId returns unauthenticated', () async {
      final repo = FakeDeliveryOfferRepository();
      final result = await GetDeliveryOffers(repo)(driverId: '  ');
      expect(result.failureOrNull, isA<DeliveryUnauthenticated>());
      expect(repo.getCallCount, 0);
      repo.dispose();
    });

    test('driverId mismatch returns security denial', () async {
      final custom = _MismatchOfferRepository();
      final result = await GetDeliveryOffers(custom)(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliverySecurityPolicyDenied>());
      custom.dispose();
    });

    test('repository failure is passthrough', () async {
      final repo = FakeDeliveryOfferRepository()
        ..nextGetFailure = const DeliveryOfferExpired();
      final result = await GetDeliveryOffers(repo)(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryOfferExpired>());
      repo.dispose();
    });
  });
}

class _MismatchOfferRepository extends FakeDeliveryOfferRepository {
  @override
  Future<DeliveryResult<List<DeliveryOffer>>> getDeliveryOffers({
    required String driverId,
  }) async {
    getCallCount++;
    return DeliverySuccess([sampleOffer(driverId: 'other')]);
  }
}
