import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/auth_session/access_token_memory_cache.dart';
import '../../core/auth_session/auth_token_store.dart';
import '../../core/auth_session/device_identity_store.dart';
import '../../core/auth_session/session_repository.dart';
import '../../core/backend_configuration/backend_configuration.dart';
import '../../core/config/app_config.dart';
import '../../core/network/authenticated_request_executor.dart';
import '../../core/network/network_monitor.dart';
import '../../core/network/saeq_api_client.dart';
import '../../core/services/api/api_client.dart';
import '../../core/services/error/app_error_handler.dart';
import '../../core/services/logger/logger_service.dart';
import '../../core/services/storage/secure_storage_service.dart';
import '../../features/auth/data/remote/http_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/fake_authentication_repository.dart';
import '../../features/auth/data/repositories/remote_authentication_repository.dart';
import '../../features/auth/data/session/auth_session_storage.dart';
import '../../features/auth/domain/repositories/authentication_repository.dart';
import '../../features/availability/data/datasources/shared_preferences_driver_availability_local_data_source.dart';
import '../../features/availability/data/remote/http_driver_availability_remote_data_source.dart';
import '../../features/availability/data/repositories/local_driver_availability_repository.dart';
import '../../features/availability/data/repositories/remote_driver_availability_repository.dart';
import '../../features/availability/domain/repositories/driver_availability_repository.dart';
import '../../features/availability/domain/usecases/apply_authoritative_availability.dart';
import '../../features/availability/domain/usecases/get_driver_availability.dart';
import '../../features/delivery/application/accept_delivery_offer_and_bind_busy.dart';
import '../../features/delivery/application/complete_delivery_and_release_busy.dart';
import '../../features/delivery/data/datasources/delivery_local_data_source.dart';
import '../../features/delivery/data/datasources/delivery_remote_data_source.dart';
import '../../features/delivery/data/datasources/drift_delivery_local_data_source.dart';
import '../../features/delivery/data/fake/fake_delivery_lifecycle_repository.dart';
import '../../features/delivery/data/fake/fake_delivery_remote_data_source.dart';
import '../../features/delivery/data/remote/customer_contact_memory_cache.dart';
import '../../features/delivery/data/remote/http_delivery_lifecycle_remote.dart';
import '../../features/delivery/data/remote/http_delivery_remote_data_source.dart';
import '../../features/delivery/data/repositories/local_delivery_assignment_repository.dart';
import '../../features/delivery/data/repositories/drift_delivery_command_repository.dart';
import '../../features/delivery/data/repositories/remote_delivery_lifecycle_repository.dart';
import '../../features/delivery/data/repositories/remote_delivery_offer_repository.dart';
import '../../features/realtime/application/realtime_coordinator.dart';
import '../../features/realtime/data/remote/http_client_sse_transport.dart';
import '../../features/realtime/data/remote/http_driver_events_remote.dart';
import '../../features/realtime/data/stores/last_event_cursor_store.dart';
import '../../features/delivery/domain/repositories/delivery_assignment_repository.dart';
import '../../features/delivery/domain/repositories/delivery_command_repository.dart';
import '../../features/delivery/domain/repositories/delivery_lifecycle_repository.dart';
import '../../features/delivery/domain/repositories/delivery_offer_repository.dart';
import '../../features/delivery/domain/usecases/accept_delivery_offer.dart';
import '../../features/delivery/domain/usecases/advance_delivery_workflow.dart';
import '../../features/delivery/domain/usecases/cancel_delivery_remote.dart';
import '../../features/delivery/domain/usecases/confirm_delivery_remote.dart';
import '../../features/delivery/domain/usecases/confirm_pickup_remote.dart';
import '../../features/delivery/domain/usecases/get_active_batch.dart';
import '../../features/delivery/domain/usecases/get_active_delivery.dart';
import '../../features/delivery/domain/usecases/get_customer_contact.dart';
import '../../features/delivery/domain/usecases/get_delivery_offers.dart';
import '../../features/delivery/domain/usecases/reject_delivery_offer.dart';
import '../../features/delivery/domain/usecases/record_local_delivery_command.dart';
import '../../features/delivery/domain/usecases/replay_pending_delivery_commands.dart';
import '../../features/delivery/domain/usecases/report_automatic_arrival_remote.dart';
import '../../features/delivery/domain/usecases/report_delivery_issue_remote.dart';
import '../../features/delivery/domain/usecases/verify_delivery_code.dart';
import '../../features/driver/data/datasources/local/driver_database.dart';
import '../../features/profile/data/remote/http_driver_profile_remote_data_source.dart';
import '../../features/profile/data/repositories/fake_driver_profile_repository.dart';
import '../../features/profile/data/repositories/remote_driver_profile_repository.dart';
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

    // STEP 5C-1 — build-time backend mode (fake|remote). Fake is forbidden
    // in profile/release; failure here is intentional and must not soft-fail.
    registry._backendConfiguration = BackendConfiguration.resolve();
    registry._accessTokenCache = AccessTokenMemoryCache();
    registry._authTokenStore = SecureAuthTokenStore(storage: registry._storage);
    registry._sessionRepository = SessionRepository(
      tokenStore: registry._authTokenStore,
      accessTokenCache: registry._accessTokenCache,
    );

    // Protected ApiClient keeps its sync tokenProvider contract without
    // editing api_client.dart — memory cache supplies the access token.
    registry._apiClient = ApiClient(
      logger: registry._logger,
      tokenProvider: () => registry._accessTokenCache.accessToken,
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

    // STEP 5C-1 — AuthenticationRepository: Fake or Remote per
    // BackendConfiguration. Remote wiring must not soft-fail into Fake.
    // FakeAuthenticationRepository's constructor enforces the production
    // guard (throws if AppConfig.isProduction is true). That failure —
    // like any other non-critical bootstrap failure for Fake — is logged
    // and degrades to null, never silently.
    final authSessionStorage = registry._authSessionStorage;
    registry._authenticationRepository = authSessionStorage == null
        ? null
        : await _initAuthenticationRepository(
            registry: registry,
            authSessionStorage: authSessionStorage,
          );

    // PHASE 2.3 / STEP 5C-2 — Driver Identity and Profile.
    final authenticationRepository = registry._authenticationRepository;
    registry._driverProfileRepository = authenticationRepository == null
        ? null
        : await _initDriverProfileRepository(
            registry: registry,
            authenticationRepository: authenticationRepository,
          );

    // PHASE 2.4 / STEP 5C-2 — Driver Availability.
    registry._driverAvailabilityRepository = authenticationRepository == null
        ? null
        : await _initDriverAvailabilityRepository(registry: registry);

    // PHASE 2.5 / 2.6 — Delivery Request Lifecycle DI wiring.
    // Remote: Fake only outside production (ADR-027). Production leaves the
    // remote port null until a real Backend adapter exists — never Fake.
    // Local: Drift when DriverDatabase activated (ADR-028).
    await registry._initDeliveryStack();

    _instance = registry;
    registry._logger.info('AppServiceRegistry initialized');
    return registry;
  }

  /// STEP 6-B: SSE + polling events channel (remote only).
  void _initRealtimeCoordinator({required SaeqApiClient api}) {
    final baseUrl = _backendConfiguration.apiBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) return;

    late final RemoteAuthenticationRepository? remoteAuth;
    final auth = _authenticationRepository;
    remoteAuth = auth is RemoteAuthenticationRepository ? auth : null;

    final eventsRemote = HttpDriverEventsRemote(
      api: api,
      baseUrl: baseUrl,
      accessTokenCache: _accessTokenCache,
      sseTransport: HttpClientSseTransport(),
    );
    _realtimeCoordinator = RealtimeCoordinator(
      remote: eventsRemote,
      cursorStore: SharedPreferencesLastEventCursorStore(),
      logger: _logger,
      onUnauthorizedRefresh: () async {
        if (remoteAuth == null) return false;
        return remoteAuth.refreshTokensForClient();
      },
    );
    _logger.info('AppServiceRegistry: RealtimeCoordinator initialized');
  }

  /// Wires Delivery datasources → repositories → use cases.
  Future<void> _initDeliveryStack() async {
    if (_backendConfiguration.isRemote) {
      final api = _saeqApiClient;
      if (api == null) {
        throw StateError(
          'SaeqApiClient is required for remote delivery offers.',
        );
      }
      _deliveryRemoteDataSource = HttpDeliveryRemoteDataSource(api: api);
      _customerContactMemoryCache = CustomerContactMemoryCache();
      _deliveryLifecycleRemote = HttpDeliveryLifecycleRemote(
        api: api,
        contactCache: _customerContactMemoryCache!,
      );
      _deliveryLifecycleRepository = RemoteDeliveryLifecycleRepository(
        remote: _deliveryLifecycleRemote!,
      );
      _initRealtimeCoordinator(api: api);
      _logger.info(
        'AppServiceRegistry: HttpDeliveryRemoteDataSource + lifecycle initialized',
      );
    } else if (!AppConfig.isProduction) {
      _deliveryRemoteDataSource = await _safeInit<DeliveryRemoteDataSource>(
        'FakeDeliveryRemoteDataSource',
        _logger,
        () async => FakeDeliveryRemoteDataSource(
          isProductionEnvironment: () => AppConfig.isProduction,
        ),
      );
      _deliveryLifecycleRepository =
          await _safeInit<DeliveryLifecycleRepository>(
            'FakeDeliveryLifecycleRepository',
            _logger,
            () async => FakeDeliveryLifecycleRepository(
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
    _deliveryCommandRepository = database == null
        ? null
        : await _safeInit<DeliveryCommandRepository>(
            'DeliveryCommandRepository',
            _logger,
            () async => DriftDeliveryCommandRepository(database: database),
          );
    final commandRepository = _deliveryCommandRepository;
    _recordLocalDeliveryCommand = commandRepository == null
        ? null
        : await _safeInit<RecordLocalDeliveryCommand>(
            'RecordLocalDeliveryCommand',
            _logger,
            () async => RecordLocalDeliveryCommand(commandRepository),
          );

    _getDeliveryOffers = offerRepository == null
        ? null
        : await _safeInit<GetDeliveryOffers>(
            'GetDeliveryOffers',
            _logger,
            () async => GetDeliveryOffers(
              offerRepository,
              commandRepository: commandRepository,
            ),
          );

    _acceptDeliveryOffer =
        (offerRepository == null || assignmentRepository == null)
        ? null
        : await _safeInit<AcceptDeliveryOffer>(
            'AcceptDeliveryOffer',
            _logger,
            () async => AcceptDeliveryOffer(
              offerRepository,
              assignmentRepository,
              commandRepository: commandRepository,
            ),
          );

    _rejectDeliveryOffer = offerRepository == null
        ? null
        : await _safeInit<RejectDeliveryOffer>(
            'RejectDeliveryOffer',
            _logger,
            () async => RejectDeliveryOffer(
              offerRepository,
              commandRepository: commandRepository,
            ),
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

    // STEP 5D-1 — Backend-authoritative lifecycle use cases.
    final lifecycleRepository = _deliveryLifecycleRepository;
    _confirmPickupRemote =
        (lifecycleRepository == null ||
            assignmentRepository == null ||
            commandRepository == null)
        ? null
        : await _safeInit<ConfirmPickupRemote>(
            'ConfirmPickupRemote',
            _logger,
            () async => ConfirmPickupRemote(
              lifecycleRepository: lifecycleRepository,
              assignmentRepository: assignmentRepository,
              commandRepository: commandRepository,
              advanceWorkflow: _advanceDeliveryWorkflow,
            ),
          );
    _reportAutomaticArrivalRemote =
        (lifecycleRepository == null ||
            assignmentRepository == null ||
            commandRepository == null)
        ? null
        : await _safeInit<ReportAutomaticArrivalRemote>(
            'ReportAutomaticArrivalRemote',
            _logger,
            () async => ReportAutomaticArrivalRemote(
              lifecycleRepository: lifecycleRepository,
              assignmentRepository: assignmentRepository,
              commandRepository: commandRepository,
              advanceWorkflow: _advanceDeliveryWorkflow,
            ),
          );
    _confirmDeliveryRemote =
        (lifecycleRepository == null ||
            assignmentRepository == null ||
            commandRepository == null)
        ? null
        : await _safeInit<ConfirmDeliveryRemote>(
            'ConfirmDeliveryRemote',
            _logger,
            () async => ConfirmDeliveryRemote(
              lifecycleRepository: lifecycleRepository,
              assignmentRepository: assignmentRepository,
              commandRepository: commandRepository,
              advanceWorkflow: _advanceDeliveryWorkflow,
            ),
          );
    _cancelDeliveryRemote =
        (lifecycleRepository == null ||
            assignmentRepository == null ||
            commandRepository == null)
        ? null
        : await _safeInit<CancelDeliveryRemote>(
            'CancelDeliveryRemote',
            _logger,
            () async => CancelDeliveryRemote(
              lifecycleRepository: lifecycleRepository,
              assignmentRepository: assignmentRepository,
              commandRepository: commandRepository,
            ),
          );
    _reportDeliveryIssueRemote =
        (lifecycleRepository == null ||
            assignmentRepository == null ||
            commandRepository == null)
        ? null
        : await _safeInit<ReportDeliveryIssueRemote>(
            'ReportDeliveryIssueRemote',
            _logger,
            () async => ReportDeliveryIssueRemote(
              lifecycleRepository: lifecycleRepository,
              assignmentRepository: assignmentRepository,
              commandRepository: commandRepository,
              advanceWorkflow: _advanceDeliveryWorkflow,
            ),
          );
    _getCustomerContact =
        (lifecycleRepository == null || assignmentRepository == null)
        ? null
        : await _safeInit<GetCustomerContact>(
            'GetCustomerContact',
            _logger,
            () async => GetCustomerContact(
              lifecycleRepository: lifecycleRepository,
              assignmentRepository: assignmentRepository,
            ),
          );
    _getActiveBatch = lifecycleRepository == null
        ? null
        : await _safeInit<GetActiveBatch>(
            'GetActiveBatch',
            _logger,
            () async => GetActiveBatch(lifecycleRepository),
          );
    _replayPendingDeliveryCommands =
        (_confirmPickupRemote == null ||
            _reportAutomaticArrivalRemote == null ||
            _confirmDeliveryRemote == null ||
            assignmentRepository == null ||
            commandRepository == null)
        ? null
        : await _safeInit<ReplayPendingDeliveryCommands>(
            'ReplayPendingDeliveryCommands',
            _logger,
            () async => ReplayPendingDeliveryCommands(
              commandRepository: commandRepository,
              assignmentRepository: assignmentRepository,
              confirmPickup: _confirmPickupRemote!,
              reportArrival: _reportAutomaticArrivalRemote!,
              confirmDelivery: _confirmDeliveryRemote!,
              advanceWorkflow: _advanceDeliveryWorkflow,
            ),
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
    registry._deliveryLifecycleRemote?.onLogoutOrSessionExpired();
    registry._customerContactMemoryCache?.clear();
    await registry._realtimeCoordinator?.dispose();
    registry._realtimeCoordinator = null;
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

  /// STEP 5C-1 auth wiring. Fake uses [_safeInit]; remote fails hard so a
  /// misconfigured remote build never silently falls back to Fake.
  static Future<AuthenticationRepository?> _initAuthenticationRepository({
    required AppServiceRegistry registry,
    required AuthSessionStorage authSessionStorage,
  }) async {
    final config = registry._backendConfiguration;
    if (config.isFake) {
      return _safeInit<AuthenticationRepository>(
        'FakeAuthenticationRepository',
        registry._logger,
        () async => FakeAuthenticationRepository(
          sessionStorage: authSessionStorage,
          logger: registry._logger,
          // Mirrors AppConfig.isProduction for the Fake ctor production gate.
          isProductionEnvironment: () => AppConfig.isProduction,
        ),
      );
    }

    final baseUrl = config.apiBaseUrl;
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError(
        'SAEQ_API_BASE_URL is required for remote authentication.',
      );
    }

    late final RemoteAuthenticationRepository remoteRepo;
    final apiClient = SaeqApiClient(
      baseUrl: baseUrl,
      accessTokenCache: registry._accessTokenCache,
      logger: registry._logger,
      onUnauthorizedRefresh: () => remoteRepo.refreshTokensForClient(),
    );
    registry._saeqApiClient = apiClient;
    registry._authenticatedRequestExecutor = AuthenticatedRequestExecutor(
      api: apiClient,
    );

    remoteRepo = RemoteAuthenticationRepository(
      remote: HttpAuthRemoteDataSource(api: apiClient),
      sessionStorage: authSessionStorage,
      tokenStore: registry._authTokenStore,
      accessTokenCache: registry._accessTokenCache,
      logger: registry._logger,
      deviceIdentityStore: SecureDeviceIdentityStore(
        storage: registry._storage,
      ),
    );
    registry._logger.info(
      'AppServiceRegistry: RemoteAuthenticationRepository initialized',
    );
    return remoteRepo;
  }

  static Future<DriverProfileRepository?> _initDriverProfileRepository({
    required AppServiceRegistry registry,
    required AuthenticationRepository authenticationRepository,
  }) async {
    if (registry._backendConfiguration.isFake) {
      return _safeInit<DriverProfileRepository>(
        'FakeDriverProfileRepository',
        registry._logger,
        () async => FakeDriverProfileRepository(
          authenticationRepository: authenticationRepository,
          logger: registry._logger,
          database: registry._database,
        ),
      );
    }
    final api = registry._saeqApiClient;
    if (api == null) {
      throw StateError('SaeqApiClient is required for remote profile.');
    }
    final repo = RemoteDriverProfileRepository(
      remote: HttpDriverProfileRemoteDataSource(api: api),
    );
    registry._logger.info(
      'AppServiceRegistry: RemoteDriverProfileRepository initialized',
    );
    return repo;
  }

  static Future<DriverAvailabilityRepository?>
  _initDriverAvailabilityRepository({
    required AppServiceRegistry registry,
  }) async {
    String driverIdReader() =>
        registry._authenticationRepository?.currentSession?.driverId ?? '';

    if (registry._backendConfiguration.isFake) {
      return _safeInit<DriverAvailabilityRepository>(
        'LocalDriverAvailabilityRepository',
        registry._logger,
        () async => LocalDriverAvailabilityRepository(
          localDataSource: SharedPreferencesDriverAvailabilityLocalDataSource(),
          currentDriverIdReader: driverIdReader,
        ),
      );
    }
    final api = registry._saeqApiClient;
    if (api == null) {
      throw StateError('SaeqApiClient is required for remote availability.');
    }
    final repo = RemoteDriverAvailabilityRepository(
      remote: HttpDriverAvailabilityRemoteDataSource(api: api),
      currentDriverIdReader: driverIdReader,
    );
    registry._logger.info(
      'AppServiceRegistry: RemoteDriverAvailabilityRepository initialized',
    );
    return repo;
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
  late final BackendConfiguration _backendConfiguration;
  late final AccessTokenMemoryCache _accessTokenCache;
  late final AuthTokenStore _authTokenStore;
  late final SessionRepository _sessionRepository;
  SaeqApiClient? _saeqApiClient;
  AuthenticatedRequestExecutor? _authenticatedRequestExecutor;
  DriverDatabase? _database;
  NetworkMonitor? _networkMonitor;
  AuthSessionStorage? _authSessionStorage;
  AuthenticationRepository? _authenticationRepository;
  DriverProfileRepository? _driverProfileRepository;
  DriverAvailabilityRepository? _driverAvailabilityRepository;
  DeliveryRemoteDataSource? _deliveryRemoteDataSource;
  CustomerContactMemoryCache? _customerContactMemoryCache;
  HttpDeliveryLifecycleRemote? _deliveryLifecycleRemote;
  DeliveryLifecycleRepository? _deliveryLifecycleRepository;
  DeliveryLocalDataSource? _deliveryLocalDataSource;
  DeliveryOfferRepository? _deliveryOfferRepository;
  DeliveryAssignmentRepository? _deliveryAssignmentRepository;
  DeliveryCommandRepository? _deliveryCommandRepository;
  GetDeliveryOffers? _getDeliveryOffers;
  AcceptDeliveryOffer? _acceptDeliveryOffer;
  RejectDeliveryOffer? _rejectDeliveryOffer;
  GetActiveDelivery? _getActiveDelivery;
  AdvanceDeliveryWorkflow? _advanceDeliveryWorkflow;
  VerifyDeliveryCode? _verifyDeliveryCode;
  ConfirmPickupRemote? _confirmPickupRemote;
  ReportAutomaticArrivalRemote? _reportAutomaticArrivalRemote;
  ConfirmDeliveryRemote? _confirmDeliveryRemote;
  CancelDeliveryRemote? _cancelDeliveryRemote;
  ReportDeliveryIssueRemote? _reportDeliveryIssueRemote;
  GetCustomerContact? _getCustomerContact;
  GetActiveBatch? _getActiveBatch;
  ReplayPendingDeliveryCommands? _replayPendingDeliveryCommands;
  AcceptDeliveryOfferAndBindBusy? _acceptDeliveryOfferAndBindBusy;
  CompleteDeliveryAndReleaseBusy? _completeDeliveryAndReleaseBusy;
  RecordLocalDeliveryCommand? _recordLocalDeliveryCommand;
  RealtimeCoordinator? _realtimeCoordinator;

  /// The application's logger service.
  static LoggerService get logger => _instance!._logger;

  /// The application's error handler.
  static AppErrorHandler get errorHandler => _instance!._errorHandler;

  /// The application's secure storage service.
  static SecureStorageService get storage => _instance!._storage;

  /// The application's API client.
  static ApiClient get apiClient => _instance!._apiClient;

  /// STEP 5C build-time backend configuration.
  static BackendConfiguration get backendConfiguration =>
      _instance!._backendConfiguration;

  /// In-memory access token cache (never SharedPreferences).
  static AccessTokenMemoryCache get accessTokenCache =>
      _instance!._accessTokenCache;

  /// Secure refresh-token store (Keystore / Keychain via SecureStorage).
  static AuthTokenStore get authTokenStore => _instance!._authTokenStore;

  /// Session boundary for tokens.
  static SessionRepository get sessionRepository =>
      _instance!._sessionRepository;

  /// STEP 5C SAEQ HTTP client (null when Fake mode).
  static SaeqApiClient? get saeqApiClient => _instance!._saeqApiClient;

  /// Authenticated request executor over [saeqApiClient].
  static AuthenticatedRequestExecutor? get authenticatedRequestExecutor =>
      _instance!._authenticatedRequestExecutor;

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

  /// STEP 5C-3 delivery lifecycle REST (pickup/arrival/confirm/batch/contact).
  static HttpDeliveryLifecycleRemote? get deliveryLifecycleRemote =>
      _instance!._deliveryLifecycleRemote;

  /// Memory-only customer contact cache (cleared on logout/completion).
  static CustomerContactMemoryCache? get customerContactMemoryCache =>
      _instance!._customerContactMemoryCache;

  /// STEP 5D-1 domain lifecycle port (remote or Fake).
  static DeliveryLifecycleRepository? get deliveryLifecycleRepository =>
      _instance!._deliveryLifecycleRepository;

  /// PHASE 2.5/2.6 Drift local assignment port, or `null` if DB unavailable.
  static DeliveryLocalDataSource? get deliveryLocalDataSource =>
      _instance!._deliveryLocalDataSource;

  /// PHASE 2.5/2.6 offer repository, or `null` when remote is unavailable.
  static DeliveryOfferRepository? get deliveryOfferRepository =>
      _instance!._deliveryOfferRepository;

  /// PHASE 2.5/2.6 assignment repository, or `null` when local is unavailable.
  static DeliveryAssignmentRepository? get deliveryAssignmentRepository =>
      _instance!._deliveryAssignmentRepository;

  /// STEP 3 local command ledger; never a Backend adapter.
  static DeliveryCommandRepository? get deliveryCommandRepository =>
      _instance!._deliveryCommandRepository;

  /// STEP 6-B realtime coordinator (SSE + polling); remote mode only.
  static RealtimeCoordinator? get realtimeCoordinator =>
      _instance!._realtimeCoordinator;

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

  /// STEP 5D-1: Backend pickup confirmation.
  static ConfirmPickupRemote? get confirmPickupRemote =>
      _instance!._confirmPickupRemote;

  /// STEP 5D-1: automatic geofence arrival report.
  static ReportAutomaticArrivalRemote? get reportAutomaticArrivalRemote =>
      _instance!._reportAutomaticArrivalRemote;

  /// STEP 5D-1: Backend delivery confirmation.
  static ConfirmDeliveryRemote? get confirmDeliveryRemote =>
      _instance!._confirmDeliveryRemote;

  /// STEP 5D-1: Backend delivery cancellation.
  static CancelDeliveryRemote? get cancelDeliveryRemote =>
      _instance!._cancelDeliveryRemote;

  /// STEP 5D-1: Backend issue report.
  static ReportDeliveryIssueRemote? get reportDeliveryIssueRemote =>
      _instance!._reportDeliveryIssueRemote;

  /// STEP 5D-1: current customer contact (memory-only after Backend ack).
  static GetCustomerContact? get getCustomerContact =>
      _instance!._getCustomerContact;

  /// STEP 5D-1: active batch summary.
  static GetActiveBatch? get getActiveBatch => _instance!._getActiveBatch;

  /// STEP 5D-1: replay pending lifecycle commands with the same keys.
  static ReplayPendingDeliveryCommands? get replayPendingDeliveryCommands =>
      _instance!._replayPendingDeliveryCommands;

  /// ADR-025 application coordinator: accept + persist + busy bind.
  static AcceptDeliveryOfferAndBindBusy? get acceptDeliveryOfferAndBindBusy =>
      _instance!._acceptDeliveryOfferAndBindBusy;

  /// Application coordinator: clear summary assignment + release busy.
  static CompleteDeliveryAndReleaseBusy? get completeDeliveryAndReleaseBusy =>
      _instance!._completeDeliveryAndReleaseBusy;

  /// Records non-state-machine local commands such as form cancellation.
  static RecordLocalDeliveryCommand? get recordLocalDeliveryCommand =>
      _instance!._recordLocalDeliveryCommand;

  /// True once [init] has completed, regardless of whether every
  /// non-critical service succeeded.
  static bool get isInitialized => _instance != null;
}
