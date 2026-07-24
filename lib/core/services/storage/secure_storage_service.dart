import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logger/logger_service.dart';

/// Service for persisting key-value data securely.
///
/// Uses [SharedPreferences] for non-sensitive data.
/// For sensitive data (tokens, credentials), use [flutter_secure_storage]
/// when added as a dependency.
final class SecureStorageService {
  SecureStorageService({required LoggerService logger}) : _logger = logger;

  final LoggerService _logger;
  SharedPreferences? _prefs;

  /// Initialize the storage service. Must be called before use.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _logger.info('SecureStorageService initialized');
  }

  /// Read a string value.
  String? getString(String key) => _prefs?.getString(key);

  /// Write a string value.
  Future<bool> setString(String key, String value) async {
    final result = await _prefs?.setString(key, value) ?? false;
    _logger.debug('Storage: set $key = ${value.length} chars');
    return result;
  }

  /// Read a boolean value.
  bool? getBool(String key) => _prefs?.getBool(key);

  /// Write a boolean value.
  Future<bool> setBool(String key, bool value) async {
    final result = await _prefs?.setBool(key, value) ?? false;
    _logger.debug('Storage: set $key = $value');
    return result;
  }

  /// Read an integer value.
  int? getInt(String key) => _prefs?.getInt(key);

  /// Write an integer value.
  Future<bool> setInt(String key, int value) async {
    final result = await _prefs?.setInt(key, value) ?? false;
    _logger.debug('Storage: set $key = $value');
    return result;
  }

  /// Read a double value.
  double? getDouble(String key) => _prefs?.getDouble(key);

  /// Write a double value.
  Future<bool> setDouble(String key, double value) async {
    final result = await _prefs?.setDouble(key, value) ?? false;
    _logger.debug('Storage: set $key = $value');
    return result;
  }

  /// Read a JSON-encoded value and decode it.
  T? getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return fromJson(map);
    } catch (e) {
      _logger.error('Failed to decode JSON for key: $key', error: e);
      return null;
    }
  }

  /// Write a value as JSON.
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final raw = jsonEncode(value);
      return setString(key, raw);
    } catch (e) {
      _logger.error('Failed to encode JSON for key: $key', error: e);
      return false;
    }
  }

  /// Remove a value by key.
  Future<bool> remove(String key) async {
    final result = await _prefs?.remove(key) ?? false;
    _logger.debug('Storage: removed $key');
    return result;
  }

  /// Check if a key exists.
  bool containsKey(String key) => _prefs?.containsKey(key) ?? false;

  /// Clear all stored data.
  Future<bool> clear() async {
    final result = await _prefs?.clear() ?? false;
    _logger.info('Storage: cleared all data');
    return result;
  }
}