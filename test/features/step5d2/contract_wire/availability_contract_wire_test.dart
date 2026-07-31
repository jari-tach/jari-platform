/// STEP 5D-2 contract wire tests — Availability resource group (2/23).
///
/// GET /v1/drivers/me/availability, PUT /v1/drivers/me/availability.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/core/network/remote_error_classification.dart';
import 'package:saeq_driver/core/network/remote_error_mapper.dart';
import 'package:saeq_driver/features/availability/data/models/driver_availability_wire.dart';
import 'package:saeq_driver/features/availability/data/remote/http_driver_availability_remote_data_source.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';

import 'contract_wire_harness.dart';

void main() {
  const mapper = RemoteErrorMapper();

  Future<Object> capture(Future<void> Function() run) async {
    try {
      await run();
    } catch (e) {
      return e;
    }
    fail('Expected an error to be thrown');
  }

  group('GET /v1/drivers/me/availability', () {
    test('sends authenticated GET and parses DriverAvailabilityWire', () async {
      final h = ContractWireHarness();
      h.enqueue(200, driverAvailabilityJson());

      final wire = await HttpDriverAvailabilityRemoteDataSource(
        api: h.api,
      ).getAvailability();

      final r = h.single;
      expect(r.method, 'GET');
      expect(r.path, DriverApiPaths.driverAvailability);
      expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
      expect(r.header('X-Request-Id'), isNotEmpty);
      expect(r.header('Idempotency-Key'), isNull);

      expect(wire.status, 'available');
      expect(wire.updatedAt.isUtc, isTrue);
      expect(wire.reason, isNull);
      expect(
        wire.toDomain(driverId: fixtureDriverId).status,
        AvailabilityStatus.available,
      );
    });

    test('unknown status enum fails with FormatException', () async {
      final h = ContractWireHarness();
      h.enqueue(200, driverAvailabilityJson(status: 'notAContractStatus'));

      final wire = await HttpDriverAvailabilityRemoteDataSource(
        api: h.api,
      ).getAvailability();
      // Wire keeps the raw string; the enum mapping is where unknown values
      // must fail loudly instead of defaulting.
      expect(
        () => wire.toDomain(driverId: fixtureDriverId),
        throwsFormatException,
      );
    });

    test('missing updatedAt fails with FormatException', () async {
      final h = ContractWireHarness();
      h.enqueue(200, {'status': 'available'});

      await expectLater(
        HttpDriverAvailabilityRemoteDataSource(api: h.api).getAvailability(),
        throwsFormatException,
      );
    });

    test('401 UNAUTHORIZED envelope classifies as sessionExpired', () async {
      final h = ContractWireHarness();
      h.enqueue(401, errorEnvelopeJson('UNAUTHORIZED'));

      final error = await capture(
        () => HttpDriverAvailabilityRemoteDataSource(
          api: h.api,
        ).getAvailability(),
      );
      expect(mapper.classify(error), RemoteErrorClassification.sessionExpired);
    });
  });

  group('PUT /v1/drivers/me/availability', () {
    test(
      'sends Idempotency-Key with wire status body and parses 200',
      () async {
        final h = ContractWireHarness();
        h.enqueue(200, driverAvailabilityJson(status: 'offline'));

        final wire = await HttpDriverAvailabilityRemoteDataSource(api: h.api)
            .putAvailability(
              status: DriverAvailabilityWire.toWireStatus(
                AvailabilityStatus.offline,
              )!,
              idempotencyKey: 'idem-availability-1',
            );

        final r = h.single;
        expect(r.method, 'PUT');
        expect(r.path, DriverApiPaths.driverAvailability);
        expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
        expect(r.header('X-Request-Id'), isNotEmpty);
        expect(r.header('Idempotency-Key'), 'idem-availability-1');
        expect(r.bodyAsMap, {'status': 'offline'});

        expect(wire.status, 'offline');
      },
    );

    test(
      '409 AGGREGATE_VERSION_CONFLICT envelope classifies as conflict',
      () async {
        final h = ContractWireHarness();
        h.enqueue(409, errorEnvelopeJson('AGGREGATE_VERSION_CONFLICT'));

        final error = await capture(
          () => HttpDriverAvailabilityRemoteDataSource(api: h.api)
              .putAvailability(
                status: 'available',
                idempotencyKey: 'idem-availability-2',
              ),
        );
        expect(mapper.classify(error), RemoteErrorClassification.conflict);
        expect(mapper.envelopeOf(error)?.code, 'AGGREGATE_VERSION_CONFLICT');
      },
    );

    test('422 VALIDATION_ERROR envelope classifies as validation', () async {
      final h = ContractWireHarness();
      h.enqueue(422, errorEnvelopeJson('VALIDATION_ERROR'));

      final error = await capture(
        () =>
            HttpDriverAvailabilityRemoteDataSource(api: h.api).putAvailability(
              status: 'available',
              idempotencyKey: 'idem-availability-3',
            ),
      );
      expect(mapper.classify(error), RemoteErrorClassification.validation);
    });
  });

  tearDownAll(() {
    expect(
      ContractWireHarness.coverage.containsAll(catalogSlice('availability')),
      isTrue,
      reason:
          'availability wire tests must exercise both availability '
          'endpoints; covered: ${ContractWireHarness.coverage}',
    );
  });
}
