import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/domain/entities/driver_session.dart';

void main() {
  group('DriverSession', () {
    const token = 'super-secret-session-token-value';

    const session = DriverSession(
      driverId: 'fake-123',
      phoneNumber: '0501234567',
      sessionToken: token,
    );

    test('round-trips through toJson/fromJson', () {
      final expiresAt = DateTime.utc(2026, 7, 25, 12, 0);
      final original = DriverSession(
        driverId: session.driverId,
        phoneNumber: session.phoneNumber,
        sessionToken: session.sessionToken,
        expiresAt: expiresAt,
      );

      final restored = DriverSession.fromJson(original.toJson());

      expect(restored, original);
    });

    test('throws FormatException for missing or invalid required fields', () {
      expect(
        () => DriverSession.fromJson(<String, dynamic>{}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DriverSession.fromJson(<String, dynamic>{'driverId': ''}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DriverSession.fromJson(<String, dynamic>{
          'driverId': 'id',
          'phoneNumber': '',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DriverSession.fromJson(<String, dynamic>{
          'driverId': 'id',
          'phoneNumber': '0501234567',
          'sessionToken': '',
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DriverSession.fromJson(<String, dynamic>{
          'driverId': 'id',
          'phoneNumber': '0501234567',
          'sessionToken': 'token',
          'expiresAt': 123,
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DriverSession.fromJson(<String, dynamic>{
          'driverId': 'id',
          'phoneNumber': '0501234567',
          'sessionToken': 'token',
          'expiresAt': 'not-a-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('isExpired reflects expiresAt against now', () {
      final active = DriverSession(
        driverId: session.driverId,
        phoneNumber: session.phoneNumber,
        sessionToken: session.sessionToken,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      final expired = DriverSession(
        driverId: session.driverId,
        phoneNumber: session.phoneNumber,
        sessionToken: session.sessionToken,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final neverExpires = DriverSession(
        driverId: session.driverId,
        phoneNumber: session.phoneNumber,
        sessionToken: session.sessionToken,
      );

      expect(active.isExpired, isFalse);
      expect(expired.isExpired, isTrue);
      expect(neverExpires.isExpired, isFalse);
    });

    test('maskedPhoneNumber and toString never expose sessionToken', () {
      expect(session.maskedPhoneNumber, '********67');
      expect(session.maskedPhoneNumber, isNot(contains(token)));
      expect(session.toString(), isNot(contains(token)));
      expect(session.toString(), contains(session.maskedPhoneNumber));
    });
  });
}
