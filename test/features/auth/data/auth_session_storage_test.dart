import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/driver_session.dart';

import '../test_doubles.dart';

void main() {
  group('AuthSessionStorage', () {
    late FakeSecureStorageService storage;
    late RecordingLoggerService logger;
    late AuthSessionStorage sessionStorage;

    const sessionKey = 'auth_driver_session_v1';

    const session = DriverSession(
      driverId: 'fake-123',
      phoneNumber: '0501234567',
      sessionToken: 'trial-token',
      expiresAt: null,
    );

    setUp(() {
      storage = FakeSecureStorageService();
      logger = RecordingLoggerService();
      sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
    });

    test('readSession returns null when storage is empty', () async {
      expect(await sessionStorage.readSession(), isNull);
    });

    test('saveSession and readSession round-trip a valid session', () async {
      await sessionStorage.saveSession(session);

      final restored = await sessionStorage.readSession();

      expect(restored, session);
    });

    test('clearSession removes the stored session', () async {
      await sessionStorage.saveSession(session);
      await sessionStorage.clearSession();

      expect(await sessionStorage.readSession(), isNull);
      expect(storage.debugRawValue(sessionKey), isNull);
    });

    test('corrupted non-JSON data is cleared and returns null', () async {
      storage.debugSeedRawValue(sessionKey, 'not-json');

      final restored = await sessionStorage.readSession();

      expect(restored, isNull);
      expect(storage.debugRawValue(sessionKey), isNull);
      expect(
        logger.messages.any((m) => m.contains('corrupted session data')),
        isTrue,
      );
    });

    test('missing required fields are cleared and return null', () async {
      storage.debugSeedRawValue(
        sessionKey,
        '{"driverId":"id","phoneNumber":"0501234567"}',
      );

      final restored = await sessionStorage.readSession();

      expect(restored, isNull);
      expect(storage.debugRawValue(sessionKey), isNull);
    });

    test(
      'delete failure during clear still does not throw from readSession',
      () async {
        storage.debugSeedRawValue(sessionKey, 'not-json');
        storage.throwOnNextDelete = Exception('delete failed');

        expect(await sessionStorage.readSession(), isNull);
      },
    );

    test('saveSession propagates storage write failures', () async {
      storage.throwOnNextWrite = Exception('write failed');

      await expectLater(
        sessionStorage.saveSession(session),
        throwsA(isA<Exception>()),
      );
    });
  });
}
