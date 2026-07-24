# SAEQ DRIVER — Architecture Documentation

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  

---

## 1. Project Vision

### 1.1 Overview

**Saeq Driver** is the Flutter foundation for the Saeq multi-app ecosystem — a comprehensive delivery platform serving Saudi Arabia. The driver app is one component of a larger ecosystem that will eventually include:

- **Customer App** — End-user ordering and tracking
- **Driver App** — Delivery personnel operations (this project)
- **Merchant App** — Restaurant/store management
- **Admin Dashboard** — Platform administration and oversight
- **Product Database** — Centralized product catalog
- **AI Services** — Route optimization, demand forecasting, fraud detection
- **Government Integrations** — Compliance, permits, taxation (ZATCA)
- **Payment Systems** — Multi-gateway payment processing
- **Notification Services** — Push, SMS, email orchestration
- **Maps** — Real-time location, routing, geofencing
- **Analytics** — Business intelligence and reporting
- **Reporting** — Operational and financial reporting

### 1.2 Mission

Build an enterprise-grade, scalable, maintainable, secure, and high-performance delivery ecosystem that serves the Kingdom of Saudi Arabia and supports future regional expansion.

### 1.3 Core Principles

Every architectural decision must prioritize:

| Principle | Description |
|-----------|-------------|
| **Scalability** | The system must handle growth in users, features, and traffic without fundamental redesign. |
| **Maintainability** | Code must be easy to understand, modify, and extend by teams of varying experience levels. |
| **Security** | All data, communications, and user interactions must be secured by design. |
| **Performance** | The application must provide a smooth, responsive experience under all conditions. |
| **Clean Architecture** | Dependencies must flow inward; business logic must be independent of frameworks. |
| **Enterprise Coding Standards** | Consistent, documented, and enforced coding practices across all teams. |
| **Future Expansion** | The architecture must accommodate new apps, services, and integrations without friction. |

### 1.4 Target Platforms

- **Mobile:** Android (API 21+), iOS (14.0+)
- **Future:** Web, Desktop (Windows, macOS, Linux)

### 1.5 Localization

- **Primary Language:** Arabic (RTL)
- **Secondary Language:** English (LTR)
- All UI must be fully RTL-compatible and support dynamic locale switching.

---

## 2. System Architecture

### 2.1 Architectural Pattern

The project follows **Clean Architecture** (a.k.a. Onion Architecture / Hexagonal Architecture) layered on top of **Feature-First Organization**.

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Feature   │  │   Feature   │  │   Feature   │              │
│  │  (UI +      │  │  (UI +      │  │  (UI +      │              │
│  │  State)     │  │  State)     │  │  State)     │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                     │
│         ▼                ▼                ▼                     │
│  ┌──────────────────────────────────────────────────┐           │
│  │              DOMAIN LAYER                         │           │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐            │           │
│  │  │Entities │  │UseCases │  │Repositories│         │           │
│  │  │(Business│  │(Business│  │(Abstract) │         │           │
│  │  │ Logic)  │  │ Logic)  │  │           │         │           │
│  │  └─────────┘  └─────────┘  └─────────┘            │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │    API      │  │  Local DB   │  │   Cache     │              │
│  │ (Remote)    │  │ (SQLite)    │  │ (InMemory)  │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                     │
│         ▼                ▼                ▼                     │
│  ┌──────────────────────────────────────────────────┐           │
│  │              REPOSITORY IMPLEMENTATIONS          │           │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐            │           │
│  │  │RemoteRepo│  │LocalRepo│  │CacheRepo│            │           │
│  │  └─────────┘  └─────────┘  └─────────┘            │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE LAYER                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Dio       │  │  Drift/     │  │  Secure     │              │
│  │  Client     │  │  SQLite     │  │  Storage    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Layer Descriptions

#### Layer 1: Presentation Layer

- **Responsibility:** UI rendering, user interaction, state management.
- **Components:**
  - **Screens/Pages:** Full-screen views (e.g., `WelcomeScreen`, `OrdersListScreen`).
  - **Widgets:** Reusable UI components (e.g., `SaeqPrimaryButton`, `SaeqSectionCard`).
  - **View Models / State Controllers:** Riverpod `StateNotifier` classes that manage screen-level state.
- **Dependencies:** Domain layer (use cases), Shared widgets.

#### Layer 2: Domain Layer

- **Responsibility:** Business logic, independent of any framework or external system.
- **Components:**
  - **Entities:** Core business objects (e.g., `Driver`, `Order`, `Delivery`).
  - **Use Cases:** Single-responsibility classes that encapsulate business operations (e.g., `GetOrdersUseCase`, `AcceptOrderUseCase`).
  - **Repository Interfaces (Abstract):** Contracts that data layer implementations must fulfill.
- **Dependencies:** None (pure Dart).

#### Layer 3: Data Layer

- **Responsibility:** Data retrieval, caching, and persistence.
- **Components:**
  - **Data Sources:** Remote (API), Local (SQLite/Drift), Cache (in-memory).
  - **Repository Implementations:** Concrete classes that implement domain repository interfaces.
  - **Models:** Data transfer objects that map between external representations and domain entities.
- **Dependencies:** Domain layer, Infrastructure layer.

#### Layer 4: Infrastructure Layer

- **Responsibility:** External system integration and technical concerns.
- **Components:**
  - **HTTP Client:** Dio-based API client with interceptors.
  - **Local Database:** Drift (SQLite) for structured local storage.
  - **Secure Storage:** flutter_secure_storage for sensitive data.
  - **Shared Preferences:** For lightweight key-value storage.
  - **Logger:** Structured logging service.
- **Dependencies:** External packages.

### 2.3 Dependency Flow

```
Presentation → Domain ← Data → Infrastructure
```

- **Presentation** depends on **Domain** (use cases, entities).
- **Data** depends on **Domain** (repository interfaces).
- **Infrastructure** is used by **Data** (concrete implementations).
- **Domain** has **no dependencies** on any other layer.

### 2.4 Feature-First Organization

Each feature is a self-contained module with its own:

```
features/<feature_name>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── viewmodels/
└── <feature_name>_feature.dart        # Feature registration
```

### 2.5 Shared / Cross-Cutting Concerns

```
lib/
├── core/                              # Shared infrastructure and foundation
│   ├── config/                        # Environment configuration
│   ├── constants/                     # Application constants
│   ├── di/                            # Dependency injection (get_it)
│   ├── error/                         # Error types and handling
│   ├── localization/                  # Internationalization
│   ├── logging/                       # Logging infrastructure
│   ├── network/                       # Network utilities (interceptors, connectivity)
│   ├── providers/                     # Global Riverpod providers
│   ├── routes/                        # GoRouter configuration
│   ├── services/                      # Core services (API, auth, storage)
│   ├── theme/                         # Design system (colors, typography, spacing)
│   ├── utils/                         # Extensions, helpers, validators
│   └── platform/                      # Platform-specific code
├── shared/                            # Reusable components across features
│   ├── widgets/                       # Shared UI widgets
│   ├── services/                      # Shared services
│   └── utils/                         # Shared utilities
├── features/                          # Feature modules (see above)
└── main.dart                          # Application entry point
```

---

## 3. Folder Structure

### 3.1 Detailed Directory Layout

```
lib/
├── main.dart
├── core/
│   ├── config/
│   │   ├── app_config.dart              # Environment variables and API endpoints
│   │   └── flavors/                     # Build flavors (dev, staging, prod)
│   ├── constants/
│   │   ├── app_constants.dart           # App metadata, dimensions, durations
│   │   └── app_keys.dart                # Global keys for navigation/testing
│   ├── di/
│   │   ├── di.dart                    # Service locator setup (get_it)
│   │   └── di_module.dart             # Module registration
│   ├── error/
│   │   ├── exceptions/                  # Domain-specific exceptions
│   │   ├── failures/                    # Failure types for error propagation
│   │   └── app_error_handler.dart       # Centralized error handler
│   ├── localization/
│   │   ├── app_localizations.dart       # Localization delegate
│   │   ├── app_localizations_en.arb     # English translations
│   │   └── app_localizations_ar.arb     # Arabic translations
│   ├── logging/
│   │   └── logger_service.dart          # Structured logging
│   ├── network/
│   │   ├── interceptors/              # Dio interceptors (auth, logging, retry)
│   │   ├── network_info.dart          # Connectivity checking
│   │   └── api_client.dart            # Dio-based HTTP client
│   ├── platform/
│   │   ├── platform_info.dart         # Platform detection
│   │   └── device_info.dart           # Device metadata
│   ├── providers/
│   │   ├── app_providers.dart         # Global providers (router, theme, locale)
│   │   └── providers.dart             # Re-exports
│   ├── routes/
│   │   ├── app_router.dart            # GoRouter configuration
│   │   ├── route_names.dart           # Route name constants
│   │   └── route_paths.dart           # Route path constants
│   ├── services/
│   │   ├── api/
│   │   │   └── api_service.dart       # High-level API service
│   │   ├── auth/
│   │   │   └── auth_service.dart      # Authentication service
│   │   └── storage/
│   │       └── storage_service.dart   # Storage service
│   ├── theme/
│   │   ├── app_theme.dart             # Theme data
│   │   ├── app_colors.dart            # Color palette
│   │   ├── app_text_styles.dart       # Typography
│   │   ├── app_dimensions.dart        # Spacing, radius, sizes
│   │   └── widgets/                   # Theme-specific widgets
│   └── utils/
│       ├── extensions/                # Dart/Flutter extensions
│       ├── validators/                # Input validation
│       ├── formatters/                # Text formatters
│       └── helpers/                   # Utility functions
├── shared/
│   ├── services/
│   │   └── app_service_registry.dart  # Service registry
│   ├── widgets/
│   │   ├── saeq_primary_button.dart
│   │   ├── saeq_section_card.dart
│   │   └── ...                        # Other shared widgets
│   └── utils/
│       └── ...                        # Shared utilities
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── auth_feature.dart
│   ├── delivery/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── delivery_feature.dart
│   ├── driver/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── welcome_screen.dart
│   │   │   ├── widgets/
│   │   │   └── viewmodels/
│   │   └── driver_feature.dart
│   ├── orders/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   └── orders_feature.dart
│   └── profile/
│       ├── data/
│       ├── domain/
│       ├── presentation/
│       └── profile_feature.dart
└── main.dart
```

### 3.2 Naming Conventions for Directories

| Directory | Purpose |
|-----------|---------|
| `core/` | Foundational infrastructure shared across the entire app |
| `shared/` | Reusable components that don't fit into `core/` or a specific feature |
| `features/` | Self-contained feature modules |
| `data/` | Data layer within a feature (models, data sources, repository implementations) |
| `domain/` | Domain layer within a feature (entities, use cases, repository interfaces) |
| `presentation/` | UI layer within a feature (pages, widgets, view models) |
| `pages/` | Full-screen views |
| `widgets/` | Reusable sub-components within a feature |
| `viewmodels/` | State management controllers |

---

## 4. Coding Standards

> **Note:** Detailed coding standards, naming conventions, and framework-specific guidelines are documented in [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md).

### 4.1 Summary

| Area | Standard |
|------|----------|
| Language | Dart (sound null safety) |
| Style Guide | Effective Dart + project-specific rules |
| Linting | `flutter_lints` + custom rules |
| Documentation | `dartdoc` for all public APIs |
| Formatting | `dart format` (120-char line limit) |

### 4.2 Key Rules

- All public classes, methods, and functions must have doc comments.
- Prefer `const` constructors where possible.
- Avoid `print()` — use the Logger service.
- Use `final` for variables that don't change.
- Prefer immutability.
- No business logic in widgets — delegate to use cases.
- Follow SOLID principles.
- Follow DRY (Don't Repeat Yourself).
- Follow KISS (Keep It Simple, Stupid).

---

## 5. Naming Convention

> **Note:** Detailed naming conventions are documented in [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md).

### 5.1 Summary

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `OrderService`, `DriverProfile` |
| Functions/Methods | camelCase | `getOrders()`, `calculateTotal()` |
| Variables | camelCase | `orderList`, `isLoading` |
| Constants | lowerCamelCase | `defaultPadding`, `apiTimeout` |
| Files | snake_case | `order_service.dart`, `driver_profile.dart` |
| Directories | snake_case | `features/orders/`, `core/utils/` |
| Providers | camelCase + `Provider` suffix | `ordersProvider`, `authStateProvider` |
| Use Cases | PascalCase + `UseCase` suffix | `GetOrdersUseCase`, `AcceptOrderUseCase` |
| Entities | PascalCase | `Order`, `Driver`, `Delivery` |
| Exceptions | PascalCase + `Exception` suffix | `NetworkException`, `AuthException` |
| Failures | PascalCase + `Failure` suffix | `NetworkFailure`, `ServerFailure` |

---

## 6. Flutter Guidelines

> **Note:** Detailed Flutter guidelines are documented in [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md).

### 6.1 Summary

- Use Material 3 design system.
- Use `flutter_screenutil` for responsive sizing.
- Use `google_fonts` (Tajawal) for typography.
- All widgets must be RTL-compatible.
- Use `ConsumerWidget` for Riverpod integration.
- Prefer `const` constructors.
- Use `Key`s when needed for testing.
- Separate UI from business logic.
- Use `SafeArea` for edge-to-edge layouts.

---

## 7. Riverpod Guidelines

> **Note:** Detailed Riverpod guidelines are documented in [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md).

### 7.1 Summary

- Use `flutter_riverpod` v3.
- Use `StateNotifierProvider` for mutable state.
- Use `Provider` for immutable values.
- Use `FutureProvider` for async operations.
- Use `StreamProvider` for real-time data.
- Scope providers appropriately (avoid global state when possible).
- Use `ref.watch` for reactive dependencies.
- Use `ref.read` for one-time reads.
- Always dispose of resources in `StateNotifier.onClose`.
- Use `override` for testing.

---

## 8. GoRouter Guidelines

> **Note:** Detailed GoRouter guidelines are documented in [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md).

### 8.1 Summary

- Use GoRouter v17+.
- Define all routes in a central `AppRouter` class.
- Use named routes.
- Use route guards for authentication.
- Use `ShellRoute` for tab-based navigation.
- Pass data via route parameters, not global state.
- Use `GoRouterState` for parameter extraction.
- Handle deep links and URL restoration.

---

## 9. Error Handling Strategy

> **Note:** Detailed error handling strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 9.1 Summary

- Use a typed exception/failure hierarchy.
- Map all errors to user-friendly messages.
- Log all errors with context.
- Show user-facing errors via SnackBars or dialogs.
- Never crash the app on recoverable errors.
- Use `try/catch` at the use case boundary.
- Propagate errors as `Failure` objects through the domain layer.

---

## 10. Logging Strategy

> **Note:** Detailed logging strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 10.1 Summary

- Use the `logger` package for structured logging.
- Log levels: `debug`, `info`, `warning`, `error`, `fatal`.
- Include context: user ID, request ID, timestamp.
- Never log sensitive data (tokens, passwords, PII).
- Disable debug logs in production.
- Log to console in debug, to file/remote in production.

---

## 11. Dependency Injection Strategy

> **Note:** Detailed DI strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 11.1 Summary

- Use `get_it` as the service locator.
- Use `injectable` for code generation.
- Register all services at app startup.
- Use lazy singletons for expensive services.
- Use factories for short-lived objects.
- Use Riverpod for presentation-layer DI.
- Use `get_it` for domain and data layer DI.

---

## 12. State Management Strategy

> **Note:** Detailed state management strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 12.1 Summary

- Use Riverpod v3 as the primary state management solution.
- Use `StateNotifier` + `StateNotifierProvider` for business logic.
- Use `AsyncNotifier` for async state.
- Use `Provider` for simple immutable values.
- Use `FutureProvider` for one-time async operations.
- Use `StreamProvider` for real-time data streams.
- Keep state immutable.
- Use `copyWith` for state updates.
- Scope providers to the smallest necessary subtree.

---

## 13. API Architecture

> **Note:** Detailed API architecture is documented in [STRATEGIES.md](./STRATEGIES.md).

### 13.1 Summary

- Use Dio as the HTTP client.
- Use `json_serializable` for JSON serialization.
- Use `retrofit` for type-safe API clients.
- Implement retry logic with exponential backoff.
- Use interceptors for auth, logging, and error handling.
- Use API versioning in the URL path.
- Use HTTPS only.
- Implement request/response timeout.
- Handle network errors gracefully.

---

## 14. Database Architecture

> **Note:** Detailed database architecture is documented in [STRATEGIES.md](./STRATEGIES.md).

### 14.1 Summary

- Use Drift (SQLite) for structured local data.
- Use `floor` or `drift` for ORM.
- Define DAOs (Data Access Objects) for database operations.
- Use transactions for atomic operations.
- Migrate schema with version tracking.
- Cache API responses in the local database.
- Use lazy loading for large datasets.

---

## 15. Offline Strategy

> **Note:** Detailed offline strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 15.1 Summary

- Cache API responses in the local database.
- Use a "cache-first, then network" strategy for read operations.
- Queue write operations for offline execution.
- Show offline status to the user.
- Sync queued operations when connectivity is restored.
- Use `connectivity_plus` for network status detection.
- Handle conflict resolution for offline edits.

---

## 16. Security Strategy

> **Note:** Detailed security strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 16.1 Summary

- Use `flutter_secure_storage` for sensitive data (tokens, credentials).
- Use HTTPS with certificate pinning.
- Implement token-based authentication (JWT).
- Use biometric authentication for sensitive operations.
- Validate all input on the client and server.
- Never log sensitive data.
- Implement proper session management.
- Use ProGuard/R8 for Android code obfuscation.

---

## 17. Testing Strategy

> **Note:** Detailed testing strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 17.1 Summary

- Unit tests for use cases, entities, and utilities.
- Widget tests for individual components.
- Integration tests for feature flows.
- Mock dependencies using `mocktail`.
- Use `golden` tests for visual regression.
- Achieve 80%+ code coverage.
- Test edge cases and error scenarios.
- Use `flutter_test` for all test types.

---

## 18. CI/CD Strategy

> **Note:** Detailed CI/CD strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 18.1 Summary

- Use GitHub Actions for CI/CD.
- Run tests on every pull request.
- Run static analysis (`flutter analyze`).
- Run code formatting checks.
- Build and test on multiple platforms.
- Deploy to Firebase App Distribution for testing.
- Deploy to Play Store and App Store for production.
- Use semantic versioning.
- Use build flavors for environments.

---

## 19. Release Strategy

> **Note:** Detailed release strategy is documented in [STRATEGIES.md](./STRATEGIES.md).

### 19.1 Summary

- Use semantic versioning (MAJOR.MINOR.PATCH).
- Use build flavors: development, staging, production.
- Use codepush for hotfix deployments.
- Use feature flags for gradual rollouts.
- Monitor crash reports with Sentry/Firebase Crashlytics.
- Monitor performance with Firebase Performance Monitoring.
- Release notes for each version.
- Backward compatibility must be maintained.

---

## 20. Development Roadmap

> **Note:** Detailed development roadmap is documented in [DEVELOPMENT_ROADMAP.md](./DEVELOPMENT_ROADMAP.md).

### 20.1 Summary

| Phase | Focus | Timeline |
|-------|-------|----------|
| Phase 0 | Foundation & Architecture (current) | Q3 2026 |
| Phase 1 | Authentication & Onboarding | Q4 2026 |
| Phase 2 | Core Driver Features (Orders, Navigation) | Q1 2027 |
| Phase 3 | Delivery & Earnings | Q2 2027 |
| Phase 4 | Profile & Settings | Q3 2027 |
| Phase 5 | Advanced Features (AI, Analytics) | Q4 2027+ |

---

## Appendix A: Current Project State

### A.1 Existing Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | SDK | UI framework |
| flutter_localizations | SDK | Localization |
| cupertino_icons | ^1.0.8 | iOS-style icons |
| flutter_riverpod | ^3.3.2 | State management |
| go_router | ^17.3.0 | Navigation |
| dio | ^5.10.0 | HTTP client |
| shared_preferences | ^2.5.5 | Key-value storage |
| google_fonts | ^8.2.0 | Typography |
| flutter_screenutil | ^5.9.3 | Responsive design |
| intl | ^0.20.2 | Internationalization |
| flutter_lints | ^6.0.0 | Linting (dev) |

### A.2 Existing Structure

The current project is in the **PROJECT FOUNDATION** phase with:
- Basic app shell with welcome screen
- RTL-first localization (Arabic/English)
- Placeholder services (API, auth, storage, error)
- Basic theme system (colors, typography, button/card styles)
- GoRouter-based navigation (home + coming-soon routes)
- Riverpod provider setup (router, theme, locale)
- Feature stubs (auth, delivery, driver, orders, profile)
- Shared widgets (primary button, section card)

### A.3 Proposed Additional Dependencies

| Package | Purpose | Status |
|---------|---------|--------|
| get_it | Service locator | Pending approval |
| injectable | Code generation for DI | Pending approval |
| logger | Structured logging | Pending approval |
| flutter_secure_storage | Secure credential storage | Pending approval |
| connectivity_plus | Network connectivity | Pending approval |
| json_annotation | JSON serialization | Pending approval |
| retrofit | Type-safe API clients | Pending approval |
| drift | SQLite ORM | Pending approval |
| freezed | Immutable data classes | Pending approval |
| mocktail | Mocking for tests | Pending approval |
| go_router | Navigation (already included) | Approved |

---

## Appendix B: Glossary

| Term | Definition |
|------|-----------|
| **SAEQ** | The overarching delivery platform ecosystem |
| **Driver App** | The mobile application for delivery drivers |
| **Feature** | A self-contained module with its own domain, data, and presentation layers |
| **Use Case** | A single business operation encapsulated in a class |
| **Entity** | A core business object with no framework dependencies |
| **Repository** | An interface that abstracts data access |
| **Data Source** | A concrete implementation of data access (API, database, cache) |
| **DI** | Dependency Injection |
| **RTL** | Right-to-Left (language direction) |
| **API** | Application Programming Interface |
| **SDK** | Software Development Kit |
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **JWT** | JSON Web Token |
| **PII** | Personally Identifiable Information |
| **DAO** | Data Access Object |
| **ORM** | Object-Relational Mapping |

---

*This document is a living document and will be updated as the architecture evolves. All changes require approval.*
