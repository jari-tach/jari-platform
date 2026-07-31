/// STEP 5D-2 acceptance — conflict / error matrix.
///
/// Covers the typed ErrorEnvelope codes of contracts-v0.1.0, the Dio-level
/// transport failures (401-refresh, 409, 422, 429, 500, timeout, offline,
/// malformed contract), and the recovery rules (conflict → reload,
/// idempotency conflict → never a new key, refresh failure → session clear).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/auth_session/auth_token_store.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/core/services/storage/secure_storage_service.dart';
import 'package:saeq_driver/features/auth/data/remote/http_auth_remote_data_source.dart';
import 'package:saeq_driver/features/auth/data/repositories/remote_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_lifecycle_wire.dart';
import 'package:saeq_driver/features/delivery/data/remote/customer_contact_memory_cache.dart';
import 'package:saeq_driver/features/delivery/data/remote/http_delivery_lifecycle_remote.dart';
import 'package:saeq_driver/features/delivery/data/remote/http_delivery_remote_data_source.dart';
import 'package:saeq_driver/features/delivery/data/repositories/remote_delivery_lifecycle_repository.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import '../contract_wire/contract_wire_harness.dart';
import 'step5d2_e2e_helpers.dart';

class _MemSecureStorage implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> clearAllAuthData() async => _data.clear();
}

void main() {
  (ContractWireHarness, RemoteDeliveryLifecycleRepository) makeRemoteStack({
    ContractWireHarness? harness,
  }) {
    final h = harness ?? ContractWireHarness();
    final repo = RemoteDeliveryLifecycleRepository(
      remote: HttpDeliveryLifecycleRemote(
        api: h.api,
        contactCache: CustomerContactMemoryCache(),
      ),
    );
    return (h, repo);
  }

  group('typed ErrorEnvelope code matrix (lifecycle mutations)', () {
    final cases = <(String code, int status, Matcher failure)>[
      ('IDEMPOTENCY_CONFLICT', 409, isA<DeliveryConflict>()),
      ('AGGREGATE_VERSION_CONFLICT', 409, isA<DeliveryConflict>()),
      (
        'INVALID_DELIVERY_TRANSITION',
        409,
        isA<InvalidDeliveryWorkflowTransition>(),
      ),
      ('ACTIVE_ASSIGNMENT_CONFLICT', 409, isA<DeliveryConflict>()),
      (
        'CUSTOMER_CONTACT_NOT_AVAILABLE',
        403,
        isA<DeliveryContactNotAvailable>(),
      ),
      ('UNAUTHORIZED', 401, isA<DeliveryUnauthenticated>()),
      ('FORBIDDEN', 403, isA<DeliverySecurityPolicyDenied>()),
      ('VALIDATION_ERROR', 422, isA<DeliveryValidationFailure>()),
      ('RATE_LIMITED', 429, isA<DeliveryRateLimited>()),
      ('INTERNAL_ERROR', 500, isA<DeliveryBackendUnavailable>()),
    ];

    for (final (code, status, failure) in cases) {
      test('$status $code maps to a typed delivery failure', () async {
        final (h, repo) = makeRemoteStack();
        h.enqueue(status, errorEnvelopeJson(code));

        final result = await repo.confirmPickup(
          deliveryId: fixtureDeliveryId,
          aggregateVersion: 1,
          idempotencyKey: 'idem-matrix-$code',
        );
        expect(result.failureOrNull, failure);
      });
    }

    test('409 OFFER_EXPIRED maps to DeliveryOfferExpired', () async {
      final h = ContractWireHarness();
      h.enqueue(409, errorEnvelopeJson('OFFER_EXPIRED'));

      await expectLater(
        HttpDeliveryRemoteDataSource(api: h.api).acceptOffer(
          driverId: fixtureDriverId,
          offerId: fixtureOfferId,
          idempotencyKey: 'idem-matrix-offer-expired',
          revision: '3',
        ),
        throwsA(isA<DeliveryOfferExpired>()),
      );
    });

    test('409 OFFER_ALREADY_ACCEPTED maps to DeliveryOfferTaken', () async {
      final h = ContractWireHarness();
      h.enqueue(409, errorEnvelopeJson('OFFER_ALREADY_ACCEPTED'));

      await expectLater(
        HttpDeliveryRemoteDataSource(api: h.api).acceptOffer(
          driverId: fixtureDriverId,
          offerId: fixtureOfferId,
          idempotencyKey: 'idem-matrix-offer-taken',
          revision: '3',
        ),
        throwsA(isA<DeliveryOfferTaken>()),
      );
    });
  });

  group('Dio-level failures', () {
    test('401 with refresh success retries once with the new token', () async {
      var refreshCalls = 0;
      late ContractWireHarness h;
      h = ContractWireHarness(
        onUnauthorizedRefresh: () async {
          refreshCalls++;
          h.tokenCache.setAccessToken('saeq-test-access-2');
          return true;
        },
      );
      h.enqueue(401, errorEnvelopeJson('TOKEN_EXPIRED'));
      h.enqueue(200, driverProfileJson());

      final response = await h.api.get<Map<String, dynamic>>(
        DriverApiPaths.driverMe,
      );

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(h.requests, hasLength(2));
      expect(
        h.requests.first.header('Authorization'),
        'Bearer $fixtureAccessToken',
      );
      expect(
        h.requests.last.header('Authorization'),
        'Bearer saeq-test-access-2',
      );
    });

    test('refresh failure clears the session (tokens + memory cache) and '
        'the PII memory cache clears on session expiration', () async {
      final h = ContractWireHarness();
      final tokenStore = InMemoryAuthTokenStore();
      await tokenStore.saveRefreshToken('saeq-test-refresh-token-1');
      final repo = RemoteAuthenticationRepository(
        remote: HttpAuthRemoteDataSource(api: h.api),
        sessionStorage: AuthSessionStorage(
          storage: _MemSecureStorage(),
          logger: SilentLogger(),
        ),
        tokenStore: tokenStore,
        accessTokenCache: h.tokenCache,
        logger: SilentLogger(),
      );

      final contactCache = CustomerContactMemoryCache();
      final lifecycleRemote = HttpDeliveryLifecycleRemote(
        api: h.api,
        contactCache: contactCache,
      );
      contactCache.set(CustomerContactWire.fromJson(customerContactJson()));

      h.enqueue(401, errorEnvelopeJson('UNAUTHORIZED'));
      await expectLater(
        repo.refreshSession(),
        throwsA(isA<SessionExpiredError>()),
      );

      expect(h.tokenCache.accessToken, isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
      expect(repo.currentSession, isNull);

      // Session-expiration cleanup wipes the memory-only customer contact.
      lifecycleRemote.onLogoutOrSessionExpired();
      expect(contactCache.current, isNull);
    });

    test(
      'bare 409 without an envelope still maps to DeliveryConflict',
      () async {
        final (h, repo) = makeRemoteStack();
        h.enqueue(409, {'not': 'an envelope'});

        final result = await repo.confirmPickup(
          deliveryId: fixtureDeliveryId,
          aggregateVersion: 1,
          idempotencyKey: 'idem-matrix-bare-409',
        );
        expect(result.failureOrNull, isA<DeliveryConflict>());
      },
    );

    test('bare 429 maps to DeliveryRateLimited', () async {
      final (h, repo) = makeRemoteStack();
      h.enqueue(429, {'not': 'an envelope'});

      final result = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-matrix-bare-429',
      );
      expect(result.failureOrNull, isA<DeliveryRateLimited>());
    });

    test('bare 500 maps to DeliveryBackendUnavailable', () async {
      final (h, repo) = makeRemoteStack();
      h.enqueue(500, {'not': 'an envelope'});

      final result = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-matrix-bare-500',
      );
      expect(result.failureOrNull, isA<DeliveryBackendUnavailable>());
    });

    test('request timeout maps to DeliveryBackendUnavailable', () async {
      final (h, repo) = makeRemoteStack();
      h.enqueueTimeout();

      final result = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-matrix-timeout',
      );
      expect(result.failureOrNull, isA<DeliveryBackendUnavailable>());
    });

    test('network unavailable maps to DeliveryNetworkUnavailable', () async {
      final (h, repo) = makeRemoteStack();
      h.enqueueNetworkFailure();

      final result = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-matrix-offline',
      );
      expect(result.failureOrNull, isA<DeliveryNetworkUnavailable>());
    });

    test('malformed contract response maps to DeliveryContractViolation, '
        'never silent unknown', () async {
      final (h, repo) = makeRemoteStack();
      h.enqueue(200, {'deliveryId': fixtureDeliveryId, 'state': 42});

      final result = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-matrix-malformed',
      );
      expect(result.failureOrNull, isA<DeliveryContractViolation>());
      expect(result.failureOrNull, isNot(isA<DeliveryUnknownFailure>()));
    });
  });

  group('recovery rules', () {
    test('AGGREGATE_VERSION_CONFLICT → typed DeliveryConflict, then the '
        'resource is reloaded from the Backend', () async {
      final (h, repo) = makeRemoteStack();
      h.enqueue(409, errorEnvelopeJson('AGGREGATE_VERSION_CONFLICT'));

      final conflicted = await repo.confirmPickup(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-rule-conflict',
      );
      expect(conflicted.failureOrNull, isA<DeliveryConflict>());

      // Reload the aggregate to learn the authoritative version.
      h.enqueue(
        200,
        deliveryResourceJson(state: 'enRouteToCustomer', aggregateVersion: 5),
      );
      final reloaded = await repo.getActiveDelivery();
      expect(reloaded.isSuccess, isTrue);
      expect(reloaded.valueOrNull?.aggregateVersion, 5);

      expect(h.requests, hasLength(2));
      expect(h.requests.last.method, 'GET');
      expect(h.requests.last.path, DriverApiPaths.deliveriesActive);
    });

    test('IDEMPOTENCY_CONFLICT → the use case never retries with a NEW '
        'Idempotency-Key', () async {
      final e2e = makeHarness(active: waitingPickupAssignment());
      e2e.backend.nextFailure = const DeliveryConflict();

      final result = await confirmPickupOf(e2e)(
        driverId: 'drv-1',
        commandId: 'cmd-idem-conflict-1',
      );
      expect(result.failureOrNull, isA<DeliveryConflict>());

      // Exactly one Backend call, carrying the original command id as key.
      expect(e2e.lifecycle.mutations, hasLength(1));
      expect(
        e2e.lifecycle.mutations.single.idempotencyKey,
        'cmd-idem-conflict-1',
      );
      // Conflicts are not retryable: nothing was queued for a re-post and no
      // substitute key was minted in the ledger.
      expect(e2e.commands.commands, isEmpty);
    });

    test('INVALID_DELIVERY_TRANSITION surfaces as the typed workflow '
        'failure', () async {
      final (h, repo) = makeRemoteStack();
      h.enqueue(409, errorEnvelopeJson('INVALID_DELIVERY_TRANSITION'));

      final result = await repo.confirmDelivery(
        deliveryId: fixtureDeliveryId,
        aggregateVersion: 1,
        idempotencyKey: 'idem-rule-transition',
      );
      expect(result.failureOrNull, isA<InvalidDeliveryWorkflowTransition>());
    });
  });
}
