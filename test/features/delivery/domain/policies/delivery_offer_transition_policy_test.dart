import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/policies/delivery_offer_transition_decision.dart';
import 'package:saeq_driver/features/delivery/domain/policies/delivery_offer_transition_policy.dart';

void main() {
  const policy = DeliveryOfferTransitionPolicy();

  DeliveryOfferTransitionDecision decide(
    DeliveryOfferStatus current,
    DeliveryOfferStatus requested,
  ) => policy.evaluate(
    DeliveryOfferTransitionContext(current: current, requested: requested),
  );

  group('DeliveryOfferTransitionDecision', () {
    test('allow and deny factories set expected fields', () {
      final allow = DeliveryOfferTransitionDecision.allow(
        policyVersion: 'v1',
        idempotent: true,
      );
      expect(allow.allowed, isTrue);
      expect(allow.idempotent, isTrue);
      expect(allow.failure, isNull);

      final deny = DeliveryOfferTransitionDecision.deny(
        failure: const InvalidDeliveryOfferTransition(),
        policyVersion: 'v1',
      );
      expect(deny.allowed, isFalse);
      expect(deny.failure, isA<InvalidDeliveryOfferTransition>());
      expect(deny.idempotent, isFalse);
    });
  });

  group('DeliveryOfferTransitionPolicy', () {
    test('identical transition is idempotent allow', () {
      final d = decide(
        DeliveryOfferStatus.offered,
        DeliveryOfferStatus.offered,
      );
      expect(d.allowed, isTrue);
      expect(d.idempotent, isTrue);
      expect(d.policyVersion, DeliveryOfferTransitionPolicy.policyVersion);
    });

    test('allow-listed transitions succeed', () {
      final allowed = <(DeliveryOfferStatus, DeliveryOfferStatus)>[
        (DeliveryOfferStatus.none, DeliveryOfferStatus.offered),
        (DeliveryOfferStatus.offered, DeliveryOfferStatus.accepting),
        (DeliveryOfferStatus.offered, DeliveryOfferStatus.rejecting),
        (DeliveryOfferStatus.offered, DeliveryOfferStatus.expired),
        (DeliveryOfferStatus.offered, DeliveryOfferStatus.takenByOther),
        (DeliveryOfferStatus.offered, DeliveryOfferStatus.cancelled),
        (DeliveryOfferStatus.accepting, DeliveryOfferStatus.accepted),
        (DeliveryOfferStatus.accepting, DeliveryOfferStatus.offered),
        (DeliveryOfferStatus.accepting, DeliveryOfferStatus.takenByOther),
        (DeliveryOfferStatus.accepting, DeliveryOfferStatus.expired),
        (DeliveryOfferStatus.accepting, DeliveryOfferStatus.failed),
        (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.rejected),
        (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.offered),
        (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.expired),
        (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.failed),
        (DeliveryOfferStatus.accepted, DeliveryOfferStatus.none),
        (DeliveryOfferStatus.rejected, DeliveryOfferStatus.none),
        (DeliveryOfferStatus.expired, DeliveryOfferStatus.none),
        (DeliveryOfferStatus.takenByOther, DeliveryOfferStatus.none),
        (DeliveryOfferStatus.cancelled, DeliveryOfferStatus.none),
        (DeliveryOfferStatus.failed, DeliveryOfferStatus.none),
        (DeliveryOfferStatus.failed, DeliveryOfferStatus.offered),
      ];

      for (final pair in allowed) {
        final d = decide(pair.$1, pair.$2);
        expect(d.allowed, isTrue, reason: '${pair.$1.name} → ${pair.$2.name}');
        expect(d.idempotent, isFalse);
      }
    });

    test('undocumented transitions are default-denied', () {
      final denied = <(DeliveryOfferStatus, DeliveryOfferStatus)>[
        (DeliveryOfferStatus.none, DeliveryOfferStatus.accepted),
        (DeliveryOfferStatus.offered, DeliveryOfferStatus.accepted),
        (DeliveryOfferStatus.offered, DeliveryOfferStatus.none),
        (DeliveryOfferStatus.accepted, DeliveryOfferStatus.offered),
        (DeliveryOfferStatus.rejected, DeliveryOfferStatus.offered),
        (DeliveryOfferStatus.expired, DeliveryOfferStatus.accepting),
        (DeliveryOfferStatus.takenByOther, DeliveryOfferStatus.rejecting),
        (DeliveryOfferStatus.cancelled, DeliveryOfferStatus.accepting),
        (DeliveryOfferStatus.accepting, DeliveryOfferStatus.rejecting),
        (DeliveryOfferStatus.rejecting, DeliveryOfferStatus.accepting),
        (DeliveryOfferStatus.none, DeliveryOfferStatus.failed),
      ];

      for (final pair in denied) {
        final d = decide(pair.$1, pair.$2);
        expect(d.allowed, isFalse, reason: '${pair.$1.name} → ${pair.$2.name}');
        expect(d.failure, isA<InvalidDeliveryOfferTransition>());
      }
    });
  });
}
