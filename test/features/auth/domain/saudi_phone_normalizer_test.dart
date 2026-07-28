import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/domain/saudi_phone_normalizer.dart';

void main() {
  group('normalizeSaudiPhoneNumber', () {
    test('returns local format unchanged', () {
      expect(normalizeSaudiPhoneNumber('0501234567'), '0501234567');
    });

    test('trims surrounding whitespace', () {
      expect(normalizeSaudiPhoneNumber('  0501234567  '), '0501234567');
    });

    test('converts +966 prefix to local format', () {
      expect(normalizeSaudiPhoneNumber('+966501234567'), '0501234567');
    });

    test('converts 966 prefix to local format', () {
      expect(normalizeSaudiPhoneNumber('966501234567'), '0501234567');
    });

    test('converts 00966 prefix to local format', () {
      expect(normalizeSaudiPhoneNumber('00966501234567'), '0501234567');
    });

    test('accepts spaced international input', () {
      expect(normalizeSaudiPhoneNumber('+966 50 123 4567'), '0501234567');
    });

    test('returns null for invalid local length', () {
      expect(normalizeSaudiPhoneNumber('051234567'), isNull);
      expect(normalizeSaudiPhoneNumber('05012345678'), isNull);
    });

    test('returns null for invalid international length', () {
      expect(normalizeSaudiPhoneNumber('+96650123456'), isNull);
    });

    test('returns null for non-mobile prefix', () {
      expect(normalizeSaudiPhoneNumber('0401234567'), isNull);
      expect(normalizeSaudiPhoneNumber('+966401234567'), isNull);
    });

    test('returns null for empty input', () {
      expect(normalizeSaudiPhoneNumber(''), isNull);
      expect(normalizeSaudiPhoneNumber('   '), isNull);
    });
  });

  group('isValidSaudiPhoneInput', () {
    test('matches normalizeSaudiPhoneNumber non-null results', () {
      expect(isValidSaudiPhoneInput('0501234567'), isTrue);
      expect(isValidSaudiPhoneInput('+966501234567'), isTrue);
      expect(isValidSaudiPhoneInput('123'), isFalse);
    });
  });
}
