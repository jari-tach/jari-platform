import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/auth_session/access_token_memory_cache.dart';
import 'package:saeq_driver/core/network/saeq_api_client.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/features/delivery/data/remote/http_delivery_remote_data_source.dart';
import 'package:saeq_driver/features/delivery/domain/local_command_id.dart';

/// Regression tests for fix/delivery-idempotency-key-charset: local command
/// ids are sent as `Idempotency-Key` headers, so they must satisfy the
/// contract pattern `^[A-Za-z0-9._~-]{8,128}$` (the legacy
/// `local:driver:target:action` format was rejected by the backend).

final RegExp _contractPattern = RegExp(r'^[A-Za-z0-9._~-]{8,128}$');

const _driverId = 'e0fd2ff7-cc3c-47b0-bf59-0bcbe8b2518a';
const _offerId = '6306a6e1-fbaf-44b2-a74f-14f680e3008e';

class _SilentLogger implements LoggerService {
  @override
  LogLevel level = LogLevel.debug;

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {}
}

/// Captures the `Idempotency-Key` header and decoded JSON body of accept
/// requests exactly as they would go over the wire.
class _CapturingAcceptAdapter implements HttpClientAdapter {
  final List<String?> idempotencyKeys = [];
  final List<Map<String, dynamic>> bodies = [];
  final List<String> paths = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    idempotencyKeys.add(options.headers['Idempotency-Key'] as String?);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final raw = bytes.isNotEmpty ? utf8.decode(bytes) : jsonEncode(options.data);
    bodies.add(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    return ResponseBody.fromString(
      jsonEncode({
        'offerId': _offerId,
        'deliveryId': '11111111-1111-4111-8111-111111111111',
        'state': 'assigned',
        'aggregateVersion': 1,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('localCommandId contract charset', () {
    test('accept key contains no ":" and matches ^[A-Za-z0-9._~-]{8,128}\$',
        () {
      final key = localCommandId(
        driverId: _driverId,
        targetId: _offerId,
        action: 'accept',
      );
      expect(key.contains(':'), isFalse);
      expect(_contractPattern.hasMatch(key), isTrue, reason: 'got: $key');
      expect(key.length, inInclusiveRange(8, 128));
    });

    test('all delivery lifecycle actions produce contract-safe keys', () {
      const actions = [
        'accept',
        'reject',
        'confirmPickup',
        'reportArrival',
        'confirm-delivery',
        'cancel',
        'reportIssue',
        // Composite workflow-group action used by _advanceWithLedger.
        'geofenceArrival.arrivedCustomer',
      ];
      for (final action in actions) {
        final key = localCommandId(
          driverId: _driverId,
          targetId: _offerId,
          action: action,
        );
        expect(key.contains(':'), isFalse, reason: action);
        expect(
          _contractPattern.hasMatch(key),
          isTrue,
          reason: '$action → $key',
        );
      }
    });

    test('same inputs always produce the same key (retry reuse)', () {
      String next() => localCommandId(
        driverId: _driverId,
        targetId: _offerId,
        action: 'confirmPickup',
      );
      final first = next();
      expect(next(), first);
      expect(next(), first);
    });

    test('changing driverId changes the key', () {
      final a = localCommandId(
        driverId: _driverId,
        targetId: _offerId,
        action: 'accept',
      );
      final b = localCommandId(
        driverId: '11111111-1111-4111-8111-111111111111',
        targetId: _offerId,
        action: 'accept',
      );
      expect(a, isNot(b));
    });

    test('changing targetId changes the key', () {
      final a = localCommandId(
        driverId: _driverId,
        targetId: _offerId,
        action: 'accept',
      );
      final b = localCommandId(
        driverId: _driverId,
        targetId: '22222222-2222-4222-8222-222222222222',
        action: 'accept',
      );
      expect(a, isNot(b));
    });

    test('changing action changes the key', () {
      final a = localCommandId(
        driverId: _driverId,
        targetId: _offerId,
        action: 'accept',
      );
      final b = localCommandId(
        driverId: _driverId,
        targetId: _offerId,
        action: 'reject',
      );
      expect(a, isNot(b));
    });

    test('disallowed characters are escaped without collisions', () {
      final colon = localCommandId(
        driverId: 'drv-1',
        targetId: 'asg-1',
        action: 'group:step',
      );
      final dash = localCommandId(
        driverId: 'drv-1',
        targetId: 'asg-1',
        action: 'group-step',
      );
      expect(_contractPattern.hasMatch(colon), isTrue, reason: colon);
      expect(_contractPattern.hasMatch(dash), isTrue);
      // A naive replaceAll would map both inputs to the same key.
      expect(colon, isNot(dash));
    });

    test('over-long inputs stay within 128 chars, deterministic and unique',
        () {
      final longA = 'a' * 200;
      final longB = '${'a' * 199}b';
      String keyFor(String target) => localCommandId(
        driverId: _driverId,
        targetId: target,
        action: 'accept',
      );
      expect(keyFor(longA).length, lessThanOrEqualTo(128));
      expect(_contractPattern.hasMatch(keyFor(longA)), isTrue);
      expect(keyFor(longA), keyFor(longA));
      expect(keyFor(longA), isNot(keyFor(longB)));
    });
  });

  group('Idempotency-Key on the accept wire', () {
    test('header carries the contract-safe key and payload is unchanged',
        () async {
      final adapter = _CapturingAcceptAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:9'))
        ..httpClientAdapter = adapter;
      final cache = AccessTokenMemoryCache()..setAccessToken('test-access');
      final api = SaeqApiClient(
        baseUrl: 'http://127.0.0.1:9',
        accessTokenCache: cache,
        logger: _SilentLogger(),
        dio: dio,
        onUnauthorizedRefresh: () async => false,
      );
      final remote = HttpDeliveryRemoteDataSource(api: api);

      final key = localCommandId(
        driverId: _driverId,
        targetId: _offerId,
        action: 'accept',
      );
      await remote.acceptOffer(
        driverId: _driverId,
        offerId: _offerId,
        idempotencyKey: key,
        revision: '3',
      );
      // Retry with the same command id → same header value.
      await remote.acceptOffer(
        driverId: _driverId,
        offerId: _offerId,
        idempotencyKey: key,
        revision: '3',
      );

      expect(adapter.idempotencyKeys, hasLength(2));
      for (final sent in adapter.idempotencyKeys) {
        expect(sent, key);
        expect(_contractPattern.hasMatch(sent!), isTrue, reason: 'got: $sent');
        expect(sent.contains(':'), isFalse);
      }
      expect(adapter.idempotencyKeys[0], adapter.idempotencyKeys[1]);

      // Path and body are exactly the pre-fix contract shape.
      expect(adapter.paths.toSet(), {'/v1/offers/$_offerId/accept'});
      for (final body in adapter.bodies) {
        expect(body.keys.toSet(), {'aggregateVersion'});
        expect(body['aggregateVersion'], 3);
      }
    });
  });
}
