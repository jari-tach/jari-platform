import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/authentication_status.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/delivery/presentation/pages/active_delivery_page.dart';
import '../../features/delivery/presentation/pages/incoming_delivery_offer_page.dart';
import '../../features/driver/presentation/home_screen.dart';
import '../../features/driver/presentation/shell_placeholder_screen.dart';
import '../../features/driver/presentation/welcome_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../localization/app_localizations.dart';

/// App routes
class AppRoutes {
  // Route paths
  static const String welcome = '/';
  static const String comingSoon = '/coming-soon';
  static const String login = '/login';
  static const String home = '/home';
  static const String deliveries = '/deliveries';
  static const String earnings = '/earnings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String support = '/support';

  /// Legacy alias — redirects to [deliveries].
  static const String orders = '/orders';

  /// Full-screen delivery offer (ADR-026). Outside shell nav.
  static const String deliveryOffer = '/delivery/offer';

  /// Active delivery stub (PHASE 2.6 Inc 1). Outside shell nav.
  static const String deliveryActive = '/delivery/active';

  /// Protected path roots (exact or nested under these prefixes).
  static const List<String> protectedRoots = [
    home,
    deliveries,
    earnings,
    notifications,
    profile,
    settings,
    support,
    orders,
    '/delivery',
  ];

  static bool isProtected(String path) {
    for (final root in protectedRoots) {
      if (path == root || path.startsWith('$root/')) {
        return true;
      }
    }
    return false;
  }

  // Prevent instantiation
  AppRoutes._();
}

/// App router configuration
///
/// Features:
/// - Deep linking
/// - Authentication redirects (PHASE 2.2)
/// - Guards
/// - ShellRoute (5-tab Driver shell — PHASE 2.6)
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
      errorBuilder: (context, state) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          body: Center(
            child: Text(
              l10n.pageNotFoundWithUri('${state.uri}'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        );
      },

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

        // Compat: old Orders tab → Deliveries.
        if (path == AppRoutes.orders) {
          return AppRoutes.deliveries;
        }

        switch (status) {
          case AuthenticationStatus.unknown:
            return null;
          case AuthenticationStatus.unauthenticated:
            return AppRoutes.isProtected(path) ? AppRoutes.login : null;
          case AuthenticationStatus.authenticated:
            // Trial sessions restore on cold start; send drivers to Home so
            // Drift assignment + busy reconciliation are visible immediately.
            if (isLoginRoute || path == AppRoutes.welcome) {
              return AppRoutes.home;
            }
            return null;
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
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return ShellPlaceholderScreen(
              title: l10n.exploreArchitectureScreenTitle,
            );
          },
        ),

        // Trial driver sign-in (public)
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),

        // Full-screen delivery offer (protected, outside bottom nav — ADR-026)
        GoRoute(
          path: AppRoutes.deliveryOffer,
          builder: (context, state) => const IncomingDeliveryOfferPage(),
        ),

        // Active delivery stub (protected, outside bottom nav — PHASE 2.6)
        GoRoute(
          path: AppRoutes.deliveryActive,
          builder: (context, state) => const ActiveDeliveryPage(),
        ),

        // Settings / Support (protected, outside bottom nav — under Profile)
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return ShellPlaceholderScreen(title: l10n.settingsScreenTitle);
          },
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return ShellPlaceholderScreen(title: l10n.supportScreenTitle);
          },
        ),

        // Shell route for main app (with bottom nav) — protected
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(
              body: child,
              bottomNavigationBar: _buildBottomNav(context),
            );
          },
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: AppRoutes.deliveries,
              builder: (context, state) {
                final l10n = AppLocalizations.of(context);
                return ShellPlaceholderScreen(
                  title: l10n.deliveriesScreenTitle,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.earnings,
              builder: (context, state) {
                final l10n = AppLocalizations.of(context);
                return ShellPlaceholderScreen(title: l10n.earningsScreenTitle);
              },
            ),
            GoRoute(
              path: AppRoutes.notifications,
              builder: (context, state) {
                final l10n = AppLocalizations.of(context);
                return ShellPlaceholderScreen(
                  title: l10n.notificationsScreenTitle,
                );
              },
            ),
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
  }

  /// Build bottom navigation bar — 5 destinations (PHASE 2.6).
  ///
  /// Settings / Support live under Profile (focus routes), not as root tabs.
  /// Use [GoRouter.go] on tab taps to avoid stacking duplicates.
  static Widget _buildBottomNav(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = switch (path) {
      AppRoutes.deliveries => 1,
      AppRoutes.earnings => 2,
      AppRoutes.notifications => 3,
      AppRoutes.profile => 4,
      _ => 0,
    };
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      // Narrow phones (320dp) + Arabic labels: avoid overflow paint errors.
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: l10n.navHome,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.local_shipping_outlined),
          label: l10n.navDeliveries,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.payments_outlined),
          label: l10n.navEarnings,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications_outlined),
          label: l10n.navNotifications,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.navProfile,
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.home);
          case 1:
            context.go(AppRoutes.deliveries);
          case 2:
            context.go(AppRoutes.earnings);
          case 3:
            context.go(AppRoutes.notifications);
          case 4:
            context.go(AppRoutes.profile);
        }
      },
    );
  }
}
