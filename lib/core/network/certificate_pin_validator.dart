import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// SHA-256 certificate (DER) pins in `sha256/<base64>` form.
final class CertificatePinValidator {
  const CertificatePinValidator();

  /// Build pin string from certificate DER bytes.
  String pinFromDer(List<int> derBytes) {
    final digest = sha256.convert(derBytes);
    return 'sha256/${base64.encode(digest.bytes)}';
  }

  String pinFromCertificate(X509Certificate certificate) =>
      pinFromDer(certificate.der);

  /// Returns true when [certificate] matches any allowed pin.
  bool matchesAny(X509Certificate certificate, Iterable<String> allowedPins) {
    if (allowedPins.isEmpty) return false;
    final pin = pinFromCertificate(certificate);
    for (final allowed in allowedPins) {
      if (pin == allowed.trim()) return true;
    }
    return false;
  }
}
