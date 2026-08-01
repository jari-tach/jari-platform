import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../availability/presentation/providers/availability_providers.dart';
import '../../../delivery/presentation/providers/delivery_providers.dart';
import '../../application/realtime_coordinator.dart';
import '../../domain/entities/realtime_connection_status.dart';
import '../state/realtime_controller_state.dart';

/// Binds [RealtimeCoordinator] to auth + delivery + availability + lifecycle.
///
/// - Starts after authentication succeeds.
/// - Stops on logout / session expiry / account switch.
/// - On offer.* events → [DeliveryController.refreshOffers] (REST authority).
/// - On delivery.* events → active delivery + batch REST refresh (STEP 6-C).
/// - On driver.availability_changed → availability REST resync (STEP 6-C).
/// - On system.resync_required the coordinator raises all three invalidation
///   streams, so offers, delivery and availability all re-fetch from REST.
/// - Observes [AppLifecycleState] for background pause / resume catch-up.
///
/// Refreshes that share [DeliveryController] are serialized on one chain —
/// its command-in-flight guard would otherwise drop the second refresh of a
/// full resync.
class RealtimeController extends Notifier<RealtimeControllerState>
    with WidgetsBindingObserver {
  RealtimeController({
    RealtimeCoordinator? Function(Ref ref)? coordinatorReader,
  }) : _coordinatorReader = coordinatorReader ?? _defaultCoordinatorReader;

  final RealtimeCoordinator? Function(Ref ref) _coordinatorReader;

  static RealtimeCoordinator? _defaultCoordinatorReader(Ref ref) => null;

  StreamSubscription<RealtimeConnectionStatus>? _statusSub;
  StreamSubscription<void>? _offersSub;
  StreamSubscription<void>? _deliverySub;
  StreamSubscription<void>? _availabilitySub;
  Future<void> _deliveryOpsChain = Future<void>.value();
  bool _offersRefreshQueued = false;
  bool _deliveryRefreshQueued = false;
  bool _availabilityRefreshQueued = false;
  bool _observerAttached = false;

  RealtimeCoordinator? get _coordinator => _coordinatorReader(ref);

  @override
  RealtimeControllerState build() {
    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
      ref.onDispose(() {
        WidgetsBinding.instance.removeObserver(this);
        _observerAttached = false;
        unawaited(_detachCoordinator());
      });
    }

    ref.listen(authControllerProvider, (previous, next) {
      unawaited(_syncWithAuth(next));
    });

    Future.microtask(() {
      unawaited(_syncWithAuth(ref.read(authControllerProvider)));
    });

    return const RealtimeControllerState.idle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final coordinator = _coordinator;
    if (coordinator == null || !coordinator.isRunning) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        coordinator.onAppPaused();
      case AppLifecycleState.resumed:
        unawaited(coordinator.onAppResumed());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _syncWithAuth(AuthControllerState auth) async {
    final coordinator = _coordinator;
    if (coordinator == null) {
      state = const RealtimeControllerState.idle();
      return;
    }

    final driverId = auth.session?.driverId.trim();
    final authenticated =
        auth.status == AuthControllerStatus.authenticated &&
        driverId != null &&
        driverId.isNotEmpty;

    if (!authenticated) {
      await _detachCoordinator();
      await coordinator.onLogout();
      state = const RealtimeControllerState.idle();
      return;
    }

    if (coordinator.driverId == driverId && coordinator.isRunning) {
      return;
    }

    await _detachCoordinator();
    _statusSub = coordinator.statusChanges.listen((status) {
      state = RealtimeControllerState(status: status, driverId: driverId);
    });
    _offersSub = coordinator.offersInvalidated.listen((_) {
      unawaited(onOffersInvalidated());
    });
    _deliverySub = coordinator.deliveryInvalidated.listen((_) {
      unawaited(onDeliveryInvalidated());
    });
    _availabilitySub = coordinator.availabilityInvalidated.listen((_) {
      unawaited(onAvailabilityInvalidated());
    });
    await coordinator.start(driverId);
    state = RealtimeControllerState(
      status: coordinator.status,
      driverId: driverId,
    );
  }

  Future<void> _detachCoordinator() async {
    await _statusSub?.cancel();
    _statusSub = null;
    await _offersSub?.cancel();
    _offersSub = null;
    await _deliverySub?.cancel();
    _deliverySub = null;
    await _availabilitySub?.cancel();
    _availabilitySub = null;
  }

  /// Soft-refresh offers after an offer.* realtime signal.
  Future<void> onOffersInvalidated() {
    if (_offersRefreshQueued) return Future<void>.value();
    _offersRefreshQueued = true;
    return _enqueueDeliveryOp(() async {
      try {
        await ref.read(deliveryControllerProvider.notifier).refreshOffers();
      } finally {
        _offersRefreshQueued = false;
      }
    });
  }

  /// Re-fetch the active delivery and batch from REST after a delivery.*
  /// signal (STEP 6-C). A cancelled delivery comes back as a null active
  /// assignment — presentation already renders that state safely.
  Future<void> onDeliveryInvalidated() {
    if (_deliveryRefreshQueued) return Future<void>.value();
    _deliveryRefreshQueued = true;
    return _enqueueDeliveryOp(() async {
      try {
        final delivery = ref.read(deliveryControllerProvider.notifier);
        await delivery.refreshActiveDelivery();
        await delivery.refreshActiveBatch();
      } finally {
        _deliveryRefreshQueued = false;
      }
    });
  }

  /// Resync availability from REST after driver.availability_changed
  /// (STEP 6-C) — e.g. changed on another device or by the platform.
  Future<void> onAvailabilityInvalidated() async {
    if (_availabilityRefreshQueued) return;
    _availabilityRefreshQueued = true;
    try {
      await ref.read(availabilityControllerProvider.notifier).initialize();
    } finally {
      _availabilityRefreshQueued = false;
    }
  }

  /// Serializes refreshes that share [DeliveryController]; its
  /// command-in-flight guard drops concurrent refresh calls.
  Future<void> _enqueueDeliveryOp(Future<void> Function() op) {
    _deliveryOpsChain = _deliveryOpsChain.then((_) async {
      try {
        await op();
      } catch (_) {
        // Refresh failures surface through DeliveryController state.
      }
    });
    return _deliveryOpsChain;
  }
}
