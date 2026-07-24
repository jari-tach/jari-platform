import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/driver/presentation/welcome_screen.dart';

/// App routes
class AppRoutes {
  // Route paths
  static const String welcome = '/';
  static const String comingSoon = '/coming-soon';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Prevent instantiation
  AppRoutes._();
}

/// App router configuration
///
/// Features:
/// - Deep linking
/// - Authentication redirects
/// - Guards
/// - ShellRoute
/// - Navigation observers
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.welcome,

    // Error page for unknown routes
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    ),

    // Redirect logic
    redirect: (context, state) {
      // TODO: Add authentication guard
      // final isAuthenticated = sl<SecureStorageService>().getAccessToken() != null;
      // final isLoginRoute = state.uri.path == AppRoutes.welcome;
      //
      // if (!isAuthenticated && !isLoginRoute) {
      //   return AppRoutes.welcome;
      // }
      // if (isAuthenticated && isLoginRoute) {
      //   return AppRoutes.home;
      // }

      return null;
    },

    // Navigation observers
    observers: [
      // TODO: Add analytics observer
      // AnalyticsObserver(),
    ],

    // Routes
    routes: [
      // Welcome screen (initial route)
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

      // Shell route for main app (with bottom nav)
      ShellRoute(
        builder: (context, state, child) {
          // TODO: Add scaffold with bottom navigation
          return Scaffold(
            body: child,
            bottomNavigationBar: _buildBottomNav(context),
          );
        },
        routes: [
          // Home
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => _buildPlaceholder(context, 'Home'),
          ),

          // Orders
          GoRoute(
            path: AppRoutes.orders,
            builder: (context, state) => _buildPlaceholder(context, 'Orders'),
          ),

          // Profile
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => _buildPlaceholder(context, 'Profile'),
          ),

          // Settings
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => _buildPlaceholder(context, 'Settings'),
          ),
        ],
      ),
    ],
  );

  /// Build bottom navigation bar
  static Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
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
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title screen - Coming soon',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}