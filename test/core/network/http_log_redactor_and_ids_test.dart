import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/network/http_log_redactor.dart';
import 'package:saeq_driver/core/network/request_id_factory.dart';
import 'package:saeq_driver/core/network/idempotency_key_factory.dart';

void main() {
  group('HttpLogRedactor', () {
    final redactor = HttpLogRedactor();

    test('redacts Authorization header', () {
      final out = redactor.redactHeaders({
        'Authorization': 'Bearer secret-token',
        'X-Request-Id': 'rid-1',
      });
      expect(out['Authorization'], '***');
      expect(out['X-Request-Id'], 'rid-1');
    });

    test('redacts tokens and otp from body', () {
      final out =
          redactor.redactBody({
                'accessToken': 'tok-a',
                'refreshToken': 'tok-r',
                'otpCode': '246810',
                'phoneNumber': '+9665',
              })
              as Map;
      expect(out['accessToken'], '***');
      expect(out['refreshToken'], '***');
      expect(out['otpCode'], '***');
      expect(out['phoneNumber'], '+9665');
    });
  });

  group('RequestIdFactory', () {
    test('generates unique non-empty ids', () {
      final factory = RequestIdFactory();
      final a = factory.next();
      final b = factory.next();
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(a, isNot(b));
    });
  });

  group('IdempotencyKeyFactory', () {
    test('generates unique keys', () {
      final factory = IdempotencyKeyFactory();
      expect(factory.next(), isNot(factory.next()));
    });
  });
}
