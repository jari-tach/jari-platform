import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saeq_driver/core/preferences/app_preferences.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/domain/policies/fake_auth_policy.dart';

import '../test_doubles.dart';

const _trialPhone = '0501234567';
const _trialOtp = '246810';

void main() {
  group('Fake OTP production gate proof', () {
    late FakeSecureStorageService storage;
    late RecordingLoggerService logger;
    late AuthSessionStorage sessionStorage;

    setUp(() {
      storage = FakeSecureStorageService();
      logger = RecordingLoggerService();
      sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
    });

    test('construction denied when production environment is reported', () {
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

    test('construction allowed in non-production environment', () {
      final repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: Duration.zero,
        otpRequestDelay: Duration.zero,
      );
      addTearDown(repository.dispose);

      expect(repository.currentSession, isNull);
    });

    test('requestOtp never persists OTP in secure storage', () async {
      final repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        otpRequestDelay: Duration.zero,
      );
      addTearDown(repository.dispose);

      await repository.requestOtp(_trialPhone);

      for (final entry in storage.debugAllRawValues().entries) {
        expect(entry.key, isNot(contains('otp')));
        expect(entry.key.toLowerCase(), isNot(contains('token')));
        expect(entry.value.contains(_trialOtp), isFalse);
      }
      expect(storage.debugRawValue('auth_driver_session_v1'), isNull);
    });

    test('verify success clears pending OTP; reuse fails as expired', () async {
      final repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        otpRequestDelay: Duration.zero,
      );
      addTearDown(repository.dispose);

      await repository.requestOtp(_trialPhone);
      await repository.verifyOtp(phoneNumber: _trialPhone, otpCode: _trialOtp);

      expect(repository.otpResendAvailableAt, isNull);

      await expectLater(
        repository.verifyOtp(phoneNumber: _trialPhone, otpCode: _trialOtp),
        throwsA(isA<ExpiredOtpError>()),
      );
    });

    test('clearOtpChallenge clears pending state', () async {
      final repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        otpRequestDelay: Duration.zero,
      );
      addTearDown(repository.dispose);

      await repository.requestOtp(_trialPhone);
      expect(repository.otpResendAvailableAt, isNotNull);

      repository.clearOtpChallenge();

      expect(repository.otpResendAvailableAt, isNull);
      await expectLater(
        repository.verifyOtp(phoneNumber: _trialPhone, otpCode: _trialOtp),
        throwsA(isA<ExpiredOtpError>()),
      );
    });

    test('expiry path clears pending OTP challenge', () async {
      final fixedNow = DateTime(2026, 1, 1, 12);
      final repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        otpRequestDelay: Duration.zero,
      );
      addTearDown(repository.dispose);

      repository.debugSetNow(() => fixedNow);
      await repository.requestOtp(_trialPhone);

      repository.debugSetNow(() => fixedNow.add(const Duration(minutes: 6)));

      await expectLater(
        repository.verifyOtp(phoneNumber: _trialPhone, otpCode: _trialOtp),
        throwsA(isA<ExpiredOtpError>()),
      );
      expect(repository.otpResendAvailableAt, isNull);
    });

    test(
      'SharedPreferences holds theme/locale only; no auth secrets after OTP',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appPreferences = AppPreferences(prefs);
        await appPreferences.saveThemeMode(ThemeMode.dark);
        await appPreferences.saveLocale(const Locale('en'));

        final repository = FakeAuthenticationRepository(
          sessionStorage: sessionStorage,
          logger: logger,
          isProductionEnvironment: () => false,
          otpRequestDelay: Duration.zero,
        );
        addTearDown(repository.dispose);

        await repository.requestOtp(_trialPhone);
        await repository.verifyOtp(
          phoneNumber: _trialPhone,
          otpCode: _trialOtp,
        );

        for (final key in prefs.getKeys()) {
          final lowerKey = key.toLowerCase();
          expect(lowerKey.contains('otp'), isFalse);
          expect(lowerKey.contains('token'), isFalse);
          expect(lowerKey.contains('session'), isFalse);
        }
        expect(prefs.getString(AppPreferences.themeModeKey), 'dark');
        expect(prefs.getString(AppPreferences.localeLanguageCodeKey), 'en');
        expect(storage.debugRawValue('auth_driver_session_v1'), isNotNull);
      },
    );

    test('logger never records trial OTP digits', () async {
      final repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        otpRequestDelay: Duration.zero,
      );
      addTearDown(repository.dispose);

      await repository.requestOtp(_trialPhone);
      await repository.verifyOtp(phoneNumber: _trialPhone, otpCode: _trialOtp);

      expect(logger.messages.any((m) => m.contains(_trialOtp)), isFalse);
    });

    test(
      'AppServiceRegistry wires Fake auth only when ctor guard allows it',
      () async {
        final registrySource = await File(
          'lib/shared/services/app_service_registry.dart',
        ).readAsString();
        final repositorySource = await File(
          'lib/features/auth/data/repositories/'
          'fake_authentication_repository.dart',
        ).readAsString();

        expect(
          registrySource,
          contains("FakeAuthenticationRepository's constructor enforces"),
        );
        expect(registrySource, contains('FakeAuthenticationRepository('));
        expect(registrySource, contains('AppConfig.isProduction'));
        expect(repositorySource, contains('Never for production'));
        expect(repositorySource, contains('FakeAuthPolicy.evaluate'));
      },
    );
  });
}
