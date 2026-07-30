import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import 'data/device_location_gateway.dart';
import 'data/external_navigation_gateway.dart';
import 'data/fake_external_navigation_gateway.dart';
import 'data/fake_location_gateway.dart';
import 'data/location_gateway.dart';
import 'data/url_launcher_external_navigation_gateway.dart';

/// Explicit debug-only switch for physical-device STEP 4A validation.
///
/// Production always uses Device adapters. This define only replaces
/// location/navigation adapters in a debug build:
/// `--dart-define=SAEQ_DEVICE_LOCATION_QA=true`.
const bool _deviceLocationQa = bool.fromEnvironment('SAEQ_DEVICE_LOCATION_QA');

bool get deviceLocationAdaptersEnabled =>
    AppConfig.isProduction || (AppConfig.isDebug && _deviceLocationQa);

/// Location gateway: Device in production; Fake otherwise (override in tests).
final locationGatewayProvider = Provider<LocationGateway>((ref) {
  try {
    if (deviceLocationAdaptersEnabled) {
      return DeviceLocationGateway();
    }
  } catch (_) {
    // Widget tests may run before AppConfig initialization.
  }
  return FakeLocationGateway();
});

/// External navigation: real launcher in production; Fake otherwise.
final externalNavigationGatewayProvider = Provider<ExternalNavigationGateway>((
  ref,
) {
  try {
    if (deviceLocationAdaptersEnabled) {
      return UrlLauncherExternalNavigationGateway();
    }
  } catch (_) {}
  return FakeExternalNavigationGateway();
});
