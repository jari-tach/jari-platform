/// STEP 5D-2 contract wire tests — Deliveries resource group (7/23).
///
/// GET /v1/deliveries/active, GET /v1/deliveries/{deliveryId},
/// POST pickup-confirmation, POST arrival, POST delivery-confirmation,
/// POST cancel, POST issues.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_lifecycle_wire.dart';
import 'package:saeq_driver/features/delivery/data/remote/customer_contact_memory_cache.dart';
import 'package:saeq_driver/features/delivery/data/remote/http_delivery_lifecycle_remote.dart';
import 'package:saeq_driver/features/delivery/data/repositories/remote_delivery_lifecycle_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import 'contract_wire_harness.dart';

void main() {
  (
    ContractWireHarness,
    HttpDeliveryLifecycleRemote,
    RemoteDeliveryLifecycleRepository,
  )
  makeStack() {
    final h = ContractWireHarness();
    final remote = HttpDeliveryLifecycleRemote(
      api: h.api,
      contactCache: CustomerContactMemoryCache(),
    );
    final repo = RemoteDeliveryLifecycleRepository(remote: remote);
    return (h, remote, repo);
  }

  group('GET /v1/deliveries/active', () {
    test('200 full delivery normalizes to mutation-shaped ack', () async {
      final (h, remote, _) = makeStack();
      h.enqueue(200, deliveryResourceJson());

      final wire = await remote.getActiveDelivery();

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, DriverApiPaths.deliveriesActive);
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), isNull);

      expect(wire, isNotNull);
      expect(wire!.deliveryId, fixtureDeliveryId);
      expect(wire.state, 'pickupAwaitingManualConfirmation');
      expect(wire.aggregateVersion, 0);
      expect(wire.updatedAt.isUtc, isTrue);
    });

    test('204 no content means no active delivery', () async {
      final (h, remote, _) = makeStack();
      h.enqueue(204);

      final wire = await remote.getActiveDelivery();
      expect(wire, isNull);
      expect(h.single.method, 'GET');
    });

    test(
      'malformed active delivery maps to DeliveryContractViolation',
      () async {
        final (h, _, repo) = makeStack();
        final malformed = deliveryResourceJson()..remove('aggregateVersion');
        h.enqueue(200, malformed);

        final result = await repo.getActiveDelivery();
        expect(result.failureOrNull, isA<DeliveryContractViolation>());
      },
    );
  });

  group('GET /v1/deliveries/{deliveryId}', () {
    // NOTE: application wiring currently reads deliveries primarily through
    // GET /v1/deliveries/active; no remote data source calls the by-id path
    // yet. This harness-level test still exercises the endpoint through the
    // live SaeqApiClient so the contract stays covered.
    test('harness-level GET parses a contract-shaped Delivery', () async {
      final h = ContractWireHarness();
      h.enqueue(
        200,
        deliveryResourceJson(state: 'enRouteToCustomer', aggregateVersion: 2),
      );

      final response = await h.api.get<Map<String, dynamic>>(
        DriverApiPaths.deliveryById(fixtureDeliveryId),
      );

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, '/v1/deliveries/$fixtureDeliveryId');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);

      expect(response.statusCode, 200);
      final data = response.data!;
      // Contract field types: UUID string, enum string, int version, UTC
      // ISO-8601 timestamp.
      expect(data['deliveryId'], fixtureDeliveryId);
      expect(data['state'], 'enRouteToCustomer');
      expect(data['aggregateVersion'], 2);
      expect(DateTime.parse(data['updatedAt'] as String).isUtc, isTrue);
      final normalized = DeliveryMutationResponseWire.fromJson(data);
      expect(normalized.aggregateVersion, 2);
    });

    test('missing required state field fails parsing', () async {
      final h = ContractWireHarness();
      final malformed = deliveryResourceJson()..remove('state');
      h.enqueue(200, malformed);

      final response = await h.api.get<Map<String, dynamic>>(
        DriverApiPaths.deliveryById(fixtureDeliveryId),
      );
      expect(
        () => DeliveryMutationResponseWire.fromJson(response.data!),
        throwsFormatException,
      );
    });
  });

  group('POST /v1/deliveries/{deliveryId}/pickup-confirmation', () {
    test('sends aggregateVersion + Idempotency-Key and parses ack', () async {
      final (h, remote, _) = makeStack();
      h.enqueue(200, deliveryMutationJson(state: 'pickupConfirmedManually'));

      final wire = await remote.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 0,
        idempotencyKey: 'idem-pickup-1',
        notes: 'at the door',
      );

      final r = h.single;
      expect(r.method, 'POST');
      expect(r.path, '/v1/deliveries/$fixtureDeliveryId/pickup-confirmation');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), 'idem-pickup-1');
      expect(r.bodyAsMap, {'aggregateVersion': 0, 'notes': 'at the door'});

      expect(wire.state, 'pickupConfirmedManually');
      expect(wire.aggregateVersion, 1);
    });

    test('409 AGGREGATE_VERSION_CONFLICT maps to DeliveryConflict', () async {
      final (h, _, repo) = makeStack();
      h.enqueue(409, errorEnvelopeJson('AGGREGATE_VERSION_CONFLICT'));

      final result = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 0,
        idempotencyKey: 'idem-pickup-2',
      );
      expect(result.failureOrNull, isA<DeliveryConflict>());
    });

    test('malformed ack maps to DeliveryContractViolation', () async {
      final (h, _, repo) = makeStack();
      h.enqueue(200, {'deliveryId': fixtureDeliveryId});

      final result = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 0,
        idempotencyKey: 'idem-pickup-3',
      );
      expect(result.failureOrNull, isA<DeliveryContractViolation>());
    });
  });

  group('POST /v1/deliveries/{deliveryId}/arrival', () {
    test('sends deviceGeofence evidence with clientEventId and '
        'Idempotency-Key', () async {
      final (h, remote, _) = makeStack();
      h.enqueue(
        200,
        deliveryMutationJson(
          state: 'arrivedAutomaticallyByLocation',
          aggregateVersion: 2,
        ),
      );

      final capturedAt = DateTime.utc(2026, 7, 30, 8, 59);
      final wire = await remote.reportArrival(
        deliveryId: fixtureDeliveryId,
        clientEventId: 'evt-geofence-1',
        idempotencyKey: 'idem-arrival-1',
        capturedAt: capturedAt,
        latitude: 24.7743,
        longitude: 46.7386,
        accuracyMeters: 8,
        policyVersion: 'geofence-v1',
        aggregateVersion: 1,
      );

      final r = h.single;
      expect(r.method, 'POST');
      expect(r.path, '/v1/deliveries/$fixtureDeliveryId/arrival');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), 'idem-arrival-1');
      expect(r.bodyAsMap, {
        'clientEventId': 'evt-geofence-1',
        'source': 'deviceGeofence',
        'capturedAt': capturedAt.toIso8601String(),
        'latitude': 24.7743,
        'longitude': 46.7386,
        'accuracyMeters': 8,
        'policyVersion': 'geofence-v1',
        'aggregateVersion': 1,
      });

      expect(wire.state, 'arrivedAutomaticallyByLocation');
      expect(wire.aggregateVersion, 2);
    });

    test('422 VALIDATION_ERROR maps to DeliveryValidationFailure', () async {
      final (h, _, repo) = makeStack();
      h.enqueue(422, errorEnvelopeJson('VALIDATION_ERROR'));

      final result = await repo.reportAutomaticArrival(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-arrival-2',
        evidence: ArrivalEvidence(
          clientEventId: 'evt-geofence-2',
          capturedAt: DateTime.utc(2026, 7, 30, 9),
          latitude: 0,
          longitude: 0,
          accuracyMeters: 9999,
          policyVersion: 'geofence-v1',
        ),
      );
      expect(result.failureOrNull, isA<DeliveryValidationFailure>());
    });
  });

  group('POST /v1/deliveries/{deliveryId}/delivery-confirmation', () {
    test('sends aggregateVersion + Idempotency-Key, parses ack and clears '
        'cached contact', () async {
      final h = ContractWireHarness();
      final cache = CustomerContactMemoryCache()
        ..set(CustomerContactWire.fromJson(customerContactJson()));
      final remote = HttpDeliveryLifecycleRemote(
        api: h.api,
        contactCache: cache,
      );
      h.enqueue(
        200,
        deliveryMutationJson(
          state: 'deliveredConfirmedManually',
          aggregateVersion: 3,
        ),
      );

      final wire = await remote.confirmDelivery(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 2,
        idempotencyKey: 'idem-confirm-1',
      );

      final r = h.single;
      expect(r.method, 'POST');
      expect(r.path, '/v1/deliveries/$fixtureDeliveryId/delivery-confirmation');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), 'idem-confirm-1');
      expect(r.bodyAsMap, {'aggregateVersion': 2});

      expect(wire.state, 'deliveredConfirmedManually');
      expect(cache.current, isNull);
    });

    test('409 IDEMPOTENCY_CONFLICT maps to DeliveryConflict', () async {
      final (h, _, repo) = makeStack();
      h.enqueue(409, errorEnvelopeJson('IDEMPOTENCY_CONFLICT'));

      final result = await repo.confirmDelivery(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 2,
        idempotencyKey: 'idem-confirm-2',
      );
      expect(result.failureOrNull, isA<DeliveryConflict>());
    });
  });

  group('POST /v1/deliveries/{deliveryId}/cancel', () {
    test('sends reasonCode + Idempotency-Key and parses ack', () async {
      final (h, remote, _) = makeStack();
      h.enqueue(
        200,
        deliveryMutationJson(state: 'cancelled', aggregateVersion: 3),
      );

      final wire = await remote.cancelDelivery(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 2,
        idempotencyKey: 'idem-cancel-1',
        reasonCode: 'customer_request',
      );

      final r = h.single;
      expect(r.method, 'POST');
      expect(r.path, '/v1/deliveries/$fixtureDeliveryId/cancel');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), 'idem-cancel-1');
      expect(r.bodyAsMap, {
        'aggregateVersion': 2,
        'reasonCode': 'customer_request',
      });

      expect(wire.state, 'cancelled');
    });

    test('409 INVALID_DELIVERY_TRANSITION maps to typed transition '
        'failure', () async {
      final (h, _, repo) = makeStack();
      h.enqueue(409, errorEnvelopeJson('INVALID_DELIVERY_TRANSITION'));

      final result = await repo.cancelDelivery(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 2,
        idempotencyKey: 'idem-cancel-2',
      );
      expect(result.failureOrNull, isA<InvalidDeliveryWorkflowTransition>());
    });
  });

  group('POST /v1/deliveries/{deliveryId}/issues', () {
    test('sends code + notes with Idempotency-Key and parses ack', () async {
      final (h, remote, _) = makeStack();
      h.enqueue(
        200,
        deliveryMutationJson(state: 'enRouteToCustomer', aggregateVersion: 2),
      );

      final wire = await remote.reportIssue(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-issue-1',
        code: 'customer_unreachable',
        notes: 'no answer at door',
      );

      final r = h.single;
      expect(r.method, 'POST');
      expect(r.path, '/v1/deliveries/$fixtureDeliveryId/issues');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), 'idem-issue-1');
      expect(r.bodyAsMap, {
        'aggregateVersion': 1,
        'code': 'customer_unreachable',
        'notes': 'no answer at door',
      });

      expect(wire.aggregateVersion, 2);
    });

    test('500 INTERNAL_ERROR maps to DeliveryBackendUnavailable', () async {
      final (h, _, repo) = makeStack();
      h.enqueue(500, errorEnvelopeJson('INTERNAL_ERROR', retryable: true));

      final result = await repo.reportIssue(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-issue-2',
        code: 'customer_unreachable',
      );
      expect(result.failureOrNull, isA<DeliveryBackendUnavailable>());
    });

    test('429 RATE_LIMITED maps to DeliveryRateLimited', () async {
      final (h, _, repo) = makeStack();
      h.enqueue(429, errorEnvelopeJson('RATE_LIMITED', retryable: true));

      final result = await repo.reportIssue(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-issue-3',
        code: 'customer_unreachable',
      );
      expect(result.failureOrNull, isA<DeliveryRateLimited>());
    });
  });

  tearDownAll(() {
    expect(
      ContractWireHarness.coverage.containsAll(catalogSlice('deliveries')),
      isTrue,
      reason:
          'deliveries wire tests must exercise all 7 delivery '
          'endpoints; covered: ${ContractWireHarness.coverage}',
    );
  });
}
