import 'package:dio/dio.dart';

import '../../../../core/network/remote_error_classification.dart';
import '../../../../core/network/remote_error_mapper.dart';
import '../../domain/entities/batch_summary.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/entities/delivery_lifecycle_ack.dart';
import '../../domain/entities/delivery_result.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/repositories/delivery_lifecycle_repository.dart';
import '../models/batch_summary_wire.dart';
import '../models/delivery_lifecycle_wire.dart';
import '../remote/http_delivery_lifecycle_remote.dart';

/// [DeliveryLifecycleRepository] over the STEP 5C-3 REST layer.
///
/// Maps transport/contract errors to typed [DeliveryFailure]s and converts
/// wire DTOs to domain entities. Customer contact stays memory-only.
final class RemoteDeliveryLifecycleRepository
    implements DeliveryLifecycleRepository {
  RemoteDeliveryLifecycleRepository({
    required this._remote,
    RemoteErrorMapper? errorMapper,
  }) : _errorMapper = errorMapper ?? const RemoteErrorMapper();

  final HttpDeliveryLifecycleRemote _remote;
  final RemoteErrorMapper _errorMapper;

  @override
  Future<DeliveryResult<DeliveryLifecycleAck?>> getActiveDelivery() =>
      _guardNullable(() async {
        final wire = await _remote.getActiveDelivery();
        return wire == null ? null : _toAck(wire);
      });

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmPickup({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? notes,
  }) => _guard(() async {
    final wire = await _remote.confirmPickup(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
      notes: notes,
    );
    return _toAck(wire);
  });

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> reportAutomaticArrival({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required ArrivalEvidence evidence,
  }) => _guard(() async {
    final wire = await _remote.reportArrival(
      deliveryId: deliveryId,
      clientEventId: evidence.clientEventId,
      idempotencyKey: idempotencyKey,
      capturedAt: evidence.capturedAt,
      latitude: evidence.latitude,
      longitude: evidence.longitude,
      accuracyMeters: evidence.accuracyMeters,
      policyVersion: evidence.policyVersion,
      aggregateVersion: aggregateVersion,
    );
    return _toAck(wire);
  });

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> confirmDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
  }) => _guard(() async {
    final wire = await _remote.confirmDelivery(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
    );
    return _toAck(wire);
  });

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> cancelDelivery({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    String? reasonCode,
  }) => _guard(() async {
    final wire = await _remote.cancelDelivery(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
      reasonCode: reasonCode,
    );
    return _toAck(wire);
  });

  @override
  Future<DeliveryResult<DeliveryLifecycleAck>> reportIssue({
    required String deliveryId,
    required int aggregateVersion,
    required String idempotencyKey,
    required String code,
    String? notes,
  }) => _guard(() async {
    final wire = await _remote.reportIssue(
      deliveryId: deliveryId,
      aggregateVersion: aggregateVersion,
      idempotencyKey: idempotencyKey,
      code: code,
      notes: notes,
    );
    return _toAck(wire);
  });

  @override
  Future<DeliveryResult<CustomerContact>> getCustomerContact({
    required String deliveryId,
    required String deliveryState,
  }) async {
    if (!CanonicalDeliveryStates.contactAllowed.contains(deliveryState)) {
      _remote.contactCache.clearForDelivery(deliveryId);
      return const DeliveryFailureResult(DeliveryContactNotAvailable());
    }
    return _guard(() async {
      final wire = await _remote.fetchCustomerContact(
        deliveryId: deliveryId,
        deliveryState: deliveryState,
      );
      return _toContact(wire);
    });
  }

  @override
  CustomerContact? get cachedCustomerContact {
    final wire = _remote.contactCache.current;
    return wire == null ? null : _toContact(wire);
  }

  @override
  void clearCustomerContact({String? deliveryId}) {
    if (deliveryId == null) {
      _remote.contactCache.clear();
    } else {
      _remote.contactCache.clearForDelivery(deliveryId);
    }
  }

  @override
  Future<DeliveryResult<BatchSummary?>> getActiveBatch() =>
      _guardNullable(() async {
        final wire = await _remote.getActiveBatch();
        return wire == null ? null : _toBatch(wire);
      });

  @override
  Future<DeliveryResult<BatchSummary>> getBatch(String batchId) =>
      _guard(() async => _toBatch(await _remote.getBatch(batchId)));

  DeliveryLifecycleAck _toAck(DeliveryMutationResponseWire wire) =>
      DeliveryLifecycleAck(
        deliveryId: wire.deliveryId,
        state: wire.state,
        aggregateVersion: wire.aggregateVersion,
        updatedAt: wire.updatedAt.toUtc(),
      );

  CustomerContact _toContact(CustomerContactWire wire) => CustomerContact(
    deliveryId: wire.deliveryId,
    name: wire.name,
    phoneNumber: wire.phoneNumber,
    availableUntil: wire.availableUntil.toUtc(),
  );

  /// Upcoming-customer PII must never reach the domain (STEP 5C-3 rule).
  BatchSummary _toBatch(BatchSummaryWire wire) {
    if (wire.upcomingStopsHaveContactFields) {
      throw const DeliverySecurityPolicyDenied(
        'Batch payload exposed upcoming-customer contact fields.',
      );
    }
    return BatchSummary(
      batchId: wire.batchId,
      currentStopSequence: wire.currentStopSequence,
      aggregateVersion: wire.aggregateVersion,
      stops: wire.stops
          .map(
            (stop) => BatchStop(
              sequence: stop.sequence,
              deliveryId: stop.deliveryId,
              stopType: stop.stopType,
              label: stop.label,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<DeliveryResult<T>> _guard<T extends Object>(
    Future<T> Function() run,
  ) async {
    try {
      return DeliverySuccess(await run());
    } catch (error) {
      return DeliveryFailureResult(_mapError(error));
    }
  }

  Future<DeliveryResult<T?>> _guardNullable<T extends Object>(
    Future<T?> Function() run,
  ) async {
    try {
      return DeliverySuccess(await run());
    } catch (error) {
      return DeliveryFailureResult(_mapError(error));
    }
  }

  DeliveryFailure _mapError(Object error) {
    if (error is DeliveryFailure) return error;
    if (error is FormatException) return const DeliveryContractViolation();
    if (error is StateError) return const DeliveryContactNotAvailable();
    if (error is DioException) {
      final envelope = _errorMapper.envelopeOf(error);
      switch (envelope?.code) {
        case 'OFFER_EXPIRED':
          return const DeliveryOfferExpired();
        case 'OFFER_ALREADY_ACCEPTED':
          return const DeliveryOfferTaken();
        case 'ACTIVE_ASSIGNMENT_CONFLICT':
        case 'AGGREGATE_VERSION_CONFLICT':
        case 'IDEMPOTENCY_CONFLICT':
          return const DeliveryConflict();
        case 'INVALID_DELIVERY_TRANSITION':
          return const InvalidDeliveryWorkflowTransition();
        case 'CUSTOMER_CONTACT_NOT_AVAILABLE':
          return const DeliveryContactNotAvailable();
        case 'VALIDATION_ERROR':
          return const DeliveryValidationFailure();
        case 'RATE_LIMITED':
          return const DeliveryRateLimited();
        case 'UNAUTHORIZED':
        case 'TOKEN_EXPIRED':
        case 'TOKEN_REVOKED':
          return const DeliveryUnauthenticated();
        case 'FORBIDDEN':
          return const DeliverySecurityPolicyDenied();
      }
      switch (_errorMapper.classify(error)) {
        case RemoteErrorClassification.networkUnavailable:
          return const DeliveryNetworkUnavailable();
        case RemoteErrorClassification.requestTimeout:
        case RemoteErrorClassification.serverUnavailable:
          return const DeliveryBackendUnavailable();
        case RemoteErrorClassification.unauthorized:
        case RemoteErrorClassification.sessionExpired:
          return const DeliveryUnauthenticated();
        case RemoteErrorClassification.forbidden:
          return const DeliverySecurityPolicyDenied();
        case RemoteErrorClassification.conflict:
          return const DeliveryConflict();
        case RemoteErrorClassification.validation:
          return const DeliveryValidationFailure();
        case RemoteErrorClassification.rateLimited:
          return const DeliveryRateLimited();
        case RemoteErrorClassification.contractViolation:
          return const DeliveryContractViolation();
        case RemoteErrorClassification.notFound:
          return const DeliveryAssignmentNotFound();
        case RemoteErrorClassification.unknown:
          return const DeliveryUnknownFailure();
      }
    }
    return const DeliveryUnknownFailure();
  }
}
