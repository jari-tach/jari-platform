import 'package:flutter/foundation.dart';

/// Build-time / runtime certificate pinning policy for [SaeqApiClient].
///
/// Pins are public certificate fingerprints (not secrets). Provide via:
/// `--dart-define=SAEQ_TLS_PINS=sha256/ABC...,sha256/DEF...`
///
/// Enable explicitly with `--dart-define=SAEQ_ENABLE_CERT_PINNING=true`,
/// or automatically when [isProductionEnvironment] is true and pins exist.
final class CertificatePinConfig {
  const CertificatePinConfig({
    required this.enabled,
    required this.pins,
    required this.pinnedHosts,
  });

  final bool enabled;
  final List<String> pins;

  /// Empty means "pin every HTTPS host used by the API base URL host only"
  /// when resolved from [baseUrl]; see [resolve].
  final Set<String> pinnedHosts;

  bool shouldPinHost(String host) {
    if (!enabled || pins.isEmpty) return false;
    if (pinnedHosts.isEmpty) return true;
    return pinnedHosts.contains(host.toLowerCase());
  }

  /// Resolves pinning for the live SAEQ HTTP client.
  factory CertificatePinConfig.resolve({
    required String baseUrl,
    bool? isProductionEnvironment,
    bool? isReleaseMode,
    String? pinsDefine,
    bool? enableDefine,
    bool requirePinsInProduction = true,
  }) {
    final release = isReleaseMode ?? kReleaseMode;
    final production = isProductionEnvironment ?? false;
    const pinsFromEnv = String.fromEnvironment(
      'SAEQ_TLS_PINS',
      defaultValue: '',
    );
    const enableFromEnv = bool.fromEnvironment(
      'SAEQ_ENABLE_CERT_PINNING',
      defaultValue: false,
    );

    final rawPins = pinsDefine ?? pinsFromEnv;
    final pins = rawPins
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);

    final enabledFlag = enableDefine ?? enableFromEnv;
    final uri = Uri.tryParse(baseUrl);
    final scheme = uri?.scheme.toLowerCase() ?? '';
    final host = (uri?.host ?? '').toLowerCase();
    final isLoopback =
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1' ||
        host == '10.0.2.2';
    final isHttps = scheme == 'https';

    // Never pin cleartext / loopback Device QA backends.
    if (!isHttps || isLoopback) {
      return const CertificatePinConfig(
        enabled: false,
        pins: <String>[],
        pinnedHosts: <String>{},
      );
    }

    final shouldEnable =
        enabledFlag ||
        (production && pins.isNotEmpty) ||
        (release && production);

    if (requirePinsInProduction && production && release && pins.isEmpty) {
      throw StateError(
        'Certificate pinning pins are required for production release builds. '
        'Pass --dart-define=SAEQ_TLS_PINS=sha256/...,sha256/... '
        '(see docs/release_hardening/CERTIFICATE_PINNING_ROTATION_GUIDE.md).',
      );
    }

    final enabled = shouldEnable && pins.isNotEmpty;
    return CertificatePinConfig(
      enabled: enabled,
      pins: pins,
      pinnedHosts: host.isEmpty ? <String>{} : <String>{host},
    );
  }
}
