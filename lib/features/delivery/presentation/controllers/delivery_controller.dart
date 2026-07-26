import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/accept_delivery_offer_and_bind_busy.dart';
import '../../domain/entities/accept_delivery_offer_request.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/entities/reject_delivery_offer_request.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/repositories/delivery_offer_repository.dart';
import '../../domain/usecases/accept_delivery_offer.dart';
import '../../domain/usecases/get_active_delivery.dart';
import '../../domain/usecases/get_delivery_offers.dart';
import '../../domain/usecases/reject_delivery_offer.dart';
import '../state/delivery_controller_state.dart';

/// Explicit accept preconditions — presentation must not invent eligibility.
class DeliveryAcceptPreconditions {
  const DeliveryAcceptPreconditions({
    required this.connectivityOnline,
    required this.isConfirmedAvailable,
  });

  final bool connectivityOnline;
  final bool isConfirmedAvailable;
}

/// Coordinates delivery use cases for the UI (PHASE 2.5 presentation).
///
/// Depends on domain/application use cases only — never datasources.
/// ADR-025 busy binding goes through [AcceptDeliveryOfferAndBindBusy].
class DeliveryController extends Notifier<DeliveryControllerState> {
  DeliveryController({
    GetDeliveryOffers? Function(Ref ref)? getOffersReader,
    AcceptDeliveryOffer? Function(Ref ref)? acceptReader,
    AcceptDeliveryOfferAndBindBusy? Function(Ref ref)? acceptAndBindReader,
    RejectDeliveryOffer? Function(Ref ref)? rejectReader,
    GetActiveDelivery? Function(Ref ref)? getActiveReader,
    DeliveryOfferRepository? Function(Ref ref)? offerRepositoryReader,
    String? Function(Ref ref)? driverIdReader,
    DeliveryAcceptPreconditions Function(Ref ref)? acceptPreconditionsReader,
    Future<void> Function(Ref ref)? availabilityRefreshReader,
  }) : _getOffersReader = getOffersReader ?? _defaultGetOffersReader,
       _acceptReader = acceptReader ?? _defaultAcceptReader,
       _acceptAndBindReader =
           acceptAndBindReader ?? _defaultAcceptAndBindReader,
       _rejectReader = rejectReader ?? _defaultRejectReader,
       _getActiveReader = getActiveReader ?? _defaultGetActiveReader,
       _offerRepositoryReader =
           offerRepositoryReader ?? _defaultOfferRepositoryReader,
       _driverIdReader = driverIdReader ?? _defaultDriverIdReader,
       _acceptPreconditionsReader =
           acceptPreconditionsReader ?? _defaultAcceptPreconditionsReader,
       _availabilityRefreshReader =
           availabilityRefreshReader ?? _defaultAvailabilityRefreshReader;

  final GetDeliveryOffers? Function(Ref ref) _getOffersReader;
  final AcceptDeliveryOffer? Function(Ref ref) _acceptReader;
  final AcceptDeliveryOfferAndBindBusy? Function(Ref ref) _acceptAndBindReader;
  final RejectDeliveryOffer? Function(Ref ref) _rejectReader;
  final GetActiveDelivery? Function(Ref ref) _getActiveReader;
  final DeliveryOfferRepository? Function(Ref ref) _offerRepositoryReader;
  final String? Function(Ref ref) _driverIdReader;
  final DeliveryAcceptPreconditions Function(Ref ref)
  _acceptPreconditionsReader;
  final Future<void> Function(Ref ref) _availabilityRefreshReader;

  static GetDeliveryOffers? _defaultGetOffersReader(Ref ref) => null;
  static AcceptDeliveryOffer? _defaultAcceptReader(Ref ref) => null;
  static AcceptDeliveryOfferAndBindBusy? _defaultAcceptAndBindReader(Ref ref) =>
      null;
  static RejectDeliveryOffer? _defaultRejectReader(Ref ref) => null;
  static GetActiveDelivery? _defaultGetActiveReader(Ref ref) => null;
  static DeliveryOfferRepository? _defaultOfferRepositoryReader(Ref ref) =>
      null;
  static String? _defaultDriverIdReader(Ref ref) => null;
  static DeliveryAcceptPreconditions _defaultAcceptPreconditionsReader(
    Ref ref,
  ) => const DeliveryAcceptPreconditions(
    connectivityOnline: false,
    isConfirmedAvailable: false,
  );
  static Future<void> _defaultAvailabilityRefreshReader(Ref ref) async {}

  int _generation = 0;
  bool _initializeStarted = false;
  bool _commandInFlight = false;
  StreamSubscription<DeliveryOffer?>? _watchSubscription;

  GetDeliveryOffers? get _getOffers => _getOffersReader(ref);
  AcceptDeliveryOffer? get _accept => _acceptReader(ref);
  AcceptDeliveryOfferAndBindBusy? get _acceptAndBind =>
      _acceptAndBindReader(ref);
  RejectDeliveryOffer? get _reject => _rejectReader(ref);
  GetActiveDelivery? get _getActive => _getActiveReader(ref);
  DeliveryOfferRepository? get _offerRepository => _offerRepositoryReader(ref);

  @override
  DeliveryControllerState build() {
    ref.onDispose(_disposeResources);
    if (!_initializeStarted) {
      _initializeStarted = true;
      Future.microtask(initialize);
    }
    return const DeliveryControllerState.initial();
  }

  void _disposeResources() {
    // Lifecycle boundary: invalidate all in-flight work and the offer watch.
    _generation++;
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _commandInFlight = false;
  }

  bool _isCurrent(int generation) => generation == _generation;

  Future<void> _cancelWatch() async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  /// Loads active assignment + offers and subscribes to the active-offer stream.
  ///
  /// Bumps [_generation] — this is a full watch-context replacement.
  Future<void> initialize() async {
    final generation = ++_generation;
    await _cancelWatch();

    final driverId = _driverIdReader(ref)?.trim();
    if (driverId == null || driverId.isEmpty) {
      if (!_isCurrent(generation)) return;
      state = DeliveryControllerState.failure(
        failure: DeliveryUnauthenticated(),
        isInitialized: false,
      );
      return;
    }

    final getOffers = _getOffers;
    final getActive = _getActive;
    if (getOffers == null && getActive == null) {
      if (!_isCurrent(generation)) return;
      state = DeliveryControllerState.failure(
        failure: DeliveryUnknownFailure('Delivery services are unavailable.'),
        isInitialized: false,
      );
      return;
    }

    state = DeliveryControllerState.loading(boundDriverId: driverId);

    DeliveryAssignment? assignment;
    if (getActive != null) {
      final activeResult = await getActive(driverId: driverId);
      if (!_isCurrent(generation)) return;
      if (activeResult.isFailure) {
        state = DeliveryControllerState.failure(
          failure: activeResult.failureOrNull ?? const DeliveryUnknownFailure(),
          isInitialized: false,
          boundDriverId: driverId,
        );
        return;
      }
      assignment = activeResult.valueOrNull;
    }

    List<DeliveryOffer> offers = const [];
    if (getOffers != null) {
      final offersResult = await getOffers(driverId: driverId);
      if (!_isCurrent(generation)) return;
      if (offersResult.isFailure) {
        state = DeliveryControllerState.failure(
          failure: offersResult.failureOrNull ?? const DeliveryUnknownFailure(),
          activeAssignment: assignment,
          isInitialized: true,
          boundDriverId: driverId,
        );
        await _subscribeWatch(driverId, generation);
        return;
      }
      offers = offersResult.valueOrNull ?? const [];
    } else if (!_isCurrent(generation)) {
      return;
    }

    // Local assignment is authoritative across process restarts (ADR-028).
    // Fake remote is in-memory and may auto-issue a competing offer on a
    // fresh process — never present it alongside an active assignment.
    if (assignment != null) {
      offers = const [];
    }

    // Restart / restore: bind busy for a persisted assignment (ADR-025).
    if (assignment != null) {
      final binder = _acceptAndBind;
      if (binder != null) {
        final bindResult = await binder.bindBusyForAssignment(assignment);
        if (!_isCurrent(generation)) return;
        if (bindResult.isFailure) {
          state = DeliveryControllerState.failure(
            failure:
                bindResult.failureOrNull ??
                DeliveryAvailabilityBindFailure(
                  'Delivery was accepted but availability could not be marked busy.',
                  assignment,
                ),
            offers: offers,
            activeAssignment: assignment,
            lastAcceptedAssignment: assignment,
            isInitialized: true,
            boundDriverId: driverId,
          );
          await _subscribeWatch(driverId, generation);
          await _availabilityRefreshReader(ref);
          return;
        }
        await _availabilityRefreshReader(ref);
      }
    }

    if (!_isCurrent(generation)) return;
    state = DeliveryControllerState.ready(
      offers: offers,
      activeAssignment: assignment,
      boundDriverId: driverId,
    );
    await _subscribeWatch(driverId, generation);
  }

  Future<void> _subscribeWatch(String driverId, int generation) async {
    await _cancelWatch();
    if (!_isCurrent(generation)) return;

    final repository = _offerRepository;
    if (repository == null) return;

    _watchSubscription = repository
        .watchActiveOffer(driverId: driverId)
        .listen(
          (offer) {
            if (!_isCurrent(generation)) return;
            if (_commandInFlight) return;
            if (state.boundDriverId != null &&
                offer != null &&
                offer.driverId != state.boundDriverId) {
              return;
            }
            final offers = (offer == null || state.activeAssignment != null)
                ? const <DeliveryOffer>[]
                : <DeliveryOffer>[offer];
            state = DeliveryControllerState.ready(
              offers: offers,
              activeOffer: state.activeAssignment != null ? null : offer,
              activeAssignment: state.activeAssignment,
              lastAcceptedAssignment: state.lastAcceptedAssignment,
              boundDriverId: state.boundDriverId ?? driverId,
            );
          },
          onError: (_) {
            if (!_isCurrent(generation)) return;
            state = DeliveryControllerState.failure(
              failure: const DeliveryUnknownFailure(),
              offers: state.offers,
              activeOffer: state.activeOffer,
              activeAssignment: state.activeAssignment,
              lastAcceptedAssignment: state.lastAcceptedAssignment,
              isInitialized: state.isInitialized,
              boundDriverId: state.boundDriverId,
            );
          },
        );
  }

  /// Reloads offers (and keeps the current active assignment).
  ///
  /// Does **not** bump [_generation] — the active offer watch stays alive.
  Future<void> refreshOffers() async {
    if (_commandInFlight || state.isLoading) return;

    final driverId = state.boundDriverId ?? _driverIdReader(ref)?.trim();
    if (driverId == null || driverId.isEmpty) {
      state = DeliveryControllerState.failure(
        failure: DeliveryUnauthenticated(),
        isInitialized: false,
      );
      return;
    }

    final getOffers = _getOffers;
    if (getOffers == null) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnknownFailure(
          'Delivery offer service is unavailable.',
        ),
        offers: state.offers,
        activeOffer: state.activeOffer,
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
      );
      return;
    }

    // Snapshot only — do not invalidate the offer watch.
    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.refreshing,
      offers: state.offers,
      activeOffer: state.activeOffer,
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
    );

    try {
      final result = await getOffers(driverId: driverId);
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
          offers: state.offers,
          activeOffer: state.activeOffer,
          activeAssignment: state.activeAssignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
        );
        return;
      }
      state = DeliveryControllerState.ready(
        offers: state.activeAssignment != null
            ? const []
            : (result.valueOrNull ?? const []),
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
      );
    } finally {
      if (_isCurrent(generation)) {
        _commandInFlight = false;
      }
    }
  }

  /// Reloads the locally persisted active assignment.
  Future<void> refreshActiveDelivery() async {
    if (_commandInFlight || state.isLoading) return;

    final driverId = state.boundDriverId ?? _driverIdReader(ref)?.trim();
    if (driverId == null || driverId.isEmpty) {
      state = DeliveryControllerState.failure(
        failure: DeliveryUnauthenticated(),
        isInitialized: false,
      );
      return;
    }

    final getActive = _getActive;
    if (getActive == null) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnknownFailure(
          'Active delivery service is unavailable.',
        ),
        offers: state.offers,
        activeOffer: state.activeOffer,
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
      );
      return;
    }

    // Snapshot only — do not invalidate the offer watch.
    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.refreshing,
      offers: state.offers,
      activeOffer: state.activeOffer,
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
    );

    try {
      final result = await getActive(driverId: driverId);
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
          offers: state.offers,
          activeOffer: state.activeOffer,
          activeAssignment: state.activeAssignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
        );
        return;
      }
      state = DeliveryControllerState.ready(
        offers: state.offers,
        activeOffer: state.activeOffer,
        activeAssignment: result.valueOrNull,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
      );
    } finally {
      if (_isCurrent(generation)) {
        _commandInFlight = false;
      }
    }
  }

  /// Accepts the current active offer.
  ///
  /// Does **not** bump [_generation] — the active offer watch stays alive.
  Future<void> acceptCurrentOffer() async {
    if (_commandInFlight || state.isLoading) return;
    if (!state.canAccept) return;

    final offer = state.activeOffer;
    final driverId = state.boundDriverId ?? offer?.driverId;
    if (offer == null || driverId == null || driverId.isEmpty) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryOfferNotFound(),
        offers: state.offers,
        activeAssignment: state.activeAssignment,
        boundDriverId: state.boundDriverId,
      );
      return;
    }

    final acceptAndBind = _acceptAndBind;
    final accept = _accept;
    if (acceptAndBind == null && accept == null) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnknownFailure(
          'Accept delivery service is unavailable.',
        ),
        offers: state.offers,
        activeOffer: offer,
        activeAssignment: state.activeAssignment,
        boundDriverId: driverId,
      );
      return;
    }

    final preconditions = _acceptPreconditionsReader(ref);
    // Snapshot only — do not invalidate the offer watch.
    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.accepting,
      offers: state.offers,
      activeOffer: offer,
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
    );

    try {
      final request = AcceptDeliveryOfferRequest(
        driverId: driverId,
        offerId: offer.offerId,
        idempotencyKey: _idempotencyKey(offer.offerId),
        connectivityOnline: preconditions.connectivityOnline,
        isConfirmedAvailable: preconditions.isConfirmedAvailable,
        revision: offer.revision,
        correlationId: offer.correlationId,
        hasActiveAssignment: state.activeAssignment != null,
      );

      final result = acceptAndBind != null
          ? await acceptAndBind(request)
          : await accept!(request);
      if (!_isCurrent(generation)) return;

      if (result.isFailure) {
        final failure = result.failureOrNull ?? const DeliveryUnknownFailure();
        final bindFailure = failure is DeliveryAvailabilityBindFailure
            ? failure
            : null;
        final preservedAssignment = bindFailure?.assignment;
        state = DeliveryControllerState.failure(
          failure: failure,
          offers: preservedAssignment != null ? const [] : state.offers,
          activeOffer: preservedAssignment != null ? null : offer,
          activeAssignment: preservedAssignment ?? state.activeAssignment,
          lastAcceptedAssignment:
              preservedAssignment ?? state.lastAcceptedAssignment,
          boundDriverId: driverId,
        );
        if (preservedAssignment != null) {
          await _availabilityRefreshReader(ref);
        }
        return;
      }

      final assignment = result.valueOrNull;
      state = DeliveryControllerState.ready(
        offers: const [],
        activeOffer: null,
        activeAssignment: assignment,
        lastAcceptedAssignment: assignment,
        boundDriverId: driverId,
      );
      await _availabilityRefreshReader(ref);
    } finally {
      if (_isCurrent(generation)) {
        _commandInFlight = false;
      }
    }
  }

  /// Rejects the current active offer.
  ///
  /// Does **not** bump [_generation] — the active offer watch stays alive.
  Future<void> rejectCurrentOffer({String? reasonCode}) async {
    if (_commandInFlight || state.isLoading) return;
    if (!state.canReject) return;

    final offer = state.activeOffer;
    final driverId = state.boundDriverId ?? offer?.driverId;
    if (offer == null || driverId == null || driverId.isEmpty) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryOfferNotFound(),
        offers: state.offers,
        activeAssignment: state.activeAssignment,
        boundDriverId: state.boundDriverId,
      );
      return;
    }

    final reject = _reject;
    if (reject == null) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnknownFailure(
          'Reject delivery service is unavailable.',
        ),
        offers: state.offers,
        activeOffer: offer,
        activeAssignment: state.activeAssignment,
        boundDriverId: driverId,
      );
      return;
    }

    final preconditions = _acceptPreconditionsReader(ref);
    // Snapshot only — do not invalidate the offer watch.
    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.rejecting,
      offers: state.offers,
      activeOffer: offer,
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
    );

    try {
      final result = await reject(
        RejectDeliveryOfferRequest(
          driverId: driverId,
          offerId: offer.offerId,
          reasonCode: reasonCode,
          correlationId: offer.correlationId,
          connectivityOnline: preconditions.connectivityOnline,
        ),
      );
      if (!_isCurrent(generation)) return;

      if (result.isFailure) {
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
          offers: state.offers,
          activeOffer: offer,
          activeAssignment: state.activeAssignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
        );
        return;
      }

      state = DeliveryControllerState.ready(
        offers: const [],
        activeOffer: null,
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
      );
    } finally {
      if (_isCurrent(generation)) {
        _commandInFlight = false;
      }
    }
  }

  /// Clears a non-destructive failure and returns to ready when possible.
  void clearFailure() {
    if (state.status != DeliveryViewStatus.failure) return;
    if (!state.isInitialized) {
      state = const DeliveryControllerState.initial();
      return;
    }
    state = DeliveryControllerState.ready(
      offers: state.offers,
      activeOffer: state.activeOffer,
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: state.boundDriverId,
    );
  }

  String _idempotencyKey(String offerId) =>
      'idem-${DateTime.now().toUtc().microsecondsSinceEpoch}-$offerId';
}
