import 'location_accuracy_level.dart';

/// Classifies horizontal accuracy for UX and geofence gating (ADR-029).
class LocationAccuracyPolicy {
  const LocationAccuracyPolicy({
    this.highMaxMeters = 50,
    this.weakMaxMeters = 150,
  });

  /// Fixes with accuracy ≤ this may trigger arrival (when inside geofence).
  final int highMaxMeters;

  /// Fixes with accuracy ≤ this show weak UX but never trigger arrival.
  final int weakMaxMeters;

  LocationAccuracyLevel classify(double? accuracyMeters) {
    if (accuracyMeters == null ||
        !accuracyMeters.isFinite ||
        accuracyMeters < 0) {
      return LocationAccuracyLevel.unknown;
    }
    if (accuracyMeters <= highMaxMeters) {
      return LocationAccuracyLevel.high;
    }
    if (accuracyMeters <= weakMaxMeters) {
      return LocationAccuracyLevel.weak;
    }
    return LocationAccuracyLevel.unknown;
  }

  /// Whether a fix is accurate enough to count toward geofence arrival.
  bool isAcceptableForArrival(double? accuracyMeters) {
    return classify(accuracyMeters) == LocationAccuracyLevel.high;
  }
}
