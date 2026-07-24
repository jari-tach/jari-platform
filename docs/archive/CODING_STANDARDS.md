# SAEQ DRIVER — Coding Standards & Development Guidelines

> **Version:** 1.0.0  
> **Status:** Draft (Pending Approval)  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  

---

## Table of Contents

1. [Coding Standards](#1-coding-standards)
2. [Naming Convention](#2-naming-convention)
3. [Flutter Guidelines](#3-flutter-guidelines)
4. [Riverpod Guidelines](#4-riverpod-guidelines)
5. [GoRouter Guidelines](#5-go_router-guidelines)

---

## 1. Coding Standards

### 1.1 Language & Toolchain

| Item | Standard |
|------|----------|
| Language | Dart (sound null safety, SDK ^3.12.2) |
| Style Guide | [Effective Dart](https://dart.dev/guides/language/effective-dart) |
| Linter | `flutter_lints` + custom rules (see `analysis_options.yaml`) |
| Formatter | `dart format` with 120-character line limit |
| Documentation | `dartdoc` for all public APIs |
| Package Manager | `pub` (via `flutter pub`) |

### 1.2 Formatting Rules

- **Line Length:** Maximum 120 characters per line.
- **Indentation:** 2 spaces (no tabs).
- **Trailing Commas:** Always include trailing commas in multi-line collections and argument lists.
- **Quotes:** Use double quotes (`"`) for strings. Single quotes (`'`) are permitted only for strings containing double quotes.
- **Braces:** Always use braces for control flow statements (`if`, `for`, `while`), even for single-line bodies.

### 1.3 Documentation Rules

- **All public classes, methods, getters, setters, and functions** must have a `///` doc comment.
- Doc comments should describe:
  - What the API does
  - Parameters and their constraints
  - Return value
  - Thrown exceptions (if any)
- Use [markdown](https://dart.dev/guides/language/effective-dart/documentation) formatting in doc comments.
- Private members (prefixed with `_`) do not require doc comments but should have inline comments for complex logic.

### 1.4 Code Quality Rules

- **Immutability:** Prefer `final` for all variables. Prefer `const` constructors where possible.
- **Null Safety:** All code must be null-safe. No `!` (bang) operators unless absolutely necessary and documented.
- **SOLID Principles:**
  - **Single Responsibility:** Each class should have one reason to change.
  - **Open/Closed:** Classes should be open for extension, closed for modification.
  - **Liskov Substitution:** Subtypes must be substitutable for their base types.
  - **Interface Segregation:** Prefer small, focused interfaces over large ones.
  - **Dependency Inversion:** Depend on abstractions, not concretions.
- **DRY:** Avoid code duplication. Extract shared logic into reusable functions, classes, or mixins.
- **KISS:** Keep it simple. Avoid over-engineering.
- **No Business Logic in Widgets:** Widgets should only handle UI rendering and user interaction. Delegate business logic to use cases.
- **No `print()`:** Use the Logger service for all output.

### 1.5 Error Handling Rules

- Use `try/catch` blocks at the use case boundary.
- Catch specific exception types, not generic `Exception` or `dynamic`.
- Convert all exceptions to `Failure` objects before propagating to the presentation layer.
- Log all errors with sufficient context for debugging.
- Show user-friendly error messages via SnackBars or dialogs.
- Never crash the app on recoverable errors.

### 1.6 Testing Rules

- Write tests for all new code.
- **Unit Tests:** Test use cases, entities, validators, and utilities in isolation.
- **Widget Tests:** Test individual widgets and their interactions.
- **Integration Tests:** Test complete feature flows.
- Use `mocktail` for mocking dependencies.
- Use `golden` tests for visual regression testing.
- Target 80%+ code coverage.
- Test edge cases and error scenarios, not just happy paths.

### 1.7 Import Rules

- Use `dart:` imports first, then `package:` imports, then relative imports.
- Group imports with a blank line between each group.
- Use relative imports within the same feature module.
- Use `package:` imports for cross-feature or core/shared dependencies.
- Avoid barrel files (re-export files) unless they significantly improve readability.

```dart
// ✅ Correct import order
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';
```

### 1.8 Async/Await Rules

- Always use `async/await` instead of `.then()` chains.
- Use `Future<void>` for async functions that don't return a value.
- Use `FutureOr<T>` when a function may return synchronously or asynchronously.
- Avoid blocking the UI thread with synchronous operations.

### 1.9 Performance Rules

- Use `const` constructors wherever possible.
- Use `ListView.builder` for large lists (lazy loading).
- Use `CachedNetworkImage` for image loading (when approved).
- Avoid `setState` in favor of Riverpod state management.
- Use `RepaintBoundary` for widgets that repaint frequently.
- Profile performance regularly with DevTools.

---

## 2. Naming Convention

### 2.1 General Rules

| Element | Convention | Example |
|---------|-----------|---------|
| Classes, Enums, Typedefs | PascalCase | `OrderService`, `DeliveryStatus`, `OrderCallback` |
| Functions, Methods, Variables | camelCase | `getOrders()`, `isLoading`, `calculateTotal()` |
| Constants (static const) | lowerCamelCase | `defaultPadding`, `apiTimeoutSeconds` |
| Constants (compile-time const) | lowerCamelCase | `maxRetryAttempts`, `defaultPageSize` |
| Files | snake_case | `order_service.dart`, `driver_profile.dart` |
| Directories | snake_case | `features/orders/`, `core/utils/` |
| Parameters | camelCase | `orderId`, `includeDetails` |
| Type Parameters (generics) | PascalCase (single letter or descriptive) | `T`, `E`, `Key`, `Value` |

### 2.2 Feature-Specific Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Feature Classes | PascalCase + `Feature` suffix | `OrdersFeature`, `DriverFeature` |
| Use Cases | PascalCase + `UseCase` suffix | `GetOrdersUseCase`, `AcceptOrderUseCase` |
| Entities | PascalCase | `Order`, `Driver`, `Delivery` |
| Repository Interfaces | PascalCase + `Repository` suffix | `OrderRepository`, `DriverRepository` |
| Data Sources | PascalCase + `DataSource` suffix | `OrderRemoteDataSource`, `OrderLocalDataSource` |
| Models | PascalCase + `Model` suffix | `OrderModel`, `DriverModel` |
| View Models | PascalCase + `ViewModel` suffix | `OrdersViewModel`, `DriverProfileViewModel` |
| State Classes | PascalCase + `State` suffix | `OrdersState`, `AuthState` |

### 2.3 Provider Naming

| Element | Convention | Example |
|---------|-----------|---------|
| StateNotifier Providers | camelCase + `Provider` suffix | `ordersProvider`, `authStateProvider` |
| Simple Value Providers | camelCase + `Provider` suffix | `appThemeModeProvider`, `appLocaleProvider` |
| Future Providers | camelCase + `Provider` suffix | `driverProfileProvider`, `ordersListProvider` |
| Stream Providers | camelCase + `Provider` suffix | `orderUpdatesProvider`, `locationStreamProvider` |
| Provider Families | camelCase + `Provider` suffix | `orderByIdProvider`, `driverByIdProvider` |

### 2.4 Exception & Failure Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Exceptions | PascalCase + `Exception` suffix | `NetworkException`, `AuthException` |
| Failures | PascalCase + `Failure` suffix | `NetworkFailure`, `ServerFailure` |
| Error Codes | SCREAMING_SNAKE_CASE | `ERROR_NETWORK_TIMEOUT`, `ERROR_AUTH_INVALID_TOKEN` |

### 2.5 Constants & Keys

| Element | Convention | Example |
|---------|-----------|---------|
| String Constants | lowerCamelCase | `appNameKey`, `defaultLanguageCode` |
| Numeric Constants | lowerCamelCase | `defaultPageSize`, `maxImageSizeBytes` |
| Route Names | kebab-case | `'orders-list'`, `'driver-profile'` |
| Route Paths | kebab-case with leading `/` | `'/orders'`, `'/driver/profile'` |
| SharedPreferences Keys | SCREAMING_SNAKE_CASE | `KEY_USER_TOKEN`, `KEY_LAST_SYNC_TIME` |
| Global Keys | lowerCamelCase + `Key` suffix | `navigatorKey`, `scaffoldKey` |

### 2.6 Widget Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Stateless Widgets | PascalCase | `SaeqPrimaryButton`, `OrderListItem` |
| Stateful Widgets | PascalCase | `AnimatedCounter`, `LocationTracker` |
| Inherited Widgets | PascalCase | `ThemeProvider`, `AuthScope` |
| CustomPainter | PascalCase + `Painter` suffix | `WavePainter`, `GradientPainter` |

### 2.7 File Naming

| File Type | Convention | Example |
|-----------|-----------|---------|
| General Dart files | snake_case | `order_service.dart`, `auth_interceptor.dart` |
| Test files | snake_case + `_test` suffix | `order_service_test.dart`, `driver_profile_test.dart` |
| Feature registration | snake_case + `_feature` suffix | `orders_feature.dart`, `driver_feature.dart` |
| Barrel files | snake_case | `models.dart`, `entities.dart` |
| Constants | snake_case | `app_constants.dart`, `route_names.dart` |

---

## 3. Flutter Guidelines

### 3.1 Widget Structure

- **Separate UI from Logic:** Use `ConsumerWidget` for Riverpod integration. Business logic should be in `StateNotifier` classes, not in widgets.
- **Prefer Const:** Use `const` constructors wherever possible to enable widget reuse.
- **Use Keys:** Add `Key`s to widgets that need to be identified (for testing or state preservation).
- **SafeArea:** Always wrap screen content in `SafeArea` for edge-to-edge layouts.
- **Responsive Design:** Use `flutter_screenutil` for responsive sizing (`w`, `h`, `r`, `sp` extensions).
- **RTL Support:** All layouts must work in both LTR and RTL. Use `Directionality` and `TextDirection` appropriately.

### 3.2 Widget Lifecycle

- Use `ConsumerStatefulWidget` + `ConsumerState` when the widget needs lifecycle methods (`initState`, `dispose`).
- Always dispose of controllers, animations, and subscriptions in `dispose()`.
- Use `ref.listen` for side effects triggered by state changes.
- Use `ref.watch` for reading state that should trigger rebuilds.

### 3.3 Layout Guidelines

- Use `Column` and `Row` with `MainAxisAlignment` and `CrossAxisAlignment`.
- Use `Expanded` and `Flexible` for flexible layouts.
- Use `Spacer` for distributing space.
- Use `Padding` with `EdgeInsets` for spacing (prefer `EdgeInsets.symmetric` and `EdgeInsets.only`).
- Use `SizedBox` for fixed spacing (prefer over `Container` with height/width).
- Use `AspectRatio` for maintaining aspect ratios.

### 3.4 Theming

- Use `Theme.of(context)` to access theme data.
- Use `AppColors` for all colors (never hardcode color values in widgets).
- Use `AppTextStyles` for all text styles (never hardcode font sizes or weights).
- Use `AppDimensions` for all spacing and sizing constants.
- Use `AppButtonStyles` for button styling.
- Support both light and dark themes.

### 3.5 Typography

- Use `GoogleFonts.tajawal` for all text.
- Define all text styles in `AppTextStyles`.
- Use semantic text styles (`headlineLarge`, `titleMedium`, `bodyLarge`, etc.).
- Ensure sufficient color contrast for accessibility.
- Support dynamic text scaling.

### 3.6 Images & Assets

- Use `flutter_svg` for SVG images (when approved).
- Use `cached_network_image` for network images (when approved).
- Organize assets in `assets/` directory:
  - `assets/images/` — Raster images
  - `assets/icons/` — Icon assets
  - `assets/illustrations/` — Illustrations
  - `assets/animations/` — Lottie animations
- Declare all assets in `pubspec.yaml`.

### 3.7 Performance

- Use `ListView.builder` for large lists.
- Use `SliverList` and `SliverAppBar` for advanced scrolling.
- Use `RepaintBoundary` for widgets that repaint frequently.
- Avoid `Opacity` — use `AnimatedOpacity` or `FadeTransition` instead.
- Use `const` constructors aggressively.
- Profile with DevTools regularly.

### 3.8 Accessibility

- Provide semantic labels for all interactive widgets.
- Use `Semantics` widget for custom semantics.
- Ensure sufficient color contrast (WCAG AA minimum).
- Support screen readers.
- Test with TalkBack (Android) and VoiceOver (iOS).

---

## 4. Riverpod Guidelines

### 4.1 Provider Types

| Provider Type | Use Case | Example |
|---------------|----------|---------|
| `Provider` | Immutable values that don't change | `appThemeModeProvider`, `appLocaleProvider` |
| `StateProvider` | Simple mutable state (primitives) | `selectedTabProvider`, `isLoadingProvider` |
| `StateNotifierProvider` | Complex mutable state | `ordersViewModelProvider`, `authViewModelProvider` |
| `FutureProvider` | Async operations that return a value | `driverProfileProvider`, `ordersListProvider` |
| `StreamProvider` | Real-time data streams | `orderUpdatesProvider`, `locationStreamProvider` |
| `Provider.family` | Providers that take arguments | `orderByIdProvider(orderId)`, `driverByIdProvider(driverId)` |
| `Provider.autoDispose` | State that should be disposed when not in use | `searchResultsProvider.autoDispose` |

### 4.2 State Management Pattern

Use `StateNotifier` + `StateNotifierProvider` for all business logic:

```dart
// State class (immutable)
class OrdersState {
  final bool isLoading;
  final List<Order> orders;
  final String? errorMessage;

  const OrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<Order>? orders,
    String? errorMessage,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// View Model
class OrdersViewModel extends StateNotifier<OrdersState> {
  final GetOrdersUseCase _getOrdersUseCase;

  OrdersViewModel(this._getOrdersUseCase) : super(const OrdersState());

  Future<void> fetchOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final orders = await _getOrdersUseCase();
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  @override
  void onClose() {
    // Dispose resources
    super.onClose();
  }
}

// Provider
final ordersViewModelProvider =
    StateNotifierProvider<OrdersViewModel, OrdersState>((ref) {
  final getOrdersUseCase = ref.watch(getOrdersUseCaseProvider);
  return OrdersViewModel(getOrdersUseCase);
});
```

### 4.3 Provider Scoping

- **Scope providers to the smallest necessary subtree.** Don't use global providers unless the state is truly global (e.g., auth, theme, locale).
- Use `ProviderScope` with `overrides` for testing.
- Use `ref.watch` for reactive dependencies (triggers rebuild).
- Use `ref.read` for one-time reads (no rebuild).
- Use `ref.listen` for side effects (no rebuild).

### 4.4 Provider Dependencies

- Use `ref.watch` to depend on other providers.
- Avoid circular dependencies.
- Use `FutureProvider.family` for parameterized async providers.
- Use `StreamProvider.family` for parameterized stream providers.

### 4.5 Testing with Riverpod

- Use `ProviderContainer` for unit testing providers.
- Use `override` to replace dependencies with mocks.
- Use `overrideWithValue` for simple overrides.
- Use `overrideWithProvider` for complex overrides.

```dart
// Testing example
test('OrdersViewModel fetches orders', () async {
  final container = ProviderContainer(
    overrides: [
      getOrdersUseCaseProvider.overrideWithValue(mockUseCase),
    ],
  );
  final viewModel = container.read(ordersViewModelProvider.notifier);
  await viewModel.fetchOrders();
  expect(container.read(ordersViewModelProvider).orders, isNotEmpty);
});
```

### 4.6 Best Practices

- Keep providers small and focused.
- Use `async*` generators with `StreamProvider` for complex streams.
- Use `FutureProvider.autoDispose` for one-time async operations that should be disposed.
- Use `ref.refresh` to force re-fetching of data.
- Use `ref.invalidate` to reset provider state.
- Document all public providers with doc comments.

---

## 5. GoRouter Guidelines

### 5.1 Route Configuration

- Define all routes in a central `AppRouter` class.
- Use named routes for all navigation.
- Use `GoRouterState` for parameter extraction.
- Use route guards for authentication and authorization.

### 5.2 Route Structure

```dart
class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    routes: [
      // ShellRoute for tab-based navigation
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'orders/:orderId',
                name: RouteNames.orderDetail,
                builder: (context, state) => OrderDetailScreen(
                  orderId: state.pathParameters['orderId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Auth routes (outside shell)
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
    redirect: (context, state) {
      // Global redirect logic (e.g., auth guard)
      return null;
    },
  );
}
```

### 5.3 Route Naming

- Use kebab-case for route names and paths.
- Use constants for all route names and paths.

```dart
class RouteNames {
  const RouteNames._();

  static const String home = 'home';
  static const String orderDetail = 'order-detail';
  static const String profile = 'profile';
  static const String login = 'login';
  static const String comingSoon = 'coming-soon';
}

class RoutePaths {
  const RoutePaths._();

  static const String home = '/';
  static const String orderDetail = '/orders/:orderId';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String comingSoon = '/coming-soon';
}
```

### 5.4 Navigation Patterns

- **Push (imperative):** `context.push('/profile')`
- **Push named:** `context.pushNamed(RouteNames.profile)`
- **Go (replace stack):** `context.go('/login')`
- **Pop:** `context.pop()`
- **Pop until:** `context.popUntil((route) => route.isFirst)`
- **Replace:** `context.replace('/login')`

### 5.5 Passing Data Between Routes

- **Path Parameters:** For required, hierarchical data (e.g., `/orders/:orderId`).
- **Query Parameters:** For optional, non-hierarchical data (e.g., `/search?q=query`).
- **Extra Data:** For complex objects that shouldn't be in the URL (e.g., `context.push('/order', extra: order)`).

### 5.6 Route Guards

- Use `redirect` for global guards (e.g., authentication).
- Use `onNavigationNotification` for custom navigation logic.
- Return `null` to allow navigation, or return a route path to redirect.

```dart
redirect: (context, state) {
  final authState = ref.read(authStateProvider);
  final loggingIn = state.subloc == '/login';

  if (authState.status == AuthStatus.unauthenticated && !loggingIn) {
    return '/login';
  }
  if (authState.status == AuthStatus.authenticated && loggingIn) {
    return '/';
  }
  return null;
},
```

### 5.7 Deep Linking & URL Restoration

- Ensure all routes can be accessed via deep links.
- Use `GoRouter.restorationScopeId` for state restoration.
- Test deep links on both Android and iOS.
- Handle web URLs appropriately.

### 5.8 Best Practices

- Keep route definitions in one place.
- Use `ShellRoute` for persistent navigation shells (bottom nav, etc.).
- Use `StatefulShellRoute` for tab-based navigation with state preservation.
- Test all routes with widget tests.
- Use `GoRouterState.error` for error handling.
- Use `GoRouterState.subloc` for the current location.
- Document all routes with their parameters and expected behavior.

---

*This document is a living document and will be updated as the architecture evolves. All changes require approval.*
