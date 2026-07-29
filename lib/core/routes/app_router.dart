import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/authentication_status.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/session_expired_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/delivery/presentation/pages/active_delivery_page.dart';
import '../../features/delivery/presentation/pages/delivery_issue_page.dart';
import '../../features/delivery/presentation/pages/delivery_verify_page.dart';
import '../../features/delivery/presentation/pages/incoming_delivery_offer_page.dart';
import '../../features/driver/presentation/home_screen.dart';
import '../../features/driver/presentation/shell_placeholder_screen.dart';
import '../../features/driver/presentation/welcome_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/history/presentation/screens/deliveries_history_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/documents/document_upload_screen.dart';
import '../../features/profile/documents/documents_list_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/vehicle/vehicle_edit_screen.dart';
import '../../features/profile/vehicle/vehicle_overview_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/support/presentation/screens/support_safety_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../localization/app_localizations.dart';
import '../theme/saeq_semantic_colors.dart';

/// App routes
class AppRoutes {
  // Route paths
  static const String splash = '/splash';
  static const String welcome = '/';
  static const String onboarding = '/onboarding';
  static const String comingSoon = '/coming-soon';
  static const String login = '/login';
  static const String loginOtp = '/login/otp';
  static const String sessionExpired = '/session-expired';
  static const String home = '/home';
  static const String deliveries = '/deliveries';
  static const String earnings = '/earnings';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileVehicle = '/profile/vehicle';
  static const String profileVehicleEdit = '/profile/vehicle/edit';
  static const String profileDocuments = '/profile/documents';
  static const String profileDocumentsUpload = '/profile/documents/upload';
  static const String settings = '/settings';
  static const String support = '/support';
  static const String supportSafety = '/support/safety';

  /// Legacy alias — redirects to [deliveries].
  static const String orders = '/orders';

  /// Full-screen delivery offer (ADR-026). Outside shell nav.
  static const String deliveryOffer = '/delivery/offer';

  /// Active delivery (PHASE 2.6 Inc 2). Outside shell nav.
  static const String deliveryActive = '/delivery/active';

  /// Delivery verification (PHASE 2.6 Inc 2).
  static const String deliveryVerify = '/delivery/verify';

  /// Delivery issue report (PHASE 2.6 Inc 2).
  static const String deliveryIssue = '/delivery/issue';

  static String deliveryHistoryDetail(String id) => '/deliveries/$id';

  static String earningsDetail(String id) => '/earnings/$id';

  static String notificationDetail(String id) => '/notifications/$id';

  static String profileDocumentDetail(String id) => '/profile/documents/$id';

  /// Public auth / entry routes that authenticated users should leave.
  static const List<String> authEntryRoutes = [
    splash,
    welcome,
    onboarding,
    login,
    loginOtp,
    sessionExpired,
  ];

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

  static bool isAuthEntry(String path) => authEntryRoutes.contains(path);

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
      initialLocation: AppRoutes.splash,
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
        final isAuthEntry = AppRoutes.isAuthEntry(path);

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
            if (isAuthEntry) {
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
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // Welcome screen (public)
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),

        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),

        GoRoute(
          path: AppRoutes.sessionExpired,
          builder: (context, state) => const SessionExpiredScreen(),
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

        // OTP verification (public, unauthenticated OTP flow)
        GoRoute(
          path: AppRoutes.loginOtp,
          builder: (context, state) {
            final phone = state.uri.queryParameters['phone'] ?? '';
            return OtpVerificationScreen(phoneNumber: phone);
          },
        ),

        // Full-screen delivery offer (protected, outside bottom nav — ADR-026)
        GoRoute(
          path: AppRoutes.deliveryOffer,
          builder: (context, state) => const IncomingDeliveryOfferPage(),
        ),

        // Active delivery (protected, outside bottom nav — PHASE 2.6)
        GoRoute(
          path: AppRoutes.deliveryActive,
          builder: (context, state) => const ActiveDeliveryPage(),
        ),
        GoRoute(
          path: AppRoutes.deliveryVerify,
          builder: (context, state) => const DeliveryVerifyPage(),
        ),
        GoRoute(
          path: AppRoutes.deliveryIssue,
          builder: (context, state) => const DeliveryIssuePage(),
        ),

        // History / earnings / notification details (no bottom nav)
        GoRoute(
          path: '/deliveries/:id',
          builder: (context, state) =>
              DeliveryHistoryDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/earnings/:id',
          builder: (context, state) =>
              EarningsDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/notifications/:id',
          builder: (context, state) =>
              NotificationDetailScreen(id: state.pathParameters['id']!),
        ),

        // Settings / Support (protected, outside bottom nav — under Profile)
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: AppRoutes.supportSafety,
          builder: (context, state) => const SupportSafetyScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileEdit,
          builder: (context, state) => const ProfileEditScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileVehicle,
          builder: (context, state) => const VehicleOverviewScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileVehicleEdit,
          builder: (context, state) => const VehicleEditScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileDocuments,
          builder: (context, state) => const DocumentsListScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileDocumentsUpload,
          builder: (context, state) => const DocumentUploadScreen(),
        ),
        GoRoute(
          path: '/profile/documents/:id',
          builder: (context, state) =>
              DocumentDetailScreen(id: state.pathParameters['id']!),
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
              builder: (context, state) => const DeliveriesHistoryScreen(),
            ),
            GoRoute(
              path: AppRoutes.earnings,
              builder: (context, state) => const EarningsScreen(),
            ),
            GoRoute(
              path: AppRoutes.notifications,
              builder: (context, state) => const NotificationsScreen(),
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
  /// Detail routes (`/deliveries/:id` etc.) live outside the shell — keep
  /// bottom-nav highlight on the nearest root tab when path is nested.
  static Widget _buildBottomNav(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = () {
      if (path == AppRoutes.deliveries ||
          path.startsWith('${AppRoutes.deliveries}/')) {
        return 1;
      }
      if (path == AppRoutes.earnings ||
          path.startsWith('${AppRoutes.earnings}/')) {
        return 2;
      }
      if (path == AppRoutes.notifications ||
          path.startsWith('${AppRoutes.notifications}/')) {
        return 3;
      }
      if (path == AppRoutes.profile ||
          path.startsWith('${AppRoutes.profile}/')) {
        return 4;
      }
      return 0;
    }();
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textSecondary,
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
