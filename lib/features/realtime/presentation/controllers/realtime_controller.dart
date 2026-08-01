import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../delivery/presentation/providers/delivery_providers.dart';
import '../../application/realtime_coordinator.dart';
import '../../domain/entities/realtime_connection_status.dart';
import '../state/realtime_controller_state.dart';

/// Binds [RealtimeCoordinator] to auth + delivery + app lifecycle.
///
/// - Starts after authentication succeeds.
/// - Stops on logout / session expiry / account switch.
/// - On offer.* events → [DeliveryController.refreshOffers] (REST authority).
/// - Observes [AppLifecycleState] for background pause / resume catch-up.
class RealtimeController extends Notifier<RealtimeControllerState>
    with WidgetsBindingObserver {
  RealtimeController({
    RealtimeCoordinator? Function(Ref ref)? coordinatorReader,
  }) : _coordinatorReader = coordinatorReader ?? _defaultCoordinatorReader;

  final RealtimeCoordinator? Function(Ref ref) _coordinatorReader;

  static RealtimeCoordinator? _defaultCoordinatorReader(Ref ref) => null;

  StreamSubscription<RealtimeConnectionStatus>? _statusSub;
  StreamSubscription<void>? _offersSub;
  bool _offersRefreshQueued = false;
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
  }

  /// Soft-refresh offers after an offer.* realtime signal.
  Future<void> onOffersInvalidated() async {
    if (_offersRefreshQueued) return;
    _offersRefreshQueued = true;
    try {
      await ref.read(deliveryControllerProvider.notifier).refreshOffers();
    } finally {
      _offersRefreshQueued = false;
    }
  }
}
