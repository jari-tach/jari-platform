import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/reject_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';

import '../../helpers/delivery_fixtures.dart';
import '../../helpers/fake_delivery_offer_repository.dart';

void main() {
  RejectDeliveryOfferRequest request({
    String offerId = 'off-1',
    bool connectivityOnline = true,
  }) => RejectDeliveryOfferRequest(
    driverId: 'drv-1',
    offerId: offerId,
    reasonCode: 'busy',
    connectivityOnline: connectivityOnline,
  );

  group('RejectDeliveryOffer', () {
    test('success path delegates reject once', () async {
      final repo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final result = await RejectDeliveryOffer(repo)(request());
      expect(result.isSuccess, isTrue);
      expect(repo.rejectCallCount, 1);
      expect(repo.rejectRequests.single.offerId, 'off-1');
      repo.dispose();
    });

    test('missing offer fails without reject call', () async {
      final repo = FakeDeliveryOfferRepository();
      final result = await RejectDeliveryOffer(repo)(request());
      expect(result.failureOrNull, isA<DeliveryOfferNotFound>());
      expect(repo.rejectCallCount, 0);
      repo.dispose();
    });

    test('invalid transition fails without reject call', () async {
      final repo = FakeDeliveryOfferRepository(
        offers: [sampleOffer(status: DeliveryOfferStatus.accepted)],
      );
      final result = await RejectDeliveryOffer(repo)(request());
      expect(result.failureOrNull, isA<InvalidDeliveryOfferTransition>());
      expect(repo.rejectCallCount, 0);
      repo.dispose();
    });

    test('repository reject failure is returned', () async {
      final repo = FakeDeliveryOfferRepository(offers: [sampleOffer()])
        ..nextRejectFailure = const DeliveryConflict();
      final result = await RejectDeliveryOffer(repo)(request());
      expect(result.failureOrNull, isA<DeliveryConflict>());
      expect(repo.rejectCallCount, 1);
      repo.dispose();
    });

    test('get offers failure is returned', () async {
      final repo = FakeDeliveryOfferRepository()
        ..nextGetFailure = const DeliveryUnknownFailure();
      final result = await RejectDeliveryOffer(repo)(request());
      expect(result.failureOrNull, isA<DeliveryUnknownFailure>());
      expect(repo.rejectCallCount, 0);
      repo.dispose();
    });

    test('offline reject may still proceed (no assignment created)', () async {
      final repo = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      final result = await RejectDeliveryOffer(repo)(
        request(connectivityOnline: false),
      );
      expect(result.isSuccess, isTrue);
      expect(repo.rejectCallCount, 1);
      repo.dispose();
    });
  });
}
