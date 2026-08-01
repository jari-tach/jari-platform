import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller_state.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/state/delivery_controller_state.dart';
import 'package:saeq_driver/features/realtime/presentation/controllers/realtime_controller.dart';
import 'package:saeq_driver/features/realtime/presentation/providers/realtime_providers.dart';

/// Records REST refresh calls triggered by STEP 6-C realtime signals.
final class _RecordingDeliveryController extends DeliveryController {
  int offersRefreshCount = 0;
  int activeDeliveryRefreshCount = 0;
  int activeBatchRefreshCount = 0;
  final List<String> order = <String>[];

  @override
  DeliveryControllerState build() {
    return DeliveryControllerState.ready(
      offers: const [],
      boundDriverId: 'drv-1',
    );
  }

  @override
  Future<void> refreshOffers() async {
    offersRefreshCount += 1;
    order.add('offers');
  }

  @override
  Future<void> refreshActiveDelivery() async {
    activeDeliveryRefreshCount += 1;
    order.add('active');
  }

  @override
  Future<void> refreshActiveBatch() async {
    activeBatchRefreshCount += 1;
    order.add('batch');
  }
}

final class _RecordingAvailabilityController extends AvailabilityController {
  int initializeCount = 0;

  @override
  AvailabilityControllerState build() {
    return const AvailabilityControllerState.initial();
  }

  @override
  Future<void> initialize() async {
    initializeCount += 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    ({
      ProviderContainer container,
      RealtimeController realtime,
      _RecordingDeliveryController delivery,
      _RecordingAvailabilityController availability,
    })
  >
  boot() async {
    final delivery = _RecordingDeliveryController();
    final availability = _RecordingAvailabilityController();
    final container = ProviderContainer(
      overrides: [
        deliveryControllerProvider.overrideWith(() => delivery),
        availabilityControllerProvider.overrideWith(() => availability),
        realtimeControllerProvider.overrideWith(
          () => RealtimeController(coordinatorReader: (_) => null),
        ),
      ],
    );
    addTearDown(container.dispose);
    final realtime = container.read(realtimeControllerProvider.notifier);
    // Allow Notifier.build microtasks to settle without starting a session
    // (coordinatorReader returns null → idle).
    await Future<void>.delayed(Duration.zero);
    return (
      container: container,
      realtime: realtime,
      delivery: delivery,
      availability: availability,
    );
  }

  test(
    'delivery invalidation refreshes active delivery then batch (STEP 6-C)',
    () async {
      final harness = await boot();
      await harness.realtime.onDeliveryInvalidated();

      expect(harness.delivery.activeDeliveryRefreshCount, 1);
      expect(harness.delivery.activeBatchRefreshCount, 1);
      expect(harness.delivery.offersRefreshCount, 0);
      expect(harness.delivery.order, ['active', 'batch']);
      expect(harness.availability.initializeCount, 0);
    },
  );

  test(
    'availability invalidation re-initializes availability (STEP 6-C)',
    () async {
      final harness = await boot();
      await harness.realtime.onAvailabilityInvalidated();

      expect(harness.availability.initializeCount, 1);
      expect(harness.delivery.offersRefreshCount, 0);
      expect(harness.delivery.activeDeliveryRefreshCount, 0);
    },
  );

  test(
    'full resync serializes offers then delivery REST refreshes (STEP 6-C)',
    () async {
      final harness = await boot();

      // Mimic coordinator._notifyFullResync raising both streams close together.
      final offersFuture = harness.realtime.onOffersInvalidated();
      final deliveryFuture = harness.realtime.onDeliveryInvalidated();
      final availabilityFuture = harness.realtime.onAvailabilityInvalidated();
      await Future.wait([offersFuture, deliveryFuture, availabilityFuture]);

      expect(harness.delivery.offersRefreshCount, 1);
      expect(harness.delivery.activeDeliveryRefreshCount, 1);
      expect(harness.delivery.activeBatchRefreshCount, 1);
      expect(harness.availability.initializeCount, 1);
      // DeliveryController ops must not overlap — offers before active/batch.
      expect(harness.delivery.order.first, 'offers');
      expect(harness.delivery.order.sublist(1), ['active', 'batch']);
    },
  );

  test(
    'duplicate delivery invalidation is coalesced while in flight',
    () async {
      final harness = await boot();
      final first = harness.realtime.onDeliveryInvalidated();
      final second = harness.realtime.onDeliveryInvalidated();
      await Future.wait([first, second]);

      expect(harness.delivery.activeDeliveryRefreshCount, 1);
      expect(harness.delivery.activeBatchRefreshCount, 1);
    },
  );
}
