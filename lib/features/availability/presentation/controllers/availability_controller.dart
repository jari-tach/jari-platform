import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/authoritative_availability_update.dart';
import '../../domain/entities/availability_change_request.dart';
import '../../domain/entities/availability_connectivity_change.dart';
import '../../domain/entities/availability_eligibility_input.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/entities/availability_status.dart';
import '../../domain/entities/driver_availability.dart';
import '../../domain/entities/logout_availability_request.dart';
import '../../domain/failures/availability_failure.dart';
import '../../domain/repositories/driver_availability_repository.dart';
import '../../domain/usecases/apply_authoritative_availability.dart';
import '../../domain/usecases/force_unavailable_on_logout.dart';
import '../../domain/usecases/get_driver_availability.dart';
import '../../domain/usecases/handle_connectivity_change.dart';
import '../../domain/usecases/request_availability_change.dart';
import '../../domain/usecases/restore_availability.dart';
import '../../domain/usecases/watch_driver_availability.dart';
import 'availability_controller_state.dart';

/// Resolves eligibility for [AvailabilityController.requestAvailable].
///
/// Production wiring must be deny-safe and must not fabricate profile facts.
typedef AvailabilityEligibilityReader =
    AvailabilityResult<AvailabilityEligibilityInput> Function(
      Ref ref,
      String driverId,
    );

/// Optional DEV-ONLY post-hook after a successful local →available request.
///
/// Returns an authoritative update for the controller to apply on itself.
/// Must NOT call [availabilityControllerProvider] (Riverpod self-dependency).
/// Used for Fake-backed device testing when no Backend confirmation exists.
/// Must be null in production wiring.
typedef AvailabilityDebugTrialConfirmer =
    Future<AuthoritativeAvailabilityUpdate?> Function(Ref ref, String driverId);

/// Coordinates availability use cases for the UI (PHASE 2.4 Increment 4).
///
/// Depends on domain use cases only — never SharedPreferences or datasources.
class AvailabilityController extends Notifier<AvailabilityControllerState> {
  AvailabilityController({
    DriverAvailabilityRepository? Function(Ref ref)? repositoryReader,
    AvailabilityEligibilityReader? eligibilityReader,
    this.debugTrialConfirmer,
  }) : _repositoryReader = repositoryReader ?? _defaultRepositoryReader,
       _eligibilityReader = eligibilityReader ?? _defaultEligibilityReader;

  final DriverAvailabilityRepository? Function(Ref ref) _repositoryReader;
  final AvailabilityEligibilityReader _eligibilityReader;

  /// DEV-ONLY Fake-trial confirmer; null outside debug device wiring.
  final AvailabilityDebugTrialConfirmer? debugTrialConfirmer;

  static DriverAvailabilityRepository? _defaultRepositoryReader(Ref ref) =>
      null;

  static AvailabilityResult<AvailabilityEligibilityInput>
  _defaultEligibilityReader(Ref ref, String driverId) {
    if (driverId.trim().isEmpty) {
      return const AvailabilityFailureResult(AvailabilityUnauthenticated());
    }
    return const AvailabilityFailureResult(
      DriverProfileMissing(
        'Authoritative availability eligibility is not available.',
      ),
    );
  }

  int _generation = 0;

  /// Monotonic token so only the latest connectivity reconciliation applies.
  int _connectivityEpoch = 0;
  bool _initializeStarted = false;
  bool _commandInFlight = false;
  StreamSubscription<DriverAvailability>? _watchSubscription;

  DriverAvailabilityRepository? get _repository => _repositoryReader(ref);

  @override
  AvailabilityControllerState build() {
    ref.onDispose(_disposeResources);
    if (!_initializeStarted) {
      _initializeStarted = true;
      Future.microtask(initialize);
    }
    return const AvailabilityControllerState.initial();
  }

  void _disposeResources() {
    _generation++;
    _connectivityEpoch++;
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _commandInFlight = false;
  }

  Future<void> initialize() async {
    final generation = ++_generation;
    await _cancelWatch();

    final repository = _repository;
    if (repository == null) {
      if (!_isCurrent(generation)) return;
      state = AvailabilityControllerState.failure(
        failure: const AvailabilityUnknownFailure(
          'Availability repository is unavailable.',
        ),
        isInitialized: false,
      );
      return;
    }

    state = AvailabilityControllerState.loading(
      boundDriverId: state.boundDriverId,
    );

    final restore = await RestoreAvailability(repository)();
    if (!_isCurrent(generation)) return;

    final restored = restore.valueOrNull;
    if (restored == null) {
      state = AvailabilityControllerState.failure(
        failure: restore.failureOrNull ?? const AvailabilityUnknownFailure(),
        current: state.lastStable,
        lastStable: state.lastStable,
        isInitialized: false,
        isRestored: false,
      );
      return;
    }

    final currentResult = await GetDriverAvailability(repository)();
    if (!_isCurrent(generation)) return;

    final current = currentResult.valueOrNull ?? restored;
    if (currentResult.isFailure && currentResult.valueOrNull == null) {
      state = AvailabilityControllerState.failure(
        failure:
            currentResult.failureOrNull ?? const AvailabilityUnknownFailure(),
        current: restored,
        lastStable: restored,
        isInitialized: true,
        isRestored: true,
        boundDriverId: restored.driverId,
      );
      await _subscribeWatch(repository, generation);
      return;
    }

    state = AvailabilityControllerState.ready(
      current: current,
      lastStable: current,
      isRestored: true,
      boundDriverId: current.driverId,
    );
    await _subscribeWatch(repository, generation);
  }

  Future<void> _subscribeWatch(
    DriverAvailabilityRepository repository,
    int generation,
  ) async {
    await _cancelWatch();
    if (!_isCurrent(generation)) return;

    _watchSubscription = WatchDriverAvailability(repository)().listen(
      (availability) {
        if (!_isCurrent(generation)) return;
        if (_commandInFlight) return;
        if (state.boundDriverId != null &&
            availability.driverId != state.boundDriverId) {
          return;
        }
        state = AvailabilityControllerState.ready(
          current: availability,
          lastStable: availability,
          isRestored: state.isRestored,
          boundDriverId: availability.driverId,
        );
      },
      onError: (_) {
        if (!_isCurrent(generation)) return;
        // Expected business denials stay typed via command paths; stream
        // errors become a non-destructive failure signal.
        state = AvailabilityControllerState.failure(
          failure: const AvailabilityUnknownFailure(),
          current: state.current,
          lastStable: state.lastStable,
          isInitialized: state.isInitialized,
          isRestored: state.isRestored,
          boundDriverId: state.boundDriverId,
        );
      },
    );
  }

  Future<void> _cancelWatch() async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  bool _isCurrent(int generation) => generation == _generation;

  Future<void> requestAvailable({
    AvailabilityEligibilityInput? eligibility,
  }) async {
    if (_commandInFlight) return;
    if (!state.isInitialized || state.current == null) {
      state = AvailabilityControllerState.failure(
        failure: const AvailabilityUnknownFailure(
          'Availability is not initialized.',
        ),
        current: state.current,
        lastStable: state.lastStable,
        isInitialized: state.isInitialized,
        isRestored: state.isRestored,
        boundDriverId: state.boundDriverId,
      );
      return;
    }
    if (state.isBusy) {
      _retainWithFailure(const ActiveAssignmentConflict());
      return;
    }
    if (state.isOffline) {
      _retainWithFailure(const AvailabilityOffline());
      return;
    }

    final repository = _repository;
    if (repository == null) {
      _retainWithFailure(const AvailabilityUnknownFailure());
      return;
    }

    final stable = state.current!;
    final AvailabilityEligibilityInput eligibilityInput;
    if (eligibility != null) {
      eligibilityInput = eligibility;
    } else {
      final eligibilityResult = _eligibilityReader(ref, stable.driverId);
      final resolved = eligibilityResult.valueOrNull;
      if (resolved == null) {
        _retainWithFailure(
          eligibilityResult.failureOrNull ??
              const DriverProfileMissing(
                'Authoritative availability eligibility is not available.',
              ),
        );
        return;
      }
      eligibilityInput = resolved;
    }

    final generation = _generation;
    _commandInFlight = true;
    state = AvailabilityControllerState.processing(
      current: stable,
      lastStable: state.lastStable ?? stable,
      isRestored: state.isRestored,
      boundDriverId: state.boundDriverId,
    );

    final result = await RequestAvailabilityChange(repository)(
      AvailabilityChangeRequest(
        driverId: stable.driverId,
        requestedStatus: AvailabilityStatus.available,
        actor: AvailabilityActor.driver,
        requestedAt: DateTime.now().toUtc(),
        correlationId: _correlationId('available'),
        eligibilityInput: eligibilityInput,
        connectivityOnline: eligibilityInput.connectivityAvailable,
        hasActiveAssignment: eligibilityInput.hasActiveAssignment,
      ),
    );

    if (!_isCurrent(generation)) {
      _commandInFlight = false;
      return;
    }
    _commandInFlight = false;
    _applyCommandResult(result, fallback: stable);

    // DEV-ONLY: Fake device testing has no Backend confirmation channel.
    // Confirmer returns an update; this notifier applies it (never re-enters
    // availabilityControllerProvider — that asserts dependency != origin).
    final confirmer = debugTrialConfirmer;
    if (result.isSuccess && confirmer != null) {
      final trialUpdate = await confirmer(ref, stable.driverId);
      if (trialUpdate != null && _isCurrent(generation)) {
        await applyAuthoritativeUpdate(trialUpdate);
      }
    }
  }

  Future<void> requestUnavailable() async {
    if (_commandInFlight) return;
    if (!state.isInitialized || state.current == null) {
      _retainWithFailure(
        const AvailabilityUnknownFailure('Availability is not initialized.'),
      );
      return;
    }
    if (state.isBusy) {
      _retainWithFailure(const ActiveAssignmentConflict());
      return;
    }

    final repository = _repository;
    if (repository == null) {
      _retainWithFailure(const AvailabilityUnknownFailure());
      return;
    }

    final generation = _generation;
    final stable = state.current!;
    _commandInFlight = true;
    state = AvailabilityControllerState.processing(
      current: stable,
      lastStable: state.lastStable ?? stable,
      isRestored: state.isRestored,
      boundDriverId: state.boundDriverId,
    );

    final result = await RequestAvailabilityChange(repository)(
      AvailabilityChangeRequest(
        driverId: stable.driverId,
        requestedStatus: AvailabilityStatus.unavailable,
        actor: AvailabilityActor.driver,
        requestedAt: DateTime.now().toUtc(),
        correlationId: _correlationId('unavailable'),
      ),
    );

    if (!_isCurrent(generation)) {
      _commandInFlight = false;
      return;
    }
    _commandInFlight = false;
    _applyCommandResult(result, fallback: stable);
  }

  Future<void> applyAuthoritativeUpdate(
    AuthoritativeAvailabilityUpdate update,
  ) async {
    if (_commandInFlight) return;
    final repository = _repository;
    if (repository == null) {
      _retainWithFailure(const AvailabilityUnknownFailure());
      return;
    }

    final generation = _generation;
    final stable = state.current;
    _commandInFlight = true;
    if (stable != null) {
      state = AvailabilityControllerState.processing(
        current: stable,
        lastStable: state.lastStable ?? stable,
        isRestored: state.isRestored,
        boundDriverId: state.boundDriverId,
      );
    }

    final result = await ApplyAuthoritativeAvailability(repository)(update);
    if (!_isCurrent(generation)) {
      _commandInFlight = false;
      return;
    }
    _commandInFlight = false;
    _applyCommandResult(result, fallback: stable);
  }

  Future<void> handleConnectivityChange(
    AvailabilityConnectivityChange change,
  ) async {
    final repository = _repository;
    if (repository == null) {
      _retainWithFailure(const AvailabilityUnknownFailure());
      return;
    }

    // Latest connectivity level wins — drop stale async completions.
    final epoch = ++_connectivityEpoch;
    final generation = _generation;
    final stable = state.current;
    final result = await HandleConnectivityChange(repository)(change);
    if (!_isCurrent(generation) || epoch != _connectivityEpoch) return;
    _applyCommandResult(result, fallback: stable);
  }

  Future<void> prepareForLogout() async {
    if (_commandInFlight) return;
    final repository = _repository;
    if (repository == null) {
      _retainWithFailure(const AvailabilityUnknownFailure());
      return;
    }

    final driverId = state.boundDriverId ?? state.current?.driverId;
    if (driverId == null || driverId.isEmpty) {
      _retainWithFailure(const AvailabilityUnauthenticated());
      return;
    }

    final generation = _generation;
    final stable = state.current;
    _commandInFlight = true;
    if (stable != null) {
      state = AvailabilityControllerState.processing(
        current: stable,
        lastStable: state.lastStable ?? stable,
        isRestored: state.isRestored,
        boundDriverId: state.boundDriverId,
      );
    }

    final result = await ForceUnavailableOnLogout(repository)(
      LogoutAvailabilityRequest(
        driverId: driverId,
        logoutAt: DateTime.now().toUtc(),
        connectivityOnline: true,
        correlationId: _correlationId('logout'),
      ),
    );

    if (!_isCurrent(generation)) {
      _commandInFlight = false;
      return;
    }
    _commandInFlight = false;

    if (result.isFailure) {
      state = AvailabilityControllerState.failure(
        failure: result.failureOrNull ?? const AvailabilityUnknownFailure(),
        current: stable,
        lastStable: state.lastStable ?? stable,
        isInitialized: state.isInitialized,
        isRestored: state.isRestored,
        boundDriverId: state.boundDriverId,
      );
      return;
    }

    await _cancelWatch();
    _generation++;
    state = const AvailabilityControllerState.initial();
  }

  void clearFailure() {
    if (state.status != AvailabilityViewStatus.failure) return;
    final current = state.current ?? state.lastStable;
    if (current == null) {
      state = const AvailabilityControllerState.initial();
      return;
    }
    state = AvailabilityControllerState.ready(
      current: current,
      lastStable: state.lastStable ?? current,
      isRestored: state.isRestored,
      boundDriverId: state.boundDriverId,
    );
  }

  void _applyCommandResult(
    AvailabilityResult<DriverAvailability> result, {
    required DriverAvailability? fallback,
  }) {
    final value = result.valueOrNull;
    if (value != null) {
      state = AvailabilityControllerState.ready(
        current: value,
        lastStable: value,
        isRestored: state.isRestored,
        boundDriverId: value.driverId,
      );
      return;
    }
    state = AvailabilityControllerState.failure(
      failure: result.failureOrNull ?? const AvailabilityUnknownFailure(),
      current: fallback,
      lastStable: state.lastStable ?? fallback,
      isInitialized: state.isInitialized,
      isRestored: state.isRestored,
      boundDriverId: state.boundDriverId ?? fallback?.driverId,
    );
  }

  void _retainWithFailure(AvailabilityFailure failure) {
    state = AvailabilityControllerState.failure(
      failure: failure,
      current: state.current,
      lastStable: state.lastStable ?? state.current,
      isInitialized: state.isInitialized,
      isRestored: state.isRestored,
      boundDriverId: state.boundDriverId,
    );
  }

  String _correlationId(String action) =>
      'avail-$action-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
