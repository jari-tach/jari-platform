import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/app_service_registry.dart';
import '../../domain/repositories/authentication_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_controller_state.dart';

/// Bridges the statically-registered [AppServiceRegistry.authenticationRepository]
/// (PHASE 2.1/2.2 dependency-registration policy) into the Riverpod graph.
/// A function reference (not a value read once) so it always reflects the
/// current registry state and so tests can substitute a different reader.
AuthenticationRepository? _readAuthenticationRepository(Ref ref) =>
    AppServiceRegistry.isInitialized
    ? AppServiceRegistry.authenticationRepository
    : null;

/// The single [AuthController] instance for the app.
final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(
      () => AuthController(repositoryReader: _readAuthenticationRepository),
    );

/// Bridges [authControllerProvider] transitions into a plain [Listenable]
/// that GoRouter's `refreshListenable` can watch, so protected-route
/// redirects re-evaluate immediately on sign-in/sign-out/session
/// restoration instead of waiting for the next unrelated navigation.
/// See `AppRouter.build`.
class AuthRouterRefreshNotifier extends ChangeNotifier {
  AuthRouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AuthControllerState>(authControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.routingStatus != next.routingStatus) {
        notifyListeners();
      }
    });
  }

  late final ProviderSubscription<AuthControllerState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final authRouterRefreshProvider = Provider<AuthRouterRefreshNotifier>((ref) {
  final notifier = AuthRouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});
