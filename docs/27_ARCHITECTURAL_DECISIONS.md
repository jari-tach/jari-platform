# SAEQ — Architectural Decision Records (ADR)

> **Version:** 1.1.0
> **Status:** Active
> **Last Updated:** 2026-07-25
> **Author:** Senior Flutter Software Engineer
> **Related:** [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md), [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md), [ADR-014](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md)

---

## 1. Purpose

This document records **every significant architectural decision** made for the SAEQ platform. Each ADR includes the decision, rationale, alternatives considered, pros/cons, and impact. This ensures institutional knowledge is preserved and new team members understand why things are the way they are.

---

## 2. ADR Index

| ID | Title | Status | Date |
|----|-------|--------|------|
| ADR-001 | Flutter as Cross-Platform Framework | ✅ Accepted | 2026-07-01 |
| ADR-002 | Clean Architecture with Feature-First Structure | ✅ Accepted | 2026-07-02 |
| ADR-003 | Riverpod for State Management | ✅ Accepted | 2026-07-03 |
| ADR-004 | GoRouter for Navigation | ✅ Accepted | 2026-07-04 |
| ADR-005 | Dio for HTTP Client | ✅ Accepted | 2026-07-05 |
| ADR-006 | Drift (SQLite) for Local Database | ✅ Accepted | 2026-07-06 |
| ADR-007 | SharedPreferences for Key-Value Storage | ✅ Accepted | 2026-07-07 |
| ADR-008 | Google Fonts (Tajawal) for Typography | ✅ Accepted | 2026-07-08 |
| ADR-009 | Sealed Classes for Error Handling | ✅ Accepted | 2026-07-09 |
| ADR-010 | Service Registry Pattern (not get_it) | ✅ Accepted | 2026-07-10 |
| ADR-011 | Material 3 Design System | ✅ Accepted | 2026-07-11 |
| ADR-012 | Arabic-First Localization Strategy | ✅ Accepted | 2026-07-12 |
| ADR-013 | Separate Applications Strategy (Driver/Customer/Merchant/Admin) | ✅ Accepted (Merchant channel amended by ADR-014) | 2026-07-24 |
| ADR-014 | Platform Channel Responsibilities and Domain Alignment | ✅ Accepted | 2026-07-25 |
| ADR-015 | Driver Availability State Machine | ✅ Accepted | 2026-07-25 |
| ADR-016 | Local Intent vs Backend Authority (Availability) | ✅ Accepted | 2026-07-25 |
| ADR-017 | Offline Availability Policy | ✅ Accepted | 2026-07-25 |
| ADR-018 | Busy State Ownership | ✅ Accepted | 2026-07-25 |
| ADR-019 | Availability Persistence and Restoration | ✅ Accepted | 2026-07-25 |

---

## 3. ADR Details

### ADR-001: Flutter as Cross-Platform Framework

| Field | Value |
|-------|-------|
| **Decision** | Use Flutter for all mobile applications (driver, customer) |
| **Date** | 2026-07-01 |
| **Status** | ✅ Accepted |

#### Reason

Flutter provides a single codebase for Android and iOS with near-native performance, hot reload for rapid development, and a mature ecosystem for production applications.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| React Native | Larger community, JavaScript ecosystem | Performance issues, bridge overhead |
| Kotlin Multiplatform | Native performance, shared logic | Less mature UI framework, steeper learning curve |
| Native (Swift + Kotlin) | Best platform integration | 2x development cost, separate codebases |

#### Pros

- Single codebase for Android and iOS
- Hot reload for fast iteration
- Strong typing with Dart
- Excellent performance (60 FPS)
- Growing ecosystem and community
- Google-backed with long-term support

#### Cons

- Larger app size compared to native
- Platform-specific features require platform channels
- Web support is less mature than mobile

#### Impact

- Development speed increased by ~40% compared to separate native apps
- Shared business logic across platforms
- Need for platform channel expertise for native integrations

---

### ADR-002: Clean Architecture with Feature-First Structure

| Field | Value |
|-------|-------|
| **Decision** | Use Clean Architecture layers (data/domain/presentation) organized by feature |
| **Date** | 2026-07-02 |
| **Status** | ✅ Accepted |

#### Reason

Clean Architecture provides separation of concerns, testability, and independence from frameworks. Feature-first organization makes the codebase navigable and scalable as the project grows.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| MVC | Simple, familiar | Tight coupling, hard to test |
| MVVM | Good separation, testable | No domain layer, business logic in ViewModel |
| Layer-First | Clear separation | Hard to navigate in large projects |

#### Pros

- Domain layer is pure Dart (no framework dependencies)
- Each feature is self-contained and independently testable
- Easy to add new features without affecting existing ones
- Clear dependency inversion (data → domain ← presentation)

#### Cons

- More boilerplate code
- Steeper learning curve for new developers
- Over-engineering for very simple features

#### Impact

- All new features follow the same structure
- Domain layer can be shared with future backend services
- Testing is straightforward with dependency injection

---

### ADR-003: Riverpod for State Management

| Field | Value |
|-------|-------|
| **Decision** | Use flutter_riverpod for state management |
| **Date** | 2026-07-03 |
| **Status** | ✅ Accepted |

#### Reason

Riverpod provides compile-time safety, no BuildContext dependency, easy testing, and supports both simple and complex state management patterns.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Bloc | Well-established, predictable | Verbose, lots of boilerplate |
| Provider | Simple, Google-recommended | Runtime errors, context-dependent |
| GetX | Simple, feature-rich | Over-engineered, poor testing support |

#### Pros

- Compile-time safety (no runtime ProviderNotFoundException)
- No dependency on BuildContext
- Built-in support for async operations (FutureProvider, StreamProvider)
- Easy to test (override providers)
- Supports code generation for complex cases
- Family modifiers for parameterized providers

#### Cons

- Smaller community than Bloc
- Learning curve for advanced features (autoDispose, family)
- Documentation can be inconsistent

#### Impact

- State management is consistent across all features
- Testing is simplified with provider overrides
- Riverpod's autodispose prevents memory leaks

---

### ADR-004: GoRouter for Navigation

| Field | Value |
|-------|-------|
| **Decision** | Use go_router for declarative routing |
| **Date** | 2026-07-04 |
| **Status** | ✅ Accepted |

#### Reason

GoRouter provides declarative routing with deep linking support, redirect guards, and nested navigation, which is essential for a multi-feature application.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Navigator 2.0 | Full control | Very complex, verbose |
| AutoRoute | Code generation, type-safe | Generated code, less flexible |
| Beamer | Declarative, flexible | Less popular, documentation gaps |

#### Pros

- Declarative route definitions
- Built-in redirect guards for authentication
- Deep linking support
- Nested navigation (ShellRoute)
- Error handling for unknown routes
- Type-safe parameters

#### Cons

- Version 17.x has breaking changes
- Complex nested navigation can be tricky
- Limited animation customization

#### Impact

- Navigation is centralized and easy to audit
- Auth guards are implemented at the router level
- Deep linking is supported out of the box

---

### ADR-005: Dio for HTTP Client

| Field | Value |
|-------|-------|
| **Decision** | Use Dio as the HTTP client |
| **Date** | 2026-07-05 |
| **Status** | ✅ Accepted |

#### Reason

Dio provides interceptors, request cancellation, retry logic, and comprehensive error handling out of the box.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| http package | Simple, official | No interceptors, manual error handling |
| Chopper | Code generation, type-safe | Generated code, less flexible |
| GraphQL (via ferry) | Modern API paradigm | Overkill for REST API |

#### Pros

- Interceptor chain (auth, logging, retry, error)
- Request cancellation with CancelToken
- Form data and multipart upload support
- Timeout configuration per request
- Comprehensive error handling (DioException)
- Large community and well-maintained

#### Cons

- Additional dependency (5.10.0)
- Error handling requires understanding of DioException types
- Interceptor ordering can be confusing

#### Impact

- All API calls go through a consistent pipeline
- Authentication tokens are automatically attached
- Failed requests are retried with exponential backoff
- Errors are mapped to domain failures

---

### ADR-006: Drift (SQLite) for Local Database

| Field | Value |
|-------|-------|
| **Decision** | Use Drift (formerly Moor) for local SQLite database |
| **Date** | 2026-07-06 |
| **Status** | ✅ Accepted |

#### Reason

Drift provides type-safe SQL queries, migration support, reactive streams, and excellent performance for complex local data needs.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Hive | Simple, fast, no SQL | No relations, limited queries |
| Isar | Fast, reactive | Smaller community, less mature |
| SQLite (sqflite) | Direct SQL control | No type safety, manual migrations |
| ObjectBox | High performance | Proprietary, limited query capabilities |

#### Pros

- Type-safe queries (compile-time validation)
- Built-in migration system
- Reactive streams (watch queries)
- DAO pattern for clean separation
- Good performance for complex queries
- Supports transactions

#### Cons

- Code generation required (build_runner)
- Learning curve for DAO pattern
- Larger dependency than Hive

#### Impact

- Local data is strongly typed and queryable
- Offline support is built on Drift's reactive streams
- Migrations are managed and versioned

---

### ADR-007: SharedPreferences for Key-Value Storage

| Field | Value |
|-------|-------|
| **Decision** | Use SharedPreferences for non-sensitive key-value storage |
| **Date** | 2026-07-07 |
| **Status** | ✅ Accepted |

#### Reason

SharedPreferences is simple, synchronous (after initialization), and sufficient for non-sensitive data like user preferences and app settings.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| flutter_secure_storage | Encrypted storage | Slower, overkill for non-sensitive data |
| Hive | Fast, supports complex objects | Overkill for simple key-value pairs |

#### Pros

- Simple API (get/set/remove)
- Synchronous reads after initialization
- Part of the Flutter ecosystem
- Sufficient for preferences and settings

#### Cons

- Not encrypted (use flutter_secure_storage for tokens)
- Not suitable for complex data structures
- Limited to primitive types

#### Impact

- Used for app settings, theme preference, language selection
- Tokens and sensitive data use flutter_secure_storage (Phase 1)
- JSON serialization for complex preferences

---

### ADR-008: Google Fonts (Tajawal) for Typography

| Field | Value |
|-------|-------|
| **Decision** | Use Google Fonts package with Tajawal font family |
| **Date** | 2026-07-08 |
| **Status** | ✅ Accepted |

#### Reason

Tajawal is a modern Arabic font with excellent readability, and Google Fonts provides easy integration without manual font file management.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Noto Sans Arabic | Comprehensive character support | Less modern appearance |
| Custom font files | No network dependency | Manual management, larger app size |
| System fonts | No additional dependency | Inconsistent across devices |

#### Pros

- Tajawal is designed for Arabic typography
- Google Fonts handles font downloading and caching
- No manual font file management
- Consistent across platforms
- Supports both Arabic and Latin characters

#### Cons

- Requires internet for first load (cached afterward)
- Additional dependency (8.2.0)
- Limited to fonts available on Google Fonts

#### Impact

- Consistent typography across the application
- Arabic text renders beautifully with proper glyphs
- Font caching ensures offline availability after first load

---

### ADR-009: Sealed Classes for Error Handling

| Field | Value |
|-------|-------|
| **Decision** | Use sealed classes for exception and failure hierarchies |
| **Date** | 2026-07-09 |
| **Status** | ✅ Accepted |

#### Reason

Sealed classes provide exhaustive pattern matching, type safety, and clear error categorization without relying on runtime type checks.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Freezed union types | Code generation, copyWith | Generated code, build_runner dependency |
| Enums with data | Simple | No associated data per variant |
| Custom exception classes | Simple | No exhaustiveness checking |

#### Pros

- Exhaustive switch statements (compile-time safety)
- Each variant can carry different data
- No code generation required
- Clear hierarchy (AppException → specific types)
- Easy to extend with new types

#### Cons

- Dart sealed classes are relatively new (Dart 3.0+)
- Requires Dart SDK 3.0 or higher
- Pattern matching syntax can be verbose

#### Impact

- Error handling is type-safe and exhaustive
- New error types can be added without breaking existing code
- UI layer can handle failures based on type

---

### ADR-010: Service Registry Pattern (not get_it)

| Field | Value |
|-------|-------|
| **Decision** | Use a custom AppServiceRegistry instead of get_it |
| **Date** | 2026-07-10 |
| **Status** | ✅ Accepted |

#### Reason

A custom service registry provides explicit dependency management without the overhead of a DI framework, while maintaining testability and clear initialization order.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| get_it + injectable (Rejected — superseded by AppServiceRegistry; see LEGACY_DI_MIGRATION_PLAN.md) | Industry standard, code generation *(not selected)* | Build_runner dependency, complex setup; rejected in favor of AppServiceRegistry |
| Provider/Riverpod | Already in use for state | Not designed for service location |
| Manual constructor injection | Pure, testable | Verbose, requires boilerplate |

#### Pros

- No additional dependencies
- Explicit initialization order
- Easy to understand and debug
- Static access for convenience
- Lazy initialization support

#### Cons

- Not as flexible as get_it for complex scenarios
- Manual registration of new services
- Global state (singleton pattern)

#### Impact

- Services are initialized once at app startup
- Clear dependency graph
- Easy to mock services in tests

---

### ADR-011: Material 3 Design System

| Field | Value |
|-------|-------|
| **Decision** | Use Material 3 (Material You) design system |
| **Date** | 2026-07-11 |
| **Status** | ✅ Accepted |

#### Reason

Material 3 provides modern design language, dynamic color theming, and is the recommended design system for Flutter applications.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Material 2 | Mature, well-documented | Outdated design language |
| Custom design system | Unique brand identity | High development cost, no component library |
| Cupertino (iOS only) | Native iOS feel | Not cross-platform |

#### Pros

- Modern, clean design language
- Dynamic color theming (Material You)
- Large component library
- Built-in Flutter support
- Adaptive layouts
- Accessibility features built-in

#### Cons

- Some components are still experimental
- Dynamic color requires Android 12+
- Customization can be complex

#### Impact

- Consistent UI across all features
- Easy theming with color schemes
- Future-proof design system

---

### ADR-012: Arabic-First Localization Strategy

| Field | Value |
|-------|-------|
| **Decision** | Design the app with Arabic as the primary language, English as secondary |
| **Date** | 2026-07-12 |
| **Status** | ✅ Accepted |

#### Reason

The target market is Saudi Arabia where Arabic is the primary language. Designing Arabic-first ensures proper RTL support and natural user experience for the majority of users.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| English-first | Global reach | Poor RTL experience, Arabic feels like an afterthought |
| Parallel development | Equal treatment | Higher development cost, slower time-to-market |

#### Pros

- Natural RTL layout from the start
- Arabic typography is prioritized
- Better user experience for Saudi users
- Compliance with Saudi digital guidelines

#### Cons

- English layout may need adjustments
- Some third-party packages have limited RTL support
- Testing requires both RTL and LTR verification

#### Impact

- All layouts are designed for RTL first
- LTR (English) is tested as a secondary layout
- Localization strings are Arabic-first

---

### ADR-013: Separate Applications Strategy (Driver/Customer/Merchant/Admin)

| Field | Value |
|-------|-------|
| **Decision** | The SAEQ platform ships as four independent applications (SAEQ Driver, SAEQ Customer, SAEQ Merchant, SAEQ Admin) — one per role — sharing only backend infrastructure. Merging roles into a single Flutter app with post-login role selection is prohibited. |
| **Date** | 2026-07-24 |
| **Status** | ✅ Accepted |

#### Reason

Drivers, customers, merchants, and platform operators have fundamentally different UX, permission, and release-cadence needs. A single merged app with role selection produces a confusing store presence, forces irrelevant OS permissions on every user, couples unrelated release cycles, and weakens role isolation to a UI-only concern. Dedicated applications per role, backed by server-side RBAC, provide genuine defense-in-depth and match the platform's pre-existing documentation (`03_ENTERPRISE_ARCHITECTURE.md`), which already assumed dedicated apps per stakeholder type.

#### Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| Single Flutter app with post-login role selection | Single codebase, single store listing initially | Confusing store presence; irrelevant permissions per user; coupled release cycles; weak UI-only role isolation; becomes a "god app" |
| Monorepo with all four app targets from day one | Immediate code sharing | Premature abstraction before a second app exists; large migration cost now; violates the no-shared-package rule during PROJECT STABILIZATION |
| Fully independent applications, shared backend only (chosen) | Clean per-audience distribution; minimal permissions; independent release cadence; strong server-side RBAC isolation | Some short-term boilerplate duplication; more repositories/pipelines to operate |

#### Pros

- Purpose-built app-store presence per audience (driver, customer, merchant)
- Minimal, role-appropriate OS permissions per app
- Independent Build/Test/Release cycle per app — a Driver hotfix never requires releasing Customer/Merchant/Admin
- Role isolation enforced twice: architecturally (separate binaries) and server-side (RBAC at the API Gateway)
- Consistent with existing `03_ENTERPRISE_ARCHITECTURE.md` and `01_BUSINESS_VISION.md` app enumeration

#### Cons

- Higher up-front scaffolding cost per new app until shared packages are proven and extracted
- Requires actively maintaining shared engineering standards across repositories (mitigated by `00_PROJECT_BIBLE.md`, `06_CODING_STANDARDS.md`)
- Multiple sets of store listings, signing keys, and Firebase projects to manage operationally

#### Impact

- The current repository (`saeq_driver`) remains scoped to the Driver role only; no customer/merchant/admin screens, role selection, or role-switching logic are added.
- No shared package (`saeq_design_system`, `saeq_core`, `saeq_networking`, `saeq_localization`, `saeq_models`) is extracted during PROJECT STABILIZATION; extraction is deferred until at least two applications have a proven, stabilized shared need.
- Future applications (SAEQ Customer, SAEQ Merchant, SAEQ Admin) each get their own project, package ID, signing, store listing, and independent versioning per `36_RELEASE_MANAGEMENT.md`.
- Full decision record: [docs/adr/ADR_SEPARATE_APPLICATIONS_STRATEGY.md](./adr/ADR_SEPARATE_APPLICATIONS_STRATEGY.md)
- Amendment (2026-07-25): Merchant Mobile daily ops + domain alignment — [ADR-014](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md). Web Admin stays platform-owner Web console.

### ADR-014: Platform Channel Responsibilities and Domain Alignment

| Field | Value |
|-------|-------|
| **Decision** | Merchant Mobile for daily ops; Web Admin for platform owners only; multi-tenant + catalog/offer + inventory movements + order SMs + Modular Monolith documented as binding design |
| **Date** | 2026-07-25 |
| **Status** | Accepted |
| **Full record** | [adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md) |

Amends ADR-013 Merchant distribution wording only. Does not authorize Windows Admin. See `41_OFFICIAL_BUSINESS_RULES.md` and `42_PLATFORM_DOMAIN_ARCHITECTURE.md`.

---

*This document is a living record of architectural decisions. New ADRs are added as decisions are made.*
