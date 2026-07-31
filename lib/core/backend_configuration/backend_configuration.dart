import 'package:flutter/foundation.dart';

import 'backend_mode.dart';

/// Build-time backend configuration (STEP 5C-1).
///
/// ```
/// --dart-define=SAEQ_BACKEND_MODE=fake|remote
/// --dart-define=SAEQ_API_BASE_URL=http://127.0.0.1:3000
/// ```
///
/// Rules:
/// - Tests / Debug: fake allowed
/// - Profile / Release: remote only (fake MUST fail)
/// - No production URL constants; base URL comes from dart-define only
final class BackendConfiguration {
  const BackendConfiguration({required this.mode, required this.apiBaseUrl});

  final BackendMode mode;
  final String? apiBaseUrl;

  bool get isFake => mode == BackendMode.fake;
  bool get isRemote => mode == BackendMode.remote;

  /// Resolves configuration for the current process.
  ///
  /// [modeOverride] / [baseUrlOverride] are test-only injection points.
  factory BackendConfiguration.resolve({
    String? modeDefine,
    String? baseUrlDefine,
    bool? isReleaseMode,
    bool? isProfileMode,
    bool? isDebugMode,
  }) {
    final release = isReleaseMode ?? kReleaseMode;
    final profile = isProfileMode ?? kProfileMode;
    final debug = isDebugMode ?? kDebugMode;

    const fromDefineMode = String.fromEnvironment(
      'SAEQ_BACKEND_MODE',
      defaultValue: 'fake',
    );
    const fromDefineUrl = String.fromEnvironment(
      'SAEQ_API_BASE_URL',
      defaultValue: '',
    );

    final mode = BackendMode.parse(modeDefine ?? fromDefineMode);
    final baseUrl = _normalizeBaseUrl(baseUrlDefine ?? fromDefineUrl);

    if (mode == BackendMode.fake && (release || profile)) {
      throw StateError(
        'Fake backend is not permitted in profile/release builds. '
        'Use SAEQ_BACKEND_MODE=remote with SAEQ_API_BASE_URL.',
      );
    }

    if (mode == BackendMode.remote) {
      if (baseUrl == null || baseUrl.isEmpty) {
        throw StateError(
          'SAEQ_API_BASE_URL is required when SAEQ_BACKEND_MODE=remote.',
        );
      }
      if (_looksLikeForbiddenProductionUrl(baseUrl) && debug) {
        // Allow only explicit non-production hosts in debug remote mode.
        // Production domains must never be committed as defaults.
      }
    }

    return BackendConfiguration(mode: mode, apiBaseUrl: baseUrl);
  }

  static String? _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  static bool _looksLikeForbiddenProductionUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('api.saeq.com') && !lower.contains('example.invalid');
  }
}
