# SAEQ DRIVER — Technical Strategies

> **Version:** 1.0.0  
> **Status:** Draft (Pending Approval)  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  

---

## Table of Contents

1. [Error Handling Strategy](#1-error-handling-strategy)
2. [Logging Strategy](#2-logging-strategy)
3. [Dependency Injection Strategy](#3-dependency-injection-strategy)
4. [State Management Strategy](#4-state-management-strategy)
5. [API Architecture](#5-api-architecture)
6. [Database Architecture](#6-database-architecture)
7. [Offline Strategy](#7-offline-strategy)
8. [Security Strategy](#8-security-strategy)
9. [Testing Strategy](#9-testing-strategy)
10. [CI/CD Strategy](#10-cicd-strategy)
11. [Release Strategy](#11-release-strategy)

---

## 1. Error Handling Strategy

### 1.1 Overview

The error handling strategy follows a **layered, typed approach** where errors are caught at the boundary of each layer, converted to typed exceptions or failures, and propagated upward. The presentation layer is responsible for displaying user-friendly messages.

### 1.2 Error Hierarchy

```
Exception (Dart core)
├── AppException (base app exception)
│   ├── NetworkException
│   │   ├── TimeoutException
│   │   ├── NoInternetException
│   │   └── SocketException
│   ├── AuthException
│   │   ├── UnauthorizedException
│   │   ├── TokenExpiredException
│   │   └── InvalidCredentialsException
│   ├── ServerException
│   │   ├── BadRequestException
│   │   ├── NotFoundException
│   │   ├── ConflictException
│   │   ├── ForbiddenException
│   │   └── InternalServerErrorException
│   ├── ValidationException
│   ├── CacheException
│   └── UnknownException
└── Failure (domain layer)
    ├── NetworkFailure
    ├── AuthFailure
    ├── ServerFailure
    ├── ValidationFailure
    ├── CacheFailure
    └── UnknownFailure
```

### 1.3 Exception Flow

```
┌─────────────────┐
│  Presentation   │ ← Displays user-friendly message
│  (UI Layer)     │
└────────┬────────┘
         │ catch (Failure)
         ▼
┌─────────────────┐
│  Domain Layer   │ ← Use cases catch exceptions, convert to Failure
│  (Use Cases)    │
└────────┬────────┘
         │ catch (AppException)
         ▼
┌─────────────────┐
│  Data Layer     │ ← Data sources catch raw errors, convert to AppException
│  (Repositories) │
└────────┬────────┘
         │ catch (DioException, etc.)
         ▼
┌─────────────────┐
│ Infrastructure   │ ← HTTP client, database, etc.
│  (External)     │
└─────────────────┘
```

### 1.4 Implementation Rules

- **Data Layer:** Catch all raw exceptions (`DioException`, `SocketException`, `SQLException`, etc.) and convert them to `AppException` subtypes.
- **Domain Layer:** Use cases catch `AppException` and convert them to `Failure` subtypes.
- **Presentation Layer:** View models catch `Failure` and update state with user-friendly error messages.
- **Never propagate raw exceptions** beyond the data layer.
- **Always log errors** with context before converting them.

### 1.5 Error Message Mapping

| Exception Type | User-Friendly Message (Arabic) | User-Friendly Message (English) |
|----------------|-------------------------------|--------------------------------|
| `NoInternetException` | "تحقق من اتصالك بالإنترنت" | "Check your internet connection" |
| `TimeoutException` | "انتهت مدة الاتصال. حاول مرة أخرى" | "Connection timed out. Try again" |
| `UnauthorizedException` | "جلسة المستخدم انتهت. يرجى تسجيل الدخول" | "Session expired. Please log in" |
| `ServerException` | "حدث خطأ في الخادم. حاول مرة أخرى" | "Server error occurred. Try again" |
| `ValidationException` | "بيانات غير صالحة" | "Invalid data provided" |
| `UnknownException` | "حدث خطأ غير متوقع" | "An unexpected error occurred" |

### 1.6 Error Display

- **Transient Errors:** Show via `SnackBar` with an action to retry.
- **Blocking Errors:** Show via `AlertDialog` with clear instructions.
- **Form Validation Errors:** Show inline with the relevant input field.
- **Network Errors:** Show a persistent banner at the top of the screen.

### 1.7 Recovery Strategies

| Error Type | Recovery Strategy |
|------------|-------------------|
| Network | Retry with exponential backoff (max 3 attempts) |
| Auth | Redirect to login screen |
| Server (5xx) | Retry with exponential backoff |
| Server (4xx) | Show user-friendly message, no retry |
| Validation | Highlight invalid fields, show message |
| Cache | Fall back to cached data, show stale indicator |

---

## 2. Logging Strategy

### 2.1 Overview

The logging strategy uses the `logger` package for structured, leveled logging. Logs are used for debugging, monitoring, and auditing. Sensitive data is never logged.

### 2.2 Log Levels

| Level | When to Use | Output |
|-------|-------------|--------|
| `debug` | Detailed diagnostic information for development | Console only (debug builds) |
| `info` | General operational messages (user actions, state changes) | Console + remote (production) |
| `warning` | Recoverable issues that don't prevent operation | Console + remote |
| `error` | Errors that affect a single operation but not the app | Console + remote + crash reporting |
| `fatal` | Errors that cause the app to crash | Console + remote + crash reporting |

### 2.3 Logger Configuration

```dart
class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 120,
      colors: kDebugMode,
      printEmojis: true,
      printTime: true,
    ),
    level: kDebugMode ? Level.debug : Level.info,
  );

  static void debug(String message, {Map<String, dynamic>? context}) {
    _logger.d(message, context: context);
  }

  static void info(String message, {Map<String, dynamic>? context}) {
    _logger.i(message, context: context);
  }

  static void warning(String message, {Map<String, dynamic>? context}) {
    _logger.w(message, context: context);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _logger.e(message, error: error, stackTrace: stackTrace, context: context);
  }

  static void fatal(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _logger.f(message, error: error, stackTrace: stackTrace, context: context);
  }
}
```

### 2.4 Log Context

All log entries should include contextual metadata:

```dart
// Good - includes context
LoggerService.info(
  'Order accepted',
  context: {
    'orderId': orderId,
    'driverId': driverId,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

### 2.5 What to Log

| Event | Level | Context |
|-------|-------|---------|
| App started | info | version, buildNumber, platform |
| User logged in | info | userId, authMethod |
| User logged out | info | userId, sessionDuration |
| API request sent | debug | endpoint, method, requestBody |
| API response received | debug | endpoint, statusCode, responseBody |
| API error | error | endpoint, statusCode, errorMessage |
| Order created | info | orderId, customerId |
| Order accepted | info | orderId, driverId |
| Order status changed | info | orderId, oldStatus, newStatus |
| Network disconnected | warning | connectivityType |
| Cache miss | debug | cacheKey |
| Cache hit | debug | cacheKey |
| Validation failed | warning | field, value, rule |
| Unhandled exception | fatal | exception, stackTrace, context |

### 2.6 What NOT to Log

- **Passwords** — Never log under any circumstances.
- **Tokens** — Never log access tokens, refresh tokens, or JWT tokens.
- **PII** — Never log personal identification information (name, phone, email, address).
- **Payment Data** — Never log credit card numbers, bank accounts, or transaction details.
- **Full Request/Response Bodies** — Log only non-sensitive fields or use redaction.

### 2.7 Remote Logging

- In production, send logs to a remote logging service (e.g., Sentry, Firebase Crashlytics).
- Use a background queue to avoid blocking the UI thread.
- Implement log rotation to prevent excessive disk usage.
- Respect user privacy — allow users to opt out of logging.

### 2.8 Log Retention

| Environment | Retention Period | Storage |
|-------------|-----------------|---------|
| Development | Until app restart | Console |
| Staging | 7 days | Remote service |
| Production | 30 days | Remote service |

---

## 3. Dependency Injection Strategy

### 3.1 Overview

The project uses a **hybrid DI approach**:

- **`get_it`** as the service locator for domain and data layer dependencies.
- **`injectable`** for code generation of DI registrations.
- **Riverpod** for presentation-layer DI (providers).

### 3.2 Architecture

```
┌─────────────────────────────────────────────┐
│  Presentation Layer (Riverpod)              │
│  ┌─────────────┐  ┌─────────────┐          │
│  │ ViewModel   │  │ ViewModel   │          │
│  │ (Provider)  │  │ (Provider)  │          │
│  └──────┬──────┘  └──────┬──────┘          │
│         │                │                  │
│         ▼                ▼                  │
│  ┌──────────────────────────────────┐      │
│  │  get_it Service Locator           │      │
│  │  ┌─────────────┐  ┌─────────────┐ │      │
│  │  │ UseCase     │  │ UseCase     │ │      │
│  │  │ (Factory)   │  │ (Factory)   │ │      │
│  │  └──────┬──────┘  └──────┬──────┘ │      │
│  │         │                │        │      │
│  │         ▼                ▼        │      │
│  │  ┌────────────────────────────────┐ │      │
│  │  │  Repository (Singleton)        │ │      │
│  │  │  ┌─────────────┐  ┌─────────────┐ │ │      │
│  │  │  │ DataSource  │  │ DataSource  │ │ │      │
│  │  │  │ (Singleton) │  │ (Singleton) │ │ │      │
│  │  │  └─────────────┘  └─────────────┘ │ │      │
│  │  └────────────────────────────────┘ │      │
│  └──────────────────────────────────┘      │
└─────────────────────────────────────────────┘
```

### 3.3 Registration Patterns

| Pattern | Use Case | Example |
|---------|----------|---------|
| **Lazy Singleton** | Expensive services, shared state | `ApiClient`, `StorageService`, `AuthService` |
| **Singleton** | Services needed at app startup | `AppConfig`, `LoggerService` |
| **Factory** | Short-lived objects, use cases | `GetOrdersUseCase`, `AcceptOrderUseCase` |
| **Factory (scoped)** | Per-request or per-operation objects | `ApiClient` with custom interceptors |

### 3.4 get_it Setup

```dart
final getIt = GetIt.instance;

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => ApiClient.createDio();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<Dio>(() => ApiClient.createDio());
  // ... generated registrations
}
```

### 3.5 Riverpod Integration

```dart
final ordersViewModelProvider = StateNotifierProvider<OrdersViewModel, OrdersState>((ref) {
  final getOrdersUseCase = getIt<GetOrdersUseCase>();
  return OrdersViewModel(getOrdersUseCase);
});
```

### 3.6 Testing with DI

- Use `get_it` overrides for integration tests.
- Use Riverpod `override` for unit tests.
- Use `mocktail` to create mock implementations.

### 3.7 Best Practices

- Register all dependencies at app startup (before `runApp`).
- Use `@lazySingleton` for most services to avoid unnecessary initialization.
- Use `@singleton` only for services needed immediately at startup.
- Use `@factory` for use cases and short-lived objects.
- Avoid service locator anti-pattern by keeping DI configuration centralized.
- Document all registrations with their lifecycle and purpose.

---

## 4. State Management Strategy

### 4.1 Overview

The project uses **Riverpod v3** as the primary state management solution. Riverpod provides compile-safe, testable, and flexible state management with no `BuildContext` dependency.

### 4.2 State Management Patterns

#### 4.2.1 Simple State (Provider)

For immutable values that don't change:

```dart
final appThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);
final appLocaleProvider = Provider<Locale>((ref) => const Locale('ar'));
```

#### 4.2.2 Mutable State (StateProvider)

For simple, primitive state:

```dart
final selectedTabProvider = StateProvider<int>((ref) => 0);
final isLoadingProvider = StateProvider<bool>((ref) => false);
```

#### 4.2.3 Complex State (StateNotifier + StateNotifierProvider)

For business logic with multiple state fields:

```dart
class OrdersState {
  final bool isLoading;
  final List<Order> orders;
  final String? errorMessage;
  final bool hasMore;

  const OrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.errorMessage,
    this.hasMore = true,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<Order>? orders,
    String? errorMessage,
    bool? hasMore,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class OrdersViewModel extends StateNotifier<OrdersState> {
  final GetOrdersUseCase _getOrdersUseCase;

  OrdersViewModel(this._getOrdersUseCase) : super(const OrdersState());

  Future<void> fetchOrders({bool refresh = false}) async {
    if (refresh) {
      state = const OrdersState();
    }
    state = state.copyWith(isLoading: true);
    try {
      final orders = await _getOrdersUseCase();
      state = state.copyWith(
        isLoading: false,
        orders: orders,
        hasMore: orders.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void onClose() {
    super.onClose();
  }
}

final ordersViewModelProvider =
    StateNotifierProvider<OrdersViewModel, OrdersState>((ref) {
  final getOrdersUseCase = getIt<GetOrdersUseCase>();
  return OrdersViewModel(getOrdersUseCase);
});
```

#### 4.2.4 Async State (FutureProvider)

For one-time async operations:

```dart
final driverProfileProvider = FutureProvider.autoDispose<Driver>((ref) async {
  final getDriverProfile = getIt<GetDriverProfileUseCase>();
  return getDriverProfile();
});
```

#### 4.2.5 Stream State (StreamProvider)

For real-time data:

```dart
final orderUpdatesProvider = StreamProvider.family<Order, String>((ref, orderId) {
  final getOrderUpdates = getIt<GetOrderUpdatesUseCase>();
  return getOrderUpdates(orderId);
});
```

### 4.3 State Management Principles

- **Immutability:** State classes must be immutable. Use `copyWith` for updates.
- **Single Source of Truth:** Each piece of state should have one owner.
- **Unidirectional Data Flow:** Events flow down, state flows up.
- **Separation of Concerns:** Business logic in `StateNotifier`, UI in widgets.
- **Testability:** All state management should be testable without a `BuildContext`.

### 4.4 Provider Scoping

- **Global State:** Auth, theme, locale, connectivity — use top-level providers.
- **Feature State:** Orders, driver status, profile — use feature-scoped providers.
- **Screen State:** Form inputs, pagination, filters — use screen-scoped providers.
- **Component State:** Individual widget state — use `StateProvider` within the widget's subtree.

### 4.5 Best Practices

- Use `autoDispose` for state that should be cleaned up when no longer observed.
- Use `family` for parameterized providers.
- Use `ref.watch` for reactive dependencies (triggers rebuild).
- Use `ref.read` for one-time reads (no rebuild).
- Use `ref.listen` for side effects (no rebuild).
- Use `ref.refresh` to force re-fetching.
- Use `ref.invalidate` to reset state.
- Document all public providers.
- Keep providers small and focused.

---

## 5. API Architecture

### 5.1 Overview

The API architecture uses **Dio** as the HTTP client with a layered approach: interceptors for cross-cutting concerns, type-safe clients for API endpoints, and automatic serialization/deserialization.

### 5.2 Architecture

```
┌─────────────────────────────────────────────┐
│  Domain Layer                               │
│  ┌─────────────┐  ┌─────────────┐          │
│  │ UseCase     │  │ UseCase     │          │
│  └──────┬──────┘  └──────┬──────┘          │
│         │                │                  │
│         ▼                ▼                  │
│  ┌──────────────────────────────────┐      │
│  │  Data Layer                       │      │
│  │  ┌─────────────┐  ┌─────────────┐ │      │
│  │  │ Repository  │  │ Repository  │ │      │
│  │  │ Impl        │  │ Impl        │ │      │
│  │  └──────┬──────┘  └──────┬──────┘ │      │
│  │         │                │        │      │
│  │         ▼                ▼        │      │
│  │  ┌────────────────────────────────┐ │      │
│  │  │  Data Sources                   │ │      │
│  │  │  ┌─────────────┐  ┌─────────────┐ │ │      │
│  │  │  │ ApiService  │  │ LocalDB     │ │ │      │
│  │  │  │ (Retrofit)  │  │ (Drift)     │ │ │      │
│  │  │  └─────────────┘  └─────────────┘ │ │      │
│  │  └────────────────────────────────┘ │      │
│  └──────────────────────────────────┘      │
└─────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────┐
│  Infrastructure Layer                       │
│  ┌─────────────┐  ┌─────────────┐          │
│  │ Dio Client  │  │ Interceptors│          │
│  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────┘
```

### 5.3 Dio Configuration

```dart
class ApiClient {
  static const String _baseUrl = 'https://api.saeq.example';
  static const int _connectTimeout = 30000;
  static const int _receiveTimeout = 30000;
  static const int _sendTimeout = 30000;

  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(milliseconds: _connectTimeout),
      receiveTimeout: const Duration(milliseconds: _receiveTimeout),
      sendTimeout: const Duration(milliseconds: _sendTimeout),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
      headers: {
        'Accept-Language': 'ar',
        'X-App-Version': AppConstants.appVersion,
        'X-Platform': Platform.operatingSystem,
      },
    ));

    dio.interceptors.addAll([
      AuthInterceptor(dio),
      LoggingInterceptor(dio),
      RetryInterceptor(dio),
      ErrorInterceptor(dio),
    ]);

    return dio;
  }
}
```

### 5.4 Interceptors

#### 5.4.1 Auth Interceptor

- Adds JWT token to the `Authorization` header.
- Refreshes expired tokens automatically.
- Redirects to login on persistent auth failures.

#### 5.4.2 Logging Interceptor

- Logs request method, URL, headers, and body (debug builds only).
- Logs response status, headers, and body (debug builds only).
- Never logs sensitive data (tokens, passwords, PII).

#### 5.4.3 Retry Interceptor

- Retries failed requests with exponential backoff.
- Max 3 retry attempts.
- Only retries on network errors and 5xx responses.
- Respects `Retry-After` header.

#### 5.4.4 Error Interceptor

- Catches all `DioException` instances.
- Converts them to `AppException` subtypes.
- Logs errors with context.
- Handles connectivity errors gracefully.

### 5.5 API Client (Retrofit)

```dart
@RestApi(baseUrl: 'https://api.saeq.example')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @GET('/health')
  Future<HealthResponse> getHealthStatus();

  @POST('/auth/login')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @GET('/orders')
  Future<List<OrderModel>> getOrders({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('status') String? status,
  });

  @GET('/orders/{id}')
  Future<OrderModel> getOrderById(@Path('id') String orderId);

  @POST('/orders/{id}/accept')
  Future<OrderModel> acceptOrder(@Path('id') String orderId);
}
```

### 5.6 Serialization

- Use `json_serializable` for JSON serialization/deserialization.
- Use `freezed` for immutable data classes with union types (when approved).
- All API models must implement `fromJson` and `toJson`.
- Use `@JsonKey` for field name mapping and default values.

### 5.7 API Versioning

- Use URL path versioning: `/api/v1/orders`, `/api/v2/orders`.
- Maintain backward compatibility for at least 2 versions.
- Deprecate old versions with a 6-month notice.
- Document all API changes in a changelog.

### 5.8 Rate Limiting

- Implement client-side rate limiting to prevent abuse.
- Use a token bucket or sliding window algorithm.
- Show user-friendly messages when rate limited.
- Queue requests when rate limited and retry when allowed.

### 5.9 Best Practices

- Use HTTPS only (enforce with network security config on Android).
- Implement certificate pinning for production.
- Use API keys or OAuth 2.0 for authentication.
- Use request/response timeouts.
- Implement retry logic with exponential backoff.
- Log API calls for debugging (without sensitive data).
- Use environment-specific base URLs.
- Handle API errors gracefully with user-friendly messages.
- Document all API endpoints with examples.

---

## 6. Database Architecture

### 6.1 Overview

The database architecture uses **Drift** (SQLite) for structured local data persistence. Drift provides a type-safe, reactive, and migration-friendly database layer.

### 6.2 Architecture

```
┌─────────────────────────────────────────────┐
│  Domain Layer                               │
│  ┌─────────────┐                           │
│  │ Repository  │                           │
│  │ Interface   │                           │
│  └──────┬──────┘                           │
│         │                                  │
│         ▼                                  │
│  ┌──────────────────────────────────┐      │
│  │  Data Layer                       │      │
│  │  ┌─────────────┐                 │      │
│  │  │ Repository  │                 │      │
│  │  │ Impl        │                 │      │
│  │  └──────┬──────┘                 │      │
│  │         │                        │      │
│  │         ▼                        │      │
│  │  ┌────────────────────────────────┐ │      │
│  │  │  Local Data Source             │ │      │
│  │  │  ┌─────────────┐               │ │      │
│  │  │  │ DAO         │               │ │      │
│  │  │  │ (Drift)     │               │ │      │
│  │  │  └─────────────┘               │ │      │
│  │  └────────────────────────────────┘ │      │
│  └──────────────────────────────────┘      │
└─────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────┐
│  Infrastructure Layer                       │
│  ┌─────────────┐                           │
│  │ Drift       │                           │
│  │ Database    │                           │
│  └─────────────┘                           │
└─────────────────────────────────────────────┘
```

### 6.3 Database Schema

```dart
@DriftDatabase(tables: [Orders, Drivers, Deliveries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAllTables();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Handle migrations
        },
      );
}
```

### 6.4 DAO Pattern

```dart
@DriftAccessor(tables: [Orders])
class OrdersDao {
  final AppDatabase db;

  OrdersDao(this.db);

  Future<List<Order>> getAllOrders() {
    return (db.select(db.orders)).get();
  }

  Future<Order?> getOrderById(String id) {
    return (db.select(db.orders)..where((t) => db.isSameValue(t.id, id))).getSingleOrNull();
  }

  Future<void> insertOrder(OrderCompanion order) {
    return db.into(db.orders).insert(order, mode: InsertMode.insertOrReplace);
  }

  Stream<List<Order>> watchAllOrders() {
    return (db.select(db.orders)).watch();
  }
}
```

### 6.5 Data Synchronization

- **Cache-First Strategy:** Read from local database first, then fetch from API.
- **Write-Through:** Write to both local database and API.
- **Conflict Resolution:** Use timestamps to resolve conflicts (last-write-wins).
- **Sync Queue:** Queue writes when offline and sync when online.

### 6.6 Migration Strategy

- Always increment `schemaVersion` when making schema changes.
- Use `MigrationStrategy` for `onCreate` and `onUpgrade`.
- Test migrations thoroughly.
- Never delete data in migrations (mark as deprecated instead).
- Provide rollback scripts for critical migrations.

### 6.7 Best Practices

- Use transactions for atomic operations.
- Use `watch()` for reactive queries.
- Use `batch()` for bulk inserts/updates.
- Index frequently queried columns.
- Use `InsertMode.insertOrReplace` for upserts.
- Limit query results for pagination.
- Use `Future` for one-time queries, `Stream` for reactive queries.
- Encrypt the database for sensitive data (when approved).

---

## 7. Offline Strategy

### 7.1 Overview

The offline strategy ensures the app remains functional and provides a good user experience even without network connectivity. It uses a **cache-first, network-fallback** approach for reads and a **queue-and-sync** approach for writes.

### 7.2 Connectivity Detection

```dart
class NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
```

### 7.3 Read Strategy (Cache-First)

```dart
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remote;
  final OrdersLocalDataSource _local;
  final NetworkInfo _networkInfo;

  @override
  Future<List<Order>> getOrders({bool forceRefresh = false}) async {
    if (forceRefresh) {
      return _fetchFromRemote();
    }

    final cached = await _local.getOrders();
    if (cached.isNotEmpty) {
      _refreshInBackground();
      return cached;
    }

    if (await _networkInfo.isConnected) {
      return _fetchFromRemote();
    }

    throw NetworkException('No data available offline');
  }

  Future<List<Order>> _fetchFromRemote() async {
    final remoteOrders = await _remote.getOrders();
    await _local.saveOrders(remoteOrders);
    return remoteOrders;
  }
}
```

### 7.4 Write Strategy (Queue-and-Sync)

```dart
class OfflineQueue {
  final AppDatabase _db;
  final NetworkInfo _networkInfo;

  Future<void> enqueue(OfflineAction action) async {
    await _db.into(_db.offlineActions).insert(OfflineActionCompanion(
      id: Value(Uuid().v4()),
      type: Value(action.type),
      payload: Value(jsonEncode(action.toJson())),
      createdAt: Value(DateTime.now()),
      status: Value(OfflineActionStatus.pending),
    ));

    if (await _networkInfo.isConnected) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    final pending = await (_db.select(_db.offlineActions)
          ..where((t) => t.status.equals(OfflineActionStatus.pending.index)))
        .get();

    for (final action in pending) {
      try {
        await _executeAction(action);
        await (_db.update(_db.offlineActions)
              ..where((t) => t.id.equals(action.id)))
            .update(OfflineActionCompanion(status: Value(OfflineActionStatus.completed)));
      } catch (e) {
        await (_db.update(_db.offlineActions)
              ..where((t) => t.id.equals(action.id)))
            .update(OfflineActionCompanion(
          status: Value(OfflineActionStatus.failed),
          errorMessage: Value(e.toString()),
        ));
      }
    }
  }
}
```

### 7.5 Offline UI Indicators

- Show an offline banner at the top of the screen when disconnected.
- Show a "syncing" indicator when syncing queued actions.
- Show a "last synced" timestamp.
- Disable online-only features when offline.
- Show cached data with a "stale" indicator.

### 7.6 Conflict Resolution

- **Last-Write-Wins:** Use timestamps to determine the latest version.
- **Merge:** Merge changes from both sources when possible.
- **User Choice:** Prompt the user to choose when conflicts can't be auto-resolved.
- **Server Wins:** For critical data, always use the server version.

### 7.7 Best Practices

- Always cache API responses in the local database.
- Use `watch()` to reactively update UI when cached data changes.
- Queue all write operations when offline.
- Sync queued operations when connectivity is restored.
- Show offline status to the user.
- Handle conflict resolution gracefully.
- Test offline scenarios thoroughly.
- Use `connectivity_plus` for network status detection.

---

## 8. Security Strategy

### 8.1 Overview

The security strategy implements a **defense-in-depth** approach with multiple layers of protection: secure storage, encrypted communications, input validation, authentication, and authorization.

### 8.2 Secure Storage

- Use `flutter_secure_storage` for sensitive data (tokens, credentials, PII).
- On Android, uses AES-256 encryption with Keystore.
- On iOS, uses Keychain Services.
- Never store sensitive data in `SharedPreferences` or plain text files.
- Encrypt the local database for sensitive data.

```dart
class SecureStorageService {
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
```

### 8.3 Network Security

- **HTTPS Only:** All API calls must use HTTPS.
- **Certificate Pinning:** Pin the server's SSL certificate to prevent MITM attacks.
- **HSTS:** Use HTTP Strict Transport Security.
- **TLS 1.3:** Enforce TLS 1.3 for all connections.

### 8.4 Authentication

- Use JWT (JSON Web Tokens) for authentication.
- Store tokens in secure storage.
- Implement token refresh (refresh tokens).
- Implement token expiration handling.
- Support biometric authentication (Face ID, Touch ID, fingerprint).
- Implement session timeout (e.g., 30 minutes of inactivity).

### 8.5 Authorization

- Use role-based access control (RBAC).
- Define roles: `driver`, `customer`, `merchant`, `admin`.
- Check permissions at the API level (not just UI).
- Use route guards for navigation-level authorization.

### 8.6 Input Validation

- Validate all user input on the client and server.
- Use `TextEditingController` with input formatters for real-time validation.
- Sanitize input to prevent injection attacks.
- Use regex for format validation (phone numbers, emails, etc.).
- Limit input length and character set.

### 8.7 Data Protection

- **Encryption at Rest:** Encrypt the local database.
- **Encryption in Transit:** Use HTTPS with TLS 1.3.
- **Data Minimization:** Only collect and store necessary data.
- **Data Retention:** Implement data retention policies.
- **Data Deletion:** Implement right to deletion (GDPR compliance).

### 8.8 App Hardening

- **Code Obfuscation:** Use ProGuard/R8 on Android, LLVM on iOS.
- **Code Shrinking:** Remove unused code and resources.
- **Anti-Tampering:** Detect rooted/jailbroken devices.
- **Anti-Debugging:** Prevent debugging in production.
- **Secure Logging:** Never log sensitive data.

### 8.9 Privacy

- **GDPR Compliance:** Implement data subject rights.
- **Saudi Data & AI Authority (SDAIA) Compliance:** Follow Saudi data protection regulations.
- **Privacy Policy:** Display a clear privacy policy.
- **Consent:** Obtain user consent for data collection.
- **Data Portability:** Allow users to export their data.

### 8.10 Best Practices

- Never hardcode secrets in source code.
- Use environment variables for API keys.
- Implement proper session management.
- Use secure random number generation.
- Validate all inputs.
- Implement rate limiting.
- Monitor for security vulnerabilities.
- Conduct regular security audits.
- Keep dependencies up to date.
- Use security scanning tools.

---

## 9. Testing Strategy

### 9.1 Overview

The testing strategy follows the **testing pyramid** with a focus on automated testing at all levels: unit, widget, and integration. The goal is to achieve 80%+ code coverage while maintaining fast and reliable test execution.

### 9.2 Testing Pyramid

```
         ┌─────────────────────────────┐
         │   Integration Tests (~10%)  │
         │   - Feature flows           │
         │   - API integration         │
         │   - Database integration    │
         └─────────────────────────────┘
         ┌─────────────────────────────┐
         │   Widget Tests (~20%)       │
         │   - Individual widgets      │
         │   - UI interactions         │
         │   - State changes           │
         └─────────────────────────────┘
         ┌─────────────────────────────┐
         │   Unit Tests (~70%)         │
         │   - Use cases               │
         │   - Entities                │
         │   - Validators              │
         │   - Utilities               │
         └─────────────────────────────┘
```

### 9.3 Test Types

#### 9.3.1 Unit Tests

- **Scope:** Individual classes and functions in isolation.
- **Coverage:** Use cases, entities, validators, formatters, utilities.
- **Mocking:** Use `mocktail` for dependencies.
- **Location:** `test/unit/`

```dart
void main() {
  group('GetOrdersUseCase', () {
    late GetOrdersUseCase useCase;
    late MockOrdersRepository mockRepository;

    setUp(() {
      mockRepository = MockOrdersRepository();
      useCase = GetOrdersUseCase(mockRepository);
    });

    test('should get orders from the repository', () async {
      final tOrders = [Order(id: '1', status: OrderStatus.pending)];
      when(() => mockRepository.getOrders()).thenAnswer((_) async => tOrders);

      final result = await useCase();

      expect(result, tOrders);
      verify(() => mockRepository.getOrders());
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
```

#### 9.3.2 Widget Tests

- **Scope:** Individual widgets and their interactions.
- **Coverage:** UI rendering, user interactions, state changes.
- **Mocking:** Use `mocktail` for dependencies, `ProviderContainer` for Riverpod.
- **Location:** `test/widget/`

```dart
void main() {
  testWidgets('SaeqPrimaryButton renders with label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SaeqPrimaryButton(label: 'Test'),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
```

#### 9.3.3 Integration Tests

- **Scope:** Complete feature flows and system integration.
- **Coverage:** End-to-end user journeys, API integration, database integration.
- **Mocking:** Use real dependencies where possible, mock external services.
- **Location:** `test/integration/`

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_screen')), findsOneWidget);
  });
}
```

### 9.4 Test Organization

```
test/
├── unit/
│   ├── usecases/
│   ├── entities/
│   ├── validators/
│   └── utils/
├── widget/
│   ├── shared/
│   └── features/
├── integration/
│   ├── auth/
│   ├── orders/
│   └── driver/
└── mocks/
```

### 9.5 Mocking Strategy

- Use `mocktail` for all mocking needs.
- Generate mocks using `mocktail` annotations.
- Mock at the boundary of each layer (repository, data source, API client).
- Use `when(() => ...)` for stubbing.
- Use `verify(() => ...)` for assertions.
- Use `verifyNoMoreInteractions()` to ensure no unexpected calls.

### 9.6 Golden Tests

- Use golden tests for visual regression testing.
- Generate golden files for all supported themes (light, dark).
- Generate golden files for all supported locales (Arabic, English).
- Generate golden files for different screen sizes.
- Update golden files intentionally (not automatically).

### 9.7 Test Coverage

- Target 80%+ code coverage.
- Exclude generated code, models, and trivial getters/setters.
- Use `flutter test --coverage` to generate coverage reports.
- Use `lcov` to view coverage reports.
- Set coverage thresholds in CI/CD.

### 9.8 Test Best Practices

- Write tests before code (TDD when possible).
- Test edge cases and error scenarios.
- Test both happy paths and failure paths.
- Use descriptive test names.
- Group related tests with `group()`.
- Use `setUp` and `tearDown` for common setup.
- Keep tests fast and independent.
- Avoid testing implementation details.
- Test public APIs, not private methods.
- Use `pumpAndSettle` for animations.
- Clean up after tests.

---

## 10. CI/CD Strategy

### 10.1 Overview

The CI/CD strategy uses **GitHub Actions** for continuous integration and continuous deployment. It automates testing, analysis, building, and deployment across multiple environments and platforms.

### 10.2 CI Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  Pull Request                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Code        │  │ Static      │  │ Unit &      │         │
│  │ Analysis    │  │ Analysis    │  │ Widget      │         │
│  │ (flutter    │  │ (flutter    │  │ Tests       │         │
│  │  analyze)   │  │  analyze)   │  │ (flutter    │         │
│  │             │  │             │  │  test)      │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│  ┌──────────────────────────────────────────────────┐      │
│  │  All checks must pass before merge               │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 10.3 CD Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│  Merge to main                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Build       │  │ Integration │  │ Deploy      │         │
│  │ (flutter    │  │ Tests       │  │ (Firebase   │         │
│  │  build)     │  │ (flutter    │  │  App Dist)  │         │
│  │             │  │  drive)     │  │             │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│         ▼                ▼                ▼                 │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Deploy to staging/production                    │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 10.4 GitHub Actions Workflows

#### 10.4.1 CI Workflow (`.github/workflows/ci.yml`)

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter format --set-exit-if-changed .

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build apk --flavor production
      - uses: actions/upload-artifact@v4
        with:
          name: app-release
          path: build/app/outputs/flutter-apk/app-production-release.apk
```

#### 10.4.2 CD Workflow (`.github/workflows/cd.yml`)

```yaml
name: CD

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter build appbundle --flavor production
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccount: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.saeq.driver
          releaseStatus: completed
          track: production
          aabBundlePath: build/app/outputs/bundle/productionRelease/app-production-release.aab
```

### 10.5 Environments

| Environment | Branch | Purpose | Deployment |
|-------------|--------|---------|------------|
| Development | `dev` | Local development | Manual |
| Staging | `staging` | QA and testing | Auto-deploy on merge |
| Production | `main` | Live users | Auto-deploy on merge |

### 10.6 Build Flavors

| Flavor | Environment | API URL | Features |
|--------|-------------|---------|----------|
| Development | `development` | `https://api-dev.saeq.example` | Debug logs, mock data |
| Staging | `staging` | `https://api-staging.saeq.example` | Debug logs, test data |
| Production | `production` | `https://api.saeq.example` | Release logs, real data |

### 10.7 Quality Gates

| Check | Threshold | Failure Action |
|-------|-----------|----------------|
| Static Analysis | 0 errors, 0 warnings | Block merge |
| Code Formatting | 100% formatted | Block merge |
| Unit Test Coverage | 80% minimum | Block merge |
| Widget Test Coverage | 70% minimum | Block merge |
| Integration Tests | All must pass | Block merge |
| Build | Must succeed | Block deploy |

### 10.8 Best Practices

- Run CI on every pull request.
- Run CD on every merge to `main`.
- Use caching to speed up builds.
- Use matrix builds for multiple platforms.
- Use artifacts for build outputs.
- Use secrets for sensitive data.
- Use environment variables for configuration.
- Monitor CI/CD pipeline health.
- Notify teams on failures.
- Keep workflows DRY with reusable workflows.

---

## 11. Release Strategy

### 11.1 Versioning

Use **Semantic Versioning** (MAJOR.MINOR.PATCH):

- **MAJOR:** Breaking changes (API, data schema, incompatible UI changes).
- **MINOR:** New features (backward compatible).
- **PATCH:** Bug fixes and minor improvements (backward compatible).

Build number is separate and increments with each build: `1.0.0+1`, `1.0.0+2`, etc.

### 11.2 Release Types

| Type | Frequency | Description | Testing |
|------|-----------|-------------|---------|
| **Patch Release** | Weekly | Bug fixes, minor improvements | Unit + widget tests |
| **Minor Release** | Monthly | New features, backward compatible | Full test suite |
| **Major Release** | Quarterly | Breaking changes, major features | Full test suite + beta testing |
| **Hotfix** | As needed | Critical bug fixes | Minimal testing, fast deploy |

### 11.3 Release Process

#### 11.3.1 Minor/Major Release

1. **Feature Freeze:** No new features merged to `main`.
2. **QA Testing:** Full regression testing on staging.
3. **Beta Testing:** Release to beta testers via Firebase App Distribution.
4. **Release Notes:** Generate release notes from changelog.
5. **Build:** Build release artifacts for all platforms.
6. **Deploy:** Deploy to Play Store and App Store.
7. **Monitor:** Monitor crash reports and user feedback.

#### 11.3.2 Hotfix

1. **Branch:** Create a hotfix branch from `main`.
2. **Fix:** Apply the minimal fix.
3. **Test:** Test the fix in isolation.
4. **Build:** Build release artifacts.
5. **Deploy:** Deploy to app stores.
6. **Merge:** Merge hotfix back to `main` and `dev`.

### 11.4 Feature Flags

- Use feature flags for gradual rollouts.
- Implement with a remote config service (e.g., Firebase Remote Config).
- Default to `false` for new features.
- Roll out to 1%, 10%, 50%, 100% of users.
- Monitor metrics during rollout.
- Allow instant rollback by toggling the flag.

### 11.5 Backward Compatibility

- **API:** Maintain backward compatibility for at least 2 versions.
- **Database:** Never delete columns or tables in migrations.
- **Data Models:** Use `@JsonKey` with `fromJson` for backward-compatible deserialization.
- **UI:** Ensure new UI works with old data.
- **Features:** New features should not break existing functionality.

### 11.6 Monitoring & Analytics

- **Crash Reporting:** Firebase Crashlytics or Sentry.
- **Performance Monitoring:** Firebase Performance Monitoring.
- **Analytics:** Firebase Analytics or custom analytics.
- **Error Tracking:** Sentry or Bugsnag.
- **Business Metrics:** Custom dashboards for KPIs.

### 11.7 Rollback Strategy

- **App Store:** Use staged rollout to gradually release, allowing quick rollback.
- **API:** Maintain old API versions for rollback.
- **Database:** Use reversible migrations.
- **Feature Flags:** Instant rollback by toggling flags.
- **Monitoring:** Set up alerts for crash rates and performance degradation.

### 11.8 Release Checklist

- [ ] All tests pass (unit, widget, integration)
- [ ] Code coverage meets thresholds
- [ ] No critical or high-severity issues
- [ ] Release notes are complete
- [ ] Build artifacts are generated
- [ ] Beta testing is completed (if applicable)
- [ ] App store listings are updated
- [ ] Monitoring is configured
- [ ] Team is notified of the release

---

*This document is a living document and will be updated as the architecture evolves. All changes require approval.*
