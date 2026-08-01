import 'dart:async';

import '../../../../core/network/idempotency_key_factory.dart';
import '../../../../core/network/remote_error_classification.dart';
import '../../../../core/network/remote_error_mapper.dart';
import '../../domain/entities/authoritative_availability_update.dart';
import '../../domain/entities/availability_change_request.dart';
import '../../domain/entities/availability_reconciliation_request.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/entities/availability_status.dart';
import '../../domain/entities/driver_availability.dart';
import '../../domain/entities/logout_availability_request.dart';
import '../../domain/failures/availability_failure.dart';
import '../../domain/repositories/driver_availability_repository.dart';
import '../models/driver_availability_wire.dart';
import '../remote/driver_availability_remote_data_source.dart';

/// Backend-authoritative availability repository (STEP 5C-2).
final class RemoteDriverAvailabilityRepository
    implements DriverAvailabilityRepository {
  RemoteDriverAvailabilityRepository({
    required this._remote,
    required this._currentDriverIdReader,
    IdempotencyKeyFactory? idempotencyKeyFactory,
    RemoteErrorMapper? errorMapper,
  }) : _idempotencyKeys = idempotencyKeyFactory ?? IdempotencyKeyFactory(),
       _errorMapper = errorMapper ?? const RemoteErrorMapper();

  final DriverAvailabilityRemoteDataSource _remote;
  final String Function() _currentDriverIdReader;
  final IdempotencyKeyFactory _idempotencyKeys;
  final RemoteErrorMapper _errorMapper;

  DriverAvailability? _current;
  final _controller = StreamController<DriverAvailability>.broadcast();

  @override
  Future<AvailabilityResult<DriverAvailability>>
  getCurrentAvailability() async {
    try {
      final driverId = _requireDriverId();
      final wire = await _remote.getAvailability();
      final domain = wire.toDomain(driverId: driverId);
      _emit(domain);
      return AvailabilitySuccess(domain);
    } catch (e) {
      return AvailabilityFailureResult(_mapError(e));
    }
  }

  @override
  Stream<DriverAvailability> watchAvailability() => _controller.stream;

  @override
  Future<AvailabilityResult<DriverAvailability>> requestAvailabilityChange(
    AvailabilityChangeRequest request,
  ) async {
    try {
      final driverId = _requireDriverId();
      if (request.driverId != driverId) {
        return const AvailabilityFailureResult(AvailabilityUnauthenticated());
      }

      // Backend wire `offline` maps to domain unavailable (Issue #32). Do not
      // treat unavailable as suspended here — Backend rejects suspended drivers
      // on PUT /availability (mapped to DriverAccountSuspended below).

      if (request.requestedStatus == AvailabilityStatus.busy) {
        return const AvailabilityFailureResult(ManualBusyTransitionDenied());
      }

      final wireStatus = DriverAvailabilityWire.toWireStatus(
        request.requestedStatus,
      );
      if (wireStatus == null) {
        return const AvailabilityFailureResult(InvalidAvailabilityTransition());
      }

      if (!request.connectivityOnline &&
          request.requestedStatus == AvailabilityStatus.available) {
        final pending =
            (_current ??
                    DriverAvailability(
                      driverId: driverId,
                      status: AvailabilityStatus.offline,
                      source: AvailabilitySource.localUserAction,
                      lastChangedAt: request.requestedAt,
                    ))
                .copyWith(
                  status: AvailabilityStatus.available,
                  source: AvailabilitySource.localUserAction,
                  lastChangedAt: request.requestedAt,
                  pendingSync: true,
                  clearLastConfirmedAt: true,
                );
        _emit(pending);
        return AvailabilitySuccess(pending);
      }

      try {
        final wire = await _remote.putAvailability(
          status: wireStatus,
          idempotencyKey: _idempotencyKeys.next(),
        );
        final domain = wire.toDomain(driverId: driverId);
        _emit(domain);
        return AvailabilitySuccess(domain);
      } catch (e) {
        final classification = _errorMapper.classify(e);
        if (classification == RemoteErrorClassification.conflict ||
            classification == RemoteErrorClassification.forbidden) {
          final reloaded = await _remote.getAvailability();
          final domain = reloaded.toDomain(driverId: driverId);
          _emit(domain);
          return AvailabilityFailureResult(
            classification == RemoteErrorClassification.forbidden
                ? const DriverAccountSuspended()
                : const AvailabilitySyncConflict(),
          );
        }
        if (classification == RemoteErrorClassification.networkUnavailable ||
            classification == RemoteErrorClassification.requestTimeout) {
          final pending =
              (_current ??
                      DriverAvailability(
                        driverId: driverId,
                        status: AvailabilityStatus.offline,
                        source: AvailabilitySource.localUserAction,
                        lastChangedAt: request.requestedAt,
                      ))
                  .copyWith(
                    status: request.requestedStatus,
                    source: AvailabilitySource.localUserAction,
                    lastChangedAt: request.requestedAt,
                    pendingSync: true,
                    clearLastConfirmedAt: true,
                  );
          _emit(pending);
          return AvailabilitySuccess(pending);
        }
        return AvailabilityFailureResult(_mapError(e));
      }
    } catch (e) {
      return AvailabilityFailureResult(_mapError(e));
    }
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> restoreLocalAvailability() {
    return getCurrentAvailability();
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> reconcileAvailability(
    AvailabilityReconciliationRequest request,
  ) {
    return getCurrentAvailability();
  }

  @override
  Future<AvailabilityResult<void>> clearAvailabilityOnLogout(
    LogoutAvailabilityRequest request,
  ) async {
    _current = null;
    return AvailabilitySuccess.unit();
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> applyAuthoritativeAvailability(
    AuthoritativeAvailabilityUpdate update,
  ) async {
    final domain = DriverAvailability(
      driverId: update.driverId,
      status: update.status,
      source: AvailabilitySource.server,
      lastChangedAt: update.confirmedAt,
      lastConfirmedAt: update.confirmedAt,
      pendingSync: false,
      reason: update.reason,
      activeAssignmentId: update.activeAssignmentId,
      revision: update.revision,
    );
    _emit(domain);
    return AvailabilitySuccess(domain);
  }

  void dispose() {
    unawaited(_controller.close());
  }

  String _requireDriverId() {
    final id = _currentDriverIdReader().trim();
    if (id.isEmpty) {
      throw const AvailabilityUnauthenticated();
    }
    return id;
  }

  void _emit(DriverAvailability value) {
    _current = value;
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  AvailabilityFailure _mapError(Object error) {
    if (error is AvailabilityFailure) return error;
    if (error is FormatException) {
      return const AvailabilityUnknownFailure();
    }
    switch (_errorMapper.classify(error)) {
      case RemoteErrorClassification.unauthorized:
      case RemoteErrorClassification.sessionExpired:
        return const AvailabilityUnauthenticated();
      case RemoteErrorClassification.forbidden:
        return const DriverAccountSuspended();
      case RemoteErrorClassification.conflict:
        return const AvailabilitySyncConflict();
      case RemoteErrorClassification.networkUnavailable:
      case RemoteErrorClassification.requestTimeout:
        return const AvailabilityOffline();
      case RemoteErrorClassification.validation:
        return const InvalidAvailabilityTransition();
      case RemoteErrorClassification.serverUnavailable:
      case RemoteErrorClassification.rateLimited:
      case RemoteErrorClassification.notFound:
      case RemoteErrorClassification.contractViolation:
      case RemoteErrorClassification.unknown:
        return const AvailabilityUnknownFailure();
    }
  }
}
