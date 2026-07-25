import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/auth_error.dart';
import 'package:saeq_driver/features/auth/domain/entities/driver_session.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller_state.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';

import '../test_doubles.dart';

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
  group('AuthController', () {
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

    test('cold start with no saved session ends unauthenticated', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);

      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.unauthenticated,
      );
    });

    test('cold start with a saved session ends authenticated', () async {
      await sessionStorage.saveSession(
        const DriverSession(
          driverId: 'fake-123',
          phoneNumber: '0501234567',
          sessionToken: 'trial-token',
        ),
      );

      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthControllerStatus.authenticated);
      expect(state.session?.phoneNumber, '0501234567');
    });

    test(
      'signIn transitions through authenticating to authenticated',
      () async {
        final container = _createContainer(repository);
        addTearDown(container.dispose);

        container.read(authControllerProvider);
        await _waitForAuthSettle(container);

        final signInFuture = container
            .read(authControllerProvider.notifier)
            .signIn('0501234567');
        expect(
          container.read(authControllerProvider).status,
          AuthControllerStatus.authenticating,
        );

        await signInFuture;

        final state = container.read(authControllerProvider);
        expect(state.status, AuthControllerStatus.authenticated);
        expect(state.session?.phoneNumber, '0501234567');
      },
    );

    test('signOut transitions through signingOut to unauthenticated', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);
      await container
          .read(authControllerProvider.notifier)
          .signIn('0501234567');

      final signOutFuture = container
          .read(authControllerProvider.notifier)
          .signOut();
      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.signingOut,
      );

      await signOutFuture;

      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.unauthenticated,
      );
      expect(repository.currentSession, isNull);
    });

    test('failure can be cleared and retried successfully', () async {
      repository.debugSimulateNextSignInFailure(
        const AuthenticationRejectedError(),
      );

      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);

      await container
          .read(authControllerProvider.notifier)
          .signIn('0501234567');
      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.failure,
      );

      container.read(authControllerProvider.notifier).clearError();
      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.unauthenticated,
      );

      await container
          .read(authControllerProvider.notifier)
          .signIn('0501234567');
      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.authenticated,
      );
    });

    test('duplicate signIn calls are ignored while busy', () async {
      final slowRepository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: const Duration(milliseconds: 100),
      );
      addTearDown(slowRepository.dispose);

      final container = _createContainer(slowRepository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);

      final first = container
          .read(authControllerProvider.notifier)
          .signIn('0501234567');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.authenticating,
      );

      await container
          .read(authControllerProvider.notifier)
          .signIn('0509999999');
      await first;

      expect(
        container.read(authControllerProvider).session?.phoneNumber,
        '0501234567',
      );
    });

    test('repeated signOut is safe', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);
      await container
          .read(authControllerProvider.notifier)
          .signIn('0501234567');

      await container.read(authControllerProvider.notifier).signOut();
      await container.read(authControllerProvider.notifier).signOut();

      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.unauthenticated,
      );
    });

    test('clearError only resets a failure state', () async {
      final container = _createContainer(repository);
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await _waitForAuthSettle(container);

      container.read(authControllerProvider.notifier).clearError();
      expect(
        container.read(authControllerProvider).status,
        AuthControllerStatus.unauthenticated,
      );
    });
  });
}
