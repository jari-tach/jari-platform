import 'package:saeq_driver/core/services/logger/logger_service.dart';
import 'package:saeq_driver/core/services/storage/secure_storage_service.dart';

/// In-memory [SecureStorageService] for auth tests.
class FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _store = {};

  Exception? throwOnNextWrite;
  Exception? throwOnNextRead;
  Exception? throwOnNextDelete;

  String? debugRawValue(String key) => _store[key];

  void debugSeedRawValue(String key, String value) {
    _store[key] = value;
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> write(String key, String value) async {
    if (throwOnNextWrite != null) {
      final error = throwOnNextWrite!;
      throwOnNextWrite = null;
      throw error;
    }
    _store[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    if (throwOnNextRead != null) {
      final error = throwOnNextRead!;
      throwOnNextRead = null;
      throw error;
    }
    return _store[key];
  }

  @override
  Future<void> delete(String key) async {
    if (throwOnNextDelete != null) {
      final error = throwOnNextDelete!;
      throwOnNextDelete = null;
      throw error;
    }
    _store.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _store.clear();
  }

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<String?> getAccessToken() => read('access_token');

  @override
  Future<String?> getRefreshToken() => read('refresh_token');

  @override
  Future<void> clearAllAuthData() async {
    await delete('access_token');
    await delete('refresh_token');
    await delete('user_id');
    await delete('auth_session');
  }
}

/// Records log messages for assertions in auth tests.
class RecordingLoggerService implements LoggerService {
  final List<String> messages = [];

  LogLevel _level = LogLevel.debug;

  @override
  LogLevel get level => _level;

  @override
  set level(LogLevel value) => _level = value;

  void _record(String message) => messages.add(message);

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _record(message);
  }

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _record(message);
  }

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _record(message);
  }

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _record(message);
  }

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    _record(message);
  }
}
