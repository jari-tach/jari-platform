import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'certificate_pin_config.dart';
import 'certificate_pin_validator.dart';

/// Applies TLS certificate pinning to a Dio client without logging pin values.
void applyCertificatePinning(
  Dio dio, {
  required CertificatePinConfig config,
  CertificatePinValidator validator = const CertificatePinValidator(),
}) {
  if (!config.enabled || config.pins.isEmpty) return;

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      // Reject bad certificates at the OS layer; pin check is additional.
      client.badCertificateCallback = (cert, host, port) => false;
      return client;
    },
    validateCertificate: (cert, host, port) {
      if (cert == null) return false;
      if (!config.shouldPinHost(host)) {
        // Host outside the API pin set: leave default TLS trust only.
        return true;
      }
      final ok = validator.matchesAny(cert, config.pins);
      if (!ok && kDebugMode) {
        // Do not print pin material — host only.
        debugPrint('Certificate pin validation failed for host=$host');
      }
      return ok;
    },
  );
}
