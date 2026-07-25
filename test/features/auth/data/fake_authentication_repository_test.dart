import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/domain/policies/fake_auth_policy.dart';

import '../test_doubles.dart';

void main() {
  group('FakeAuthenticationRepository', () {
    late FakeSecureStorageService storage;
    late RecordingLoggerService logger;
    late AuthSessionStorage sessionStorage;
    late FakeAuthenticationRepository repository;

    setUp(() {
      storage = FakeSecureStorageService();
      logger = RecordingLoggerService();
      sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
      repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: Duration.zero,
      );
    });

    tearDown(() => repository.dispose());

    test('restoreSession returns null when no session exists', () async {
      final restored = await repository.restoreSession();

      expect(restored, isNull);
      expect(repository.currentSession, isNull);
    });

    test('restoreSession returns the session saved by signIn', () async {
      await repository.signIn('0501234567');

      final freshRepository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: Duration.zero,
      );
      addTearDown(freshRepository.dispose);

      final restored = await freshRepository.restoreSession();

      expect(restored, isNotNull);
      expect(restored!.phoneNumber, '0501234567');
      expect(freshRepository.currentSession, restored);
    });

    test(
      'restoreSession clears corrupted stored data and returns null',
      () async {
        storage.debugSeedRawValue('auth_driver_session_v1', 'not-json');

        final restored = await repository.restoreSession();

        expect(restored, isNull);
        expect(repository.currentSession, isNull);
        expect(storage.debugRawValue('auth_driver_session_v1'), isNull);
      },
    );

    test('signIn succeeds for a valid trial phone number', () async {
      final session = await repository.signIn('0501234567');

      expect(session.phoneNumber, '0501234567');
      expect(repository.currentSession, session);
      expect(await sessionStorage.readSession(), isNotNull);
    });

    test('signIn throws InvalidPhoneNumberError for invalid input', () async {
      await expectLater(
        repository.signIn('123'),
        throwsA(isA<InvalidPhoneNumberError>()),
      );
    });

    test('signIn propagates a simulated failure', () async {
      repository.debugSimulateNextSignInFailure(
        const AuthenticationRejectedError(),
      );

      await expectLater(
        repository.signIn('0501234567'),
        throwsA(isA<AuthenticationRejectedError>()),
      );
    });

    test('signOut clears the stored session', () async {
      await repository.signIn('0501234567');

      await repository.signOut();

      expect(repository.currentSession, isNull);
      expect(await sessionStorage.readSession(), isNull);
    });

    test('repeated signOut is safe', () async {
      await repository.signIn('0501234567');

      await repository.signOut();
      await repository.signOut();

      expect(repository.currentSession, isNull);
    });

    test('restoreSession treats a forced-expired session as absent', () async {
      await repository.signIn('0501234567');
      repository.debugForceSessionExpired(true);

      final restored = await repository.restoreSession();

      expect(restored, isNull);
      expect(repository.currentSession, isNull);
      expect(await sessionStorage.readSession(), isNull);
    });

    test('throws StateError when production environment is reported', () {
      expect(
        () => FakeAuthenticationRepository(
          sessionStorage: sessionStorage,
          logger: logger,
          isProductionEnvironment: () => true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('productionEnvironmentDenied'),
              contains(FakeAuthPolicy.policyVersion),
            ),
          ),
        ),
      );
    });

    test('caller data cannot enable Fake Auth when production is reported', () {
      // Injected session/logger/phone are irrelevant — construction still fails.
      expect(
        () => FakeAuthenticationRepository(
          sessionStorage: sessionStorage,
          logger: logger,
          isProductionEnvironment: () => true,
          signInDelay: Duration.zero,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('works in allowed development/test configuration', () async {
      expect(repository.currentSession, isNull);
      final session = await repository.signIn('0501234567');
      expect(session.phoneNumber, '0501234567');
    });

    test(
      'supplemental: no bool.fromEnvironment release bypass in source',
      () async {
        final source = await File(
          'lib/features/auth/data/repositories/'
          'fake_authentication_repository.dart',
        ).readAsString();
        expect(source.contains('bool.fromEnvironment'), isFalse);
        expect(source.contains('kReleaseMode'), isTrue);
      },
    );
  });
}
