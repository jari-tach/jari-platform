import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/auth_session/access_token_memory_cache.dart';
import 'package:saeq_driver/core/network/saeq_api_client.dart';
import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_order_model.dart';
import 'package:saeq_driver/features/delivery/data/remote/http_delivery_remote_data_source.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';

/// Regression for Device QA blocker after PR #31: Backend accept returns
/// `pickupAwaitingManualConfirmation`, which must map to local
/// [DeliveryStatus.accepted] so the assignment persists and Active Delivery
/// shows Confirm pickup.
const _driverId = 'e0fd2ff7-cc3c-47b0-bf59-0bcbe8b2518a';
const _offerId = '6306a6e1-fbaf-44b2-a74f-14f680e3008e';
const _deliveryId = '11111111-1111-4111-8111-111111111111';

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

class _AcceptAdapter implements HttpClientAdapter {
  _AcceptAdapter({required this.backendState});

  final String backendState;
  String? lastIdempotencyKey;
  Map<String, dynamic>? lastBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastIdempotencyKey = options.headers['Idempotency-Key'] as String?;
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final raw = bytes.isNotEmpty
        ? utf8.decode(bytes)
        : jsonEncode(options.data);
    lastBody = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return ResponseBody.fromString(
      jsonEncode({
        'offerId': _offerId,
        'deliveryId': _deliveryId,
        'state': backendState,
        'aggregateVersion': 2,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('deliveryStatusForCanonicalState', () {
    test('maps accept-commit Backend state to local accepted', () {
      expect(
        deliveryStatusForCanonicalState(
          CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
        ),
        DeliveryStatus.accepted,
      );
    });

    test('maps the full Backend lifecycle into the four local statuses', () {
      expect(
        deliveryStatusForCanonicalState(CanonicalDeliveryStates.offered),
        DeliveryStatus.accepted,
      );
      expect(
        deliveryStatusForCanonicalState(CanonicalDeliveryStates.accepted),
        DeliveryStatus.accepted,
      );
      expect(
        deliveryStatusForCanonicalState(
          CanonicalDeliveryStates.pickupConfirmedManually,
        ),
        DeliveryStatus.pickedUp,
      );
      expect(
        deliveryStatusForCanonicalState(
          CanonicalDeliveryStates.enRouteToCustomer,
        ),
        DeliveryStatus.pickedUp,
      );
      expect(
        deliveryStatusForCanonicalState(
          CanonicalDeliveryStates.arrivedAutomaticallyByLocation,
        ),
        DeliveryStatus.pickedUp,
      );
      expect(
        deliveryStatusForCanonicalState(
          CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
        ),
        DeliveryStatus.pickedUp,
      );
      expect(
        deliveryStatusForCanonicalState(
          CanonicalDeliveryStates.deliveredConfirmedManually,
        ),
        DeliveryStatus.delivered,
      );
      expect(
        deliveryStatusForCanonicalState(CanonicalDeliveryStates.cancelled),
        DeliveryStatus.cancelled,
      );
      expect(
        deliveryStatusForCanonicalState(CanonicalDeliveryStates.expired),
        DeliveryStatus.cancelled,
      );
      expect(
        deliveryStatusForCanonicalState(CanonicalDeliveryStates.rejected),
        DeliveryStatus.cancelled,
      );
    });

    test('still accepts legacy local enum names from Drift snapshots', () {
      for (final status in DeliveryStatus.values) {
        expect(deliveryStatusForCanonicalState(status.name), status);
      }
    });

    test('rejects unknown wire values', () {
      expect(
        () => deliveryStatusForCanonicalState('not-a-real-state'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('DeliveryAssignmentModel restore', () {
    test('toEntity accepts a canonical Backend state stored as status', () {
      final model = DeliveryAssignmentModel(
        assignmentId: _deliveryId,
        offerId: _offerId,
        driverId: _driverId,
        status: CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
        order: const DeliveryOrderModel(
          orderId: _deliveryId,
          pickupLabel: 'Pickup',
          dropoffLabel: 'Dropoff',
        ),
        acceptedAt: DateTime.utc(2026, 8, 1),
        workflowStage: 'assigned',
      );

      final entity = model.toEntity();
      expect(entity.status, DeliveryStatus.accepted);
      expect(entity.isActive, isTrue);
      expect(entity.workflowStage, DriverWorkflowStage.assigned);
    });
  });

  group('HttpDeliveryRemoteDataSource.acceptOffer status mapping', () {
    test(
      'Backend pickupAwaitingManualConfirmation becomes local accepted',
      () async {
        final adapter = _AcceptAdapter(
          backendState:
              CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
        );
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

        final model = await remote.acceptOffer(
          driverId: _driverId,
          offerId: _offerId,
          idempotencyKey: 'local_${_driverId}_${_offerId}_accept',
          revision: '1',
        );

        expect(model.status, DeliveryStatus.accepted.name);
        expect(model.toEntity().status, DeliveryStatus.accepted);
        expect(model.toEntity().isActive, isTrue);
        expect(model.assignmentId, _deliveryId);
        expect(model.offerId, _offerId);
        expect(model.driverId, _driverId);
        expect(model.serverRevision, '2');
        expect(model.workflowStage, 'assigned');
        // Request contract unchanged.
        expect(adapter.lastBody, {'aggregateVersion': 1});
        expect(
          adapter.lastIdempotencyKey,
          'local_${_driverId}_${_offerId}_accept',
        );
      },
    );

    test('unknown Backend state still fails loudly', () async {
      final adapter = _AcceptAdapter(backendState: 'totally-unknown');
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

      await expectLater(
        remote.acceptOffer(
          driverId: _driverId,
          offerId: _offerId,
          idempotencyKey: 'local_key_ok_length',
          revision: '1',
        ),
        throwsA(anything),
      );
    });
  });
}
