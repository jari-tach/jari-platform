import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/realtime/data/stores/last_event_cursor_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LastEventCursorStore', () {
    test('MemoryLastEventCursorStore persists and clears per driver', () async {
      final store = MemoryLastEventCursorStore();
      expect(await store.read('drv-a'), isNull);

      await store.write('drv-a', 42);
      await store.write('drv-b', 7);

      expect(await store.read('drv-a'), 42);
      expect(await store.read('drv-b'), 7);

      await store.clear('drv-a');
      expect(await store.read('drv-a'), isNull);
      expect(await store.read('drv-b'), 7);
    });

    test(
      'SharedPreferencesLastEventCursorStore round-trips Last-Event-ID',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final store = SharedPreferencesLastEventCursorStore(prefs: prefs);

        await store.write('drv-1', 99);
        expect(await store.read('drv-1'), 99);

        await store.clear('drv-1');
        expect(await store.read('drv-1'), isNull);
      },
    );
  });
}
