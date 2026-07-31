/// STEP 5D-2 contract wire tests — Auth resource group (4/23 endpoints).
///
/// POST /v1/auth/otp/request, POST /v1/auth/otp/verify,
/// POST /v1/auth/token/refresh, POST /v1/auth/logout.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/backend_configuration/driver_api_paths.dart';
import 'package:saeq_driver/core/network/remote_error_classification.dart';
import 'package:saeq_driver/core/network/remote_error_mapper.dart';
import 'package:saeq_driver/features/auth/data/remote/http_auth_remote_data_source.dart';

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

  group('POST /v1/auth/otp/request', () {
    test(
      'sends contract-shaped unauthenticated request and parses 200',
      () async {
        final h = ContractWireHarness();
        h.enqueue(200, otpChallengeJson());

        final wire = await HttpAuthRemoteDataSource(
          api: h.api,
        ).requestOtp(phoneNumber: '+966512345678', locale: 'ar-SA');

        final r = h.single;
        expect(r.method, 'POST');
        expect(r.path, DriverApiPaths.otpRequest);
        // OTP request is unauthenticated per client design — even with a
        // cached access token the Authorization header must not be sent.
        expect(r.header('Authorization'), isNull);
        expect(r.header('X-Request-Id'), isNotNull);
        expect(r.header('X-Request-Id'), isNotEmpty);
        expect(r.header('Idempotency-Key'), isNull);
        expect(r.bodyAsMap, {
          'phoneNumber': '+966512345678',
          'locale': 'ar-SA',
        });

        expect(wire.challengeId, fixtureChallengeId);
        expect(wire.expiresAt.isUtc, isTrue);
        expect(wire.resendAvailableAt, isNotNull);
      },
    );

    test('429 OTP_RATE_LIMITED envelope classifies as rateLimited', () async {
      final h = ContractWireHarness();
      h.enqueue(429, errorEnvelopeJson('OTP_RATE_LIMITED', retryable: true));

      final error = await capture(
        () => HttpAuthRemoteDataSource(
          api: h.api,
        ).requestOtp(phoneNumber: '+966512345678', locale: 'ar-SA'),
      );
      expect(mapper.classify(error), RemoteErrorClassification.rateLimited);
      expect(mapper.envelopeOf(error)?.code, 'OTP_RATE_LIMITED');
      expect(mapper.envelopeOf(error)?.requestId, isNotEmpty);
    });

    test(
      'malformed success (missing challengeId) throws FormatException',
      () async {
        final h = ContractWireHarness();
        h.enqueue(200, {'expiresAt': fixtureExpiresAt});

        await expectLater(
          HttpAuthRemoteDataSource(
            api: h.api,
          ).requestOtp(phoneNumber: '+966512345678', locale: 'ar-SA'),
          throwsFormatException,
        );
      },
    );
  });

  group('POST /v1/auth/otp/verify', () {
    test(
      'sends Idempotency-Key without Authorization and parses tokens',
      () async {
        final h = ContractWireHarness();
        h.enqueue(200, tokenResponseJson());

        final wire = await HttpAuthRemoteDataSource(api: h.api).verifyOtp(
          challengeId: fixtureChallengeId,
          otpCode: '123456',
          idempotencyKey: 'idem-verify-1',
          device: const {'deviceId': 'saeq-driver-flutter'},
        );

        final r = h.single;
        expect(r.method, 'POST');
        expect(r.path, DriverApiPaths.otpVerify);
        expect(r.header('Authorization'), isNull);
        expect(r.header('X-Request-Id'), isNotEmpty);
        expect(r.header('Idempotency-Key'), 'idem-verify-1');
        expect(r.bodyAsMap['challengeId'], fixtureChallengeId);
        expect(r.bodyAsMap['otpCode'], '123456');
        expect(r.bodyAsMap['device'], isA<Map<dynamic, dynamic>>());

        expect(wire.accessToken, fixtureAccessToken);
        expect(wire.tokenType, 'Bearer');
        expect(wire.accessTokenExpiresAt.isUtc, isTrue);
        expect(wire.driver.driverId, fixtureDriverId);
        expect(wire.driver.status, 'active');
      },
    );

    test('401 OTP_INVALID envelope classifies as validation', () async {
      final h = ContractWireHarness();
      h.enqueue(401, errorEnvelopeJson('OTP_INVALID'));

      final error = await capture(
        () => HttpAuthRemoteDataSource(api: h.api).verifyOtp(
          challengeId: fixtureChallengeId,
          otpCode: '000000',
          idempotencyKey: 'idem-verify-2',
        ),
      );
      expect(mapper.classify(error), RemoteErrorClassification.validation);
    });

    test('missing required driver field throws FormatException', () async {
      final h = ContractWireHarness();
      final malformed = tokenResponseJson()..remove('driver');
      h.enqueue(200, malformed);

      await expectLater(
        HttpAuthRemoteDataSource(api: h.api).verifyOtp(
          challengeId: fixtureChallengeId,
          otpCode: '123456',
          idempotencyKey: 'idem-verify-3',
        ),
        throwsFormatException,
      );
    });
  });

  group('POST /v1/auth/token/refresh', () {
    test(
      'sends refresh token with Idempotency-Key, no Authorization',
      () async {
        final h = ContractWireHarness();
        h.enqueue(200, tokenResponseJson(accessToken: 'saeq-test-access-2'));

        final wire = await HttpAuthRemoteDataSource(api: h.api).refreshToken(
          refreshToken: 'saeq-test-refresh-token-1',
          idempotencyKey: 'idem-refresh-1',
        );

        final r = h.single;
        expect(r.method, 'POST');
        expect(r.path, DriverApiPaths.tokenRefresh);
        expect(r.header('Authorization'), isNull);
        expect(r.header('X-Request-Id'), isNotEmpty);
        expect(r.header('Idempotency-Key'), 'idem-refresh-1');
        expect(r.bodyAsMap, {'refreshToken': 'saeq-test-refresh-token-1'});

        expect(wire.accessToken, 'saeq-test-access-2');
        expect(
          wire.refreshTokenExpiresAt.isAfter(wire.accessTokenExpiresAt),
          isTrue,
        );
      },
    );

    test('401 UNAUTHORIZED envelope classifies as sessionExpired', () async {
      final h = ContractWireHarness();
      h.enqueue(401, errorEnvelopeJson('UNAUTHORIZED'));

      final error = await capture(
        () => HttpAuthRemoteDataSource(api: h.api).refreshToken(
          refreshToken: 'saeq-test-refresh-token-1',
          idempotencyKey: 'idem-refresh-2',
        ),
      );
      expect(mapper.classify(error), RemoteErrorClassification.sessionExpired);
    });

    test('unknown envelope code classifies as contractViolation', () async {
      final h = ContractWireHarness();
      h.enqueue(400, errorEnvelopeJson('NOT_A_CONTRACT_CODE'));

      final error = await capture(
        () => HttpAuthRemoteDataSource(api: h.api).refreshToken(
          refreshToken: 'saeq-test-refresh-token-1',
          idempotencyKey: 'idem-refresh-3',
        ),
      );
      expect(
        mapper.classify(error),
        RemoteErrorClassification.contractViolation,
      );
    });
  });

  group('POST /v1/auth/logout', () {
    test(
      'sends Bearer Authorization + Idempotency-Key and accepts 204',
      () async {
        final h = ContractWireHarness();
        h.enqueue(204);

        await HttpAuthRemoteDataSource(api: h.api).logout(
          refreshToken: 'saeq-test-refresh-token-1',
          idempotencyKey: 'idem-logout-1',
        );

        final r = h.single;
        expect(r.method, 'POST');
        expect(r.path, DriverApiPaths.logout);
        expect(r.header('Authorization'), 'Bearer $fixtureAccessToken');
        expect(r.header('X-Request-Id'), isNotEmpty);
        expect(r.header('Idempotency-Key'), 'idem-logout-1');
        expect(r.bodyAsMap, {'refreshToken': 'saeq-test-refresh-token-1'});
      },
    );
  });

  tearDownAll(() {
    expect(
      ContractWireHarness.coverage.containsAll(catalogSlice('auth')),
      isTrue,
      reason:
          'auth wire tests must exercise all 4 auth endpoints; '
          'covered: ${ContractWireHarness.coverage}',
    );
  });
}
