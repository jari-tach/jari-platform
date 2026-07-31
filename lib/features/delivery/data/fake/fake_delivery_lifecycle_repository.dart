import '../../domain/entities/batch_summary.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/entities/delivery_lifecycle_ack.dart';
import '../../domain/entities/delivery_result.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/repositories/delivery_lifecycle_repository.dart';

/// In-memory Fake lifecycle port for non-remote builds (STEP 5D-1).
///
/// Keeps Fake/Alpha journeys working without a Backend while still exercising
/// the same domain contracts the remote repository implements.
final class FakeDeliveryLifecycleRepository
    implements DeliveryLifecycleRepository {
  FakeDeliveryLifecycleRepository({
    DateTime Function()? clock,
    bool Function()? isProductionEnvironment,
  }) : _clock = clock ?? DateTime.now,
       _isProductionEnvironment = isProductionEnvironment ?? (() => false) {
    if (_isProductionEnvironment()) {
      throw StateError(
        'FakeDeliveryLifecycleRepository must not be used in production.',
      );
    }
  }

  final DateTime Function() _clock;
  final bool Function() _isProductionEnvironment;

  DeliveryLifecycleAck? _active;
  CustomerContact? _contact;
  BatchSummary? _batch;
  DeliveryFailure? nextFailure;

  /// Seeds an active delivery for Fake journeys/tests.
  void seedActive(DeliveryLifecycleAck ack) {
    _active = ack;
  }

  /// Seeds a Fake customer contact (memory-only).
  void seedContact(CustomerContact contact) {
    _contact = contact;
  }

  /// Seeds an active batch for Fake journeys/tests.
  void seedBatch(BatchSummary batch) {
    _batch = batch;
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck?>> getActiveDelivery() async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    return DeliverySuccess(_active);
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmPickup({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? notes,
  }) => _mutate(
    deliveryId: deliveryId,
    aggregateVersion: aggregateVersion,
    nextState: CanonicalDeliveryStates.pickupConfirmedManually,
  );

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> reportAutomaticArrival({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required ArrivalEvidence evidence,
  }) => _mutate(
    deliveryId: deliveryId,
    aggregateVersion: aggregateVersion,
    nextState: CanonicalDeliveryStates.arrivedAutomaticallyByLocation,
  );

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
  }) async {
    final result = await _mutate(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      nextState: CanonicalDeliveryStates.deliveredConfirmedManually,
    );
    if (result.isSuccess) clearCustomerContact(deliveryId: deliveryId);
    return result;
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> cancelDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? reasonCode,
  }) async {
    final result = await _mutate(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      nextState: CanonicalDeliveryStates.cancelled,
    );
    if (result.isSuccess) {
      clearCustomerContact(deliveryId: deliveryId);
      _active = null;
    }
    return result;
  }

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> reportIssue({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required String code,
    String? notes,
  }) => _mutate(
    deliveryId: deliveryId,
    aggregateVersion: aggregateVersion,
    nextState: _active?.state ?? CanonicalDeliveryStates.enRouteToCustomer,
  );

  @override
  Future<DeliveryResult<CustomerContact>> getCustomerContact({
    required String deliveryId,
    required String deliveryState,
  }) async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    if (!CanonicalDeliveryStates.contactAllowed.contains(deliveryState)) {
      clearCustomerContact(deliveryId: deliveryId);
      return const DeliveryFailureResult(DeliveryContactNotAvailable());
    }
    final contact = _contact;
    if (contact == null || contact.deliveryId != deliveryId) {
      return const DeliveryFailureResult(DeliveryContactNotAvailable());
    }
    return DeliverySuccess(contact);
  }

  @override
  CustomerContact? get cachedCustomerContact => _contact;

  @override
  void clearCustomerContact({String? deliveryId}) {
    if (deliveryId == null || _contact?.deliveryId == deliveryId) {
      _contact = null;
    }
  }

  @override
  Future<DeliveryResult<BatchSummary?>> getActiveBatch() async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    return DeliverySuccess(_batch);
  }

  @override
  Future<DeliveryResult<BatchSummary>> getBatch(String batchId) async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    final batch = _batch;
    if (batch == null || batch.batchId != batchId) {
      return const DeliveryFailureResult(DeliveryAssignmentNotFound());
    }
    return DeliverySuccess(batch);
  }

  Future<DeliveryResult<DeliveryLifecycleAck>> _mutate({
    required String deliveryId,
    required int aggregateVersion,
    required String nextState,
  }) async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    final current = _active;
    if (current == null || current.deliveryId != deliveryId) {
      return const DeliveryFailureResult(DeliveryAssignmentNotFound());
    }
    if (current.aggregateVersion != aggregateVersion) {
      return const DeliveryFailureResult(DeliveryConflict());
    }
    final next = DeliveryLifecycleAck(
      deliveryId: deliveryId,
      state: nextState,
      aggregateVersion: aggregateVersion + 1,
      updatedAt: _clock().toUtc(),
    );
    _active = nextState == CanonicalDeliveryStates.cancelled ? null : next;
    return DeliverySuccess(next);
  }
}
