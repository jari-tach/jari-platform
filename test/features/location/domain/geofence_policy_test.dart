import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/location/domain/geo_distance.dart';
import 'package:saeq_driver/features/location/domain/geo_point.dart';
import 'package:saeq_driver/features/location/domain/geofence_policy.dart';
import 'package:saeq_driver/features/location/domain/location_accuracy_level.dart';
import 'package:saeq_driver/features/location/domain/location_accuracy_policy.dart';
import 'package:saeq_driver/features/location/domain/location_fix.dart';

void main() {
  group('GeoDistance', () {
    test('returns ~0 for identical points', () {
      const p = GeoPoint(latitude: 24.7136, longitude: 46.6753);
      expect(GeoDistance.metersBetween(p, p), closeTo(0, 0.01));
    });

    test('measures ~111 km per degree latitude near equator', () {
      const a = GeoPoint(latitude: 0, longitude: 0);
      const b = GeoPoint(latitude: 1, longitude: 0);
      expect(GeoDistance.metersBetween(a, b), closeTo(111195, 500));
    });
  });

  group('LocationAccuracyPolicy', () {
    const policy = LocationAccuracyPolicy();

    test('classifies high / weak / unknown', () {
      expect(policy.classify(12), LocationAccuracyLevel.high);
      expect(policy.classify(50), LocationAccuracyLevel.high);
      expect(policy.classify(80), LocationAccuracyLevel.weak);
      expect(policy.classify(150), LocationAccuracyLevel.weak);
      expect(policy.classify(151), LocationAccuracyLevel.unknown);
      expect(policy.classify(null), LocationAccuracyLevel.unknown);
    });

    test('only high accuracy is acceptable for arrival', () {
      expect(policy.isAcceptableForArrival(40), isTrue);
      expect(policy.isAcceptableForArrival(80), isFalse);
    });
  });

  group('LocationFixDebouncer', () {
    test('requires consecutive spaced hits', () {
      final debouncer = LocationFixDebouncer(
        requiredHits: 2,
        minInterval: const Duration(seconds: 1),
      );
      final t0 = DateTime.utc(2026, 7, 30, 12);
      final fix0 = LocationFix(
        point: const GeoPoint(latitude: 1, longitude: 1),
        recordedAt: t0,
        accuracyMeters: 10,
      );
      expect(debouncer.accept(fix0, sampleAccepted: true), isFalse);
      expect(
        debouncer.accept(
          LocationFix(
            point: const GeoPoint(latitude: 1, longitude: 1),
            recordedAt: t0.add(const Duration(milliseconds: 500)),
            accuracyMeters: 10,
          ),
          sampleAccepted: true,
        ),
        isFalse,
      );
      expect(
        debouncer.accept(
          LocationFix(
            point: const GeoPoint(latitude: 1, longitude: 1),
            recordedAt: t0.add(const Duration(seconds: 2)),
            accuracyMeters: 10,
          ),
          sampleAccepted: true,
        ),
        isTrue,
      );
    });

    test('resets on rejected sample', () {
      final debouncer = LocationFixDebouncer(
        requiredHits: 2,
        minInterval: Duration.zero,
      );
      final t0 = DateTime.utc(2026, 7, 30, 12);
      expect(
        debouncer.accept(
          LocationFix(
            point: const GeoPoint(latitude: 1, longitude: 1),
            recordedAt: t0,
          ),
          sampleAccepted: true,
        ),
        isFalse,
      );
      expect(
        debouncer.accept(
          LocationFix(
            point: const GeoPoint(latitude: 1, longitude: 1),
            recordedAt: t0.add(const Duration(seconds: 1)),
          ),
          sampleAccepted: false,
        ),
        isFalse,
      );
      expect(
        debouncer.accept(
          LocationFix(
            point: const GeoPoint(latitude: 1, longitude: 1),
            recordedAt: t0.add(const Duration(seconds: 2)),
          ),
          sampleAccepted: true,
        ),
        isFalse,
      );
    });

    test('advances on wall clock when GNSS timestamps are stuck', () {
      final debouncer = LocationFixDebouncer(
        requiredHits: 2,
        minInterval: const Duration(seconds: 1),
      );
      final t0 = DateTime.utc(2026, 7, 30, 12);
      final stuck = LocationFix(
        point: const GeoPoint(latitude: 1, longitude: 1),
        recordedAt: t0,
        accuracyMeters: 10,
      );
      expect(debouncer.accept(stuck, sampleAccepted: true, now: t0), isFalse);
      expect(
        debouncer.accept(
          stuck,
          sampleAccepted: true,
          now: t0.add(const Duration(milliseconds: 500)),
        ),
        isFalse,
      );
      expect(
        debouncer.accept(
          stuck,
          sampleAccepted: true,
          now: t0.add(const Duration(seconds: 2)),
        ),
        isTrue,
      );
    });
  });

  group('GeofencePolicy', () {
    final target = const GeoPoint(latitude: 24.7136, longitude: 46.6753);
    final near = const GeoPoint(latitude: 24.7137, longitude: 46.6754);
    final far = const GeoPoint(latitude: 24.8, longitude: 46.8);

    test('reports approaching then arrived for stable inside fixes', () {
      final policy = GeofencePolicy(
        radiusMeters: 80,
        clock: () => DateTime.utc(2026, 7, 30, 12, 0, 1),
        debouncer: LocationFixDebouncer(
          requiredHits: 2,
          minInterval: const Duration(milliseconds: 100),
        ),
      );
      final t0 = DateTime.utc(2026, 7, 30, 12);
      expect(
        policy.evaluate(
          fix: LocationFix(point: near, recordedAt: t0, accuracyMeters: 12),
          target: target,
        ),
        GeofenceEvaluation.approaching,
      );
      expect(
        policy.evaluate(
          fix: LocationFix(
            point: near,
            recordedAt: t0.add(const Duration(milliseconds: 200)),
            accuracyMeters: 12,
          ),
          target: target,
        ),
        GeofenceEvaluation.arrived,
      );
    });

    test('rejects weak accuracy inside radius', () {
      final policy = GeofencePolicy(
        clock: () => DateTime.utc(2026, 7, 30, 0, 0, 1),
        debouncer: LocationFixDebouncer(
          requiredHits: 1,
          minInterval: Duration.zero,
        ),
      );
      expect(
        policy.evaluate(
          fix: LocationFix(
            point: near,
            recordedAt: DateTime.utc(2026, 7, 30),
            accuracyMeters: 90,
          ),
          target: target,
        ),
        GeofenceEvaluation.outside,
      );
    });

    test('rejects far points', () {
      final policy = GeofencePolicy(
        clock: () => DateTime.utc(2026, 7, 30, 0, 0, 1),
        debouncer: LocationFixDebouncer(
          requiredHits: 1,
          minInterval: Duration.zero,
        ),
      );
      expect(
        policy.evaluate(
          fix: LocationFix(
            point: far,
            recordedAt: DateTime.utc(2026, 7, 30),
            accuracyMeters: 10,
          ),
          target: target,
        ),
        GeofenceEvaluation.outside,
      );
    });

    test('rejects stale accurate fallback inside radius', () {
      final now = DateTime.utc(2026, 7, 30, 12);
      final policy = GeofencePolicy(
        clock: () => now,
        debouncer: LocationFixDebouncer(
          requiredHits: 1,
          minInterval: Duration.zero,
        ),
      );
      expect(
        policy.evaluate(
          fix: LocationFix(
            point: near,
            recordedAt: now.subtract(const Duration(minutes: 5)),
            accuracyMeters: 10,
            source: LocationSampleSource.lastKnown,
          ),
          target: target,
        ),
        GeofenceEvaluation.outside,
      );
    });
  });
}
