import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/network/certificate_pin_config.dart';
import 'package:saeq_driver/core/network/certificate_pin_validator.dart';

void main() {
  group('CertificatePinValidator', () {
    const validator = CertificatePinValidator();

    test('matches known DER pin and rejects wrong pin', () {
      final der = Uint8List.fromList(List<int>.generate(64, (i) => i));
      final digest = sha256.convert(der);
      final goodPin = 'sha256/${base64.encode(digest.bytes)}';
      final badPin = 'sha256/${base64.encode(List<int>.filled(32, 9))}';

      expect(validator.pinFromDer(der), goodPin);
      // X509Certificate is platform-backed; exercise pinFromDer + list compare.
      expect(
        goodPin == badPin,
        isFalse,
        reason: 'fixture pins must differ for rejection assertion',
      );
      expect(<String>[goodPin].contains(validator.pinFromDer(der)), isTrue);
      expect(<String>[badPin].contains(validator.pinFromDer(der)), isFalse);
    });
  });

  group('CertificatePinConfig.resolve', () {
    test('disables pinning for loopback http Device QA backends', () {
      final config = CertificatePinConfig.resolve(
        baseUrl: 'http://127.0.0.1:3000',
        isProductionEnvironment: true,
        isReleaseMode: true,
        pinsDefine: 'sha256/AAAA',
        enableDefine: true,
        requirePinsInProduction: false,
      );
      expect(config.enabled, isFalse);
    });

    test('enables pinning for production https when pins provided', () {
      final config = CertificatePinConfig.resolve(
        baseUrl: 'https://api.saeq.com',
        isProductionEnvironment: true,
        isReleaseMode: true,
        pinsDefine: 'sha256/ABC,sha256/DEF',
        enableDefine: false,
        requirePinsInProduction: true,
      );
      expect(config.enabled, isTrue);
      expect(config.pins, ['sha256/ABC', 'sha256/DEF']);
      expect(config.shouldPinHost('api.saeq.com'), isTrue);
      expect(config.shouldPinHost('evil.example'), isFalse);
    });

    test('requires pins for production release builds', () {
      expect(
        () => CertificatePinConfig.resolve(
          baseUrl: 'https://api.saeq.com',
          isProductionEnvironment: true,
          isReleaseMode: true,
          pinsDefine: '',
          enableDefine: false,
          requirePinsInProduction: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'keeps local/dev https path usable without pins when not production',
      () {
        final config = CertificatePinConfig.resolve(
          baseUrl: 'https://dev-api.saeq.com',
          isProductionEnvironment: false,
          isReleaseMode: false,
          pinsDefine: '',
          enableDefine: false,
          requirePinsInProduction: true,
        );
        expect(config.enabled, isFalse);
      },
    );
  });
}
