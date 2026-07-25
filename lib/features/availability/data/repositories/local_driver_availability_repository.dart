import 'dart:async';

import '../../domain/entities/authoritative_availability_update.dart';
import '../../domain/entities/availability_change_request.dart';
import '../../domain/entities/availability_reconciliation_request.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/entities/availability_status.dart';
import '../../domain/entities/driver_availability.dart';
import '../../domain/entities/logout_availability_request.dart';
import '../../domain/failures/availability_failure.dart';
import '../../domain/repositories/driver_availability_repository.dart';
import '../datasources/driver_availability_local_data_source.dart';
import '../models/persisted_driver_availability_record.dart';

/// Production local [DriverAvailabilityRepository] (PHASE 2.4 Increment 3).
///
/// Persists non-sovereign snapshots only. Never grants Backend authority from
/// restored or pending local state (ADR-016 / ADR-019).
class LocalDriverAvailabilityRepository
    implements DriverAvailabilityRepository {
  LocalDriverAvailabilityRepository({
    required DriverAvailabilityLocalDataSource localDataSource,
    required this.currentDriverIdReader,
  }) : _local = localDataSource;

  final DriverAvailabilityLocalDataSource _local;
  final String Function() currentDriverIdReader;
  final _controller = StreamController<DriverAvailability>.broadcast();
  DriverAvailability? _cached;

  void dispose() {
    _controller.close();
  }

  String _requireDriverId() {
    final id = currentDriverIdReader().trim();
    if (id.isEmpty) {
      throw const AvailabilityUnauthenticated();
    }
    return id;
  }

  DriverAvailability _defaultUnavailable(String driverId) {
    return DriverAvailability(
      driverId: driverId,
      status: AvailabilityStatus.unavailable,
      source: AvailabilitySource.system,
      lastChangedAt: DateTime.now().toUtc(),
    );
  }

  /// ADR-019 safe restore normalization.
  DriverAvailability _normalizeRestored(DriverAvailability raw) {
    switch (raw.status) {
      case AvailabilityStatus.available:
        return DriverAvailability(
          driverId: raw.driverId,
          status: AvailabilityStatus.available,
          source: AvailabilitySource.restoredLocalState,
          lastChangedAt: raw.lastChangedAt,
          lastConfirmedAt: null,
          pendingSync: true,
          revision: raw.revision,
          reason: raw.reason,
        );
      case AvailabilityStatus.busy:
        // Domain forbids busy+restoredLocalState; keep system/server ownership.
        return DriverAvailability(
          driverId: raw.driverId,
          status: AvailabilityStatus.busy,
          source:
              raw.source == AvailabilitySource.server ||
                  raw.source == AvailabilitySource.system
              ? raw.source
              : AvailabilitySource.system,
          lastChangedAt: raw.lastChangedAt,
          lastConfirmedAt: null,
          pendingSync: true,
          revision: raw.revision,
          reason: raw.reason,
          activeAssignmentId: raw.activeAssignmentId,
        );
      case AvailabilityStatus.offline:
      case AvailabilityStatus.unavailable:
        return DriverAvailability(
          driverId: raw.driverId,
          status: raw.status,
          source: AvailabilitySource.restoredLocalState,
          lastChangedAt: raw.lastChangedAt,
          lastConfirmedAt: null,
          pendingSync: raw.pendingSync,
          revision: raw.revision,
          reason: raw.reason,
        );
    }
  }

  Future<AvailabilityResult<DriverAvailability>> _loadBound({
    required bool normalizeAsRestore,
  }) async {
    try {
      final driverId = _requireDriverId();
      final record = await _local.read();
      if (record == null) {
        final fallback = _defaultUnavailable(driverId);
        _cacheEmit(fallback, force: _cached == null);
        return AvailabilitySuccess(fallback);
      }
      if (record.driverId != driverId) {
        await _local.clear();
        _cached = null;
        return const AvailabilityFailureResult(
          AvailabilitySecurityPolicyDenied(
            'Persisted availability driverId does not match current session.',
          ),
        );
      }

      DriverAvailability domain;
      try {
        domain = record.toDomain();
      } on ArgumentError {
        await _local.clear();
        return const AvailabilityFailureResult(
          AvailabilityPersistenceFailure(),
        );
      }

      final effective = normalizeAsRestore
          ? _normalizeRestored(domain)
          : _effectiveFromStored(domain);
      _cacheEmit(effective);
      return AvailabilitySuccess(effective);
    } on AvailabilityFailure catch (failure) {
      return AvailabilityFailureResult(failure);
    } on FormatException {
      try {
        await _local.clear();
      } catch (_) {}
      return const AvailabilityFailureResult(AvailabilityPersistenceFailure());
    } catch (_) {
      return const AvailabilityFailureResult(AvailabilityPersistenceFailure());
    }
  }

  /// For getCurrent: only server/system confirmed available stays confirmed.
  DriverAvailability _effectiveFromStored(DriverAvailability stored) {
    if (stored.status != AvailabilityStatus.available) {
      return stored;
    }
    final authoritativeConfirmed =
        !stored.pendingSync &&
        stored.lastConfirmedAt != null &&
        (stored.source == AvailabilitySource.server ||
            stored.source == AvailabilitySource.system);
    if (!authoritativeConfirmed) {
      return _normalizeRestored(stored);
    }
    return stored;
  }

  void _cacheEmit(DriverAvailability next, {bool force = false}) {
    if (!force && _cached == next) return;
    _cached = next;
    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  Future<AvailabilityResult<DriverAvailability>> _persist(
    DriverAvailability next,
  ) async {
    try {
      await _local.write(PersistedDriverAvailabilityRecord.fromDomain(next));
      _cacheEmit(next);
      return AvailabilitySuccess(next);
    } catch (_) {
      return const AvailabilityFailureResult(AvailabilityPersistenceFailure());
    }
  }

  bool _sameAuthoritativeState(
    DriverAvailability current,
    AuthoritativeAvailabilityUpdate update,
  ) {
    return current.driverId == update.driverId &&
        current.status == update.status &&
        current.source == update.source &&
        current.revision == update.revision &&
        current.activeAssignmentId == update.activeAssignmentId &&
        current.reason == update.reason &&
        !current.pendingSync &&
        (update.status != AvailabilityStatus.available ||
            current.lastConfirmedAt != null);
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> getCurrentAvailability() =>
      _loadBound(normalizeAsRestore: false);

  @override
  Stream<DriverAvailability> watchAvailability() async* {
    if (_cached != null) {
      yield _cached!;
    } else {
      final loaded = await getCurrentAvailability();
      final value = loaded.valueOrNull;
      if (value != null) yield value;
    }
    yield* _controller.stream;
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> requestAvailabilityChange(
    AvailabilityChangeRequest request,
  ) async {
    try {
      final driverId = _requireDriverId();
      if (request.driverId != driverId) {
        return const AvailabilityFailureResult(
          AvailabilitySecurityPolicyDenied(
            'Availability change driverId does not match current session.',
          ),
        );
      }
      if (request.actor == AvailabilityActor.driver &&
          request.requestedStatus == AvailabilityStatus.busy) {
        return const AvailabilityFailureResult(ManualBusyTransitionDenied());
      }

      final currentResult = await getCurrentAvailability();
      final current = currentResult.valueOrNull;
      if (current == null) {
        return AvailabilityFailureResult(
          currentResult.failureOrNull ?? const AvailabilityUnknownFailure(),
        );
      }

      if (current.status == request.requestedStatus) {
        return AvailabilitySuccess(current);
      }

      final source = switch (request.actor) {
        AvailabilityActor.driver => AvailabilitySource.localUserAction,
        AvailabilityActor.connectivity => AvailabilitySource.connectivityPolicy,
        AvailabilityActor.backend => AvailabilitySource.server,
        AvailabilityActor.system => AvailabilitySource.system,
      };

      final requestingAvailable =
          request.requestedStatus == AvailabilityStatus.available;

      final next = DriverAvailability(
        driverId: driverId,
        status: request.requestedStatus,
        source: source,
        lastChangedAt: request.requestedAt,
        // Local request never confirms available.
        lastConfirmedAt: null,
        pendingSync:
            requestingAvailable ||
            (request.requestedStatus == AvailabilityStatus.unavailable &&
                !request.connectivityOnline),
        revision: current.revision,
        reason: request.reason,
        activeAssignmentId: null,
      );

      return _persist(next);
    } on AvailabilityFailure catch (failure) {
      return AvailabilityFailureResult(failure);
    } catch (_) {
      return const AvailabilityFailureResult(AvailabilityPersistenceFailure());
    }
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> restoreLocalAvailability() =>
      _loadBound(normalizeAsRestore: true);

  @override
  Future<AvailabilityResult<DriverAvailability>> reconcileAvailability(
    AvailabilityReconciliationRequest request,
  ) async {
    try {
      final driverId = _requireDriverId();
      if (request.driverId != driverId) {
        return const AvailabilityFailureResult(
          AvailabilitySecurityPolicyDenied(
            'Reconciliation driverId does not match current session.',
          ),
        );
      }

      final currentResult = await getCurrentAvailability();
      final current = currentResult.valueOrNull;
      if (current == null) {
        return AvailabilityFailureResult(
          currentResult.failureOrNull ?? const AvailabilityUnknownFailure(),
        );
      }

      final local = request.localState;
      final known = request.lastKnownRevision;

      if (local != null && local.driverId != driverId) {
        return const AvailabilityFailureResult(
          AvailabilitySecurityPolicyDenied(
            'Reconciliation local state driverId mismatch.',
          ),
        );
      }

      // Authoritative persisted server revision wins over stale local intent.
      if (current.revision != null &&
          known != null &&
          known < current.revision! &&
          (current.source == AvailabilitySource.server ||
              current.source == AvailabilitySource.system)) {
        return AvailabilitySuccess(current);
      }

      if (current.revision != null &&
          known != null &&
          known == current.revision &&
          local != null &&
          (local.status != current.status ||
              local.activeAssignmentId != current.activeAssignmentId)) {
        return const AvailabilityFailureResult(AvailabilitySyncConflict());
      }

      if (current.revision != null &&
          known != null &&
          known > current.revision!) {
        // Newer remote revision referenced but no network payload here.
        return const AvailabilityFailureResult(AvailabilitySyncConflict());
      }

      // Preserve safe pending available intent; do not confirm.
      final safe = _effectiveFromStored(current);
      _cacheEmit(safe);
      return AvailabilitySuccess(safe);
    } on AvailabilityFailure catch (failure) {
      return AvailabilityFailureResult(failure);
    } catch (_) {
      return const AvailabilityFailureResult(AvailabilityPersistenceFailure());
    }
  }

  @override
  Future<AvailabilityResult<void>> clearAvailabilityOnLogout(
    LogoutAvailabilityRequest request,
  ) async {
    try {
      final driverId = _requireDriverId();
      if (request.driverId != driverId) {
        return const AvailabilityFailureResult(
          AvailabilitySecurityPolicyDenied(
            'Logout clear driverId does not match current session.',
          ),
        );
      }

      // Repository does not clear busy — use case blocks first; defense here.
      final current = _cached ?? (await getCurrentAvailability()).valueOrNull;
      if (current?.status == AvailabilityStatus.busy) {
        return const AvailabilityFailureResult(ActiveAssignmentConflict());
      }

      await _local.clear();
      final cleared = DriverAvailability(
        driverId: driverId,
        status: AvailabilityStatus.unavailable,
        source: AvailabilitySource.system,
        lastChangedAt: request.logoutAt,
        lastConfirmedAt: null,
        pendingSync: false,
      );
      _cacheEmit(cleared, force: true);
      return AvailabilitySuccess.unit();
    } on AvailabilityFailure catch (failure) {
      return AvailabilityFailureResult<void>(failure);
    } catch (_) {
      return const AvailabilityFailureResult(AvailabilityPersistenceFailure());
    }
  }

  @override
  Future<AvailabilityResult<DriverAvailability>> applyAuthoritativeAvailability(
    AuthoritativeAvailabilityUpdate update,
  ) async {
    try {
      final driverId = _requireDriverId();
      if (update.driverId != driverId) {
        return const AvailabilityFailureResult(
          AvailabilitySecurityPolicyDenied(
            'Authoritative update driverId does not match current session.',
          ),
        );
      }
      if (update.source == AvailabilitySource.localUserAction ||
          update.source == AvailabilitySource.restoredLocalState) {
        return const AvailabilityFailureResult(
          AvailabilitySecurityPolicyDenied(
            'Authoritative update cannot use local or restored source.',
          ),
        );
      }

      final currentResult = await getCurrentAvailability();
      final current = currentResult.valueOrNull;
      if (current == null) {
        return AvailabilityFailureResult(
          currentResult.failureOrNull ?? const AvailabilityUnknownFailure(),
        );
      }

      if (current.revision != null && update.revision != null) {
        if (update.revision! < current.revision!) {
          return const AvailabilityFailureResult(AvailabilityStateStale());
        }
        if (update.revision! == current.revision!) {
          if (_sameAuthoritativeState(current, update)) {
            return AvailabilitySuccess(current);
          }
          return const AvailabilityFailureResult(AvailabilitySyncConflict());
        }
      }

      final next = DriverAvailability(
        driverId: driverId,
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

      return _persist(next);
    } on AvailabilityFailure catch (failure) {
      return AvailabilityFailureResult(failure);
    } catch (_) {
      return const AvailabilityFailureResult(AvailabilityPersistenceFailure());
    }
  }
}
