import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/persisted_driver_availability_record.dart';
import 'driver_availability_local_data_source.dart';

/// SharedPreferences-backed availability snapshot (ADR-019 / ADR-007).
///
/// Reuses an existing dependency — no package additions.
class SharedPreferencesDriverAvailabilityLocalDataSource
    implements DriverAvailabilityLocalDataSource {
  SharedPreferencesDriverAvailabilityLocalDataSource({
    this.preferences,
    Future<SharedPreferences> Function()? preferencesReader,
  }) : _preferencesReader = preferencesReader ?? SharedPreferences.getInstance;

  static const storageKey = 'driver_availability_snapshot_v1';

  final SharedPreferences? preferences;
  final Future<SharedPreferences> Function() _preferencesReader;

  Future<SharedPreferences> _prefs() async =>
      preferences ?? await _preferencesReader();

  @override
  Future<PersistedDriverAvailabilityRecord?> read() async {
    final prefs = await _prefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('availability snapshot is not a JSON object');
    }
    return PersistedDriverAvailabilityRecord.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }

  @override
  Future<void> write(PersistedDriverAvailabilityRecord record) async {
    final prefs = await _prefs();
    final ok = await prefs.setString(storageKey, jsonEncode(record.toJson()));
    if (!ok) {
      throw StateError('SharedPreferences failed to persist availability');
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs.remove(storageKey);
  }
}
