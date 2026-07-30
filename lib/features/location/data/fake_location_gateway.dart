import 'dart:async';

import '../domain/geo_point.dart';
import '../domain/location_fix.dart';
import '../domain/location_probe.dart';
import 'location_gateway.dart';

/// Deterministic Fake gateway for tests and non-production trials (STEP 4).
class FakeLocationGateway implements LocationGateway {
  FakeLocationGateway({
    this.permission = LocationPermissionStatus.granted,
    this.serviceStatus = LocationServiceStatus.enabled,
    this.probeResult = const LocationProbeResult(
      outcome: LocationProbeOutcome.available,
      accuracyMeters: 12,
    ),
    List<LocationFix>? fixes,
    this.latency = Duration.zero,
    this.anchorPoint = const GeoPoint(latitude: 24.7136, longitude: 46.6753),
  }) : _fixes = List<LocationFix>.from(fixes ?? const []);

  LocationPermissionStatus permission;
  LocationServiceStatus serviceStatus;
  LocationProbeResult probeResult;
  Duration latency;

  /// Default point emitted by [watchFixes] when the queue is empty.
  GeoPoint anchorPoint;
  final List<LocationFix> _fixes;
  int _fixIndex = 0;

  void enqueueFixes(Iterable<LocationFix> fixes) {
    _fixes.addAll(fixes);
  }

  void clearFixes() {
    _fixes.clear();
    _fixIndex = 0;
  }

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    await Future<void>.delayed(latency);
    return permission;
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    await Future<void>.delayed(latency);
    if (permission == LocationPermissionStatus.permanentlyDenied) {
      return permission;
    }
    if (permission == LocationPermissionStatus.denied ||
        permission == LocationPermissionStatus.notDetermined) {
      permission = LocationPermissionStatus.granted;
    }
    return permission;
  }

  @override
  Future<LocationServiceStatus> checkServiceStatus() async {
    await Future<void>.delayed(latency);
    return serviceStatus;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationProbeResult> probeCurrent() async {
    await Future<void>.delayed(latency);
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
    if (serviceStatus == LocationServiceStatus.disabled) {
      return const LocationProbeResult(
        outcome: LocationProbeOutcome.gpsDisabled,
      );
    }
    return probeResult;
  }

  @override
  Stream<LocationFix> watchFixes({
    Duration interval = const Duration(seconds: 2),
  }) async* {
    yield _nextFix();
    yield* Stream.periodic(interval, (_) => _nextFix());
  }

  LocationFix _nextFix() {
    if (_fixes.isEmpty) {
      return LocationFix(
        point: anchorPoint,
        recordedAt: DateTime.now().toUtc(),
        accuracyMeters: 12,
        source: LocationSampleSource.fake,
      );
    }
    final fix = _fixes[_fixIndex % _fixes.length];
    _fixIndex++;
    return LocationFix(
      point: fix.point,
      recordedAt: DateTime.now().toUtc(),
      accuracyMeters: fix.accuracyMeters ?? 12,
      source: LocationSampleSource.fake,
    );
  }
}
