import 'dart:async';

import 'package:saeq_driver/features/delivery/data/datasources/delivery_remote_data_source.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_offer_model.dart';

/// Recording remote datasource for repository tests only.
class RecordingDeliveryRemoteDataSource implements DeliveryRemoteDataSource {
  List<DeliveryOfferModel> offers = [];
  DeliveryAssignmentModel? acceptResult;
  Object? throwOnFetch;
  Object? throwOnAccept;
  Object? throwOnReject;

  int fetchCount = 0;
  int acceptCount = 0;
  int rejectCount = 0;

  String? lastFetchDriverId;
  String? lastAcceptOfferId;
  String? lastAcceptIdempotencyKey;
  String? lastRejectOfferId;

  final _activeController = StreamController<DeliveryOfferModel?>.broadcast();

  void emitActive(DeliveryOfferModel? model) => _activeController.add(model);

  void dispose() {
    _activeController.close();
  }

  @override
  Future<List<DeliveryOfferModel>> fetchOffers({
    required String driverId,
  }) async {
    fetchCount++;
    lastFetchDriverId = driverId;
    if (throwOnFetch != null) {
      throw throwOnFetch!;
    }
    return List<DeliveryOfferModel>.from(offers);
  }

  @override
  Stream<DeliveryOfferModel?> watchActiveOffer({required String driverId}) =>
      _activeController.stream;

  @override
  Future<DeliveryAssignmentModel> acceptOffer({
    required String driverId,
    required String offerId,
    required String idempotencyKey,
    String? revision,
    String? correlationId,
  }) async {
    acceptCount++;
    lastAcceptOfferId = offerId;
    lastAcceptIdempotencyKey = idempotencyKey;
    if (throwOnAccept != null) {
      throw throwOnAccept!;
    }
    final result = acceptResult;
    if (result == null) {
      throw StateError('acceptResult not configured');
    }
    return result;
  }

  @override
  Future<void> rejectOffer({
    required String driverId,
    required String offerId,
    String? idempotencyKey,
    String? reasonCode,
    String? correlationId,
  }) async {
    rejectCount++;
    lastRejectOfferId = offerId;
    if (throwOnReject != null) {
      throw throwOnReject!;
    }
  }
}
