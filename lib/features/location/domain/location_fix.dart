import 'geo_point.dart';

/// Origin of a location sample; fallback samples never bypass policy checks.
enum LocationSampleSource { live, lastKnown, fake }

/// A single location sample from Fake or Device adapters.
class LocationFix {
  const LocationFix({
    required this.point,
    required this.recordedAt,
    this.accuracyMeters,
    this.source = LocationSampleSource.live,
  });

  final GeoPoint point;

  /// Timestamp captured by the platform provider, not receipt time.
  final DateTime recordedAt;
  final double? accuracyMeters;
  final LocationSampleSource source;

  bool get isFallback => source == LocationSampleSource.lastKnown;

  bool isFreshAt(
    DateTime now, {
    Duration maxAge = const Duration(seconds: 30),
  }) {
    final age = now.toUtc().difference(recordedAt.toUtc());
    return !age.isNegative && age <= maxAge;
  }
}

/// Requires [requiredHits] consecutive accepted samples spaced by
/// [minInterval] before emitting a stable “inside” signal.
class LocationFixDebouncer {
  LocationFixDebouncer({
    this.requiredHits = 2,
    this.minInterval = const Duration(milliseconds: 1500),
  });

  final int requiredHits;
  final Duration minInterval;

  int _hits = 0;
  DateTime? _lastAcceptedAt;

  void reset() {
    _hits = 0;
    _lastAcceptedAt = null;
  }

  /// Returns `true` when the debouncer has enough consecutive accepts.
  ///
  /// Spacing prefers [LocationFix.recordedAt]. When GNSS timestamps do not
  /// advance (common with mock / fused providers), [now] (wall clock) is used
  /// so stationary-inside-geofence can still satisfy [requiredHits].
  bool accept(LocationFix fix, {required bool sampleAccepted, DateTime? now}) {
    if (!sampleAccepted) {
      reset();
      return false;
    }
    final gnssAt = fix.recordedAt.toUtc();
    final wallAt = now?.toUtc();
    final last = _lastAcceptedAt;
    if (last != null) {
      final gnssSpaced = gnssAt.difference(last) >= minInterval;
      final wallSpaced =
          wallAt != null && wallAt.difference(last) >= minInterval;
      if (!gnssSpaced && !wallSpaced) {
        // Too soon — ignore without resetting the streak.
        return _hits >= requiredHits;
      }
      _lastAcceptedAt = gnssSpaced ? gnssAt : wallAt!;
    } else {
      _lastAcceptedAt = gnssAt;
    }
    _hits += 1;
    return _hits >= requiredHits;
  }
}
