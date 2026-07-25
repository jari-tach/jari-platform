import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/authentication_status.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/driver/presentation/home_screen.dart';
import '../../features/driver/presentation/welcome_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// App routes
class AppRoutes {
  // Route paths
  static const String welcome = '/';
  static const String comingSoon = '/coming-soon';
  static const String login = '/login';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// Routes that require an authenticated session (PHASE 2.2).
  /// `welcome` and `comingSoon` intentionally stay public so the existing
  /// Explore Architecture flow keeps working unauthenticated (no
  /// regression — see STABILIZATION STEP 4C).
  static const List<String> protectedPaths = [home, orders, profile, settings];

  static bool isProtected(String path) => protectedPaths.contains(path);

  // Prevent instantiation
  AppRoutes._();
}

/// App router configuration
///
/// Features:
/// - Deep linking
/// - Authentication redirects (PHASE 2.2)
/// - Guards
/// - ShellRoute
/// - Navigation observers
class AppRouter {
  /// Builds the app's [GoRouter].
  ///
  /// [refreshListenable] should notify whenever the coarse-grained
  /// [AuthenticationStatus] changes (see `AuthRouterRefreshNotifier`) so
  /// protected-route redirects re-evaluate immediately on sign-in/sign-out
  /// instead of waiting for the next unrelated navigation.
  ///
  /// [authStatus] must be a cheap, synchronous read of the current status
  /// (e.g. `() => ref.read(authControllerProvider).routingStatus`).
  static GoRouter build({
    required Listenable refreshListenable,
    required AuthenticationStatus Function() authStatus,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.welcome,
      refreshListenable: refreshListenable,

      // Error page for unknown routes
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Page not found: ${state.uri}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),

      // Authentication guard (PHASE 2.2).
      //
      // Rules:
      // - `unknown` (initial/restoring/authenticating/signingOut): never
      //   redirect. Avoids both a flicker away from wherever the user
      //   already is and any redirect loop while status is undecided.
      // - `unauthenticated`: bounce away from protected routes to /login.
      // - `authenticated`: bounce away from /login to /home.
      redirect: (context, state) {
        final status = authStatus();
        final path = state.uri.path;
        final isLoginRoute = path == AppRoutes.login;

        switch (status) {
          case AuthenticationStatus.unknown:
            return null;
          case AuthenticationStatus.unauthenticated:
            return AppRoutes.isProtected(path) ? AppRoutes.login : null;
          case AuthenticationStatus.authenticated:
            return isLoginRoute ? AppRoutes.home : null;
        }
      },

      // Navigation observers
      observers: [
        // TODO: Add analytics observer
        // AnalyticsObserver(),
      ],

      // Routes
      routes: [
        // Welcome screen (initial route, public)
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),

        // Explore Architecture (sub-screen pushed from Welcome; must allow
        // Back to return to the Welcome screen instead of exiting the app).
        GoRoute(
          path: AppRoutes.comingSoon,
          builder: (context, state) =>
              _buildPlaceholder(context, 'Explore Architecture'),
        ),

        // Trial driver sign-in (public)
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),

        // Shell route for main app (with bottom nav) — protected
        ShellRoute(
          builder: (context, state, child) {
            // TODO: Add scaffold with bottom navigation
            return Scaffold(
              body: child,
              bottomNavigationBar: _buildBottomNav(context),
            );
          },
          routes: [
            // Home (authenticated landing + sign-out)
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),

            // Orders
            GoRoute(
              path: AppRoutes.orders,
              builder: (context, state) => _buildPlaceholder(context, 'Orders'),
            ),

            // Profile (PHASE 2.3)
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),

            // Settings
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) =>
                  _buildPlaceholder(context, 'Settings'),
            ),
          ],
        ),
      ],
    );
  }

  /// Build bottom navigation bar
  static Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.home);
            break;
          case 1:
            context.go(AppRoutes.orders);
            break;
          case 2:
            context.go(AppRoutes.profile);
            break;
          case 3:
            context.go(AppRoutes.settings);
            break;
        }
      },
    );
  }

  /// Build placeholder screen
  static Widget _buildPlaceholder(BuildContext context, String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title screen - Coming soon',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
