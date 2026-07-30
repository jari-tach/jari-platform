import 'geo_distance.dart';
import 'geo_point.dart';
import 'location_accuracy_policy.dart';
import 'location_fix.dart';

/// Outcome of evaluating one fix against a target geofence.
enum GeofenceEvaluation {
  /// Not enough data / rejected accuracy / outside radius.
  outside,

  /// Inside radius with acceptable accuracy but debounce not satisfied.
  approaching,

  /// Inside + accuracy + debounce satisfied → automatic arrival may fire.
  arrived,
}

/// Local geofence policy (ADR-029). Intent only — not Backend proof.
class GeofencePolicy {
  GeofencePolicy({
    this.radiusMeters = 80,
    this.maxFixAge = const Duration(seconds: 30),
    LocationAccuracyPolicy? accuracyPolicy,
    LocationFixDebouncer? debouncer,
    DateTime Function()? clock,
  }) : accuracyPolicy = accuracyPolicy ?? const LocationAccuracyPolicy(),
       debouncer = debouncer ?? LocationFixDebouncer(),
       _clock = clock ?? _utcNow;

  final double radiusMeters;
  final Duration maxFixAge;
  final LocationAccuracyPolicy accuracyPolicy;
  final LocationFixDebouncer debouncer;
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  void reset() => debouncer.reset();

  GeofenceEvaluation evaluate({
    required LocationFix fix,
    required GeoPoint target,
  }) {
    if (!fix.point.isValid ||
        !target.isValid ||
        !fix.isFreshAt(_clock(), maxAge: maxFixAge)) {
      debouncer.reset();
      return GeofenceEvaluation.outside;
    }
    final accuracyOk = accuracyPolicy.isAcceptableForArrival(
      fix.accuracyMeters,
    );
    final distance = GeoDistance.metersBetween(fix.point, target);
    final inside = distance <= radiusMeters;
    if (!inside || !accuracyOk) {
      debouncer.reset();
      return GeofenceEvaluation.outside;
    }
    final stable = debouncer.accept(fix, sampleAccepted: true);
    return stable ? GeofenceEvaluation.arrived : GeofenceEvaluation.approaching;
  }
}
