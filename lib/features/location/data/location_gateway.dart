import '../domain/location_fix.dart';
import '../domain/location_probe.dart';

/// Platform permission snapshot for location (port — no plugin types).
enum LocationPermissionStatus {
  notDetermined,
  denied,
  permanentlyDenied,
  granted,
  restricted,
}

/// OS location service (GPS) enabled/disabled.
enum LocationServiceStatus { enabled, disabled, unknown }

/// Port for device / fake location. Controllers depend on this — not plugins.
abstract interface class LocationGateway {
  Future<LocationPermissionStatus> checkPermission();

  Future<LocationPermissionStatus> requestPermission();

  Future<LocationServiceStatus> checkServiceStatus();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();

  /// One-shot probe for the Location screen (maps to [LocationProbeResult]).
  Future<LocationProbeResult> probeCurrent();

  /// Continuous fixes while subscribed. Implementations must not leak
  /// plugin types across the boundary.
  Stream<LocationFix> watchFixes({
    Duration interval = const Duration(seconds: 2),
  });
}
