/// STEP 5D-2 contract wire tests — Offers resource group (4/23).
///
/// GET /v1/offers, GET /v1/offers/{offerId},
/// POST /v1/offers/{offerId}/accept, POST /v1/offers/{offerId}/reject.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/features/delivery/data/models/offer_summary_wire.dart';
import 'package:saeq_driver/features/delivery/data/remote/http_delivery_remote_data_source.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import 'contract_wire_harness.dart';

void main() {
  group('GET /v1/offers', () {
    test(
      'sends authenticated GET and parses paginated offer summaries',
      () async {
        final h = ContractWireHarness();
        h.enqueue(200, offersPageJson());

        final offers = await HttpDeliveryRemoteDataSource(
          api: h.api,
        ).fetchOffers(driverId: fixtureDriverId);

        final r = h.single;
        expect(r.method, 'GET');
        expect(r.path, DriverApiPaths.offers);
        expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
        expect(r.header('X-Request-Id'), isNotEmpty);
        expect(r.header('Idempotency-Key'), isNull);

        expect(offers, hasLength(1));
        final offer = offers.single;
        expect(offer.offerId, fixtureOfferId);
        expect(offer.status, 'offered');
        expect(offer.revision, '3');
        expect(offer.expiresAt.isUtc, isTrue);
        expect(offer.order.pickupLabel, 'Merchant A');
        expect(offer.order.dropoffLabel, 'District B');
      },
    );

    test(
      'malformed page (missing items) fails typed, not silent unknown',
      () async {
        final h = ContractWireHarness();
        h.enqueue(200, {'nextCursor': null});

        // The offers data source maps FormatException to a typed persistence
        // failure — never an untyped/unknown pass-through of malformed data.
        await expectLater(
          HttpDeliveryRemoteDataSource(
            api: h.api,
          ).fetchOffers(driverId: fixtureDriverId),
          throwsA(isA<DeliveryPersistenceFailure>()),
        );
      },
    );

    test('offer item missing required aggregateVersion fails parsing', () {
      final malformed = offerSummaryJson()..remove('aggregateVersion');
      expect(() => OfferSummaryWire.fromJson(malformed), throwsFormatException);
    });

    test('401 UNAUTHORIZED envelope maps to DeliveryUnauthenticated', () async {
      final h = ContractWireHarness();
      h.enqueue(401, errorEnvelopeJson('UNAUTHORIZED'));

      await expectLater(
        HttpDeliveryRemoteDataSource(
          api: h.api,
        ).fetchOffers(driverId: fixtureDriverId),
        throwsA(isA<DeliveryUnauthenticated>()),
      );
    });
  });

  group('GET /v1/offers/{offerId}', () {
    // NOTE: application wiring currently reads offers primarily through the
    // GET /v1/offers list endpoint; no remote data source calls the by-id
    // path yet. This harness-level test still exercises the endpoint through
    // the live SaeqApiClient so the contract (path, headers, response shape)
    // stays covered.
    test('harness-level GET parses a contract-shaped OfferSummary', () async {
      final h = ContractWireHarness();
      h.enqueue(200, offerSummaryJson(status: 'offered'));

      final response = await h.api.get<Map<String, dynamic>>(
        DriverApiPaths.offerById(fixtureOfferId),
      );

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, '/v1/offers/$fixtureOfferId');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);

      expect(response.statusCode, 200);
      final wire = OfferSummaryWire.fromJson(response.data!);
      expect(wire.offerId, fixtureOfferId);
      expect(wire.aggregateVersion, 3);
      expect(wire.compensationCurrency, 'SAR');
    });

    test('unknown-shaped offer body fails parsing (missing pickup)', () async {
      final h = ContractWireHarness();
      final malformed = offerSummaryJson()..remove('pickup');
      h.enqueue(200, malformed);

      final response = await h.api.get<Map<String, dynamic>>(
        DriverApiPaths.offerById(fixtureOfferId),
      );
      expect(
        () => OfferSummaryWire.fromJson(response.data!),
        throwsFormatException,
      );
    });
  });

  group('POST /v1/offers/{offerId}/accept', () {
    test(
      'sends aggregateVersion body with Idempotency-Key and parses ack',
      () async {
        final h = ContractWireHarness();
        final ds = HttpDeliveryRemoteDataSource(api: h.api);
        h.enqueue(200, offersPageJson());
        await ds.fetchOffers(driverId: fixtureDriverId);

        h.enqueue(200, offerActionResponseJson());
        final assignment = await ds.acceptOffer(
          driverId: fixtureDriverId,
          offerId: fixtureOfferId,
          idempotencyKey: 'idem-accept-1',
          revision: '3',
        );

        final r = h.last;
        expect(r.method, 'POST');
        expect(r.path, '/v1/offers/$fixtureOfferId/accept');
        expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
        expect(r.header('X-Request-Id'), isNotEmpty);
        expect(r.header('Idempotency-Key'), 'idem-accept-1');
        expect(r.bodyAsMap, {'aggregateVersion': 3});

        expect(assignment.assignmentId, fixtureDeliveryId);
        expect(assignment.offerId, fixtureOfferId);
        expect(assignment.status, 'accepted');
        expect(assignment.serverRevision, '4');
      },
    );

    test('409 OFFER_ALREADY_ACCEPTED maps to DeliveryOfferTaken', () async {
      final h = ContractWireHarness();
      h.enqueue(409, errorEnvelopeJson('OFFER_ALREADY_ACCEPTED'));

      await expectLater(
        HttpDeliveryRemoteDataSource(api: h.api).acceptOffer(
          driverId: fixtureDriverId,
          offerId: fixtureOfferId,
          idempotencyKey: 'idem-accept-2',
          revision: '3',
        ),
        throwsA(isA<DeliveryOfferTaken>()),
      );
    });

    test('409 OFFER_EXPIRED maps to DeliveryOfferExpired', () async {
      final h = ContractWireHarness();
      h.enqueue(409, errorEnvelopeJson('OFFER_EXPIRED'));

      await expectLater(
        HttpDeliveryRemoteDataSource(api: h.api).acceptOffer(
          driverId: fixtureDriverId,
          offerId: fixtureOfferId,
          idempotencyKey: 'idem-accept-3',
          revision: '3',
        ),
        throwsA(isA<DeliveryOfferExpired>()),
      );
    });

    test('malformed accept ack fails typed (missing deliveryId)', () async {
      final h = ContractWireHarness();
      final malformed = offerActionResponseJson()..remove('deliveryId');
      h.enqueue(200, malformed);

      await expectLater(
        HttpDeliveryRemoteDataSource(api: h.api).acceptOffer(
          driverId: fixtureDriverId,
          offerId: fixtureOfferId,
          idempotencyKey: 'idem-accept-4',
          revision: '3',
        ),
        throwsA(isA<DeliveryPersistenceFailure>()),
      );
    });
  });

  group('POST /v1/offers/{offerId}/reject', () {
    test('sends reason + version with Idempotency-Key', () async {
      final h = ContractWireHarness();
      final ds = HttpDeliveryRemoteDataSource(api: h.api);
      h.enqueue(200, offersPageJson());
      await ds.fetchOffers(driverId: fixtureDriverId);

      h.enqueue(200, offerActionResponseJson(state: 'rejected'));
      await ds.rejectOffer(
        driverId: fixtureDriverId,
        offerId: fixtureOfferId,
        idempotencyKey: 'idem-reject-1',
        reasonCode: 'too_far',
      );

      final r = h.last;
      expect(r.method, 'POST');
      expect(r.path, '/v1/offers/$fixtureOfferId/reject');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), 'idem-reject-1');
      expect(r.bodyAsMap, {'aggregateVersion': 3, 'reasonCode': 'too_far'});
    });

    test(
      '429 RATE_LIMITED envelope maps to typed failure (not silent)',
      () async {
        final h = ContractWireHarness();
        h.enqueue(429, errorEnvelopeJson('RATE_LIMITED', retryable: true));

        await expectLater(
          HttpDeliveryRemoteDataSource(api: h.api).rejectOffer(
            driverId: fixtureDriverId,
            offerId: fixtureOfferId,
            idempotencyKey: 'idem-reject-2',
          ),
          throwsA(isA<DeliveryFailure>()),
        );
      },
    );
  });

  tearDownAll(() {
    expect(
      ContractWireHarness.coverage.containsAll(catalogSlice('offers')),
      isTrue,
      reason:
          'offers wire tests must exercise all 4 offer endpoints; '
          'covered: ${ContractWireHarness.coverage}',
    );
  });
}
