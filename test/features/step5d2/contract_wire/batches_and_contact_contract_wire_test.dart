/// STEP 5D-2 contract wire tests — Batches + Customer contact (3/23).
///
/// GET /v1/batches/active, GET /v1/batches/{batchId},
/// GET /v1/deliveries/{deliveryId}/customer-contact.
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
    CustomerContactMemoryCache,
    HttpDeliveryLifecycleRemote,
    RemoteDeliveryLifecycleRepository,
  )
  makeStack() {
    final h = ContractWireHarness();
    final cache = CustomerContactMemoryCache();
    final remote = HttpDeliveryLifecycleRemote(api: h.api, contactCache: cache);
    final repo = RemoteDeliveryLifecycleRepository(remote: remote);
    return (h, cache, remote, repo);
  }

  group('GET /v1/batches/active', () {
    test('sends authenticated GET and parses BatchSummaryWire', () async {
      final (h, _, remote, _) = makeStack();
      h.enqueue(200, batchSummaryJson());

      final wire = await remote.getActiveBatch();

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, DriverApiPaths.batchesActive);
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), isNull);

      expect(wire, isNotNull);
      expect(wire!.batchId, fixtureBatchId);
      expect(wire.currentStopSequence, 1);
      expect(wire.aggregateVersion, 2);
      expect(wire.stops, hasLength(2));
      expect(wire.upcomingStopsHaveContactFields, isFalse);
    });

    test('204 no content means no active batch', () async {
      final (h, _, remote, _) = makeStack();
      h.enqueue(204);

      final wire = await remote.getActiveBatch();
      expect(wire, isNull);
    });

    test('upcoming stop carrying contact fields is denied by the '
        'repository security guard', () async {
      final (h, _, _, repo) = makeStack();
      h.enqueue(
        200,
        batchSummaryJson(
          stops: [
            batchStopJson(),
            batchStopJson(sequence: 2, label: 'Stop 2')
              ..['phoneNumber'] = '+966500000009',
          ],
        ),
      );

      final result = await repo.getActiveBatch();
      expect(result.failureOrNull, isA<DeliverySecurityPolicyDenied>());
    });

    test('401 UNAUTHORIZED envelope maps to DeliveryUnauthenticated', () async {
      final (h, _, _, repo) = makeStack();
      h.enqueue(401, errorEnvelopeJson('UNAUTHORIZED'));

      final result = await repo.getActiveBatch();
      expect(result.failureOrNull, isA<DeliveryUnauthenticated>());
    });
  });

  group('GET /v1/batches/{batchId}', () {
    test('sends authenticated GET by id and parses BatchSummaryWire', () async {
      final (h, _, remote, _) = makeStack();
      h.enqueue(200, batchSummaryJson());

      final wire = await remote.getBatch(fixtureBatchId);

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, '/v1/batches/$fixtureBatchId');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);

      expect(wire.batchId, fixtureBatchId);
      expect(wire.stops.first.deliveryId, fixtureDeliveryId);
      expect(wire.stops.first.stopType, 'dropoff');
    });

    test('malformed batch (missing aggregateVersion) maps to '
        'DeliveryContractViolation', () async {
      final (h, _, _, repo) = makeStack();
      final malformed = batchSummaryJson()..remove('aggregateVersion');
      h.enqueue(200, malformed);

      final result = await repo.getBatch(fixtureBatchId);
      expect(result.failureOrNull, isA<DeliveryContractViolation>());
    });
  });

  group('GET /v1/deliveries/{deliveryId}/customer-contact', () {
    test('allowed state sends authenticated GET, parses and caches '
        'contact', () async {
      final (h, cache, remote, _) = makeStack();
      h.enqueue(200, customerContactJson());

      final wire = await remote.fetchCustomerContact(
        deliveryId: fixtureDeliveryId,
        deliveryState: CanonicalDeliveryStates.enRouteToCustomer,
      );

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, '/v1/deliveries/$fixtureDeliveryId/customer-contact');
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), isNull);

      expect(wire.deliveryId, fixtureDeliveryId);
      expect(wire.name, fixtureCustomerName);
      expect(wire.phoneNumber, fixtureCustomerPhone);
      expect(wire.availableUntil.isUtc, isTrue);
      expect(cache.current?.phoneNumber, fixtureCustomerPhone);
    });

    test('pre-pickup state never issues a request and clears the '
        'cache', () async {
      final (h, cache, remote, _) = makeStack();
      cache.set(CustomerContactWire.fromJson(customerContactJson()));

      await expectLater(
        remote.fetchCustomerContact(
          deliveryId: fixtureDeliveryId,
          deliveryState: CanonicalDeliveryStates.accepted,
        ),
        throwsStateError,
      );
      expect(h.requests, isEmpty);
      expect(cache.current, isNull);
    });

    test('403 CUSTOMER_CONTACT_NOT_AVAILABLE envelope maps to '
        'DeliveryContactNotAvailable', () async {
      final (h, _, _, repo) = makeStack();
      h.enqueue(403, errorEnvelopeJson('CUSTOMER_CONTACT_NOT_AVAILABLE'));

      final result = await repo.getCustomerContact(
        deliveryId: fixtureDeliveryId,
        deliveryState: CanonicalDeliveryStates.enRouteToCustomer,
      );
      expect(result.failureOrNull, isA<DeliveryContactNotAvailable>());
    });

    test('malformed contact (missing phoneNumber) maps to '
        'DeliveryContractViolation', () async {
      final (h, _, _, repo) = makeStack();
      final malformed = customerContactJson()..remove('phoneNumber');
      h.enqueue(200, malformed);

      final result = await repo.getCustomerContact(
        deliveryId: fixtureDeliveryId,
        deliveryState: CanonicalDeliveryStates.enRouteToCustomer,
      );
      expect(result.failureOrNull, isA<DeliveryContractViolation>());
    });
  });

  tearDownAll(() {
    expect(
      ContractWireHarness.coverage.containsAll(
        catalogSlice('batches_and_contact'),
      ),
      isTrue,
      reason:
          'batch/contact wire tests must exercise all 3 endpoints; '
          'covered: ${ContractWireHarness.coverage}',
    );
  });
}
