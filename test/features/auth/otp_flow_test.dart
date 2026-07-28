import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller_state.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';
import 'package:saeq_driver/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:saeq_driver/shared/widgets/saeq_primary_button.dart';

import 'test_doubles.dart';

const _trialPhone = '0501234567';
const _trialOtp = '246810';

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

Future<void> _pumpOtpScreen(
  WidgetTester tester, {
  required List<Override> overrides,
  String phone = _trialPhone,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: OtpVerificationScreen(phoneNumber: phone),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('OTP authentication flow', () {
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
        otpRequestDelay: Duration.zero,
      );
    });

    tearDown(() => repository.dispose());

    List<Override> overridesWith(FakeAuthenticationRepository repo) => [
      authControllerProvider.overrideWith(
        () => AuthController(repositoryReader: (ref) => repo),
      ),
    ];

    test('requestOtp succeeds for a valid phone number', () async {
      await repository.requestOtp(_trialPhone);

      expect(repository.otpResendAvailableAt, isNotNull);
      expect(logger.messages.any((m) => m.contains(_trialOtp)), isFalse);
    });

    test(
      'requestOtp throws InvalidPhoneNumberError for invalid input',
      () async {
        await expectLater(
          repository.requestOtp('123'),
          throwsA(isA<InvalidPhoneNumberError>()),
        );
      },
    );

    test('requestOtp enforces resend cooldown', () async {
      await repository.requestOtp(_trialPhone);

      await expectLater(
        repository.requestOtp(_trialPhone),
        throwsA(isA<OtpRateLimitedError>()),
      );
    });

    test('verifyOtp succeeds with Fake Alpha trial code', () async {
      await repository.requestOtp(_trialPhone);

      final session = await repository.verifyOtp(
        phoneNumber: _trialPhone,
        otpCode: _trialOtp,
      );

      expect(session.phoneNumber, _trialPhone);
      expect(repository.currentSession, session);
      expect(repository.otpResendAvailableAt, isNull);
      expect(await sessionStorage.readSession(), isNotNull);
    });

    test('verifyOtp throws InvalidOtpError for incorrect code', () async {
      await repository.requestOtp(_trialPhone);

      await expectLater(
        repository.verifyOtp(phoneNumber: _trialPhone, otpCode: '000000'),
        throwsA(isA<InvalidOtpError>()),
      );
    });

    test('verifyOtp throws ExpiredOtpError when challenge expired', () async {
      final fixedNow = DateTime(2026, 1, 1, 12);
      repository.debugSetNow(() => fixedNow);
      await repository.requestOtp(_trialPhone);

      repository.debugSetNow(() => fixedNow.add(const Duration(minutes: 6)));

      await expectLater(
        repository.verifyOtp(phoneNumber: _trialPhone, otpCode: _trialOtp),
        throwsA(isA<ExpiredOtpError>()),
      );
    });

    test('OTP code is never written to secure session storage', () async {
      await repository.requestOtp(_trialPhone);

      final raw = storage.debugRawValue('auth_driver_session_v1');
      expect(raw, isNull);
      expect(raw?.contains(_trialOtp) ?? false, isFalse);
    });

    test('OTP code is never logged', () async {
      await repository.requestOtp(_trialPhone);
      await repository.verifyOtp(phoneNumber: _trialPhone, otpCode: _trialOtp);

      expect(logger.messages.any((m) => m.contains(_trialOtp)), isFalse);
    });

    test('signOut clears session and pending OTP state', () async {
      await repository.requestOtp(_trialPhone);
      await repository.signIn(_trialPhone);

      await repository.signOut();

      expect(repository.currentSession, isNull);
      expect(repository.otpResendAvailableAt, isNull);
      expect(await sessionStorage.readSession(), isNull);
    });

    test('refreshSession returns current session when valid', () async {
      await repository.signIn(_trialPhone);

      final refreshed = await repository.refreshSession();

      expect(refreshed, isNotNull);
      expect(refreshed!.phoneNumber, _trialPhone);
    });

    test('AuthController requestOtp transitions to otpRequested', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);

      await container
          .read(authControllerProvider.notifier)
          .requestOtp(_trialPhone);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthControllerStatus.otpRequested);
      expect(state.pendingPhone, _trialPhone);
      expect(state.resendAvailableAt, isNotNull);
    });

    test('AuthController resendOtp respects cooldown', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);
      await container
          .read(authControllerProvider.notifier)
          .requestOtp(_trialPhone);

      await container.read(authControllerProvider.notifier).resendOtp();

      final state = container.read(authControllerProvider);
      expect(state.error, isA<OtpRateLimitedError>());
    });

    test('AuthController verifyOtp authenticates with trial code', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);
      await container
          .read(authControllerProvider.notifier)
          .requestOtp(_trialPhone);

      await container
          .read(authControllerProvider.notifier)
          .verifyOtp(_trialOtp);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthControllerStatus.authenticated);
      expect(state.session?.phoneNumber, _trialPhone);
    });

    test('verifyOtp throws IncompleteOtpError for short code', () async {
      await repository.requestOtp(_trialPhone);

      await expectLater(
        repository.verifyOtp(phoneNumber: _trialPhone, otpCode: '123'),
        throwsA(isA<IncompleteOtpError>()),
      );
    });

    testWidgets('verify button is disabled when OTP field is empty', (
      tester,
    ) async {
      await _pumpOtpScreen(tester, overrides: overridesWith(repository));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OtpVerificationScreen)),
      );
      await container
          .read(authControllerProvider.notifier)
          .requestOtp(_trialPhone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final button = tester.widget<SaeqPrimaryButton>(
        find.byKey(const Key('otpVerifySubmit')),
      );
      expect(button.onPressed, isNull);
    });

    test(
      'AuthController verifyOtp with incomplete code surfaces IncompleteOtpError',
      () async {
        final container = _createContainer(repository);
        addTearDown(container.dispose);

        container.read(authControllerProvider);
        await _waitForAuthSettle(container);
        await container
            .read(authControllerProvider.notifier)
            .requestOtp(_trialPhone);

        await container.read(authControllerProvider.notifier).verifyOtp('12');

        final state = container.read(authControllerProvider);
        expect(state.status, AuthControllerStatus.otpRequested);
        expect(state.error, isA<IncompleteOtpError>());
      },
    );

    testWidgets('resend shows cooldown text after OTP request', (tester) async {
      await _pumpOtpScreen(tester, overrides: overridesWith(repository));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OtpVerificationScreen)),
      );
      await container
          .read(authControllerProvider.notifier)
          .requestOtp(_trialPhone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Resend in'), findsOneWidget);
      expect(_cooldownSecondsFrom(tester), isNotNull);
      expect(_cooldownSecondsFrom(tester)!, greaterThan(0));
    });
  });
}

int? _cooldownSecondsFrom(WidgetTester tester) {
  final finder = find.byKey(const Key('otpSubtitleMessage'));
  if (finder.evaluate().isEmpty) return null;
  final text = tester.widget<Text>(finder).data ?? '';
  final match = RegExp(r'(\d{2}):(\d{2})').firstMatch(text);
  if (match == null) return null;
  final minutes = int.tryParse(match.group(1)!);
  final seconds = int.tryParse(match.group(2)!);
  if (minutes == null || seconds == null) return null;
  return minutes * 60 + seconds;
}
