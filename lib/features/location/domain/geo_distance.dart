import 'dart:math' as math;

import 'geo_point.dart';

/// Great-circle distance helpers (pure Dart — no plugins).
abstract final class GeoDistance {
  static const double earthRadiusMeters = 6371000;

  /// Haversine distance in meters between [a] and [b].
  static double metersBetween(GeoPoint a, GeoPoint b) {
    if (!a.isValid || !b.isValid) {
      return double.infinity;
    }
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
