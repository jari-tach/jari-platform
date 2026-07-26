import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/config/app_config.dart';
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
import '../../features/availability/domain/usecases/apply_authoritative_availability.dart';
import '../../features/availability/domain/usecases/get_driver_availability.dart';
import '../../features/delivery/application/accept_delivery_offer_and_bind_busy.dart';
import '../../features/delivery/application/complete_delivery_and_release_busy.dart';
import '../../features/delivery/data/datasources/delivery_local_data_source.dart';
import '../../features/delivery/data/datasources/delivery_remote_data_source.dart';
import '../../features/delivery/data/datasources/drift_delivery_local_data_source.dart';
import '../../features/delivery/data/fake/fake_delivery_remote_data_source.dart';
import '../../features/delivery/data/repositories/local_delivery_assignment_repository.dart';
import '../../features/delivery/data/repositories/remote_delivery_offer_repository.dart';
import '../../features/delivery/domain/repositories/delivery_assignment_repository.dart';
import '../../features/delivery/domain/repositories/delivery_offer_repository.dart';
import '../../features/delivery/domain/usecases/accept_delivery_offer.dart';
import '../../features/delivery/domain/usecases/advance_delivery_workflow.dart';
import '../../features/delivery/domain/usecases/get_active_delivery.dart';
import '../../features/delivery/domain/usecases/get_delivery_offers.dart';
import '../../features/delivery/domain/usecases/reject_delivery_offer.dart';
import '../../features/delivery/domain/usecases/verify_delivery_code.dart';
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

    // PHASE 2.5 / 2.6 — Delivery Request Lifecycle DI wiring.
    // Remote: Fake only outside production (ADR-027). Production leaves the
    // remote port null until a real Backend adapter exists — never Fake.
    // Local: Drift when DriverDatabase activated (ADR-028).
    await registry._initDeliveryStack();

    _instance = registry;
    registry._logger.info('AppServiceRegistry initialized');
    return registry;
  }

  /// Wires Delivery datasources → repositories → use cases.
  Future<void> _initDeliveryStack() async {
    if (!AppConfig.isProduction) {
      _deliveryRemoteDataSource = await _safeInit<DeliveryRemoteDataSource>(
        'FakeDeliveryRemoteDataSource',
        _logger,
        () async => FakeDeliveryRemoteDataSource(
          // Fake constructor also enforces Release/Production policy (ADR-027).
          isProductionEnvironment: () => AppConfig.isProduction,
        ),
      );
    } else {
      _deliveryRemoteDataSource = null;
      _logger.info(
        'AppServiceRegistry: FakeDeliveryRemoteDataSource skipped in production',
      );
    }

    final remote = _deliveryRemoteDataSource;
    _deliveryOfferRepository = remote == null
        ? null
        : await _safeInit<DeliveryOfferRepository>(
            'DeliveryOfferRepository',
            _logger,
            () async => RemoteDeliveryOfferRepository(remoteDataSource: remote),
          );

    final database = _database;
    _deliveryLocalDataSource = database == null
        ? null
        : await _safeInit<DeliveryLocalDataSource>(
            'DriftDeliveryLocalDataSource',
            _logger,
            () async => DriftDeliveryLocalDataSource(database: database),
          );

    final local = _deliveryLocalDataSource;
    _deliveryAssignmentRepository = local == null
        ? null
        : await _safeInit<DeliveryAssignmentRepository>(
            'DeliveryAssignmentRepository',
            _logger,
            () async =>
                LocalDeliveryAssignmentRepository(localDataSource: local),
          );

    final offerRepository = _deliveryOfferRepository;
    final assignmentRepository = _deliveryAssignmentRepository;

    _getDeliveryOffers = offerRepository == null
        ? null
        : await _safeInit<GetDeliveryOffers>(
            'GetDeliveryOffers',
            _logger,
            () async => GetDeliveryOffers(offerRepository),
          );

    _acceptDeliveryOffer =
        (offerRepository == null || assignmentRepository == null)
        ? null
        : await _safeInit<AcceptDeliveryOffer>(
            'AcceptDeliveryOffer',
            _logger,
            () async =>
                AcceptDeliveryOffer(offerRepository, assignmentRepository),
          );

    _rejectDeliveryOffer = offerRepository == null
        ? null
        : await _safeInit<RejectDeliveryOffer>(
            'RejectDeliveryOffer',
            _logger,
            () async => RejectDeliveryOffer(offerRepository),
          );

    _getActiveDelivery = assignmentRepository == null
        ? null
        : await _safeInit<GetActiveDelivery>(
            'GetActiveDelivery',
            _logger,
            () async => GetActiveDelivery(assignmentRepository),
          );

    _advanceDeliveryWorkflow = assignmentRepository == null
        ? null
        : await _safeInit<AdvanceDeliveryWorkflow>(
            'AdvanceDeliveryWorkflow',
            _logger,
            () async => AdvanceDeliveryWorkflow(assignmentRepository),
          );

    _verifyDeliveryCode = assignmentRepository == null
        ? null
        : await _safeInit<VerifyDeliveryCode>(
            'VerifyDeliveryCode',
            _logger,
            () async => VerifyDeliveryCode(assignmentRepository),
          );

    // ADR-025 — accept + busy binding coordinator (application layer).
    final availabilityRepository = _driverAvailabilityRepository;
    _acceptDeliveryOfferAndBindBusy =
        (_acceptDeliveryOffer == null || availabilityRepository == null)
        ? null
        : await _safeInit<AcceptDeliveryOfferAndBindBusy>(
            'AcceptDeliveryOfferAndBindBusy',
            _logger,
            () async => AcceptDeliveryOfferAndBindBusy(
              _acceptDeliveryOffer!,
              ApplyAuthoritativeAvailability(availabilityRepository),
              GetDriverAvailability(availabilityRepository),
            ),
          );

    _completeDeliveryAndReleaseBusy =
        (assignmentRepository == null || availabilityRepository == null)
        ? null
        : await _safeInit<CompleteDeliveryAndReleaseBusy>(
            'CompleteDeliveryAndReleaseBusy',
            _logger,
            () async => CompleteDeliveryAndReleaseBusy(
              assignmentRepository,
              ApplyAuthoritativeAvailability(availabilityRepository),
              GetDriverAvailability(availabilityRepository),
            ),
          );

    _logger.info(
      'AppServiceRegistry delivery stack: '
      'remote=${_deliveryRemoteDataSource == null ? "none" : _deliveryRemoteDataSource.runtimeType}, '
      'localDb=${_deliveryLocalDataSource == null ? "none" : "Drift"}, '
      'offers=${_getDeliveryOffers != null}, '
      'acceptBind=${_acceptDeliveryOfferAndBindBusy != null}, '
      'workflow=${_advanceDeliveryWorkflow != null}, '
      'env=${AppConfig.environment.name}, '
      'debug=${AppConfig.isDebug}',
    );
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
    final remote = registry._deliveryRemoteDataSource;
    if (remote is FakeDeliveryRemoteDataSource) {
      remote.dispose();
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
  DeliveryRemoteDataSource? _deliveryRemoteDataSource;
  DeliveryLocalDataSource? _deliveryLocalDataSource;
  DeliveryOfferRepository? _deliveryOfferRepository;
  DeliveryAssignmentRepository? _deliveryAssignmentRepository;
  GetDeliveryOffers? _getDeliveryOffers;
  AcceptDeliveryOffer? _acceptDeliveryOffer;
  RejectDeliveryOffer? _rejectDeliveryOffer;
  GetActiveDelivery? _getActiveDelivery;
  AdvanceDeliveryWorkflow? _advanceDeliveryWorkflow;
  VerifyDeliveryCode? _verifyDeliveryCode;
  AcceptDeliveryOfferAndBindBusy? _acceptDeliveryOfferAndBindBusy;
  CompleteDeliveryAndReleaseBusy? _completeDeliveryAndReleaseBusy;

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

  /// PHASE 2.5/2.6 remote delivery port (Fake outside production), or `null`.
  static DeliveryRemoteDataSource? get deliveryRemoteDataSource =>
      _instance!._deliveryRemoteDataSource;

  /// PHASE 2.5/2.6 Drift local assignment port, or `null` if DB unavailable.
  static DeliveryLocalDataSource? get deliveryLocalDataSource =>
      _instance!._deliveryLocalDataSource;

  /// PHASE 2.5/2.6 offer repository, or `null` when remote is unavailable.
  static DeliveryOfferRepository? get deliveryOfferRepository =>
      _instance!._deliveryOfferRepository;

  /// PHASE 2.5/2.6 assignment repository, or `null` when local is unavailable.
  static DeliveryAssignmentRepository? get deliveryAssignmentRepository =>
      _instance!._deliveryAssignmentRepository;

  /// Use case: load offers (one-active enforced).
  static GetDeliveryOffers? get getDeliveryOffers =>
      _instance!._getDeliveryOffers;

  /// Use case: accept offer and persist assignment.
  static AcceptDeliveryOffer? get acceptDeliveryOffer =>
      _instance!._acceptDeliveryOffer;

  /// Use case: reject offer.
  static RejectDeliveryOffer? get rejectDeliveryOffer =>
      _instance!._rejectDeliveryOffer;

  /// Use case: restore/read active assignment.
  static GetActiveDelivery? get getActiveDelivery =>
      _instance!._getActiveDelivery;

  /// Use case: advance active delivery workflow stage (PHASE 2.6).
  static AdvanceDeliveryWorkflow? get advanceDeliveryWorkflow =>
      _instance!._advanceDeliveryWorkflow;

  /// Use case: Fake/Backend delivery code verification (PHASE 2.6).
  static VerifyDeliveryCode? get verifyDeliveryCode =>
      _instance!._verifyDeliveryCode;

  /// ADR-025 application coordinator: accept + persist + busy bind.
  static AcceptDeliveryOfferAndBindBusy? get acceptDeliveryOfferAndBindBusy =>
      _instance!._acceptDeliveryOfferAndBindBusy;

  /// Application coordinator: clear summary assignment + release busy.
  static CompleteDeliveryAndReleaseBusy? get completeDeliveryAndReleaseBusy =>
      _instance!._completeDeliveryAndReleaseBusy;

  /// True once [init] has completed, regardless of whether every
  /// non-critical service succeeded.
  static bool get isInitialized => _instance != null;
}
