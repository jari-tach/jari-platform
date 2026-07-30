import 'dart:async';

import '../domain/geo_point.dart';
import '../domain/location_accuracy_policy.dart';
import '../domain/location_accuracy_level.dart';
import '../domain/location_fix.dart';
import '../domain/location_probe.dart';
import 'device_location_platform.dart';
import 'location_gateway.dart';

/// Device GPS / permission adapter (STEP 4). Plugins stay behind this port.
class DeviceLocationGateway implements LocationGateway {
  DeviceLocationGateway({
    this._accuracyPolicy = const LocationAccuracyPolicy(),
    DeviceLocationPlatform? platform,
    DateTime Function()? clock,
    this.maxLastKnownAge = const Duration(minutes: 2),
  }) : _platform = platform ?? const PluginDeviceLocationPlatform(),
       _clock = clock ?? _utcNow;

  final LocationAccuracyPolicy _accuracyPolicy;
  final DeviceLocationPlatform _platform;
  final DateTime Function() _clock;
  final Duration maxLastKnownAge;

  static DateTime _utcNow() => DateTime.now().toUtc();

  @override
  Future<LocationPermissionStatus> checkPermission() =>
      _platform.checkPermission();

  @override
  Future<LocationPermissionStatus> requestPermission() =>
      _platform.requestPermission();

  @override
  Future<LocationServiceStatus> checkServiceStatus() async {
    final enabled = await _platform.isServiceEnabled();
    return enabled
        ? LocationServiceStatus.enabled
        : LocationServiceStatus.disabled;
  }

  @override
  Future<bool> openAppSettings() => _platform.openAppSettings();

  @override
  Future<bool> openLocationSettings() => _platform.openLocationSettings();

  @override
  Future<LocationProbeResult> probeCurrent() async {
    final permission = await checkPermission();
    if (permission == LocationPermissionStatus.denied) {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.permissionDenied,
      );
    }
    if (permission == LocationPermissionStatus.permanentlyDenied ||
        permission == LocationPermissionStatus.restricted) {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.permissionPermanentlyDenied,
      );
    }
    if (permission != LocationPermissionStatus.granted) {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.permissionDenied,
      );
    }

    final service = await checkServiceStatus();
    if (service != LocationServiceStatus.enabled) {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.gpsDisabled,
      );
    }

    try {
      return await _probePosition();
    } on DeviceLocationServiceDisabledException {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.gpsDisabled,
      );
    } on DeviceLocationPermissionException {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.permissionDenied,
      );
    } catch (_) {
      return _fallbackOrUnavailable();
    }
  }

  @override
  Stream<LocationFix> watchFixes({
    Duration interval = const Duration(seconds: 2),
  }) {
    return _platform.watchPositions().map((position) {
      return LocationFix(
        point: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        recordedAt: position.capturedAt.toUtc(),
        accuracyMeters: position.accuracyMeters,
      );
    });
  }

  Future<LocationProbeResult> _probePosition() async {
    try {
      final current = await _platform.currentPosition(
        precision: DeviceLocationPrecision.high,
        timeout: const Duration(seconds: 25),
      );
      return _resultFromPosition(current);
    } on TimeoutException {
      final last = await _safeLastKnown();
      if (last != null && _isFresh(last)) {
        return _resultFromPosition(
          last,
          source: LocationSampleSource.lastKnown,
        );
      }

      // Exactly one bounded lower-precision attempt after a cold GNSS timeout.
      try {
        final medium = await _platform.currentPosition(
          precision: DeviceLocationPrecision.medium,
          timeout: const Duration(seconds: 20),
        );
        return _resultFromPosition(medium);
      } on TimeoutException {
        if (last != null) return _staleResult(last);
        return const LocationProbeResult(
          outcome: LocationProbeOutcome.unavailable,
        );
      }
    }
  }

  Future<LocationProbeResult> _fallbackOrUnavailable() async {
    final last = await _safeLastKnown();
    if (last == null) {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.unavailable,
      );
    }
    if (!_isFresh(last)) return _staleResult(last);
    return _resultFromPosition(last, source: LocationSampleSource.lastKnown);
  }

  Future<DevicePositionSample?> _safeLastKnown() async {
    try {
      return await _platform.lastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  bool _isFresh(DevicePositionSample position) {
    final age = _clock().toUtc().difference(position.capturedAt.toUtc());
    return !age.isNegative && age <= maxLastKnownAge;
  }

  LocationProbeResult _staleResult(DevicePositionSample position) {
    return LocationProbeResult(
      outcome: LocationProbeOutcome.stale,
      accuracyMeters: position.accuracyMeters.round(),
      capturedAt: position.capturedAt.toUtc(),
      source: LocationSampleSource.lastKnown,
    );
  }

  LocationProbeResult _resultFromPosition(
    DevicePositionSample position, {
    LocationSampleSource source = LocationSampleSource.live,
  }) {
    final meters = position.accuracyMeters;
    final level = _accuracyPolicy.classify(meters);
    return switch (level) {
      LocationAccuracyLevel.high => LocationProbeResult(
        outcome: LocationProbeOutcome.available,
        accuracyMeters: meters.round(),
        capturedAt: position.capturedAt.toUtc(),
        source: source,
      ),
      LocationAccuracyLevel.weak => LocationProbeResult(
        outcome: LocationProbeOutcome.weakAccuracy,
        accuracyMeters: meters.round(),
        capturedAt: position.capturedAt.toUtc(),
        source: source,
      ),
      LocationAccuracyLevel.unknown => LocationProbeResult(
        outcome: LocationProbeOutcome.weakAccuracy,
        accuracyMeters: meters.round(),
        capturedAt: position.capturedAt.toUtc(),
        source: source,
      ),
    };
  }
}
