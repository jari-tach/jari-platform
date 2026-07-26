import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:saeq_driver/features/delivery/data/fake/fake_delivery_remote_data_source.dart';
import 'package:saeq_driver/features/delivery/data/repositories/remote_delivery_offer_repository.dart';
import 'package:saeq_driver/shared/services/app_service_registry.dart';

/// Simulates the plugin being unavailable, as happens in a plain
/// `flutter test` run without platform channel mocks. Used deliberately in
/// every test in this file so [DriverDatabase]'s process-wide singleton
/// (see driver_database.dart) is never asked to open successfully here.
/// A successful-activation attempt lives in a separate test file
/// (app_service_registry_activation_test.dart) so it runs in its own VM
/// isolate, because drift's LazyDatabase permanently caches the outcome
/// (success or failure) of its first open attempt for the lifetime of the
/// singleton (see PHASE_2_1 report, "Technical debt").
class _ThrowingPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    throw MissingPluginException('path_provider is not available in this test');
  }
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

/// Simulates the connectivity plugin being unavailable.
class _ThrowingConnectivityPlatform extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    throw MissingPluginException(
      'connectivity_plus is not available in this test',
    );
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => Stream.error(
    MissingPluginException('connectivity_plus is not available in this test'),
  );
}

void main() {
  final originalPathProvider = PathProviderPlatform.instance;
  final originalConnectivity = ConnectivityPlatform.instance;

  setUp(() {
    // Every test in this file intentionally keeps DriverDatabase unable to
    // open (see class doc above), so it never taints later assertions.
    PathProviderPlatform.instance = _ThrowingPathProviderPlatform();
  });

  tearDown(() async {
    // Every test must leave AppServiceRegistry and the swapped platform
    // interfaces in a clean state so tests do not leak into one another.
    await AppServiceRegistry.dispose();
    PathProviderPlatform.instance = originalPathProvider;
    ConnectivityPlatform.instance = originalConnectivity;
  });

  group('AppServiceRegistry bootstrap — non-critical failure policy', () {
    test('init() never throws when DriverDatabase cannot initialize', () async {
      ConnectivityPlatform.instance = _FakeConnectivityPlatform();

      await AppServiceRegistry.init();

      expect(AppServiceRegistry.isInitialized, isTrue);
      expect(AppServiceRegistry.logger, isNotNull);
      expect(AppServiceRegistry.storage, isNotNull);
      expect(AppServiceRegistry.apiClient, isNotNull);
      // DriverDatabase failed to initialize: the getter must return null,
      // not throw, and bootstrap must still complete.
      expect(AppServiceRegistry.database, isNull);
      // A DriverDatabase failure must not block NetworkMonitor activation.
      expect(AppServiceRegistry.networkMonitor, isNotNull);
      // Delivery remote Fake still wires without DB; local Drift does not.
      expect(
        AppServiceRegistry.deliveryRemoteDataSource,
        isA<FakeDeliveryRemoteDataSource>(),
      );
      expect(
        AppServiceRegistry.deliveryOfferRepository,
        isA<RemoteDeliveryOfferRepository>(),
      );
      expect(AppServiceRegistry.getDeliveryOffers, isNotNull);
      expect(AppServiceRegistry.rejectDeliveryOffer, isNotNull);
      expect(AppServiceRegistry.deliveryLocalDataSource, isNull);
      expect(AppServiceRegistry.deliveryAssignmentRepository, isNull);
      expect(AppServiceRegistry.acceptDeliveryOffer, isNull);
      expect(AppServiceRegistry.getActiveDelivery, isNull);
    });

    test(
      'init() never throws when the connectivity platform channel fails',
      () async {
        ConnectivityPlatform.instance = _ThrowingConnectivityPlatform();

        await AppServiceRegistry.init();

        expect(AppServiceRegistry.isInitialized, isTrue);
        expect(AppServiceRegistry.logger, isNotNull);
        expect(AppServiceRegistry.storage, isNotNull);
        expect(AppServiceRegistry.apiClient, isNotNull);
        // NetworkMonitor.checkConnectivity() already catches its own
        // platform-channel failures (see network_monitor.dart), so the
        // monitor object itself still activates; only its reported status
        // degrades to `unknown` instead of crashing bootstrap.
        expect(AppServiceRegistry.networkMonitor, isNotNull);
        expect(AppServiceRegistry.networkMonitor!.isOnline, isFalse);
      },
    );
  });

  group('AppServiceRegistry bootstrap — lifecycle and duplication', () {
    test(
      'init() is idempotent: no duplicate registry is created on repeated calls',
      () async {
        ConnectivityPlatform.instance = _FakeConnectivityPlatform();

        final first = await AppServiceRegistry.init();
        final second = await AppServiceRegistry.init();
        final third = await AppServiceRegistry.init();

        expect(identical(first, second), isTrue);
        expect(identical(second, third), isTrue);
      },
    );

    test(
      'dispose() releases the registry and a later init() creates a fresh one',
      () async {
        ConnectivityPlatform.instance = _FakeConnectivityPlatform();

        final first = await AppServiceRegistry.init();
        expect(AppServiceRegistry.isInitialized, isTrue);

        await AppServiceRegistry.dispose();
        expect(AppServiceRegistry.isInitialized, isFalse);

        final second = await AppServiceRegistry.init();
        expect(identical(first, second), isFalse);
      },
    );

    test('dispose() is safe to call when init() was never called', () async {
      await expectLater(AppServiceRegistry.dispose(), completes);
      expect(AppServiceRegistry.isInitialized, isFalse);
    });

    test('dispose() is safe to call more than once in a row', () async {
      ConnectivityPlatform.instance = _FakeConnectivityPlatform();

      await AppServiceRegistry.init();

      await AppServiceRegistry.dispose();
      await expectLater(AppServiceRegistry.dispose(), completes);
    });
  });
}
