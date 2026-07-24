import 'package:get_it/get_it.dart';

import '../config/app_config.dart';
import '../services/api/api_client.dart';
import '../services/error/app_error_handler.dart';
import '../services/logger/logger_service.dart';
import '../services/storage/secure_storage_service.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // Core services - lazy singleton
  sl.registerLazySingleton<LoggerService>(() => ConsoleLoggerService());

  // Storage - lazy singleton (requires async init)
  final secureStorage = SecureStorageServiceImpl(logger: sl<LoggerService>());
  await secureStorage.init();
  sl.registerLazySingleton<SecureStorageService>(() => secureStorage);

  // Error handler - lazy singleton
  sl.registerLazySingleton<AppErrorHandler>(
    () => AppErrorHandler(logger: sl<LoggerService>()),
  );

  // API client - lazy singleton
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      logger: sl<LoggerService>(),
      // Token provider must be synchronous (see AuthInterceptor), while
      // getAccessToken() is async; no synchronous token cache exists yet.
      tokenProvider: () => null,
    ),
  );

  // Configuration - factory (creates new instance per request)
  sl.registerFactory<AppConfig>(() => AppConfig());
}

/// Dispose all dependencies
Future<void> disposeDependencies() async {
  // Reset service locator
  await sl.reset();
}
