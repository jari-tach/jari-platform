import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:saeq_driver/features/location/data/device_location_platform.dart';

void main() {
  group('PluginDeviceLocationPlatform.deviceWatchLocationSettings', () {
    test('uses zero distanceFilter so stationary geofence hits can arrive', () {
      final settings = PluginDeviceLocationPlatform.deviceWatchLocationSettings(
        forceAndroidLocationManager: false,
      );
      expect(settings.distanceFilter, 0);
      expect(settings.accuracy, geo.LocationAccuracy.high);
    });

    test(
      'Android watch settings keep Fused (do not force LocationManager)',
      () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        // Issue #38 HONOR Device QA: adb mocks land on fused/test; LM gps stays
        // null. Watch path must use Fused (forceLocationManager: false).
        final settings =
            PluginDeviceLocationPlatform.deviceWatchLocationSettings(
              forceAndroidLocationManager: false,
              interval: const Duration(seconds: 2),
            );
        expect(settings, isA<geo.AndroidSettings>());
        final android = settings as geo.AndroidSettings;
        expect(android.distanceFilter, 0);
        expect(android.intervalDuration, const Duration(seconds: 2));
        expect(android.forceLocationManager, isFalse);
      },
    );

    test(
      'Android settings can still opt into LocationManager when requested',
      () {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        final settings =
            PluginDeviceLocationPlatform.deviceWatchLocationSettings(
              forceAndroidLocationManager: true,
              interval: const Duration(seconds: 2),
            );
        final android = settings as geo.AndroidSettings;
        expect(android.forceLocationManager, isTrue);
      },
    );
  });
}
