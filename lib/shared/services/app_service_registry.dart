import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/network/network_monitor.dart';
import '../../core/services/api/api_client.dart';
import '../../core/services/error/app_error_handler.dart';
import '../../core/services/logger/logger_service.dart';
import '../../core/services/storage/secure_storage_service.dart';
import '../../features/auth/data/repositories/fake_authentication_repository.dart';
import '../../features/auth/data/session/auth_session_storage.dart';
import '../../features/auth/domain/repositories/authentication_repository.dart';
import '../../features/availability/data/datasources/shared_preferences_driver_availability_local_data_source.dart';
import '../../features/availability/data/repositories/local_driver_availability_repository.dart';
import '../../features/availability/domain/repositories/driver_availability_repository.dart';
import '../../features/driver/data/datasources/local/driver_database.dart';
import '../../features/profile/data/repositories/fake_driver_profile_repository.dart';
import '../../features/profile/domain/repositories/driver_profile_repository.dart';

/// Central service registry for the application.
///
/// Provides access to all core services and manages their lifecycle.
/// Services are lazily initialized and can be accessed via static getters.
final class AppServiceRegistry {
  AppServiceRegistry._();

  static AppServiceRegistry? _instance;

  /// Initialize the service registry with all core services.
  /// Must be called once at app startup before accessing any services.
  static Future<AppServiceRegistry> init() async {
    if (_instance != null) return _instance!;

    final registry = AppServiceRegistry._();
    registry._logger = ConsoleLoggerService();
    registry._errorHandler = AppErrorHandler(logger: registry._logger);
    registry._storage = SecureStorageServiceImpl(logger: registry._logger);
    await registry._storage.init();
    registry._apiClient = ApiClient(
      logger: registry._logger,
      // Token provider must be synchronous (see AuthInterceptor), while
      // getAccessToken() is async; no synchronous token cache exists yet.
      tokenProvider: () => null,
    );

    // Non-critical service activation policy (PHASE 2.1):
    // DriverDatabase and NetworkMonitor are required by later features
    // (offline cache, connectivity-aware UI) but are NOT required for the
    // app to start. A failure in either is logged and the service is left
    // as `null` instead of crashing bootstrap or the whole app. Callers
    // MUST null-check `database`/`networkMonitor` until a feature phase
    // makes one of them a hard requirement.
    registry._database = await _safeInit<DriverDatabase>(
      'DriverDatabase',
      registry._logger,
      () async {
        final database = DriverDatabase();
        // Forces the lazy connection to open and the schema to be created
        // right now, so a failure surfaces here instead of on first real
        // use inside a feature.
        await database.allSyncMetadata;
        return database;
      },
    );

    registry._networkMonitor = await _safeInit<NetworkMonitor>(
      'NetworkMonitor',
      registry._logger,
      () async {
        final monitor = NetworkMonitor(
          logger: registry._logger,
          connectivity: Connectivity(),
        );
        await monitor.init();
        return monitor;
      },
    );

    // PHASE 2.2 — Authentication Foundation.
    // AuthSessionStorage is a thin, synchronous wrapper around the
    // already-initialized SecureStorageService (no extra I/O at
    // construction), but is still routed through _safeInit for
    // consistency and defense-in-depth.
    registry._authSessionStorage = await _safeInit<AuthSessionStorage>(
      'AuthSessionStorage',
      registry._logger,
      () async => AuthSessionStorage(
        storage: registry._storage,
        logger: registry._logger,
      ),
    );

    // FakeAuthenticationRepository's constructor enforces the
    // production guard (throws if AppConfig.isProduction is true). That
    // failure — like any other non-critical bootstrap failure — is
    // logged loudly here and degrades to `null`, never silently.
    final authSessionStorage = registry._authSessionStorage;
    registry._authenticationRepository = authSessionStorage == null
        ? null
        : await _safeInit<AuthenticationRepository>(
            'AuthenticationRepository',
            registry._logger,
            () async => FakeAuthenticationRepository(
              sessionStorage: authSessionStorage,
              logger: registry._logger,
            ),
          );

    // PHASE 2.3 — Driver Identity and Profile.
    final authenticationRepository = registry._authenticationRepository;
    registry._driverProfileRepository = authenticationRepository == null
        ? null
        : await _safeInit<DriverProfileRepository>(
            'DriverProfileRepository',
            registry._logger,
            () async => FakeDriverProfileRepository(
              authenticationRepository: authenticationRepository,
              logger: registry._logger,
              database: registry._database,
            ),
          );

    // PHASE 2.4 — Driver Availability (local persistence).
    registry._driverAvailabilityRepository = authenticationRepository == null
        ? null
        : await _safeInit<DriverAvailabilityRepository>(
            'DriverAvailabilityRepository',
            registry._logger,
            () async => LocalDriverAvailabilityRepository(
              localDataSource:
                  SharedPreferencesDriverAvailabilityLocalDataSource(),
              currentDriverIdReader: () =>
                  registry
                      ._authenticationRepository
                      ?.currentSession
                      ?.driverId ??
                  '',
            ),
          );

    _instance = registry;
    registry._logger.info('AppServiceRegistry initialized');
    return registry;
  }

  /// Releases resources held by services that support explicit disposal
  /// (currently [NetworkMonitor] and [DriverDatabase]). Safe to call more
  /// than once and safe to call even if [init] was never called.
  ///
  /// Not wired to an automatic app-lifecycle hook yet: Flutter/Android do
  /// not guarantee a reliable "app is being terminated" callback, so this
  /// is exposed for explicit use (e.g. tests, a future logout flow) rather
  /// than invented lifecycle plumbing.
  static Future<void> dispose() async {
    final registry = _instance;
    if (registry == null) return;

    await registry._networkMonitor?.dispose();
    await registry._database?.close();
    await registry._authenticationRepository?.dispose();
    final availability = registry._driverAvailabilityRepository;
    if (availability is LocalDriverAvailabilityRepository) {
      availability.dispose();
    }

    _instance = null;
  }

  /// Runs [create], returning its result. If it throws, the failure is
  /// logged via [logger] and `null` is returned instead of rethrowing, so
  /// a non-critical service failure never crashes bootstrap.
  static Future<T?> _safeInit<T>(
    String serviceName,
    LoggerService logger,
    Future<T> Function() create,
  ) async {
    try {
      final service = await create();
      logger.info('AppServiceRegistry: $serviceName initialized');
      return service;
    } catch (error, stackTrace) {
      logger.error(
        'AppServiceRegistry: $serviceName failed to initialize; continuing without it',
        error,
        stackTrace,
      );
      return null;
    }
  }

  late final LoggerService _logger;
  late final AppErrorHandler _errorHandler;
  late final SecureStorageService _storage;
  late final ApiClient _apiClient;
  DriverDatabase? _database;
  NetworkMonitor? _networkMonitor;
  AuthSessionStorage? _authSessionStorage;
  AuthenticationRepository? _authenticationRepository;
  DriverProfileRepository? _driverProfileRepository;
  DriverAvailabilityRepository? _driverAvailabilityRepository;

  /// The application's logger service.
  static LoggerService get logger => _instance!._logger;

  /// The application's error handler.
  static AppErrorHandler get errorHandler => _instance!._errorHandler;

  /// The application's secure storage service.
  static SecureStorageService get storage => _instance!._storage;

  /// The application's API client.
  static ApiClient get apiClient => _instance!._apiClient;

  /// The application's offline-first local database, or `null` if it
  /// failed to initialize. See [init] for the non-critical failure policy.
  static DriverDatabase? get database => _instance!._database;

  /// The application's network connectivity monitor, or `null` if it
  /// failed to initialize. See [init] for the non-critical failure policy.
  static NetworkMonitor? get networkMonitor => _instance!._networkMonitor;

  /// Session persistence for [authenticationRepository], or `null` if it
  /// failed to initialize. See [init] for the non-critical failure policy.
  static AuthSessionStorage? get authSessionStorage =>
      _instance!._authSessionStorage;

  /// PHASE 2.2 mock authentication repository, or `null` if it failed to
  /// initialize (including the production guard rejecting it — see
  /// [FakeAuthenticationRepository]). See [init] for the non-critical
  /// failure policy. [AuthController] treats `null` as "no repository
  /// available" and degrades to the unauthenticated state instead of
  /// crashing.
  static AuthenticationRepository? get authenticationRepository =>
      _instance!._authenticationRepository;

  /// PHASE 2.3 driver profile repository (Fake/local), or `null` if it
  /// failed to initialize. Depends on [authenticationRepository].
  static DriverProfileRepository? get driverProfileRepository =>
      _instance!._driverProfileRepository;

  /// PHASE 2.4 local availability repository, or `null` if it failed to
  /// initialize. Depends on [authenticationRepository] for session identity.
  static DriverAvailabilityRepository? get driverAvailabilityRepository =>
      _instance!._driverAvailabilityRepository;

  /// True once [init] has completed, regardless of whether every
  /// non-critical service succeeded.
  static bool get isInitialized => _instance != null;
}
