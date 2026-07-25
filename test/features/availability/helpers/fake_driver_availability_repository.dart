import 'dart:async';

import 'package:saeq_driver/features/availability/domain/entities/authoritative_availability_update.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_change_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_reconciliation_request.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_result.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/entities/logout_availability_request.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/repositories/driver_availability_repository.dart';

/// In-memory [DriverAvailabilityRepository] for tests only.
///
/// Not for production. No environment flags. No release fake path.
class FakeDriverAvailabilityRepository implements DriverAvailabilityRepository {
  FakeDriverAvailabilityRepository({DriverAvailability? seed}) : _state = seed {
    if (seed != null) {
      _controller.add(seed);
    }
  }

  DriverAvailability? _state;
  AvailabilityFailure? nextFailure;
  AvailabilityFailure? nextRequestFailure;
  AvailabilityFailure? nextRestoreFailure;
  AvailabilityFailure? nextReconcileFailure;
  AvailabilityFailure? nextLogoutFailure;
  AvailabilityFailure? nextAuthoritativeFailure;

  final List<AvailabilityChangeRequest> changeRequests = [];
  final List<AvailabilityReconciliationRequest> reconcileRequests = [];
  final List<LogoutAvailabilityRequest> logoutRequests = [];
  final List<AuthoritativeAvailabilityUpdate> authoritativeUpdates = [];
  int getCurrentCallCount = 0;
  int restoreCallCount = 0;
  int requestCallCount = 0;

  final _controller = StreamController<DriverAvailability>.broadcast();

  DriverAvailability? get state => _state;

  void seed(DriverAvailability value) {
    _state = value;
    _controller.add(value);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Future<AvailabilityResult<DriverAvailability>>
  getCurrentAvailability() async {
    getCurrentCallCount++;
    if (nextFailure != null) {
      return AvailabilityFailureResult(nextFailure!);
    }
    final current = _state;
    if (current == null) {
      return const AvailabilityFailureResult(AvailabilityUnknownFailure());
    }
    return AvailabilitySuccess(current);
  }

  @override
  Stream<DriverAvailability> watchAvailability() => _controller.stream;

  @override
  Future<AvailabilityResult<DriverAvailability>> requestAvailabilityChange(
    AvailabilityChangeRequest request,
  ) async {
    requestCallCount++;
    changeRequests.add(request);
    if (nextRequestFailure != null) {
      return AvailabilityFailureResult(nextRequestFailure!);
    }
    final current = _state;
    if (current == null) {
      return const AvailabilityFailureResult(AvailabilityUnknownFailure());
    }
    final next = DriverAvailability(
      driverId: current.driverId,
      status: request.requestedStatus,
      source: request.actor == AvailabilityActor.driver
          ? AvailabilitySource.localUserAction
          : request.actor == AvailabilityActor.connectivity
          ? AvailabilitySource.connectivityPolicy
          : request.actor == AvailabilityActor.backend
          ? AvailabilitySource.server
          : AvailabilitySource.system,
      lastChangedAt: request.requestedAt,
      lastConfirmedAt:
          request.requestedStatus == AvailabilityStatus.available &&
              request.connectivityOnline
          ? request.requestedAt
          : null,
      pendingSync: request.requestedStatus == AvailabilityStatus.available
          ? false
          : current.pendingSync,
      revision: current.revision,
      reason: request.reason,
      activeAssignmentId: request.requestedStatus == AvailabilityStatus.busy
          ? current.activeAssignmentId
          : null,
    );
    seed(next);
    return AvailabilitySuccess(next);
  }

  @override
  Future<AvailabilityResult<DriverAvailability>>
  restoreLocalAvailability() async {
    restoreCallCount++;
    if (nextRestoreFailure != null) {
      return AvailabilityFailureResult(nextRestoreFailure!);
    }
    final current = _state;
    if (current == null) {
      return const AvailabilityFailureResult(AvailabilityUnknownFailure());
    }
    // Restore never marks available as authoritative confirmation.
    final restored = DriverAvailability(
      driverId: current.driverId,
      status: current.status == AvailabilityStatus.available
          ? AvailabilityStatus.available
          : current.status,
      source: AvailabilitySource.restoredLocalState,
      lastChangedAt: current.lastChangedAt,
      lastConfirmedAt: null,
      pendingSync: current.status == AvailabilityStatus.available,
      revision: current.revision,
      reason: current.reason,
      activeAssignmentId: current.status == AvailabilityStatus.busy
          ? current.activeAssignmentId
          : null,
    );
    seed(restored);
    return AvailabilitySuccess(restored);
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> reconcileAvailability(
    AvailabilityReconciliationRequest request,
  ) async {
    reconcileRequests.add(request);
    if (nextReconcileFailure != null) {
      return AvailabilityFailureResult(nextReconcileFailure!);
    }
    final current = _state;
    if (current == null) {
      return const AvailabilityFailureResult(AvailabilityUnknownFailure());
    }
    // Contract stub: preserve current; backend-over-local left to apply path.
    return AvailabilitySuccess(current);
  }

  @override
  Future<AvailabilityResult<void>> clearAvailabilityOnLogout(
    LogoutAvailabilityRequest request,
  ) async {
    logoutRequests.add(request);
    if (nextLogoutFailure != null) {
      return AvailabilityFailureResult<void>(nextLogoutFailure!);
    }
    final current = _state;
    if (current == null) {
      return AvailabilitySuccess.unit();
    }
    final cleared = DriverAvailability(
      driverId: current.driverId,
      status: AvailabilityStatus.unavailable,
      source: AvailabilitySource.system,
      lastChangedAt: request.logoutAt,
      lastConfirmedAt: null,
      pendingSync: false,
      revision: current.revision,
      reason: 'logout',
    );
    seed(cleared);
    return AvailabilitySuccess.unit();
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> applyAuthoritativeAvailability(
    AuthoritativeAvailabilityUpdate update,
  ) async {
    authoritativeUpdates.add(update);
    if (nextAuthoritativeFailure != null) {
      return AvailabilityFailureResult(nextAuthoritativeFailure!);
    }
    final next = DriverAvailability(
      driverId: update.driverId,
      status: update.status,
      source: update.source,
      lastChangedAt: update.confirmedAt,
      lastConfirmedAt: update.status == AvailabilityStatus.available
          ? update.confirmedAt
          : null,
      pendingSync: false,
      revision: update.revision,
      reason: update.reason,
      activeAssignmentId: update.status == AvailabilityStatus.busy
          ? update.activeAssignmentId
          : null,
    );
    seed(next);
    return AvailabilitySuccess(next);
  }
}
