import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'location_feature.dart';

/// Fake map preview view states (STEP 2B Fake UI).
enum MapPreviewStatus {
  loading,
  loadedPlaceholder,
  error,
  offline,
  externalNavigationUnavailable,
}

/// Trial scenarios driving [FakeMapPreviewService].
enum FakeMapScenario { seeded, error, offline }

/// Normalized (0..1) point inside the fake map placeholder box.
class FakeMapPoint {
  const FakeMapPoint(this.dx, this.dy);

  final double dx;
  final double dy;
}

/// Fake route snapshot rendered by the placeholder — no map SDK, no tiles.
class FakeMapSnapshot {
  const FakeMapSnapshot({
    required this.driver,
    required this.pickup,
    required this.dropoff,
    required this.route,
    required this.accuracy,
    required this.accuracyMeters,
  });

  final FakeMapPoint driver;
  final FakeMapPoint pickup;
  final FakeMapPoint dropoff;
  final List<FakeMapPoint> route;
  final LocationAccuracyLevel accuracy;
  final int accuracyMeters;
}

class MapPreviewException implements Exception {
  const MapPreviewException();
}

class MapPreviewOfflineException implements Exception {
  const MapPreviewOfflineException();
}

abstract interface class MapPreviewService {
  Future<FakeMapSnapshot> loadSnapshot(FakeMapScenario scenario);

  /// Always false in this increment — no navigation handoff exists yet.
  Future<bool> canOpenExternalNavigation();
}

class FakeMapPreviewService implements MapPreviewService {
  FakeMapPreviewService({
    this.latency = Duration.zero,
    this.recoverAfterFailures = 1,
  });

  static const defaultSnapshot = FakeMapSnapshot(
    driver: FakeMapPoint(0.18, 0.76),
    pickup: FakeMapPoint(0.44, 0.36),
    dropoff: FakeMapPoint(0.8, 0.2),
    route: [
      FakeMapPoint(0.18, 0.76),
      FakeMapPoint(0.28, 0.58),
      FakeMapPoint(0.44, 0.36),
      FakeMapPoint(0.62, 0.42),
      FakeMapPoint(0.8, 0.2),
    ],
    accuracy: LocationAccuracyLevel.high,
    accuracyMeters: 14,
  );

  /// Trial latency so the `loading` state stays observable.
  final Duration latency;

  /// Failed loads returned before the fake snapshot recovers. `0` keeps the
  /// failing state until the scenario changes.
  final int recoverAfterFailures;

  int _failedLoads = 0;

  @override
  Future<FakeMapSnapshot> loadSnapshot(FakeMapScenario scenario) async {
    await Future<void>.delayed(latency);
    switch (scenario) {
      case FakeMapScenario.seeded:
        return defaultSnapshot;
      case FakeMapScenario.error:
        _failedLoads++;
        if (recoverAfterFailures > 0 && _failedLoads > recoverAfterFailures) {
          return defaultSnapshot;
        }
        throw const MapPreviewException();
      case FakeMapScenario.offline:
        _failedLoads++;
        if (recoverAfterFailures > 0 && _failedLoads > recoverAfterFailures) {
          return defaultSnapshot;
        }
        throw const MapPreviewOfflineException();
    }
  }

  @override
  Future<bool> canOpenExternalNavigation() async {
    await Future<void>.delayed(latency);
    return false;
  }
}

/// Immutable map preview state.
class MapPreviewState {
  const MapPreviewState({
    this.status = MapPreviewStatus.loading,
    this.scenario = FakeMapScenario.seeded,
    this.snapshot,
    this.isProcessing = false,
  });

  final MapPreviewStatus status;
  final FakeMapScenario scenario;
  final FakeMapSnapshot? snapshot;

  /// In-flight guard — repeated taps must not re-trigger a transition.
  final bool isProcessing;

  MapPreviewState copyWith({
    MapPreviewStatus? status,
    FakeMapScenario? scenario,
    FakeMapSnapshot? snapshot,
    bool clearSnapshot = false,
    bool? isProcessing,
  }) {
    return MapPreviewState(
      status: status ?? this.status,
      scenario: scenario ?? this.scenario,
      snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

final mapPreviewServiceProvider = Provider<MapPreviewService?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {
    // Widget tests may run before AppConfig initialization.
  }
  return FakeMapPreviewService();
});

class MapPreviewController extends Notifier<MapPreviewState> {
  @override
  MapPreviewState build() {
    Future.microtask(load);
    return const MapPreviewState();
  }

  MapPreviewService? get _service => ref.read(mapPreviewServiceProvider);

  Future<void> load() => _load(state.scenario);

  Future<void> retry() => _load(state.scenario);

  Future<void> selectScenario(FakeMapScenario scenario) => _load(scenario);

  /// Fake external navigation handoff — never leaves the app in this
  /// increment, so it always reports the unavailable state.
  Future<void> openExternalNavigation() async {
    if (state.isProcessing) return;
    final service = _service;
    if (service == null) {
      state = state.copyWith(status: MapPreviewStatus.error);
      return;
    }
    state = state.copyWith(isProcessing: true);
    try {
      final canOpen = await service.canOpenExternalNavigation();
      if (!ref.mounted) return;
      state = state.copyWith(
        status: canOpen
            ? MapPreviewStatus.loadedPlaceholder
            : MapPreviewStatus.externalNavigationUnavailable,
        isProcessing: false,
      );
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          status: MapPreviewStatus.externalNavigationUnavailable,
          isProcessing: false,
        );
      }
    }
  }

  void dismissExternalNavigationNotice() {
    if (state.status != MapPreviewStatus.externalNavigationUnavailable) return;
    state = state.copyWith(status: MapPreviewStatus.loadedPlaceholder);
  }

  Future<void> _load(FakeMapScenario scenario) async {
    if (state.isProcessing) return;
    final service = _service;
    if (service == null) {
      state = state.copyWith(
        status: MapPreviewStatus.error,
        scenario: scenario,
        clearSnapshot: true,
        isProcessing: false,
      );
      return;
    }
    state = state.copyWith(
      status: MapPreviewStatus.loading,
      scenario: scenario,
      clearSnapshot: true,
      isProcessing: true,
    );
    try {
      final snapshot = await service.loadSnapshot(scenario);
      if (!ref.mounted) return;
      state = state.copyWith(
        status: MapPreviewStatus.loadedPlaceholder,
        snapshot: snapshot,
        isProcessing: false,
      );
    } on MapPreviewOfflineException {
      if (ref.mounted) {
        state = state.copyWith(
          status: MapPreviewStatus.offline,
          isProcessing: false,
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          status: MapPreviewStatus.error,
          isProcessing: false,
        );
      }
    }
  }
}

final mapPreviewControllerProvider =
    NotifierProvider<MapPreviewController, MapPreviewState>(
      MapPreviewController.new,
    );
