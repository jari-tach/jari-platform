import 'dart:convert';

import '../../../../core/services/logger/logger_service.dart';
import '../../../../core/services/storage/secure_storage_service.dart';
import '../../domain/entities/driver_session.dart';

/// Small persistence abstraction for the current [DriverSession].
///
/// Wraps the existing [SecureStorageService] with explicit JSON
/// serialization and corruption handling. Does NOT add any new storage
/// mechanism or encryption library.
class AuthSessionStorage {
  AuthSessionStorage({
    required SecureStorageService storage,
    required LoggerService logger,
  }) : _storage = storage,
       _logger = logger;

  final SecureStorageService _storage;
  final LoggerService _logger;

  /// Versioned key: a future incompatible session shape can bump this
  /// suffix instead of silently misinterpreting old data.
  static const String _sessionKey = 'auth_driver_session_v1';

  Future<void> saveSession(DriverSession session) async {
    final payload = jsonEncode(session.toJson());
    await _storage.write(_sessionKey, payload);
  }

  /// Returns the stored session, or `null` if none exists OR the stored
  /// data is corrupted/unreadable. On corruption: logs the error, clears
  /// the invalid entry, and returns `null` — never throws, never leaves a
  /// half-broken value in storage.
  Future<DriverSession?> readSession() async {
    final raw = await _storage.read(_sessionKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'AuthSessionStorage: stored session is not a JSON object',
        );
      }
      return DriverSession.fromJson(decoded);
    } catch (error, stackTrace) {
      _logger.error(
        'AuthSessionStorage: corrupted session data, clearing',
        error,
        stackTrace,
      );
      try {
        await clearSession();
      } catch (clearError, clearStackTrace) {
        // Best-effort cleanup only: a failure here must not turn a
        // "corrupted session" case into an app crash.
        _logger.error(
          'AuthSessionStorage: failed to clear corrupted session',
          clearError,
          clearStackTrace,
        );
      }
      return null;
    }
  }

  Future<void> clearSession() => _storage.delete(_sessionKey);
}
