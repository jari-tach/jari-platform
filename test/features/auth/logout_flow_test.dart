import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saeq_driver/core/preferences/app_preferences.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/domain/entities/authentication_status.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller_state.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';

import 'test_doubles.dart';

const _trialPhone = '0501234567';

Future<void> _waitForAuthSettle(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
    final status = container.read(authControllerProvider).status;
    if (status != AuthControllerStatus.initial &&
        status != AuthControllerStatus.restoring) {
      return;
    }
  }
}

ProviderContainer _createContainer(FakeAuthenticationRepository repository) {
  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith(
        () => AuthController(repositoryReader: (ref) => repository),
      ),
    ],
  );
}

void main() {
  group('Logout flow', () {
    late FakeSecureStorageService storage;
    late RecordingLoggerService logger;
    late AuthSessionStorage sessionStorage;
    late FakeAuthenticationRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = FakeSecureStorageService();
      logger = RecordingLoggerService();
      sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
      repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: Duration.zero,
        otpRequestDelay: Duration.zero,
      );
    });

    tearDown(() => repository.dispose());

    test('logout success clears session and OTP challenge', () async {
      await repository.requestOtp(_trialPhone);
      await repository.signIn(_trialPhone);

      await repository.signOut();

      expect(repository.currentSession, isNull);
      expect(repository.otpResendAvailableAt, isNull);
      expect(await sessionStorage.readSession(), isNull);
    });

    test('AuthController logout success clears session', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);
      await container.read(authControllerProvider.notifier).signIn(_trialPhone);

      await container.read(authControllerProvider.notifier).signOut();

      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.unauthenticated,
      );
      expect(repository.currentSession, isNull);
    });

    test('duplicate logout calls are ignored while signingOut', () async {
      final deleteGate = Completer<void>();
      storage.deleteDelay = deleteGate.future;

      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);
      await container.read(authControllerProvider.notifier).signIn(_trialPhone);

      final first = container.read(authControllerProvider.notifier).signOut();
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.signingOut,
      );

      await container.read(authControllerProvider.notifier).signOut();
      deleteGate.complete();
      await first;

      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.unauthenticated,
      );
    });

    test(
      'secure-clear failure surfaces SecureStorageFailureError and keeps session',
      () async {
        final container = _createContainer(repository);
        addTearDown(container.dispose);

        container.read(authControllerProvider);
        await _waitForAuthSettle(container);
        await container
            .read(authControllerProvider.notifier)
            .signIn(_trialPhone);

        repository.debugFailNextSessionClear();

        await container.read(authControllerProvider.notifier).signOut();

        final state = container.read(authControllerProvider);
        expect(state.status, AuthControllerStatus.failure);
        expect(state.error, isA<SecureStorageFailureError>());
        expect(state.session, isNotNull);
        expect(state.routingStatus, AuthenticationStatus.authenticated);
        expect(repository.currentSession, isNotNull);
        expect(await sessionStorage.readSession(), isNotNull);
      },
    );

    test(
      'repository signOut throws SecureStorageFailureError on clear failure',
      () async {
        await repository.signIn(_trialPhone);
        repository.debugFailNextSessionClear();

        await expectLater(
          repository.signOut(),
          throwsA(isA<SecureStorageFailureError>()),
        );
      },
    );

    test('theme and language preferences survive logout', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.themeModeKey: 'dark',
        AppPreferences.localeLanguageCodeKey: 'en',
      });

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => AuthController(repositoryReader: (ref) => repository),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(appThemeModeProvider);
      container.read(appLocaleProvider);
      await container.read(appPreferencesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(appThemeModeProvider), ThemeMode.dark);
      expect(container.read(appLocaleProvider).languageCode, 'en');

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);
      await container.read(authControllerProvider.notifier).signIn(_trialPhone);
      await container.read(authControllerProvider.notifier).signOut();

      expect(container.read(appThemeModeProvider), ThemeMode.dark);
      expect(container.read(appLocaleProvider).languageCode, 'en');
    });

    test('concurrent refreshSession calls share one Future', () async {
      await repository.signIn(_trialPhone);

      final first = repository.refreshSession();
      final second = repository.refreshSession();

      expect(identical(first, second), isTrue);
      await first;
      await second;
    });

    test('concurrent refresh does not double-clear expired session', () async {
      await repository.signIn(_trialPhone);
      repository.debugForceSessionExpired(true);

      final first = repository.refreshSession();
      final second = repository.refreshSession();

      expect(identical(first, second), isTrue);
      final results = await Future.wait([first, second]);
      expect(results.every((session) => session == null), isTrue);
      expect(await sessionStorage.readSession(), isNull);
    });

    test(
      'AuthController refreshSession de-duplicates concurrent calls',
      () async {
        final container = _createContainer(repository);
        addTearDown(container.dispose);

        container.read(authControllerProvider);
        await _waitForAuthSettle(container);
        await container
            .read(authControllerProvider.notifier)
            .signIn(_trialPhone);

        final first = container
            .read(authControllerProvider.notifier)
            .refreshSession();
        final second = container
            .read(authControllerProvider.notifier)
            .refreshSession();

        await Future.wait([first, second]);

        expect(
          container.read(authControllerProvider).status,
          AuthControllerStatus.authenticated,
        );
      },
    );

    test('requestOtp normalizes international phone numbers', () async {
      await repository.requestOtp('+966501234567');

      final session = await repository.verifyOtp(
        phoneNumber: '0501234567',
        otpCode: '246810',
      );

      expect(session.phoneNumber, _trialPhone);
    });

    test('requestOtp rejects invalid phone after normalization', () async {
      await expectLater(
        repository.requestOtp('+966401234567'),
        throwsA(isA<InvalidPhoneNumberError>()),
      );
    });

    test('resend cooldown survives repository instance semantics', () async {
      await repository.requestOtp(_trialPhone);
      final cooldownUntil = repository.otpResendAvailableAt;

      await expectLater(
        repository.requestOtp(_trialPhone),
        throwsA(isA<OtpRateLimitedError>()),
      );
      expect(repository.otpResendAvailableAt, cooldownUntil);
    });
  });
}
