import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/network_monitor.dart';
import '../../shared/services/app_service_registry.dart';

/// Connectivity for UI banners. Falls back to online when monitor is absent
/// (widget tests / early boot).
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  if (!AppServiceRegistry.isInitialized) {
    return Stream.value(ConnectivityStatus.online);
  }
  final live = AppServiceRegistry.networkMonitor;
  if (live == null) {
    return Stream.value(ConnectivityStatus.online);
  }
  return Stream<ConnectivityStatus>.multi((controller) {
    controller.add(live.status);
    final sub = live.statusStream.listen(
      controller.add,
      onError: controller.addError,
    );
    ref.onDispose(sub.cancel);
  });
});

/// Offline flag for Home / shell banners.
final isOfflineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStatusProvider);
  return async.maybeWhen(
    data: (status) => status == ConnectivityStatus.offline,
    orElse: () {
      if (!AppServiceRegistry.isInitialized) return false;
      return AppServiceRegistry.networkMonitor?.isOffline ?? false;
    },
  );
});

/// Fake Home summary seed (Increment 1 — no Drift schema).
class FakeHomeSummary {
  const FakeHomeSummary({
    required this.todayEarningsSar,
    required this.completedTripsToday,
    required this.acceptanceRatePercent,
  });

  final double todayEarningsSar;
  final int completedTripsToday;
  final int acceptanceRatePercent;

  static const seed = FakeHomeSummary(
    todayEarningsSar: 185.5,
    completedTripsToday: 7,
    acceptanceRatePercent: 92,
  );
}

final fakeHomeSummaryProvider = Provider<FakeHomeSummary?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {
    // AppConfig not initialized in some widget tests — still show Fake seed.
  }
  return FakeHomeSummary.seed;
});
