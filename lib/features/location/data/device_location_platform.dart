import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;

import 'location_gateway.dart';

/// Debug Device QA builds force Android LocationManager so adb mock /
/// test-provider fixes are visible (Fused often ignores them).
const bool _deviceLocationQa = bool.fromEnvironment('SAEQ_DEVICE_LOCATION_QA');

enum DeviceLocationPrecision { high, medium }

class DevicePositionSample {
  const DevicePositionSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime capturedAt;
}

class DeviceLocationPermissionException implements Exception {
  const DeviceLocationPermissionException();
}

class DeviceLocationServiceDisabledException implements Exception {
  const DeviceLocationServiceDisabledException();
}

/// Testable boundary around static platform-plugin APIs.
abstract interface class DeviceLocationPlatform {
  Future<LocationPermissionStatus> checkPermission();

  Future<LocationPermissionStatus> requestPermission();

  Future<bool> isServiceEnabled();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();

  Future<DevicePositionSample> currentPosition({
    required DeviceLocationPrecision precision,
    required Duration timeout,
  });

  Future<DevicePositionSample?> lastKnownPosition();

  Stream<DevicePositionSample> watchPositions();
}

class PluginDeviceLocationPlatform implements DeviceLocationPlatform {
  const PluginDeviceLocationPlatform();

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    return _mapPermission(await ph.Permission.locationWhenInUse.status);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    return _mapPermission(await ph.Permission.locationWhenInUse.request());
  }

  @override
  Future<bool> isServiceEnabled() => geo.Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();

  @override
  Future<bool> openLocationSettings() => geo.Geolocator.openLocationSettings();

  @override
  Future<DevicePositionSample> currentPosition({
    required DeviceLocationPrecision precision,
    required Duration timeout,
  }) async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: geo.LocationSettings(
          accuracy: precision == DeviceLocationPrecision.high
              ? geo.LocationAccuracy.high
              : geo.LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      );
      return _sample(position);
    } on geo.PermissionDeniedException {
      throw const DeviceLocationPermissionException();
    } on geo.LocationServiceDisabledException {
      throw const DeviceLocationServiceDisabledException();
    }
  }

  @override
  Future<DevicePositionSample?> lastKnownPosition() async {
    final position = await geo.Geolocator.getLastKnownPosition();
    return position == null ? null : _sample(position);
  }

  @override
  Stream<DevicePositionSample> watchPositions() {
    // Deliberately no timeLimit: silence is not failure or arrival.
    // distanceFilter must be 0: geofence arrival requires ≥2 spaced hits while
    // the driver is often stationary inside the radius (ADR-029).
    return geo.Geolocator.getPositionStream(
      locationSettings: deviceWatchLocationSettings(
        forceAndroidLocationManager: _deviceLocationQa,
      ),
    ).map(_sample);
  }

  /// Shared watch settings for production + Device QA.
  @visibleForTesting
  static geo.LocationSettings deviceWatchLocationSettings({
    required bool forceAndroidLocationManager,
    Duration interval = const Duration(seconds: 2),
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: interval,
        forceLocationManager: forceAndroidLocationManager,
      );
    }
    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  static DevicePositionSample _sample(geo.Position position) {
    return DevicePositionSample(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      capturedAt: position.timestamp.toUtc(),
    );
  }

  static LocationPermissionStatus _mapPermission(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return LocationPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    if (status.isDenied) return LocationPermissionStatus.denied;
    return LocationPermissionStatus.notDetermined;
  }
}
