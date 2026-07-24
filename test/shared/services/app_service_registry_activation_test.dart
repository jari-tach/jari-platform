import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:saeq_driver/shared/services/app_service_registry.dart';

/// Returns a valid documents path, letting DriverDatabase's real
/// `NativeDatabase` open successfully.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._documentsPath);
  final String _documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _documentsPath;
}

/// Reports a stable "online" status without touching a real platform channel.
class _FakeConnectivityPlatform extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [
    ConnectivityResult.wifi,
  ];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();
}

void main() {
  // This scenario is kept in its own file, run in its own VM isolate by
  // `flutter test`, deliberately separate from
  // app_service_registry_test.dart. DriverDatabase (driver_database.dart)
  // is a process-wide singleton whose underlying drift `LazyDatabase`
  // permanently caches the outcome of its *first* open attempt for the
  // life of the isolate (drift/src/utils/lazy_database.dart). Sharing a
  // file with a test that deliberately makes DriverDatabase fail would
  // permanently poison the singleton for every later test in that same
  // isolate. See PHASE_2_1 report, "Technical debt", for the follow-up
  // recommendation (inject the QueryExecutor instead of a hardcoded
  // factory singleton) — out of scope for this phase.
  test('DriverDatabase and NetworkMonitor both activate when their platform '
      'dependencies are available', () async {
    final tempDir = await Directory.systemTemp.createTemp('saeq_driver_test_');
    addTearDown(() async {
      await AppServiceRegistry.dispose();
      await tempDir.delete(recursive: true).catchError((_) => tempDir);
    });

    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    ConnectivityPlatform.instance = _FakeConnectivityPlatform();

    await AppServiceRegistry.init();

    expect(AppServiceRegistry.isInitialized, isTrue);
    expect(AppServiceRegistry.database, isNotNull);
    expect(AppServiceRegistry.networkMonitor, isNotNull);
    expect(AppServiceRegistry.networkMonitor!.isOnline, isTrue);
  });
}
