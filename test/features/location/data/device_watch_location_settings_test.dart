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

    test('Android QA settings force LocationManager and interval', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final settings = PluginDeviceLocationPlatform.deviceWatchLocationSettings(
        forceAndroidLocationManager: true,
        interval: const Duration(seconds: 2),
      );
      expect(settings, isA<geo.AndroidSettings>());
      final android = settings as geo.AndroidSettings;
      expect(android.distanceFilter, 0);
      expect(android.intervalDuration, const Duration(seconds: 2));
      expect(android.forceLocationManager, isTrue);
    });
  });
}
