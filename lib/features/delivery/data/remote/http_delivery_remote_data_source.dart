import 'package:dio/dio.dart';

import '../../../../core/backend_configuration/driver_api_paths.dart';
import '../../../../core/network/remote_error_mapper.dart';
import '../../../../core/network/saeq_api_client.dart';
import '../../domain/failures/delivery_failure.dart';
import '../datasources/delivery_remote_data_source.dart';
import '../models/delivery_assignment_model.dart';
import '../models/delivery_offer_model.dart';
import '../models/delivery_order_model.dart';
import '../models/offer_summary_wire.dart';

/// HTTP [DeliveryRemoteDataSource] against contracts-v0.1.0 (STEP 5C-2).
final class HttpDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  HttpDeliveryRemoteDataSource({
    required this._api,
    RemoteErrorMapper? errorMapper,
  }) : _errorMapper = errorMapper ?? const RemoteErrorMapper();

  final SaeqApiClient _api;
  final RemoteErrorMapper _errorMapper;

  final Map<String, DeliveryOfferModel> _offerCache = {};

  @override
  Future<List<DeliveryOfferModel>> fetchOffers({
    required String driverId,
  }) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        DriverApiPaths.offers,
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        if (raw is! Map) {
          throw const FormatException('offers page is not an object');
        }
      }
      final page = Map<String, dynamic>.from(raw as Map);
      final items = page['items'];
      if (items is! List) {
        throw const FormatException('offers.items missing');
      }
      final offers = items
          .map((e) {
            final wire = OfferSummaryWire.fromJson(
              Map<String, dynamic>.from(e as Map),
            );
            final model = wire.toDeliveryOfferModel(driverId: driverId);
            _offerCache[model.offerId] = model;
            return model;
          })
          .toList(growable: false);
      return offers;
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Stream<DeliveryOfferModel?> watchActiveOffer({required String driverId}) {
    // STEP 6 Realtime is locked — no polling/SSE/WebSocket here.
    return const Stream<DeliveryOfferModel?>.empty();
  }

  @override
  Future<DeliveryAssignmentModel> acceptOffer({
    required String driverId,
    required String offerId,
    required String idempotencyKey,
    String? revision,
    String? correlationId,
  }) async {
    try {
      final version = int.tryParse(revision ?? '') ?? 0;
      final response = await _api.post<Map<String, dynamic>>(
        DriverApiPaths.offerAccept(offerId),
        data: {'aggregateVersion': version},
        idempotencyKey: idempotencyKey,
      );
      final action = OfferActionResponseWire.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      final cached = _offerCache[offerId];
      return DeliveryAssignmentModel(
        assignmentId: action.deliveryId,
        offerId: action.offerId,
        driverId: driverId,
        status: action.state,
        order:
            cached?.order ??
            DeliveryOrderModel(
              orderId: action.deliveryId,
              pickupLabel: 'Pickup',
              dropoffLabel: 'Dropoff',
            ),
        acceptedAt: DateTime.now().toUtc(),
        serverRevision: '${action.aggregateVersion}',
        workflowStage: 'assigned',
        pendingSync: false,
      );
    } catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> rejectOffer({
    required String driverId,
    required String offerId,
    String? idempotencyKey,
    String? reasonCode,
    String? correlationId,
  }) async {
    try {
      final cached = _offerCache[offerId];
      final version = int.tryParse(cached?.revision ?? '') ?? 0;
      await _api.post<Map<String, dynamic>>(
        DriverApiPaths.offerReject(offerId),
        data: {'aggregateVersion': version, 'reasonCode': ?reasonCode},
        idempotencyKey: idempotencyKey ?? offerId,
      );
      _offerCache.remove(offerId);
    } catch (e) {
      throw _mapError(e);
    }
  }

  DeliveryFailure _mapError(Object error) {
    if (error is DeliveryFailure) return error;
    if (error is FormatException) {
      return const DeliveryPersistenceFailure();
    }
    if (error is DioException) {
      final envelope = _errorMapper.envelopeOf(error);
      switch (envelope?.code) {
        case 'OFFER_EXPIRED':
          return const DeliveryOfferExpired();
        case 'OFFER_ALREADY_ACCEPTED':
          return const DeliveryOfferTaken();
        case 'ACTIVE_ASSIGNMENT_CONFLICT':
          return const DeliveryConflict();
        case 'AGGREGATE_VERSION_CONFLICT':
        case 'IDEMPOTENCY_CONFLICT':
          return const DeliveryConflict();
        case 'UNAUTHORIZED':
        case 'TOKEN_EXPIRED':
        case 'TOKEN_REVOKED':
          return const DeliveryUnauthenticated();
      }
    }
    return const DeliveryUnknownFailure();
  }
}
