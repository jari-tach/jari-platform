import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/policies/one_active_offer_policy.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  const policy = OneActiveOfferPolicy();

  group('OneActiveOfferPolicy', () {
    test('allows first active offer when none current', () {
      expect(
        policy.allowsIncoming(current: null, candidate: sampleOffer()),
        isTrue,
      );
    });

    test('allows same offerId refresh while active', () {
      final current = sampleOffer(status: DeliveryOfferStatus.accepting);
      expect(
        policy.allowsIncoming(
          current: current,
          candidate: sampleOffer(status: DeliveryOfferStatus.offered),
        ),
        isTrue,
      );
    });

    test('denies distinct active offer while one is active', () {
      final current = sampleOffer(offerId: 'off-1');
      expect(
        policy.allowsIncoming(
          current: current,
          candidate: sampleOffer(offerId: 'off-2'),
        ),
        isFalse,
      );
    });

    test('terminal candidates are allowed for non-active incoming checks', () {
      expect(
        policy.allowsIncoming(
          current: sampleOffer(),
          candidate: sampleOffer(
            offerId: 'off-2',
            status: DeliveryOfferStatus.expired,
          ),
        ),
        isTrue,
      );
    });

    test('enforce keeps at most one active offer (first wins)', () {
      final filtered = policy.enforce([
        sampleOffer(offerId: 'off-1', status: DeliveryOfferStatus.offered),
        sampleOffer(offerId: 'off-2', status: DeliveryOfferStatus.accepting),
        sampleOffer(offerId: 'off-3', status: DeliveryOfferStatus.rejected),
      ]);
      expect(filtered, hasLength(1));
      expect(filtered.single.offerId, 'off-1');
    });

    test('enforce refreshes same offerId later occurrence', () {
      final first = sampleOffer(
        offerId: 'off-1',
        status: DeliveryOfferStatus.offered,
        revision: 'rev-1',
      );
      final refreshed = sampleOffer(
        offerId: 'off-1',
        status: DeliveryOfferStatus.accepting,
        revision: 'rev-2',
      );
      final filtered = policy.enforce([first, refreshed]);
      expect(filtered, hasLength(1));
      expect(filtered.single.status, DeliveryOfferStatus.accepting);
      expect(filtered.single.revision, 'rev-2');
    });

    test('policyVersion is stable', () {
      expect(OneActiveOfferPolicy.policyVersion, isNotEmpty);
    });
  });
}
