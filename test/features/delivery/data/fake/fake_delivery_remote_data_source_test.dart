import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/fake/fake_delivery_remote_data_source.dart';
import 'package:saeq_driver/features/delivery/data/fake/fake_delivery_seed.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_offer_model.dart';
import 'package:saeq_driver/features/delivery/data/repositories/remote_delivery_offer_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/accept_delivery_offer_request.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_offer_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

void main() {
  late DateTime now;

  FakeDeliveryRemoteDataSource buildFake({
    FakeDeliverySeed seed = const FakeDeliverySeed(),
    Duration latency = Duration.zero,
    bool Function()? isProductionEnvironment,
  }) {
    return FakeDeliveryRemoteDataSource(
      seed: seed,
      networkLatency: latency,
      clock: () => now,
      isProductionEnvironment: isProductionEnvironment ?? () => false,
    );
  }

  setUp(() {
    now = DateTime.utc(2026, 7, 26, 12);
  });

  group('FakeDeliverySeed', () {
    test('same inputs produce identical offer identities', () {
      const seed = FakeDeliverySeed();
      final a = seed.buildOffer(driverId: 'drv-1', sequence: 1, now: now);
      final b = seed.buildOffer(driverId: 'drv-1', sequence: 1, now: now);
      expect(a.offerId, b.offerId);
      expect(a.order.orderId, b.order.orderId);
      expect(a.revision, b.revision);
      expect(a.expiresAt, now.add(seed.offerTtl));
    });

    test('assignment ids are deterministic for the same offer', () {
      const seed = FakeDeliverySeed();
      final offer = seed.buildOffer(driverId: 'drv-1', sequence: 1, now: now);
      final a = seed.buildAssignment(offer: offer, acceptedAt: now);
      final b = seed.buildAssignment(offer: offer, acceptedAt: now);
      expect(a.assignmentId, b.assignmentId);
      expect(a.assignmentId, startsWith('asg-'));
      expect(a.status, DeliveryStatus.accepted.name);
    });
  });

  group('FakeDeliveryRemotePolicy', () {
    test('allows non-release non-production', () {
      final d = FakeDeliveryRemotePolicy.evaluate(
        isReleaseMode: false,
        isProductionEnvironment: false,
      );
      expect(d.allowed, isTrue);
    });

    test('denies production', () {
      final d = FakeDeliveryRemotePolicy.evaluate(
        isReleaseMode: false,
        isProductionEnvironment: true,
      );
      expect(d.allowed, isFalse);
      expect(
        d.reasonCodes,
        contains(FakeDeliveryRemoteReasonCode.productionEnvironmentDenied),
      );
    });
  });

  group('FakeDeliveryRemoteDataSource', () {
    test('construction denied in production environment', () {
      expect(
        () => FakeDeliveryRemoteDataSource(
          networkLatency: Duration.zero,
          isProductionEnvironment: () => true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('fetchOffers auto-issues exactly one active offer', () async {
      final fake = buildFake();
      final offers = await fake.fetchOffers(driverId: 'drv-1');
      expect(offers, hasLength(1));
      expect(offers.single.status, DeliveryOfferStatus.offered.name);
      expect(offers.single.driverId, 'drv-1');

      final again = await fake.fetchOffers(driverId: 'drv-1');
      expect(again.single.offerId, offers.single.offerId);
      fake.dispose();
    });

    test('offers are deterministic for a fixed seed and clock', () async {
      final a = buildFake();
      final b = buildFake();
      final oa = await a.fetchOffers(driverId: 'drv-1');
      final ob = await b.fetchOffers(driverId: 'drv-1');
      expect(oa.single.offerId, ob.single.offerId);
      expect(oa.single.order.orderId, ob.single.order.orderId);
      a.dispose();
      b.dispose();
    });

    test('accept returns server assignment and clears active offer', () async {
      final fake = buildFake();
      final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
      final assignment = await fake.acceptOffer(
        driverId: 'drv-1',
        offerId: offer.offerId,
        idempotencyKey: 'idem-1',
        revision: offer.revision,
      );

      expect(assignment.assignmentId, startsWith('asg-'));
      expect(assignment.offerId, offer.offerId);
      expect(assignment.driverId, 'drv-1');
      expect(assignment.status, DeliveryStatus.accepted.name);
      final next = await fake.fetchOffers(driverId: 'drv-1');
      expect(next, hasLength(1));
      expect(next.single.offerId, isNot(offer.offerId));
      fake.dispose();
    });

    test('accept is idempotent for the same key', () async {
      final fake = buildFake();
      final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
      final first = await fake.acceptOffer(
        driverId: 'drv-1',
        offerId: offer.offerId,
        idempotencyKey: 'idem-1',
      );
      final second = await fake.acceptOffer(
        driverId: 'drv-1',
        offerId: offer.offerId,
        idempotencyKey: 'idem-1',
      );
      expect(second, first);
      fake.dispose();
    });

    test('reject clears offer; auto-issue waits for cooldown', () async {
      final fake = buildFake();
      final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
      await fake.rejectOffer(driverId: 'drv-1', offerId: offer.offerId);
      final duringCooldown = await fake.fetchOffers(driverId: 'drv-1');
      expect(duringCooldown, isEmpty);
      now = now.add(
        FakeDeliveryRemoteDataSource.rejectReissueCooldown +
            const Duration(seconds: 1),
      );
      final next = await fake.fetchOffers(driverId: 'drv-1');
      expect(next, hasLength(1));
      expect(next.single.offerId, isNot(offer.offerId));
      fake.dispose();
    });

    test(
      'immediate fetch after reject stays empty for full cooldown window',
      () async {
        var now = DateTime.utc(2026, 7, 26, 12, 0, 0);
        final fake = FakeDeliveryRemoteDataSource(
          networkLatency: Duration.zero,
          clock: () => now,
          isProductionEnvironment: () => false,
        );
        final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
        await fake.rejectOffer(driverId: 'drv-1', offerId: offer.offerId);

        // Simulate rapid Refresh taps during cooldown (< 8s total).
        for (var i = 0; i < 5; i++) {
          now = now.add(const Duration(milliseconds: 500));
          final mid = await fake.fetchOffers(driverId: 'drv-1');
          expect(mid, isEmpty, reason: 'fetch #$i during cooldown');
        }

        // 2.5s + 5s = 7.5s from reject — still inside cooldown.
        now = now.add(const Duration(seconds: 5));
        expect(await fake.fetchOffers(driverId: 'drv-1'), isEmpty);

        now = now.add(const Duration(seconds: 1)); // 8.5s — past cooldown
        final next = await fake.fetchOffers(driverId: 'drv-1');
        expect(next, hasLength(1));
        fake.dispose();
      },
    );

    test('reject emits null on watch before cooldown re-issue', () async {
      final fake = buildFake();
      final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
      final events = <DeliveryOfferModel?>[];
      final sub = fake.watchActiveOffer(driverId: 'drv-1').listen(events.add);
      await fake.rejectOffer(driverId: 'drv-1', offerId: offer.offerId);
      await Future<void>.delayed(Duration.zero);
      expect(events, contains(null));
      await sub.cancel();
      fake.dispose();
    });

    test('accept unknown offer throws DeliveryOfferNotFound', () async {
      final fake = buildFake();
      await fake.fetchOffers(driverId: 'drv-1');
      expect(
        () => fake.acceptOffer(
          driverId: 'drv-1',
          offerId: 'missing',
          idempotencyKey: 'idem-1',
        ),
        throwsA(isA<DeliveryOfferNotFound>()),
      );
      fake.dispose();
    });

    test('revision mismatch throws DeliveryConflict', () async {
      final fake = buildFake();
      final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
      expect(
        () => fake.acceptOffer(
          driverId: 'drv-1',
          offerId: offer.offerId,
          idempotencyKey: 'idem-1',
          revision: 'wrong-rev',
        ),
        throwsA(isA<DeliveryConflict>()),
      );
      fake.dispose();
    });

    test('expired offer cannot be accepted', () async {
      final fake = buildFake(
        seed: const FakeDeliverySeed(offerTtl: Duration(minutes: 1)),
      );
      final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
      now = now.add(const Duration(minutes: 2));
      expect(
        () => fake.acceptOffer(
          driverId: 'drv-1',
          offerId: offer.offerId,
          idempotencyKey: 'idem-1',
        ),
        throwsA(isA<DeliveryOfferExpired>()),
      );
      fake.dispose();
    });

    test('empty driverId throws DeliveryUnauthenticated', () async {
      final fake = buildFake();
      expect(
        () => fake.fetchOffers(driverId: ' '),
        throwsA(isA<DeliveryUnauthenticated>()),
      );
      fake.dispose();
    });

    test('autoIssueOnFetch false returns empty until issued', () async {
      final fake = buildFake(
        seed: const FakeDeliverySeed(autoIssueOnFetch: false),
      );
      expect(await fake.fetchOffers(driverId: 'drv-1'), isEmpty);
      fake.dispose();
    });

    test('watchActiveOffer emits offer then null after accept', () async {
      final fake = buildFake();
      final events = <DeliveryOfferModel?>[];
      final sub = fake.watchActiveOffer(driverId: 'drv-1').listen(events.add);

      final offer = (await fake.fetchOffers(driverId: 'drv-1')).single;
      await fake.acceptOffer(
        driverId: 'drv-1',
        offerId: offer.offerId,
        idempotencyKey: 'idem-1',
      );
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<DeliveryOfferModel>(), isNotEmpty);
      expect(events.last, isNull);
      await sub.cancel();
      fake.dispose();
    });

    test('works through RemoteDeliveryOfferRepository mapping', () async {
      final fake = buildFake();
      final repo = RemoteDeliveryOfferRepository(remoteDataSource: fake);
      final result = await repo.getDeliveryOffers(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(1));

      final accept = await repo.acceptOffer(
        AcceptDeliveryOfferRequest(
          driverId: 'drv-1',
          offerId: result.valueOrNull!.single.offerId,
          idempotencyKey: 'idem-repo',
          connectivityOnline: true,
          isConfirmedAvailable: true,
          revision: result.valueOrNull!.single.revision,
        ),
      );
      expect(accept.isSuccess, isTrue);
      expect(accept.valueOrNull!.assignmentId, startsWith('asg-'));
      fake.dispose();
    });
  });
}
