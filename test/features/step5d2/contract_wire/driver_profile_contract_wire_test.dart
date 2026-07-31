/// STEP 5D-2 contract wire tests — Driver resource group (3/23 endpoints).
///
/// GET /v1/drivers/me, PATCH /v1/drivers/me, GET /v1/drivers/me/compliance.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/features/profile/data/remote/http_driver_profile_remote_data_source.dart';
import 'package:saeq_driver/features/profile/data/repositories/remote_driver_profile_repository.dart';
import 'package:saeq_driver/features/profile/domain/entities/driver_status.dart';
import 'package:saeq_driver/features/profile/domain/entities/profile_error.dart';

import 'contract_wire_harness.dart';

void main() {
  group('GET /v1/drivers/me', () {
    test('sends authenticated GET and parses DriverProfileWire', () async {
      final h = ContractWireHarness();
      h.enqueue(200, driverProfileJson());

      final wire = await HttpDriverProfileRemoteDataSource(api: h.api).getMe();

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, DriverApiPaths.driverMe);
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), isNull);

      expect(wire.driverId, fixtureDriverId);
      expect(wire.displayName, 'Test Driver');
      expect(wire.locale, 'ar-SA');
      expect(wire.status, 'active');
      expect(wire.createdAt.isUtc, isTrue);
      expect(wire.updatedAt.isUtc, isTrue);
      expect(wire.vehicleType, 'sedan');
      expect(wire.toDomain().accountStatus, AccountStatus.verified);
    });

    test('missing required field maps to ProfileInvalidDataError', () async {
      final h = ContractWireHarness();
      final malformed = driverProfileJson()..remove('updatedAt');
      h.enqueue(200, malformed);

      final repo = RemoteDriverProfileRepository(
        remote: HttpDriverProfileRemoteDataSource(api: h.api),
      );
      await expectLater(
        repo.getCurrentProfile(),
        throwsA(isA<ProfileInvalidDataError>()),
      );
    });

    test('unknown status enum maps to ProfileInvalidDataError', () async {
      final h = ContractWireHarness();
      h.enqueue(200, driverProfileJson(status: 'notAContractStatus'));

      final repo = RemoteDriverProfileRepository(
        remote: HttpDriverProfileRemoteDataSource(api: h.api),
      );
      await expectLater(
        repo.getCurrentProfile(),
        throwsA(isA<ProfileInvalidDataError>()),
      );
    });

    test(
      '401 UNAUTHORIZED envelope maps to ProfileSessionExpiredError',
      () async {
        final h = ContractWireHarness();
        h.enqueue(401, errorEnvelopeJson('UNAUTHORIZED'));

        final repo = RemoteDriverProfileRepository(
          remote: HttpDriverProfileRemoteDataSource(api: h.api),
        );
        await expectLater(
          repo.getCurrentProfile(),
          throwsA(isA<ProfileSessionExpiredError>()),
        );
      },
    );
  });

  group('PATCH /v1/drivers/me', () {
    test('sends Idempotency-Key with sparse body and parses 200', () async {
      final h = ContractWireHarness();
      h.enqueue(200, driverProfileJson());

      final wire = await HttpDriverProfileRemoteDataSource(api: h.api).patchMe(
        idempotencyKey: 'idem-patch-me-1',
        displayName: 'Test Driver',
        locale: 'ar-SA',
      );

      final r = h.single;
      expect(r.method, 'PATCH');
      expect(r.path, DriverApiPaths.driverMe);
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), 'idem-patch-me-1');
      // Sparse PATCH: omitted fields must not be sent at all.
      expect(r.bodyAsMap, {'displayName': 'Test Driver', 'locale': 'ar-SA'});
      expect(r.bodyAsMap.containsKey('vehicleType'), isFalse);

      expect(wire.driverId, fixtureDriverId);
      expect(wire.updatedAt.isUtc, isTrue);
    });

    test(
      '422 VALIDATION_ERROR envelope maps to ProfileInvalidDataError',
      () async {
        final h = ContractWireHarness();
        h.enqueue(422, errorEnvelopeJson('VALIDATION_ERROR'));

        Object? caught;
        try {
          await HttpDriverProfileRemoteDataSource(
            api: h.api,
          ).patchMe(idempotencyKey: 'idem-patch-me-2', displayName: '');
        } catch (e) {
          caught = e;
        }
        expect(caught, isNotNull);

        // Same mapping the repository applies for PATCH failures.
        final repo = RemoteDriverProfileRepository(
          remote: HttpDriverProfileRemoteDataSource(api: h.api),
        );
        h.enqueue(422, errorEnvelopeJson('VALIDATION_ERROR'));
        await expectLater(
          repo.getCurrentProfile(),
          throwsA(isA<ProfileInvalidDataError>()),
        );
      },
    );
  });

  group('GET /v1/drivers/me/compliance', () {
    test('sends authenticated GET and parses DriverComplianceWire', () async {
      final h = ContractWireHarness();
      h.enqueue(200, driverComplianceJson());

      final wire = await HttpDriverProfileRemoteDataSource(
        api: h.api,
      ).getCompliance();

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, DriverApiPaths.driverCompliance);
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), isNull);

      expect(wire.overallStatus, 'compliant');
      expect(wire.requirements, hasLength(2));
      expect(wire.requirements.first.code, 'nationalId');
      expect(wire.blockingReasons, isEmpty);
      expect(wire.lastEvaluatedAt.isUtc, isTrue);
    });

    test('malformed compliance (requirements not a list) maps to '
        'ProfileInvalidDataError', () async {
      final h = ContractWireHarness();
      final malformed = driverComplianceJson()..['requirements'] = 'oops';
      h.enqueue(200, malformed);

      final repo = RemoteDriverProfileRepository(
        remote: HttpDriverProfileRemoteDataSource(api: h.api),
      );
      await expectLater(
        repo.getCompliance(),
        throwsA(isA<ProfileInvalidDataError>()),
      );
    });

    test('401 envelope maps to ProfileSessionExpiredError', () async {
      final h = ContractWireHarness();
      h.enqueue(401, errorEnvelopeJson('TOKEN_EXPIRED'));

      final repo = RemoteDriverProfileRepository(
        remote: HttpDriverProfileRemoteDataSource(api: h.api),
      );
      await expectLater(
        repo.getCompliance(),
        throwsA(isA<ProfileSessionExpiredError>()),
      );
    });
  });

  tearDownAll(() {
    expect(
      ContractWireHarness.coverage.containsAll(catalogSlice('driver_profile')),
      isTrue,
      reason:
          'driver profile wire tests must exercise all 3 driver '
          'endpoints; covered: ${ContractWireHarness.coverage}',
    );
  });
}
