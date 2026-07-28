import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/profile/domain/email_validator.dart';

void main() {
  group('normalizeOptionalEmail', () {
    test('null and empty become null', () {
      expect(normalizeOptionalEmail(null), isNull);
      expect(normalizeOptionalEmail(''), isNull);
      expect(normalizeOptionalEmail('   '), isNull);
    });

    test('trims non-empty values', () {
      expect(normalizeOptionalEmail('  a@b.co  '), 'a@b.co');
    });
  });

  group('isValidOptionalEmail', () {
    test('empty optional email is valid', () {
      expect(isValidOptionalEmail(null), isTrue);
      expect(isValidOptionalEmail(''), isTrue);
      expect(isValidOptionalEmail('   '), isTrue);
    });

    test('accepts reasonable email shapes', () {
      expect(isValidOptionalEmail('user@example.com'), isTrue);
      expect(isValidOptionalEmail('  user@example.com  '), isTrue);
    });

    test('rejects missing @', () {
      expect(isValidOptionalEmail('not-an-email'), isFalse);
    });

    test('rejects missing domain', () {
      expect(isValidOptionalEmail('user@'), isFalse);
    });

    test('rejects malformed domain', () {
      expect(isValidOptionalEmail('user@domain'), isFalse);
      expect(isValidOptionalEmail('user@domain.'), isFalse);
    });
  });

  group('validateOptionalEmail', () {
    test('returns null for valid or empty input', () {
      expect(validateOptionalEmail('', invalidMessage: 'Invalid'), isNull);
      expect(
        validateOptionalEmail('user@example.com', invalidMessage: 'Invalid'),
        isNull,
      );
    });

    test('returns message for invalid input', () {
      expect(
        validateOptionalEmail('bad', invalidMessage: 'Enter a valid email.'),
        'Enter a valid email.',
      );
    });
  });
}
