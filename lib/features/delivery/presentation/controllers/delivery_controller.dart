import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../location/data/fake_location_gateway.dart';
import '../../../location/domain/geo_point.dart';
import '../../../location/domain/geofence_policy.dart';
import '../../../location/domain/location_fix.dart';
import '../../../location/location_providers.dart';
import '../../application/accept_delivery_offer_and_bind_busy.dart';
import '../../application/complete_delivery_and_release_busy.dart';
import '../../domain/entities/accept_delivery_offer_request.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_lifecycle_ack.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/entities/delivery_result.dart';
import '../../domain/entities/driver_workflow_stage.dart';
import '../../domain/entities/local_delivery_command.dart';
import '../../domain/entities/reject_delivery_offer_request.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/local_command_id.dart';
import '../../domain/policies/driver_workflow_transition_policy.dart';
import '../../domain/repositories/delivery_offer_repository.dart';
import '../../domain/usecases/accept_delivery_offer.dart';
import '../../domain/usecases/advance_delivery_workflow.dart';
import '../../domain/usecases/cancel_delivery_remote.dart';
import '../../domain/usecases/confirm_delivery_remote.dart';
import '../../domain/usecases/confirm_pickup_remote.dart';
import '../../domain/usecases/get_active_batch.dart';
import '../../domain/usecases/get_active_delivery.dart';
import '../../domain/usecases/get_customer_contact.dart';
import '../../domain/usecases/get_delivery_offers.dart';
import '../../domain/usecases/reject_delivery_offer.dart';
import '../../domain/usecases/replay_pending_delivery_commands.dart';
import '../../domain/usecases/record_local_delivery_command.dart';
import '../../domain/usecases/report_automatic_arrival_remote.dart';
import '../../domain/usecases/report_delivery_issue_remote.dart';
import '../../domain/usecases/verify_delivery_code.dart';
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
    AdvanceDeliveryWorkflow? Function(Ref ref)? advanceWorkflowReader,
    VerifyDeliveryCode? Function(Ref ref)? verifyCodeReader,
    RecordLocalDeliveryCommand? Function(Ref ref)? recordLocalCommandReader,
    CompleteDeliveryAndReleaseBusy? Function(Ref ref)? completeDeliveryReader,
    DeliveryOfferRepository? Function(Ref ref)? offerRepositoryReader,
    String? Function(Ref ref)? driverIdReader,
    DeliveryAcceptPreconditions Function(Ref ref)? acceptPreconditionsReader,
    Future<void> Function(Ref ref)? availabilityRefreshReader,
    ConfirmPickupRemote? Function(Ref ref)? confirmPickupReader,
    ReportAutomaticArrivalRemote? Function(Ref ref)? reportArrivalReader,
    ConfirmDeliveryRemote? Function(Ref ref)? confirmDeliveryReader,
    CancelDeliveryRemote? Function(Ref ref)? cancelDeliveryReader,
    ReportDeliveryIssueRemote? Function(Ref ref)? reportIssueReader,
    GetCustomerContact? Function(Ref ref)? getCustomerContactReader,
    GetActiveBatch? Function(Ref ref)? getActiveBatchReader,
    ReplayPendingDeliveryCommands? Function(Ref ref)? replayPendingReader,
    void Function(Ref ref, {String? deliveryId})? clearCustomerContactReader,
  }) : _getOffersReader = getOffersReader ?? _defaultGetOffersReader,
       _acceptReader = acceptReader ?? _defaultAcceptReader,
       _acceptAndBindReader =
           acceptAndBindReader ?? _defaultAcceptAndBindReader,
       _rejectReader = rejectReader ?? _defaultRejectReader,
       _getActiveReader = getActiveReader ?? _defaultGetActiveReader,
       _advanceWorkflowReader =
           advanceWorkflowReader ?? _defaultAdvanceWorkflowReader,
       _verifyCodeReader = verifyCodeReader ?? _defaultVerifyCodeReader,
       _recordLocalCommandReader =
           recordLocalCommandReader ?? _defaultRecordLocalCommandReader,
       _completeDeliveryReader =
           completeDeliveryReader ?? _defaultCompleteDeliveryReader,
       _offerRepositoryReader =
           offerRepositoryReader ?? _defaultOfferRepositoryReader,
       _driverIdReader = driverIdReader ?? _defaultDriverIdReader,
       _acceptPreconditionsReader =
           acceptPreconditionsReader ?? _defaultAcceptPreconditionsReader,
       _availabilityRefreshReader =
           availabilityRefreshReader ?? _defaultAvailabilityRefreshReader,
       _confirmPickupReader =
           confirmPickupReader ?? _defaultConfirmPickupReader,
       _reportArrivalReader =
           reportArrivalReader ?? _defaultReportArrivalReader,
       _confirmDeliveryReader =
           confirmDeliveryReader ?? _defaultConfirmDeliveryReader,
       _cancelDeliveryReader =
           cancelDeliveryReader ?? _defaultCancelDeliveryReader,
       _reportIssueReader = reportIssueReader ?? _defaultReportIssueReader,
       _getCustomerContactReader =
           getCustomerContactReader ?? _defaultGetCustomerContactReader,
       _getActiveBatchReader =
           getActiveBatchReader ?? _defaultGetActiveBatchReader,
       _replayPendingReader =
           replayPendingReader ?? _defaultReplayPendingReader,
       _clearCustomerContactReader =
           clearCustomerContactReader ?? _defaultClearCustomerContactReader;

  final GetDeliveryOffers? Function(Ref ref) _getOffersReader;
  final AcceptDeliveryOffer? Function(Ref ref) _acceptReader;
  final AcceptDeliveryOfferAndBindBusy? Function(Ref ref) _acceptAndBindReader;
  final RejectDeliveryOffer? Function(Ref ref) _rejectReader;
  final GetActiveDelivery? Function(Ref ref) _getActiveReader;
  final AdvanceDeliveryWorkflow? Function(Ref ref) _advanceWorkflowReader;
  final VerifyDeliveryCode? Function(Ref ref) _verifyCodeReader;
  final RecordLocalDeliveryCommand? Function(Ref ref) _recordLocalCommandReader;
  final CompleteDeliveryAndReleaseBusy? Function(Ref ref)
  _completeDeliveryReader;
  final DeliveryOfferRepository? Function(Ref ref) _offerRepositoryReader;
  final String? Function(Ref ref) _driverIdReader;
  final DeliveryAcceptPreconditions Function(Ref ref)
  _acceptPreconditionsReader;
  final Future<void> Function(Ref ref) _availabilityRefreshReader;
  final ConfirmPickupRemote? Function(Ref ref) _confirmPickupReader;
  final ReportAutomaticArrivalRemote? Function(Ref ref) _reportArrivalReader;
  final ConfirmDeliveryRemote? Function(Ref ref) _confirmDeliveryReader;
  final CancelDeliveryRemote? Function(Ref ref) _cancelDeliveryReader;
  final ReportDeliveryIssueRemote? Function(Ref ref) _reportIssueReader;
  final GetCustomerContact? Function(Ref ref) _getCustomerContactReader;
  final GetActiveBatch? Function(Ref ref) _getActiveBatchReader;
  final ReplayPendingDeliveryCommands? Function(Ref ref) _replayPendingReader;
  final void Function(Ref ref, {String? deliveryId})
  _clearCustomerContactReader;

  static GetDeliveryOffers? _defaultGetOffersReader(Ref ref) => null;
  static AcceptDeliveryOffer? _defaultAcceptReader(Ref ref) => null;
  static AcceptDeliveryOfferAndBindBusy? _defaultAcceptAndBindReader(Ref ref) =>
      null;
  static RejectDeliveryOffer? _defaultRejectReader(Ref ref) => null;
  static GetActiveDelivery? _defaultGetActiveReader(Ref ref) => null;
  static AdvanceDeliveryWorkflow? _defaultAdvanceWorkflowReader(Ref ref) =>
      null;
  static VerifyDeliveryCode? _defaultVerifyCodeReader(Ref ref) => null;
  static RecordLocalDeliveryCommand? _defaultRecordLocalCommandReader(
    Ref ref,
  ) => null;
  static CompleteDeliveryAndReleaseBusy? _defaultCompleteDeliveryReader(
    Ref ref,
  ) => null;
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
  static ConfirmPickupRemote? _defaultConfirmPickupReader(Ref ref) => null;
  static ReportAutomaticArrivalRemote? _defaultReportArrivalReader(Ref ref) =>
      null;
  static ConfirmDeliveryRemote? _defaultConfirmDeliveryReader(Ref ref) => null;
  static CancelDeliveryRemote? _defaultCancelDeliveryReader(Ref ref) => null;
  static ReportDeliveryIssueRemote? _defaultReportIssueReader(Ref ref) => null;
  static GetCustomerContact? _defaultGetCustomerContactReader(Ref ref) => null;
  static GetActiveBatch? _defaultGetActiveBatchReader(Ref ref) => null;
  static ReplayPendingDeliveryCommands? _defaultReplayPendingReader(Ref ref) =>
      null;
  static void _defaultClearCustomerContactReader(
    Ref ref, {
    String? deliveryId,
  }) {}

  int _generation = 0;
  int _buildEpoch = 0;
  bool _commandInFlight = false;
  StreamSubscription<DeliveryOffer?>? _watchSubscription;
  StreamSubscription<LocationFix>? _arrivalSubscription;
  bool _arrivalInFlight = false;

  GetDeliveryOffers? get _getOffers => _getOffersReader(ref);
  AcceptDeliveryOffer? get _accept => _acceptReader(ref);
  AcceptDeliveryOfferAndBindBusy? get _acceptAndBind =>
      _acceptAndBindReader(ref);
  RejectDeliveryOffer? get _reject => _rejectReader(ref);
  GetActiveDelivery? get _getActive => _getActiveReader(ref);
  AdvanceDeliveryWorkflow? get _advanceWorkflow => _advanceWorkflowReader(ref);
  VerifyDeliveryCode? get _verifyCode => _verifyCodeReader(ref);
  RecordLocalDeliveryCommand? get _recordLocalCommand =>
      _recordLocalCommandReader(ref);
  CompleteDeliveryAndReleaseBusy? get _completeDelivery =>
      _completeDeliveryReader(ref);
  DeliveryOfferRepository? get _offerRepository => _offerRepositoryReader(ref);
  ConfirmPickupRemote? get _confirmPickupRemote => _confirmPickupReader(ref);
  ReportAutomaticArrivalRemote? get _reportArrivalRemote =>
      _reportArrivalReader(ref);
  ConfirmDeliveryRemote? get _confirmDeliveryRemote =>
      _confirmDeliveryReader(ref);
  CancelDeliveryRemote? get _cancelDeliveryRemote => _cancelDeliveryReader(ref);
  ReportDeliveryIssueRemote? get _reportIssueRemote => _reportIssueReader(ref);
  GetCustomerContact? get _getCustomerContact => _getCustomerContactReader(ref);
  GetActiveBatch? get _getActiveBatch => _getActiveBatchReader(ref);
  ReplayPendingDeliveryCommands? get _replayPending =>
      _replayPendingReader(ref);

  @override
  DeliveryControllerState build() {
    final buildEpoch = ++_buildEpoch;
    ref.onDispose(_disposeResources);
    Future.microtask(() async {
      // A newer rebuild owns initialization. Never use a Ref from an
      // invalidated provider lifecycle.
      if (buildEpoch != _buildEpoch || !ref.mounted) return;
      await initialize();
    });
    return const DeliveryControllerState.initial();
  }

  void _disposeResources() {
    // Lifecycle boundary: invalidate all in-flight work and the offer watch.
    _generation++;
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _arrivalSubscription?.cancel();
    _arrivalSubscription = null;
    _arrivalInFlight = false;
    _commandInFlight = false;
    // PII hygiene: memory-only customer contact must not outlive the
    // controller lifecycle (logout / provider teardown).
    try {
      _clearCustomerContactReader(ref);
    } catch (_) {
      // Disposal must never throw — registry may already be torn down.
    }
  }

  bool _isCurrent(int generation) => generation == _generation;

  Future<void> _cancelWatch() async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  Future<void> _cancelArrivalWatch() async {
    await _arrivalSubscription?.cancel();
    _arrivalSubscription = null;
  }

  /// Loads active assignment + offers and subscribes to the active-offer stream.
  ///
  /// Bumps [_generation] — this is a full watch-context replacement.
  Future<void> initialize() async {
    final generation = ++_generation;
    await _cancelWatch();
    // Drop any prior-generation geofence subscription before restore/resume.
    await _cancelArrivalWatch();

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
      isRestored: assignment != null,
    );
    await _subscribeWatch(driverId, generation);

    // Soft remote refresh — read-side failures must not fail initialize.
    if (assignment != null) {
      await _refreshCustomerContactSoft(
        driverId: driverId,
        generation: generation,
      );
      await _refreshActiveBatchSoft(generation);
      if (!_isCurrent(generation)) return;
      // Issue #38 RC-2: process restore must resume geofence watch while en
      // route to customer — otherwise automatic arrival never fires after
      // force-stop / cold start (Device QA session restore).
      // Require dropoff coordinates: without them `_watchCustomerArrivalAndAdvance`
      // fabricates arrival at (0,0), which races cancel/reportIssue and is not a
      // valid Device restore path (real orders carry dropoff coords).
      if (assignment.workflowStage == DriverWorkflowStage.navToCustomer &&
          assignment.order.hasDropoffCoordinates) {
        unawaited(
          _watchCustomerArrivalAndAdvance(
            driverId: driverId,
            assignment: assignment,
            generation: generation,
            simulateOffline: !_acceptPreconditionsReader(
              ref,
            ).connectivityOnline,
          ),
        );
      }
    }
  }

  /// Best-effort contact refresh; only mutates [DeliveryControllerState.customerContact].
  Future<void> _refreshCustomerContactSoft({
    required String driverId,
    required int generation,
  }) async {
    final getContact = _getCustomerContact;
    if (getContact == null) return;
    final result = await getContact(driverId: driverId);
    if (!_isCurrent(generation) || !ref.mounted) return;
    if (result.isFailure) {
      if (result.failureOrNull is DeliveryContactNotAvailable) {
        state = state.copyWith(clearCustomerContact: true);
      }
      return;
    }
    state = state.copyWith(customerContact: result.valueOrNull);
  }

  /// Best-effort batch refresh; only mutates [DeliveryControllerState.activeBatch].
  Future<void> _refreshActiveBatchSoft(int generation) async {
    final getBatch = _getActiveBatch;
    if (getBatch == null) return;
    final result = await getBatch();
    if (!_isCurrent(generation) || !ref.mounted) return;
    if (result.isFailure) return;
    final batch = result.valueOrNull;
    state = batch == null
        ? state.copyWith(clearActiveBatch: true)
        : state.copyWith(activeBatch: batch);
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
              customerContact: state.customerContact,
              activeBatch: state.activeBatch,
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
              customerContact: state.customerContact,
              activeBatch: state.activeBatch,
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
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
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
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
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
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
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
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
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
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
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
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
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
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }
      state = DeliveryControllerState.ready(
        offers: state.offers,
        activeOffer: state.activeOffer,
        activeAssignment: result.valueOrNull,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
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
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );

    try {
      final request = AcceptDeliveryOfferRequest(
        driverId: driverId,
        offerId: offer.offerId,
        idempotencyKey: _commandId(
          driverId: driverId,
          targetId: offer.offerId,
          action: 'accept',
        ),
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
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        if (preservedAssignment != null) {
          await _availabilityRefreshReader(ref);
        }
        return;
      }

      var assignment = result.valueOrNull;
      if (assignment != null && _advanceWorkflow != null) {
        final pickupReady = await _runWorkflowSequence(
          driverId: driverId,
          assignmentId: assignment.assignmentId,
          commands: const [
            DriverWorkflowCommand.startTripPickup,
            DriverWorkflowCommand.arrivedPickup,
            DriverWorkflowCommand.waitAtPickup,
          ],
          commandGroup: 'auto-pickup-arrival',
        );
        if (!_isCurrent(generation)) return;
        if (pickupReady.isFailure) {
          state = DeliveryControllerState.failure(
            failure:
                pickupReady.failureOrNull ?? const DeliveryUnknownFailure(),
            offers: const [],
            activeAssignment: assignment,
            lastAcceptedAssignment: assignment,
            boundDriverId: driverId,
            customerContact: state.customerContact,
            activeBatch: state.activeBatch,
          );
          return;
        }
        assignment = pickupReady.valueOrNull ?? assignment;
      }
      state = DeliveryControllerState.ready(
        offers: const [],
        activeOffer: null,
        activeAssignment: assignment,
        lastAcceptedAssignment: assignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
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
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );

    try {
      final result = await reject(
        RejectDeliveryOfferRequest(
          driverId: driverId,
          offerId: offer.offerId,
          idempotencyKey: _commandId(
            driverId: driverId,
            targetId: offer.offerId,
            action: 'reject',
          ),
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
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }

      state = DeliveryControllerState.ready(
        offers: const [],
        activeOffer: null,
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
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
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );
  }

  /// Advances the active assignment workflow (PHASE 2.6).
  ///
  /// Does **not** bump [_generation].
  Future<void> advanceWorkflow(
    DriverWorkflowCommand command, {
    bool? simulateOffline,
  }) async {
    if (_commandInFlight || state.isLoading) return;
    if (state.activeAssignment == null) return;

    final driverId =
        state.boundDriverId ?? state.activeAssignment!.driverId.trim();
    if (driverId.isEmpty) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnauthenticated(),
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: state.boundDriverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
      return;
    }

    final advance = _advanceWorkflow;
    final hasRemoteConfirmPickup =
        command == DriverWorkflowCommand.confirmPickup &&
        _confirmPickupRemote != null;
    if (advance == null && !hasRemoteConfirmPickup) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnknownFailure(
          'Delivery workflow service is unavailable.',
        ),
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
      return;
    }

    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.advancing,
      offers: state.offers,
      activeOffer: state.activeOffer,
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );

    try {
      final assignmentId = state.activeAssignment!.assignmentId;
      final offline =
          simulateOffline ??
          !_acceptPreconditionsReader(ref).connectivityOnline;

      // Remote mode (STEP 5D-1): confirmPickup goes to Backend first. The
      // local confirmPickup + startTripCustomer sequence is owned by the use
      // case — never run it here as well.
      final confirmPickupRemote = command == DriverWorkflowCommand.confirmPickup
          ? _confirmPickupRemote
          : null;
      if (confirmPickupRemote != null) {
        final result = await confirmPickupRemote(
          driverId: driverId,
          commandId: _commandId(
            driverId: driverId,
            targetId: assignmentId,
            action: 'confirmPickup',
            scope: state.activeAssignment?.serverRevision,
          ),
          connectivityOnline: !offline,
        );
        if (!_isCurrent(generation)) return;
        if (result.isFailure) {
          final failure =
              result.failureOrNull ?? const DeliveryUnknownFailure();
          final retryable =
              failure is DeliveryNetworkUnavailable ||
              failure is DeliveryBackendUnavailable;
          // Retryable Backend failures keep the assignment pending-sync so
          // the driver can replay with the same idempotency key.
          final assignment = retryable
              ? state.activeAssignment?.copyWith(pendingSync: true)
              : state.activeAssignment;
          state = DeliveryControllerState.failure(
            failure: failure,
            activeAssignment: assignment,
            lastAcceptedAssignment: state.lastAcceptedAssignment,
            boundDriverId: driverId,
            customerContact: state.customerContact,
            activeBatch: state.activeBatch,
          );
          return;
        }
        final assignment = result.valueOrNull;
        state = DeliveryControllerState.ready(
          offers: const [],
          activeAssignment: assignment,
          lastAcceptedAssignment: assignment ?? state.lastAcceptedAssignment,
          boundDriverId: driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        await _refreshCustomerContactSoft(
          driverId: driverId,
          generation: generation,
        );
        if (!_isCurrent(generation)) return;
        if (assignment != null) {
          unawaited(
            _watchCustomerArrivalAndAdvance(
              driverId: driverId,
              assignment: assignment,
              generation: generation,
              simulateOffline: offline,
            ),
          );
        }
        return;
      }

      final commands = switch (command) {
        DriverWorkflowCommand.startTripPickup => const [
          DriverWorkflowCommand.startTripPickup,
          DriverWorkflowCommand.arrivedPickup,
          DriverWorkflowCommand.waitAtPickup,
        ],
        // STEP 4: customer arrival is geofence-driven (ADR-029), not sequenced.
        DriverWorkflowCommand.confirmPickup => const [
          DriverWorkflowCommand.confirmPickup,
          DriverWorkflowCommand.startTripCustomer,
        ],
        _ => [command],
      };
      final result = await _runWorkflowSequence(
        driverId: driverId,
        assignmentId: assignmentId,
        commands: commands,
        commandGroup: command.name,
        simulateOffline: offline,
      );
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
          activeAssignment: state.activeAssignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }
      final assignment = result.valueOrNull;
      state = DeliveryControllerState.ready(
        offers: const [],
        activeAssignment: assignment,
        lastAcceptedAssignment: assignment ?? state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
      if (command == DriverWorkflowCommand.confirmPickup &&
          assignment != null) {
        unawaited(
          _watchCustomerArrivalAndAdvance(
            driverId: driverId,
            assignment: assignment,
            generation: generation,
            simulateOffline: offline,
          ),
        );
      }
    } finally {
      if (_isCurrent(generation)) {
        _commandInFlight = false;
      }
    }
  }

  /// Geofence-driven automatic customer arrival (no manual arrival button).
  Future<void> _watchCustomerArrivalAndAdvance({
    required String driverId,
    required DeliveryAssignment assignment,
    required int generation,
    required bool simulateOffline,
  }) async {
    if (_arrivalInFlight) return;
    await _cancelArrivalWatch();

    final order = assignment.order;
    Future<void> applyArrival(LocationFix? fix) async {
      if (!_isCurrent(generation) || _arrivalInFlight) {
        return;
      }
      _arrivalInFlight = true;
      try {
        final reportArrival = _reportArrivalRemote;
        if (reportArrival != null) {
          // Remote mode: Backend must acknowledge the automatic arrival
          // before any local stage advances (ADR-029 / STEP 5D-1).
          // Fake paths without coordinates synthesize zeroed evidence.
          final evidence = ArrivalEvidence(
            clientEventId: 'arrival:${assignment.assignmentId}',
            capturedAt: (fix?.recordedAt ?? DateTime.now()).toUtc(),
            latitude: fix?.point.latitude ?? 0,
            longitude: fix?.point.longitude ?? 0,
            accuracyMeters: fix?.accuracyMeters ?? 0,
            policyVersion: 'geofence-v1',
          );
          final result = await reportArrival(
            driverId: driverId,
            commandId: _commandId(
              driverId: driverId,
              targetId: assignment.assignmentId,
              action: 'reportArrival',
              scope: assignment.serverRevision,
            ),
            evidence: evidence,
            connectivityOnline: !simulateOffline,
          );
          if (!_isCurrent(generation)) return;
          if (result.isFailure) {
            final failure =
                result.failureOrNull ?? const DeliveryUnknownFailure();
            final retryable =
                failure is DeliveryNetworkUnavailable ||
                failure is DeliveryBackendUnavailable;
            // Stay locked on navToCustomer/pendingSync until Backend ack.
            final pending = retryable
                ? state.activeAssignment?.copyWith(pendingSync: true)
                : state.activeAssignment;
            state = DeliveryControllerState.failure(
              failure: failure,
              activeAssignment: pending,
              lastAcceptedAssignment: state.lastAcceptedAssignment,
              boundDriverId: driverId,
              customerContact: state.customerContact,
              activeBatch: state.activeBatch,
            );
            return;
          }
          final next = result.valueOrNull;
          state = DeliveryControllerState.ready(
            offers: const [],
            activeAssignment: next,
            lastAcceptedAssignment: next ?? state.lastAcceptedAssignment,
            boundDriverId: driverId,
            customerContact: state.customerContact,
            activeBatch: state.activeBatch,
          );
          await _refreshCustomerContactSoft(
            driverId: driverId,
            generation: generation,
          );
          return;
        }

        final result = await _runWorkflowSequence(
          driverId: driverId,
          assignmentId: assignment.assignmentId,
          commands: const [
            DriverWorkflowCommand.arrivedCustomer,
            DriverWorkflowCommand.startVerify,
          ],
          commandGroup: 'geofenceArrival',
          simulateOffline: simulateOffline,
        );
        if (!_isCurrent(generation)) return;
        if (result.isFailure) {
          state = DeliveryControllerState.failure(
            failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
            activeAssignment: state.activeAssignment,
            lastAcceptedAssignment: state.lastAcceptedAssignment,
            boundDriverId: driverId,
            customerContact: state.customerContact,
            activeBatch: state.activeBatch,
          );
          return;
        }
        final next = result.valueOrNull;
        state = DeliveryControllerState.ready(
          offers: const [],
          activeAssignment: next,
          lastAcceptedAssignment: next ?? state.lastAcceptedAssignment,
          boundDriverId: driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
      } finally {
        _arrivalInFlight = false;
      }
    }

    if (!order.hasDropoffCoordinates) {
      await applyArrival(null);
      return;
    }

    final target = GeoPoint(
      latitude: order.dropoffLatitude!,
      longitude: order.dropoffLongitude!,
    );
    final gateway = ref.read(locationGatewayProvider);
    if (gateway is FakeLocationGateway) {
      gateway.anchorPoint = target;
      gateway.clearFixes();
    }

    final policy = GeofencePolicy(
      debouncer: LocationFixDebouncer(
        requiredHits: 2,
        minInterval: const Duration(milliseconds: 50),
      ),
    );
    final interval = gateway is FakeLocationGateway
        ? const Duration(milliseconds: 50)
        : const Duration(seconds: 2);

    final done = Completer<void>();
    _arrivalSubscription = gateway
        .watchFixes(interval: interval)
        .listen(
          (fix) async {
            if (!_isCurrent(generation) || done.isCompleted) return;
            final evaluation = policy.evaluate(fix: fix, target: target);
            if (evaluation != GeofenceEvaluation.arrived) return;
            await _cancelArrivalWatch();
            await applyArrival(fix);
            if (!done.isCompleted) done.complete();
          },
          onError: (Object _, StackTrace _) async {
            await _cancelArrivalWatch();
            if (!done.isCompleted) done.complete();
          },
        );

    // Fake path should complete quickly; Device path returns after cancel/dispose.
    await done.future.timeout(
      gateway is FakeLocationGateway
          ? const Duration(seconds: 5)
          : const Duration(hours: 12),
      onTimeout: () {},
    );
  }

  Future<DeliveryResult<DeliveryAssignment>> _runWorkflowSequence({
    required String driverId,
    required String assignmentId,
    required List<DriverWorkflowCommand> commands,
    required String commandGroup,
    bool simulateOffline = false,
  }) async {
    final advance = _advanceWorkflow;
    if (advance == null) {
      return const DeliveryFailureResult(
        DeliveryUnknownFailure('Delivery workflow service is unavailable.'),
      );
    }

    DeliveryAssignment? assignment;
    for (final command in commands) {
      final result = await advance(
        driverId: driverId,
        command: command,
        commandId: _commandId(
          driverId: driverId,
          targetId: assignmentId,
          action: '$commandGroup.${command.name}',
        ),
        simulateOffline: simulateOffline,
      );
      if (result.isFailure) return result;
      assignment = result.valueOrNull;
    }
    return assignment == null
        ? const DeliveryFailureResult(DeliveryAssignmentNotFound())
        : DeliverySuccess(assignment);
  }

  /// Replays pending Backend lifecycle commands (remote mode) or clears the
  /// STEP 3 local pending-sync simulation (Fake mode).
  Future<void> retryPendingSync() async {
    if (_commandInFlight || state.isLoading) return;
    final assignment = state.activeAssignment;
    final replay = _replayPending;
    final advance = _advanceWorkflow;
    if (assignment == null || !assignment.pendingSync) return;
    if (replay == null && advance == null) return;

    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.refreshing,
      offers: const [],
      activeAssignment: assignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: assignment.driverId,
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );
    try {
      final result = replay != null
          ? await replay(
              driverId: assignment.driverId,
              connectivityOnline: _acceptPreconditionsReader(
                ref,
              ).connectivityOnline,
            )
          : await advance!.clearPendingSync(driverId: assignment.driverId);
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryPersistenceFailure(),
          activeAssignment: assignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: assignment.driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }
      final synced = result.valueOrNull;
      state = DeliveryControllerState.ready(
        offers: const [],
        activeAssignment: synced,
        lastAcceptedAssignment: synced ?? state.lastAcceptedAssignment,
        boundDriverId: assignment.driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
      if (replay != null) {
        await _refreshCustomerContactSoft(
          driverId: assignment.driverId,
          generation: generation,
        );
      }
    } finally {
      if (_isCurrent(generation)) _commandInFlight = false;
    }
  }

  /// Records a local form cancellation without changing delivery lifecycle.
  Future<void> recordCancelCommand() async {
    if (_commandInFlight || state.isLoading) return;
    final assignment = state.activeAssignment;
    final recorder = _recordLocalCommand;
    if (assignment == null || recorder == null) return;

    final result = await recorder(
      commandId: _commandId(
        driverId: assignment.driverId,
        targetId: assignment.assignmentId,
        action: 'cancel',
        scope: assignment.serverRevision,
      ),
      driverId: assignment.driverId,
      targetId: assignment.assignmentId,
      type: LocalDeliveryCommandType.cancel,
    );
    if (result.isFailure) {
      state = DeliveryControllerState.failure(
        failure: result.failureOrNull ?? const DeliveryPersistenceFailure(),
        activeAssignment: assignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: assignment.driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
    }
  }

  /// Cancels the active delivery via Backend (remote mode) and clears the
  /// assignment; Fake mode falls back to the local cancel-command record.
  Future<void> cancelActiveDelivery({String? reasonCode}) async {
    if (_commandInFlight || state.isLoading) return;
    final assignment = state.activeAssignment;
    if (assignment == null) return;

    final cancelRemote = _cancelDeliveryRemote;
    if (cancelRemote == null) {
      // Fake Alpha path: record-only, no lifecycle change.
      await recordCancelCommand();
      return;
    }

    final driverId = state.boundDriverId ?? assignment.driverId;
    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.advancing,
      offers: const [],
      activeAssignment: assignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );
    try {
      final result = await cancelRemote(
        driverId: driverId,
        commandId: _commandId(
          driverId: driverId,
          targetId: assignment.assignmentId,
          action: 'cancel',
          scope: assignment.serverRevision,
        ),
        reasonCode: reasonCode,
      );
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
          activeAssignment: assignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }
      await _cancelArrivalWatch();
      _clearCustomerContactReader(ref, deliveryId: assignment.assignmentId);
      state = DeliveryControllerState.ready(
        offers: const [],
        activeAssignment: null,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
        activeBatch: state.activeBatch,
      );
      await _availabilityRefreshReader(ref);
    } finally {
      if (_isCurrent(generation)) _commandInFlight = false;
    }
  }

  /// Reports a delivery issue via Backend (remote mode); Fake mode keeps the
  /// local reportIssue workflow transition.
  Future<void> reportIssueRemote({required String code, String? notes}) async {
    final reportIssue = _reportIssueRemote;
    if (reportIssue == null) {
      await advanceWorkflow(DriverWorkflowCommand.reportIssue);
      return;
    }

    if (_commandInFlight || state.isLoading) return;
    final assignment = state.activeAssignment;
    if (assignment == null) return;

    final driverId = state.boundDriverId ?? assignment.driverId;
    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.advancing,
      offers: const [],
      activeAssignment: assignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );
    try {
      final result = await reportIssue(
        driverId: driverId,
        commandId: _commandId(
          driverId: driverId,
          targetId: assignment.assignmentId,
          action: 'reportIssue',
          scope: assignment.serverRevision,
        ),
        code: code,
        notes: notes,
      );
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
          activeAssignment: assignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }
      final next = result.valueOrNull;
      state = DeliveryControllerState.ready(
        offers: const [],
        activeAssignment: next,
        lastAcceptedAssignment: next ?? state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
    } finally {
      if (_isCurrent(generation)) _commandInFlight = false;
    }
  }

  /// Refreshes the memory-only current-customer contact (remote mode only).
  Future<void> refreshCustomerContact() async {
    final driverId = state.boundDriverId ?? _driverIdReader(ref)?.trim();
    if (driverId == null || driverId.isEmpty) return;
    await _refreshCustomerContactSoft(
      driverId: driverId,
      generation: _generation,
    );
  }

  /// Refreshes the active batch summary (remote mode only).
  Future<void> refreshActiveBatch() async {
    await _refreshActiveBatchSoft(_generation);
  }

  /// Clears the memory-only customer contact (repository cache + state).
  void clearCustomerContactMemory({String? deliveryId}) {
    _clearCustomerContactReader(ref, deliveryId: deliveryId);
    state = state.copyWith(clearCustomerContact: true);
  }

  /// Verifies Fake/Backend delivery code then moves to summary.
  Future<void> verifyDeliveryCode(String code, {bool? simulateOffline}) async {
    if (_commandInFlight || state.isLoading) return;
    if (state.activeAssignment == null) return;

    final driverId =
        state.boundDriverId ?? state.activeAssignment!.driverId.trim();
    if (driverId.isEmpty) return;

    // Remote mode: Backend confirmDelivery has no verification code in the
    // contracts — the code argument is ignored and the Fake trial gate is
    // bypassed. Fake mode keeps the existing VerifyDeliveryCode path.
    final confirmDeliveryRemote =
        state.activeAssignment!.workflowStage == DriverWorkflowStage.verifying
        ? _confirmDeliveryRemote
        : null;

    final verify = _verifyCode;
    if (verify == null && confirmDeliveryRemote == null) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnknownFailure(
          'Delivery verification service is unavailable.',
        ),
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
      return;
    }

    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.verifying,
      offers: const [],
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );

    try {
      final assignmentId = state.activeAssignment!.assignmentId;
      final offline =
          simulateOffline ??
          !_acceptPreconditionsReader(ref).connectivityOnline;
      final result = confirmDeliveryRemote != null
          ? await confirmDeliveryRemote(
              driverId: driverId,
              commandId: _commandId(
                driverId: driverId,
                targetId: assignmentId,
                action: 'confirm-delivery',
                scope: state.activeAssignment?.serverRevision,
              ),
              connectivityOnline: !offline,
            )
          : await verify!(
              driverId: driverId,
              code: code,
              commandId: _commandId(
                driverId: driverId,
                targetId: assignmentId,
                action: 'confirm-delivery',
                scope: state.activeAssignment?.serverRevision,
              ),
              simulateOffline: offline,
            );
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        final failure = result.failureOrNull ?? const DeliveryUnknownFailure();
        final retryable =
            confirmDeliveryRemote != null &&
            (failure is DeliveryNetworkUnavailable ||
                failure is DeliveryBackendUnavailable);
        state = DeliveryControllerState.failure(
          failure: failure,
          activeAssignment: retryable
              ? state.activeAssignment?.copyWith(pendingSync: true)
              : state.activeAssignment,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }
      final assignment = result.valueOrNull;
      if (confirmDeliveryRemote != null) {
        // Backend acknowledged delivery — contact must leave memory now.
        _clearCustomerContactReader(ref, deliveryId: assignmentId);
      }
      state = DeliveryControllerState.ready(
        offers: const [],
        activeAssignment: assignment,
        lastAcceptedAssignment: assignment ?? state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: confirmDeliveryRemote != null
            ? null
            : state.customerContact,
        activeBatch: state.activeBatch,
      );
    } finally {
      if (_isCurrent(generation)) {
        _commandInFlight = false;
      }
    }
  }

  /// Dismisses summary after availability release, then clears assignment.
  ///
  /// Does **not** bump [_generation]. On failure, re-reads persisted
  /// assignment truth so memory cannot diverge from the repository.
  Future<void> completeDeliverySummary() async {
    if (_commandInFlight || state.isLoading) return;

    final driverId =
        state.boundDriverId ?? state.activeAssignment?.driverId.trim();
    if (driverId == null || driverId.isEmpty) {
      if (state.activeAssignment == null) {
        // Allow idempotent retry when memory already cleared but use case
        // still needs a bound driver id from session.
        final sessionDriver = _driverIdReader(ref)?.trim();
        if (sessionDriver == null || sessionDriver.isEmpty) return;
        return _runCompleteDeliverySummary(sessionDriver);
      }
      return;
    }

    await _runCompleteDeliverySummary(driverId);
  }

  Future<void> _runCompleteDeliverySummary(String driverId) async {
    final complete = _completeDelivery;
    if (complete == null) {
      state = DeliveryControllerState.failure(
        failure: const DeliveryUnknownFailure(
          'Delivery completion service is unavailable.',
        ),
        offers: state.activeAssignment != null ? const [] : state.offers,
        activeOffer: state.activeAssignment != null ? null : state.activeOffer,
        activeAssignment: state.activeAssignment,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
        customerContact: state.customerContact,
        activeBatch: state.activeBatch,
      );
      return;
    }

    final generation = _generation;
    _commandInFlight = true;
    state = DeliveryControllerState.processing(
      action: DeliveryProcessingAction.completing,
      offers: const [],
      activeAssignment: state.activeAssignment,
      lastAcceptedAssignment: state.lastAcceptedAssignment,
      boundDriverId: driverId,
      customerContact: state.customerContact,
      activeBatch: state.activeBatch,
    );

    try {
      await _cancelArrivalWatch();
      final result = await complete(driverId: driverId);
      if (!_isCurrent(generation)) return;
      if (result.isFailure) {
        final synced = await _syncActiveAssignmentAfterCompletionFailure(
          driverId: driverId,
          generation: generation,
        );
        if (!_isCurrent(generation)) return;
        await _availabilityRefreshReader(ref);
        if (!_isCurrent(generation)) return;
        state = DeliveryControllerState.failure(
          failure: result.failureOrNull ?? const DeliveryUnknownFailure(),
          offers: const [],
          activeOffer: null,
          activeAssignment: synced,
          lastAcceptedAssignment: state.lastAcceptedAssignment,
          boundDriverId: driverId,
          customerContact: state.customerContact,
          activeBatch: state.activeBatch,
        );
        return;
      }
      // Delivery released — memory-only contact must not survive completion.
      _clearCustomerContactReader(ref);
      state = DeliveryControllerState.ready(
        offers: const [],
        activeAssignment: null,
        lastAcceptedAssignment: state.lastAcceptedAssignment,
        boundDriverId: driverId,
        activeBatch: state.activeBatch,
      );
      await _availabilityRefreshReader(ref);
    } finally {
      if (_isCurrent(generation)) {
        _commandInFlight = false;
      }
    }
  }

  /// Re-reads repository assignment after a failed completion attempt.
  Future<DeliveryAssignment?> _syncActiveAssignmentAfterCompletionFailure({
    required String driverId,
    required int generation,
  }) async {
    final getActive = _getActive;
    if (getActive == null) {
      return state.activeAssignment;
    }
    final activeResult = await getActive(driverId: driverId);
    if (!_isCurrent(generation)) return state.activeAssignment;
    if (activeResult.isFailure) {
      return state.activeAssignment;
    }
    return activeResult.valueOrNull;
  }

  /// Contract-safe deterministic key (`^[A-Za-z0-9._~-]{8,128}$`); reused on
  /// retry and by Local Command Ledger replays. See [localCommandId].
  ///
  /// [scope] is the assignment `serverRevision` / aggregate version for
  /// delivery-scoped mutations so recycled Backend deliveries do not collide
  /// with a prior Idempotency-Key + different payload.
  String _commandId({
    required String driverId,
    required String targetId,
    required String action,
    String? scope,
  }) => localCommandId(
    driverId: driverId,
    targetId: targetId,
    action: action,
    scope: scope,
  );
}
