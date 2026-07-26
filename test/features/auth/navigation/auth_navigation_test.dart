import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';
import 'package:saeq_driver/core/providers/app_providers.dart';
import 'package:saeq_driver/core/routes/app_router.dart';
import 'package:saeq_driver/features/auth/data/repositories/fake_authentication_repository.dart';
import 'package:saeq_driver/features/auth/data/session/auth_session_storage.dart';
import 'package:saeq_driver/features/auth/domain/entities/authentication_status.dart';
import 'package:saeq_driver/features/auth/domain/entities/driver_session.dart';
import 'package:saeq_driver/features/auth/domain/repositories/authentication_repository.dart';
import 'package:saeq_driver/features/auth/presentation/controllers/auth_controller.dart';
import 'package:saeq_driver/features/auth/presentation/providers/auth_providers.dart';

import '../test_doubles.dart';

/// Manual fake whose `restoreSession()` never resolves, used to hold the
/// controller in the `restoring` (routing `unknown`) state indefinitely —
/// exercises the "no redirect loop while unknown" guard rule.
class _NeverRestoringRepository implements AuthenticationRepository {
  @override
  Future<DriverSession?> restoreSession() => Completer<DriverSession?>().future;

  @override
  Future<DriverSession> signIn(String phoneNumber) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  DriverSession? get currentSession => null;

  @override
  Stream<AuthenticationStatus> get authStateChanges => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

/// Bounded pump: avoids `pumpAndSettle` hanging forever when a Theme
/// dependency (Google Fonts) or an unfinished Future keeps scheduling
/// frames. Enough for GoRouter redirects + AuthController.restoreSession
/// (which is a single microtask + one await) to settle.
Future<void> _pumpUntilSettled(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

Future<GoRouter> _pumpRouterApp(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await _pumpUntilSettled(tester);
  return router;
}

void main() {
  group('Authentication-aware routing', () {
    late FakeSecureStorageService storage;
    late RecordingLoggerService logger;
    late AuthSessionStorage sessionStorage;

    setUp(() {
      storage = FakeSecureStorageService();
      logger = RecordingLoggerService();
      sessionStorage = AuthSessionStorage(storage: storage, logger: logger);
    });

    // 20. Guest blocked from protected route
    testWidgets(
      'unauthenticated user is redirected away from a protected route',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => AuthController(repositoryReader: (ref) => null),
            ),
          ],
        );
        addTearDown(container.dispose);
        final router = await _pumpRouterApp(tester, container);

        router.go(AppRoutes.home);
        await _pumpUntilSettled(tester);

        expect(router.state.uri.path, AppRoutes.login);
      },
    );

    // 21. Authenticated user redirected from login
    testWidgets('authenticated user is redirected away from the login route', (
      tester,
    ) async {
      final repository = FakeAuthenticationRepository(
        sessionStorage: sessionStorage,
        logger: logger,
        isProductionEnvironment: () => false,
        signInDelay: Duration.zero,
      );
      addTearDown(repository.dispose);
      await repository.signIn('0501234567');

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => AuthController(repositoryReader: (ref) => repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = await _pumpRouterApp(tester, container);

      router.go(AppRoutes.login);
      await _pumpUntilSettled(tester);

      expect(router.state.uri.path, AppRoutes.home);
    });

    // 22. Logout prevents Back to protected screen
    testWidgets(
      'signing out redirects away from a protected route and blocks returning to it',
      (tester) async {
        final repository = FakeAuthenticationRepository(
          sessionStorage: sessionStorage,
          logger: logger,
          isProductionEnvironment: () => false,
          signInDelay: Duration.zero,
        );
        addTearDown(repository.dispose);
        await repository.signIn('0501234567');

        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => AuthController(repositoryReader: (ref) => repository),
            ),
          ],
        );
        addTearDown(container.dispose);
        final router = await _pumpRouterApp(tester, container);

        router.go(AppRoutes.home);
        await _pumpUntilSettled(tester);
        expect(router.state.uri.path, AppRoutes.home);

        await container.read(authControllerProvider.notifier).signOut();
        await _pumpUntilSettled(tester);

        // refreshListenable must bounce away from the now-stale protected
        // route automatically, without any explicit navigation call.
        expect(router.state.uri.path, AppRoutes.login);

        // Simulates a back-stack entry still pointing at the protected
        // route: re-entering it after logout must redirect again, not show
        // the protected screen.
        router.go(AppRoutes.home);
        await _pumpUntilSettled(tester);
        expect(router.state.uri.path, AppRoutes.login);
      },
    );

    // 23. Restore session opens protected route
    testWidgets(
      'a successfully restored session allows a protected deep link through',
      (tester) async {
        final repository = FakeAuthenticationRepository(
          sessionStorage: sessionStorage,
          logger: logger,
          isProductionEnvironment: () => false,
          signInDelay: Duration.zero,
        );
        addTearDown(repository.dispose);
        await repository.signIn('0501234567');

        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => AuthController(repositoryReader: (ref) => repository),
            ),
          ],
        );
        addTearDown(container.dispose);
        final router = await _pumpRouterApp(tester, container);

        router.go(AppRoutes.home);
        await _pumpUntilSettled(tester);

        expect(router.state.uri.path, AppRoutes.home);
      },
    );

    // 24. No redirect loop during unknown state
    testWidgets(
      'an undecided (restoring) status never redirects, on any route',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(
              () => AuthController(
                repositoryReader: (ref) => _NeverRestoringRepository(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        final router = await _pumpRouterApp(tester, container);

        router.go(AppRoutes.home);
        await _pumpUntilSettled(tester);
        expect(router.state.uri.path, AppRoutes.home);

        router.go(AppRoutes.login);
        await _pumpUntilSettled(tester);
        expect(router.state.uri.path, AppRoutes.login);

        router.go(AppRoutes.welcome);
        await _pumpUntilSettled(tester);
        expect(router.state.uri.path, AppRoutes.welcome);
      },
    );

    // Regression guard: the pre-existing Explore Architecture flow must
    // keep working unauthenticated (STABILIZATION STEP 4C).
    testWidgets('Explore Architecture stays reachable without authentication', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => AuthController(repositoryReader: (ref) => null),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = await _pumpRouterApp(tester, container);

      router.go(AppRoutes.comingSoon);
      await _pumpUntilSettled(tester);

      expect(router.state.uri.path, AppRoutes.comingSoon);
      expect(
        find.text('Page not found: ${AppRoutes.comingSoon}'),
        findsNothing,
      );
    });
  });
}
