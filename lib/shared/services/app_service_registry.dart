import '../../core/services/api/api_client.dart';
import '../../core/services/error/app_error_handler.dart';
import '../../core/services/logger/logger_service.dart';
import '../../core/services/storage/secure_storage_service.dart';

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

    _instance = registry;
    registry._logger.info('AppServiceRegistry initialized');
    return registry;
  }

  late final LoggerService _logger;
  late final AppErrorHandler _errorHandler;
  late final SecureStorageService _storage;
  late final ApiClient _apiClient;

  /// The application's logger service.
  static LoggerService get logger => _instance!._logger;

  /// The application's error handler.
  static AppErrorHandler get errorHandler => _instance!._errorHandler;

  /// The application's secure storage service.
  static SecureStorageService get storage => _instance!._storage;

  /// The application's API client.
  static ApiClient get apiClient => _instance!._apiClient;
}