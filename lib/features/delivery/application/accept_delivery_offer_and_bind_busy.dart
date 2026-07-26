import 'package:flutter/foundation.dart';

import '../../availability/domain/entities/authoritative_availability_update.dart';
import '../../availability/domain/entities/availability_status.dart';
import '../../availability/domain/entities/driver_availability.dart';
import '../../availability/domain/usecases/apply_authoritative_availability.dart';
import '../../availability/domain/usecases/get_driver_availability.dart';
import '../domain/entities/accept_delivery_offer_request.dart';
import '../domain/entities/delivery_assignment.dart';
import '../domain/entities/delivery_result.dart';
import '../domain/failures/delivery_failure.dart';
import '../domain/usecases/accept_delivery_offer.dart';

/// Cross-feature application coordinator for ADR-025.
///
/// Order (strict):
/// 1. [AcceptDeliveryOffer] — accept authority + local assignment persistence
/// 2. Authoritative availability → `busy` + `activeAssignmentId`
///
/// Domains stay independent: this layer depends on use cases only, never on
/// Delivery↔Availability repositories directly from each other.
///
/// Compensation (ADR-025 has no rollback rule): on busy-bind failure the
/// accepted assignment **remains** persisted; a typed
/// [DeliveryAvailabilityBindFailure] is returned.
class AcceptDeliveryOfferAndBindBusy {
  /// Creates the coordinator.
  AcceptDeliveryOfferAndBindBusy(
    this._acceptDeliveryOffer,
    this._applyAuthoritativeAvailability,
    this._getDriverAvailability, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AcceptDeliveryOffer _acceptDeliveryOffer;
  final ApplyAuthoritativeAvailability _applyAuthoritativeAvailability;
  final GetDriverAvailability _getDriverAvailability;
  final DateTime Function() _clock;

  int acceptCallCount = 0;
  int bindCallCount = 0;

  /// Accept + persist, then bind availability busy.
  Future<DeliveryResult<DeliveryAssignment>> call(
    AcceptDeliveryOfferRequest request,
  ) async {
    acceptCallCount++;
    if (kDebugMode) {
      debugPrint('DeliveryAcceptBind: accept started');
    }
    final acceptResult = await _acceptDeliveryOffer(request);
    if (acceptResult.isFailure) {
      if (kDebugMode) {
        debugPrint(
          'DeliveryAcceptBind: accept failed '
          '(${acceptResult.failureOrNull.runtimeType})',
        );
      }
      return acceptResult;
    }

    final assignment = acceptResult.valueOrNull;
    if (assignment == null) {
      return const DeliveryFailureResult(DeliveryUnknownFailure());
    }

    final bindResult = await bindBusyForAssignment(assignment);
    if (bindResult.isFailure) {
      if (kDebugMode) {
        debugPrint(
          'DeliveryAcceptBind: busy bind failed after accept '
          '(assignment retained)',
        );
      }
      final failure =
          bindResult.failureOrNull ??
          DeliveryAvailabilityBindFailure(
            'Delivery was accepted but availability could not be marked busy.',
            assignment,
          );
      // Ensure assignment is attached for presentation compensate-and-surface.
      if (failure is DeliveryAvailabilityBindFailure &&
          failure.assignment == null) {
        return DeliveryFailureResult(
          DeliveryAvailabilityBindFailure(failure.message, assignment),
        );
      }
      return DeliveryFailureResult(failure);
    }

    return DeliverySuccess(assignment);
  }

  /// Idempotent busy bind for an already-persisted assignment (accept path
  /// and restart/reconcile). Does **not** call accept again.
  Future<DeliveryResult<void>> bindBusyForAssignment(
    DeliveryAssignment assignment,
  ) async {
    bindCallCount++;

    final currentResult = await _getDriverAvailability();
    final current = currentResult.valueOrNull;
    if (_alreadyBoundToAssignment(current, assignment)) {
      if (kDebugMode) {
        debugPrint('DeliveryAcceptBind: busy already bound (idempotent)');
      }
      return DeliverySuccess.unit();
    }

    final update = AuthoritativeAvailabilityUpdate(
      driverId: assignment.driverId,
      status: AvailabilityStatus.busy,
      source: AvailabilitySource.system,
      confirmedAt: _clock().toUtc(),
      activeAssignmentId: assignment.assignmentId,
      reason: 'delivery.accept',
    );

    final applied = await _applyAuthoritativeAvailability(update);
    if (applied.isFailure) {
      if (kDebugMode) {
        debugPrint('DeliveryAcceptBind: apply busy failed');
      }
      return DeliveryFailureResult(
        DeliveryAvailabilityBindFailure(
          applied.failureOrNull?.message ??
              'Delivery was accepted but availability could not be marked busy.',
          assignment,
        ),
      );
    }

    if (kDebugMode) {
      debugPrint('DeliveryAcceptBind: busy bind succeeded');
    }
    return DeliverySuccess.unit();
  }

  static bool _alreadyBoundToAssignment(
    DriverAvailability? current,
    DeliveryAssignment assignment,
  ) {
    if (current == null) return false;
    return current.status == AvailabilityStatus.busy &&
        current.activeAssignmentId == assignment.assignmentId;
  }
}
