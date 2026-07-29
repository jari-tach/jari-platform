import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';

/// Driver location / GPS view states (STEP 2B Fake UI).
///
/// This increment models only the UI states a driver can face. No platform
/// location API, system permission, or background service is involved.
enum LocationViewStatus {
  permissionIntro,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  locating,
  available,
  weakAccuracy,
  offline,
}

/// Accuracy bucket reported with a fake fix — shown as icon + text, never
/// color alone.
enum LocationAccuracyLevel { unknown, high, weak }

/// Trial scenarios driving [FakeLocationService].
enum FakeLocationScenario {
  permissionGranted,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  weakAccuracy,
  offline,
}

/// Outcome of a single fake location probe.
enum LocationProbeOutcome {
  available,
  weakAccuracy,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,
  offline,
}

class LocationProbeResult {
  const LocationProbeResult({required this.outcome, this.accuracyMeters});

  final LocationProbeOutcome outcome;
  final int? accuracyMeters;
}

abstract interface class LocationService {
  Future<LocationProbeResult> probe(FakeLocationScenario scenario);
}

/// Fake location source — deterministic, offline, no platform channels.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.latency = Duration.zero,
    this.recoverAfterFailures = 1,
  });

  /// Trial latency so the `locating` state stays observable.
  final Duration latency;

  /// Offline probes returned before the fake fix recovers. `0` keeps the
  /// offline state until the scenario changes.
  final int recoverAfterFailures;

  int _offlineProbes = 0;

  @override
  Future<LocationProbeResult> probe(FakeLocationScenario scenario) async {
    await Future<void>.delayed(latency);
    switch (scenario) {
      case FakeLocationScenario.permissionGranted:
        return const LocationProbeResult(
          outcome: LocationProbeOutcome.available,
          accuracyMeters: 12,
        );
      case FakeLocationScenario.weakAccuracy:
        return const LocationProbeResult(
          outcome: LocationProbeOutcome.weakAccuracy,
          accuracyMeters: 180,
        );
      case FakeLocationScenario.permissionDenied:
        return const LocationProbeResult(
          outcome: LocationProbeOutcome.permissionDenied,
        );
      case FakeLocationScenario.permissionPermanentlyDenied:
        return const LocationProbeResult(
          outcome: LocationProbeOutcome.permissionPermanentlyDenied,
        );
      case FakeLocationScenario.gpsDisabled:
        return const LocationProbeResult(
          outcome: LocationProbeOutcome.gpsDisabled,
        );
      case FakeLocationScenario.offline:
        _offlineProbes++;
        if (recoverAfterFailures > 0 && _offlineProbes > recoverAfterFailures) {
          return const LocationProbeResult(
            outcome: LocationProbeOutcome.available,
            accuracyMeters: 18,
          );
        }
        return const LocationProbeResult(outcome: LocationProbeOutcome.offline);
    }
  }
}

/// Immutable location view state.
class LocationState {
  const LocationState({
    this.status = LocationViewStatus.permissionIntro,
    this.scenario = FakeLocationScenario.permissionGranted,
    this.accuracy = LocationAccuracyLevel.unknown,
    this.accuracyMeters,
    this.isProcessing = false,
    this.settingsGuidanceVisible = false,
    this.serviceUnavailable = false,
  });

  final LocationViewStatus status;
  final FakeLocationScenario scenario;
  final LocationAccuracyLevel accuracy;
  final int? accuracyMeters;

  /// In-flight guard — repeated taps must not re-trigger a transition.
  final bool isProcessing;

  /// Permanently-denied guidance is UI only; no system settings intent.
  final bool settingsGuidanceVisible;

  /// Fake services are never wired into production builds.
  final bool serviceUnavailable;

  bool get canOpenMapPreview =>
      !serviceUnavailable &&
      (status == LocationViewStatus.available ||
          status == LocationViewStatus.weakAccuracy);

  LocationState copyWith({
    LocationViewStatus? status,
    FakeLocationScenario? scenario,
    LocationAccuracyLevel? accuracy,
    int? accuracyMeters,
    bool clearAccuracyMeters = false,
    bool? isProcessing,
    bool? settingsGuidanceVisible,
    bool? serviceUnavailable,
  }) {
    return LocationState(
      status: status ?? this.status,
      scenario: scenario ?? this.scenario,
      accuracy: accuracy ?? this.accuracy,
      accuracyMeters: clearAccuracyMeters
          ? null
          : (accuracyMeters ?? this.accuracyMeters),
      isProcessing: isProcessing ?? this.isProcessing,
      settingsGuidanceVisible:
          settingsGuidanceVisible ?? this.settingsGuidanceVisible,
      serviceUnavailable: serviceUnavailable ?? this.serviceUnavailable,
    );
  }
}

final locationServiceProvider = Provider<LocationService?>((ref) {
  try {
    if (AppConfig.isProduction) return null;
  } catch (_) {
    // Widget tests may run before AppConfig initialization.
  }
  return FakeLocationService();
});

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  LocationService? get _service => ref.read(locationServiceProvider);

  /// Primary flow: fake permission grant, then locate.
  Future<void> requestPermission() => _probe(state.scenario);

  /// Retry the current trial scenario.
  Future<void> retry() => _probe(state.scenario);

  /// Switch trial scenario and probe again.
  Future<void> selectScenario(FakeLocationScenario scenario) =>
      _probe(scenario);

  /// UI-only guidance for permanently denied permission.
  void showSettingsGuidance() {
    if (state.status != LocationViewStatus.permissionPermanentlyDenied) return;
    state = state.copyWith(settingsGuidanceVisible: true);
  }

  Future<void> _probe(FakeLocationScenario scenario) async {
    if (state.isProcessing) return;
    final service = _service;
    if (service == null) {
      state = state.copyWith(
        scenario: scenario,
        serviceUnavailable: true,
        settingsGuidanceVisible: false,
        isProcessing: false,
      );
      return;
    }
    state = state.copyWith(
      status: LocationViewStatus.locating,
      scenario: scenario,
      accuracy: LocationAccuracyLevel.unknown,
      clearAccuracyMeters: true,
      isProcessing: true,
      settingsGuidanceVisible: false,
      serviceUnavailable: false,
    );
    try {
      final result = await service.probe(scenario);
      if (!ref.mounted) return;
      state = state.copyWith(
        status: _statusFor(result.outcome),
        accuracy: _accuracyFor(result.outcome),
        accuracyMeters: result.accuracyMeters,
        clearAccuracyMeters: result.accuracyMeters == null,
        isProcessing: false,
      );
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          status: LocationViewStatus.gpsDisabled,
          accuracy: LocationAccuracyLevel.unknown,
          clearAccuracyMeters: true,
          isProcessing: false,
        );
      }
    }
  }

  static LocationViewStatus _statusFor(LocationProbeOutcome outcome) {
    return switch (outcome) {
      LocationProbeOutcome.available => LocationViewStatus.available,
      LocationProbeOutcome.weakAccuracy => LocationViewStatus.weakAccuracy,
      LocationProbeOutcome.permissionDenied =>
        LocationViewStatus.permissionDenied,
      LocationProbeOutcome.permissionPermanentlyDenied =>
        LocationViewStatus.permissionPermanentlyDenied,
      LocationProbeOutcome.gpsDisabled => LocationViewStatus.gpsDisabled,
      LocationProbeOutcome.offline => LocationViewStatus.offline,
    };
  }

  static LocationAccuracyLevel _accuracyFor(LocationProbeOutcome outcome) {
    return switch (outcome) {
      LocationProbeOutcome.available => LocationAccuracyLevel.high,
      LocationProbeOutcome.weakAccuracy => LocationAccuracyLevel.weak,
      LocationProbeOutcome.permissionDenied ||
      LocationProbeOutcome.permissionPermanentlyDenied ||
      LocationProbeOutcome.gpsDisabled ||
      LocationProbeOutcome.offline => LocationAccuracyLevel.unknown,
    };
  }
}

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);
