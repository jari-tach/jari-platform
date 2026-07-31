import '../../../../core/backend_configuration/driver_api_paths.dart';
import '../../../../core/network/saeq_api_client.dart';
import '../models/batch_summary_wire.dart';
import '../models/delivery_lifecycle_wire.dart';
import 'customer_contact_memory_cache.dart';

/// REST lifecycle operations for deliveries / batches / customer contact.
final class HttpDeliveryLifecycleRemote {
  HttpDeliveryLifecycleRemote({
    required this._api,
    required this._contactCache,
  });

  final SaeqApiClient _api;
  final CustomerContactMemoryCache _contactCache;

  CustomerContactMemoryCache get contactCache => _contactCache;

  Future<DeliveryMutationResponseWire?> getActiveDelivery() async {
    final response = await _api.get<dynamic>(DriverApiPaths.deliveriesActive);
    if (response.statusCode == 204 || response.data == null) return null;
    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('active delivery is not an object');
    }
    // Active may return full Delivery — normalize mutation-like fields via
    // the validating wire parser so malformed payloads surface as
    // FormatException (contract violation), never a silent unknown failure.
    return DeliveryMutationResponseWire.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }

  Future<DeliveryMutationResponseWire> confirmPickup({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? notes,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.deliveryPickupConfirmation(deliveryId),
      data: {'aggregateVersion': aggregateVersion, 'notes': ?notes},
      idempotencyKey: idempotencyKey,
    );
    return DeliveryMutationResponseWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<DeliveryMutationResponseWire> reportArrival({
    required String deliveryId,
    required String clientEventId,
    required String idempotencyKey,
    required DateTime capturedAt,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required String policyVersion,
    required int aggregateVersion,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.deliveryArrival(deliveryId),
      data: {
        'clientEventId': clientEventId,
        'source': 'deviceGeofence',
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'policyVersion': policyVersion,
        'aggregateVersion': aggregateVersion,
      },
      idempotencyKey: idempotencyKey,
    );
    return DeliveryMutationResponseWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<DeliveryMutationResponseWire> confirmDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.deliveryConfirmation(deliveryId),
      data: {'aggregateVersion': aggregateVersion},
      idempotencyKey: idempotencyKey,
    );
    final result = DeliveryMutationResponseWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    _contactCache.clearForDelivery(deliveryId);
    return result;
  }

  Future<DeliveryMutationResponseWire> cancelDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? reasonCode,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.deliveryCancel(deliveryId),
      data: {'aggregateVersion': aggregateVersion, 'reasonCode': ?reasonCode},
      idempotencyKey: idempotencyKey,
    );
    final result = DeliveryMutationResponseWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    _contactCache.clearForDelivery(deliveryId);
    return result;
  }

  Future<DeliveryMutationResponseWire> reportIssue({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required String code,
    String? notes,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      DriverApiPaths.deliveryIssues(deliveryId),
      data: {
        'aggregateVersion': aggregateVersion,
        'code': code,
        'notes': ?notes,
      },
      idempotencyKey: idempotencyKey,
    );
    return DeliveryMutationResponseWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// Loads customer contact only after pickup confirmation.
  Future<CustomerContactWire> fetchCustomerContact({
    required String deliveryId,
    required String deliveryState,
  }) async {
    const allowed = {
      'pickupConfirmedManually',
      'enRouteToCustomer',
      'arrivedAutomaticallyByLocation',
      'deliveryAwaitingManualConfirmation',
    };
    if (!allowed.contains(deliveryState)) {
      _contactCache.clearForDelivery(deliveryId);
      throw StateError(
        'Customer contact is not available before pickup confirmation.',
      );
    }
    final response = await _api.get<Map<String, dynamic>>(
      DriverApiPaths.deliveryCustomerContact(deliveryId),
    );
    final contact = CustomerContactWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    _contactCache.set(contact);
    return contact;
  }

  Future<BatchSummaryWire?> getActiveBatch() async {
    final response = await _api.get<dynamic>(DriverApiPaths.batchesActive);
    if (response.statusCode == 204 || response.data == null) return null;
    return BatchSummaryWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<BatchSummaryWire> getBatch(String batchId) async {
    final response = await _api.get<Map<String, dynamic>>(
      DriverApiPaths.batchById(batchId),
    );
    return BatchSummaryWire.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  void onLogoutOrSessionExpired() {
    _contactCache.clear();
  }
}
