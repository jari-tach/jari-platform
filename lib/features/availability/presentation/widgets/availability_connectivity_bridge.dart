import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_monitor.dart';
import '../../../../core/providers/home_ui_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/availability_connectivity_change.dart';
import '../controllers/availability_controller_state.dart';
import '../providers/availability_providers.dart';

/// Bridges network connectivity into [AvailabilityController].
///
/// Level reconciliation (not edge-only):
/// - Always stores the latest connectivity snapshot, including while
///   [AvailabilityController.initialize] is in flight.
/// - After initialization completes, replays that snapshot so Online that
///   arrived before restore cannot be lost (Batch 3 M2 race).
/// - Idempotent: identical online/offline levels are not re-applied.
///
/// Does not construct eligibility or call repositories.
class AvailabilityConnectivityBridge extends ConsumerStatefulWidget {
  const AvailabilityConnectivityBridge({super.key});

  @override
  ConsumerState<AvailabilityConnectivityBridge> createState() =>
      _AvailabilityConnectivityBridgeState();
}

class _AvailabilityConnectivityBridgeState
    extends ConsumerState<AvailabilityConnectivityBridge> {
  /// Latest observed device connectivity (level), including during init.
  ConnectivityStatus? _latestConnectivity;

  /// Last level successfully handed to [AvailabilityController].
  bool? _lastAppliedOnline;

  @override
  Widget build(BuildContext context) {
    // Seed / refresh snapshot from the current provider value.
    final snapshot = ref.watch(connectivityStatusProvider).asData?.value;
    if (snapshot != null) {
      _latestConnectivity = snapshot;
    }

    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (
      previous,
      next,
    ) {
      next.whenData((status) {
        _latestConnectivity = status;
        _reconcileLatest(force: false);
      });
    });

    ref.listen<AvailabilityControllerState>(availabilityControllerProvider, (
      previous,
      next,
    ) {
      final becameReady = previous?.isInitialized != true && next.isInitialized;
      if (becameReady) {
        // Always replay after init — Online may have arrived during restore.
        _reconcileLatest(force: true);
      }
    });

    return const SizedBox.shrink();
  }

  void _reconcileLatest({required bool force}) {
    final latest = _latestConnectivity;
    if (latest == null) return;

    final availability = ref.read(availabilityControllerProvider);
    if (!availability.isInitialized) {
      // Keep snapshot only; do not latch applied level yet.
      return;
    }

    final isOnline = latest != ConnectivityStatus.offline;
    if (!force && _lastAppliedOnline == isOnline) {
      return;
    }

    final auth = ref.read(authControllerProvider);
    final driverId =
        availability.boundDriverId ??
        availability.current?.driverId ??
        auth.session?.driverId;
    if (driverId == null || driverId.isEmpty) return;

    _lastAppliedOnline = isOnline;
    ref
        .read(availabilityControllerProvider.notifier)
        .handleConnectivityChange(
          AvailabilityConnectivityChange(
            driverId: driverId,
            isOnline: isOnline,
            changedAt: DateTime.now().toUtc(),
          ),
        );
  }
}
