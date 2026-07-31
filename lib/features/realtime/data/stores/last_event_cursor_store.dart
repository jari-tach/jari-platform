import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last processed event `sequence` per driver for SSE resume
/// (`Last-Event-ID`) and polling `after` cursors.
abstract interface class LastEventCursorStore {
  Future<int?> read(String driverId);
  Future<void> write(String driverId, int sequence);
  Future<void> clear(String driverId);
}

final class SharedPreferencesLastEventCursorStore
    implements LastEventCursorStore {
  SharedPreferencesLastEventCursorStore({SharedPreferences? prefs})
    : _prefsFuture = prefs != null
          ? Future.value(prefs)
          : SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefsFuture;

  static String _key(String driverId) =>
      'saeq.realtime.last_event_sequence.$driverId';

  @override
  Future<int?> read(String driverId) async {
    final prefs = await _prefsFuture;
    if (!prefs.containsKey(_key(driverId))) return null;
    return prefs.getInt(_key(driverId));
  }

  @override
  Future<void> write(String driverId, int sequence) async {
    final prefs = await _prefsFuture;
    await prefs.setInt(_key(driverId), sequence);
  }

  @override
  Future<void> clear(String driverId) async {
    final prefs = await _prefsFuture;
    await prefs.remove(_key(driverId));
  }
}

/// In-memory store for unit tests.
final class MemoryLastEventCursorStore implements LastEventCursorStore {
  final Map<String, int> _values = {};

  @override
  Future<int?> read(String driverId) async => _values[driverId];

  @override
  Future<void> write(String driverId, int sequence) async {
    _values[driverId] = sequence;
  }

  @override
  Future<void> clear(String driverId) async {
    _values.remove(driverId);
  }
}
