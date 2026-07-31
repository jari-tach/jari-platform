import '../entities/batch_summary.dart';
import '../entities/customer_contact.dart';
import '../entities/delivery_lifecycle_ack.dart';
import '../entities/delivery_result.dart';

/// Backend-authoritative delivery lifecycle port (STEP 5D-1).
///
/// Implementations call the SAEQ REST API (contracts-v0.1.0) and map
/// transport errors to typed [DeliveryFailure]s. Presentation reaches this
/// only through use cases — never directly.
abstract interface class DeliveryLifecycleRepository {
  /// Reads the driver's active delivery, or `null` when none exists.
  Future<DeliveryResult<DeliveryLifecycleAck?>> getActiveDelivery();

  /// Manual pickup confirmation (idempotent via [idempotencyKey]).
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmPickup({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? notes,
  });

  /// Automatic geofence arrival report — never manual (ADR-029).
  Future<DeliveryResult<DeliveryLifecycleAck>> reportAutomaticArrival({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required ArrivalEvidence evidence,
  });

  /// Manual delivery confirmation. Clears the cached customer contact.
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
  });

  /// Cancels the delivery. Clears the cached customer contact.
  Future<DeliveryResult<DeliveryLifecycleAck>> cancelDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? reasonCode,
  });

  /// Reports a delivery issue without changing the lifecycle state.
  Future<DeliveryResult<DeliveryLifecycleAck>> reportIssue({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required String code,
    String? notes,
  });

  /// Loads the current customer contact — only allowed after Backend pickup
  /// acknowledgment ([CanonicalDeliveryStates.contactAllowed]).
  Future<DeliveryResult<CustomerContact>> getCustomerContact({
    required String deliveryId,
    required String deliveryState,
  });

  /// Memory-only cached contact, or `null` when hidden/cleared.
  CustomerContact? get cachedCustomerContact;

  /// Clears the memory-only contact (all, or one delivery when id given).
  void clearCustomerContact({String? deliveryId});

  /// Reads the driver's active batch, or `null` when none exists.
  Future<DeliveryResult<BatchSummary?>> getActiveBatch();

  /// Reads one batch by id.
  Future<DeliveryResult<BatchSummary>> getBatch(String batchId);
}
