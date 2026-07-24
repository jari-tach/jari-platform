import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application environment
enum Environment { dev, staging, production }

/// Application configuration
///
/// Supports multiple environments:
/// - dev: Development environment
/// - staging: Staging/QA environment
/// - production: Production environment
class AppConfig {
  static const String _apiUrlDev = 'https://dev-api.saeq.com';
  static const String _apiUrlStaging = 'https://staging-api.saeq.com';
  static const String _apiUrlProd = 'https://api.saeq.com';

  static const String _appName = 'SAEQ Driver';
  static const String _appVersion = '1.0.0';
  static const int _buildNumber = 1;

  // Environment
  static Environment _environment = Environment.dev;

  // API Configuration
  static String get baseApiUrl {
    switch (_environment) {
      case Environment.dev:
        return _apiUrlDev;
      case Environment.staging:
        return _apiUrlStaging;
      case Environment.production:
        return _apiUrlProd;
    }
  }

  // App Information
  static String get appName => _appName;
  static String get appVersion => _appVersion;
  static int get buildNumber => _buildNumber;

  // Environment
  static Environment get environment => _environment;
  static bool get isDev => _environment == Environment.dev;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  // Debug Mode
  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;
  static bool get isProfile => kProfileMode;

  // Platform
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => kIsWeb;
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  // Feature Flags
  static const bool enableLogging = true;
  static const bool enableAnalytics = false; // TODO: Enable in production
  static const bool enableCrashReporting = false; // TODO: Enable in production
  static const bool enablePerformanceMonitoring = false; // TODO: Enable in production

  // API Configuration
  static const int connectTimeout = 15; // seconds
  static const int receiveTimeout = 15; // seconds
  static const int sendTimeout = 15; // seconds

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Cache Configuration
  static const Duration cacheDuration = Duration(minutes: 5);
  static const int maxCacheSize = 100; // MB

  // Security Configuration
  static const bool enableCertificatePinning = false; // TODO: Enable in production
  static const bool enableRequestSigning = false; // TODO: Enable in production

  // Initialize configuration
  static void init({Environment? environment}) {
    // Set environment from command line or default to dev
    if (environment != null) {
      _environment = environment;
    } else {
      // Try to get from environment variable
      final env = Platform.environment['SAEQ_ENV'];
      switch (env?.toLowerCase()) {
        case 'staging':
          _environment = Environment.staging;
          break;
        case 'production':
          _environment = Environment.production;
          break;
        case 'dev':
        default:
          _environment = Environment.dev;
          break;
      }
    }

    if (kDebugMode) {
      _environment = Environment.dev;
    }

    // Use debugPrint instead of print for Flutter compatibility
    debugPrint('AppConfig: Initialized with environment: $_environment');
    debugPrint('AppConfig: API URL: $baseApiUrl');
  }

  // Get configuration as map (for debugging)
  Map<String, dynamic> toMap() {
    return {
      'environment': _environment.name,
      'apiUrl': baseApiUrl,
      'appName': _appName,
      'appVersion': _appVersion,
      'buildNumber': _buildNumber,
      'isDebug': isDebug,
      'isRelease': isRelease,
      'platform': Platform.operatingSystem,
      'featureFlags': {
        'enableLogging': enableLogging,
        'enableAnalytics': enableAnalytics,
        'enableCrashReporting': enableCrashReporting,
        'enablePerformanceMonitoring': enablePerformanceMonitoring,
      },
    };
  }

  @override
  String toString() {
    return 'AppConfig(${toMap()})';
  }
}