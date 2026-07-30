import 'location_fix.dart';

/// Outcome of a single location probe (Fake or Device).
enum LocationProbeOutcome {
  available,
  weakAccuracy,
  stale,
  unavailable,
  permissionDenied,
  permissionPermanentlyDenied,
  gpsDisabled,

  /// Reserved for operations that genuinely require network connectivity.
  offline,
}

class LocationProbeResult {
  const LocationProbeResult({
    required this.outcome,
    this.accuracyMeters,
    this.capturedAt,
    this.source = LocationSampleSource.live,
  });

  final LocationProbeOutcome outcome;
  final int? accuracyMeters;
  final DateTime? capturedAt;
  final LocationSampleSource source;

  bool get isFallback => source == LocationSampleSource.lastKnown;
}
