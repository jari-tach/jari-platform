import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/delivery/application/accept_delivery_offer_and_bind_busy.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/accept_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_delivery_offers.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/reject_delivery_offer.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/state/delivery_controller_state.dart';

import '../../availability/helpers/fake_driver_availability_repository.dart';
import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';
import '../helpers/fake_delivery_offer_repository.dart';

/// STEP 3 Item 26 — proves Loading Offers after Accept under production wiring.
///
/// Before the fix, production `_readAcceptPreconditions` used
/// `ref.watch(availability…)`. After accept, `_refreshAvailability`
/// re-initialized availability and rebuilt [DeliveryController] to `initial`.
/// The fixed command snapshot uses `ref.read`, while an actual controller
/// recreation still restores the accepted assignment from its repository.
void main() {
  final at = DateTime.utc(2026, 7, 26, 12);

  DriverAvailability available() => DriverAvailability(
    driverId: 'drv-1',
    status: AvailabilityStatus.available,
    source: AvailabilitySource.server,
    lastChangedAt: at,
    lastConfirmedAt: at,
    pendingSync: false,
    revision: 1,
  );

  Future<ProviderContainer> bootProductionLike({
    required FakeDeliveryOfferRepository offers,
    required FakeDeliveryAssignmentRepository assignments,
    required FakeDriverAvailabilityRepository availability,
  }) async {
    final coordinator = AcceptDeliveryOfferAndBindBusy(
      AcceptDeliveryOffer(offers, assignments),
      ApplyAuthoritativeAvailability(availability),
      GetDriverAvailability(availability),
      clock: () => at,
    );

    final container = ProviderContainer(
      overrides: [
        availabilityControllerProvider.overrideWith(
          () => AvailabilityController(repositoryReader: (_) => availability),
        ),
        deliveryControllerProvider.overrideWith(
          () => DeliveryController(
            getOffersReader: (_) => GetDeliveryOffers(offers),
            acceptAndBindReader: (_) => coordinator,
            rejectReader: (_) => RejectDeliveryOffer(offers),
            getActiveReader: (_) => GetActiveDelivery(assignments),
            offerRepositoryReader: (_) => offers,
            driverIdReader: (_) => 'drv-1',
            // Production command snapshot after the fix: do not register
            // availability as a DeliveryController build dependency.
            acceptPreconditionsReader: (ref) {
              ref.read(availabilityControllerProvider);
              return const DeliveryAcceptPreconditions(
                connectivityOnline: true,
                isConfirmedAvailable: true,
              );
            },
            // Production-like: refresh availability after accept/bind.
            availabilityRefreshReader: (ref) async {
              await ref
                  .read(availabilityControllerProvider.notifier)
                  .initialize();
            },
          ),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      offers.dispose();
      availability.dispose();
    });

    container.read(availabilityControllerProvider);
    await container.read(availabilityControllerProvider.notifier).initialize();
    container.read(deliveryControllerProvider);

    // Wait until the offer is ready before accepting.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final delivery = container.read(deliveryControllerProvider);
      if (delivery.status == DeliveryViewStatus.ready && delivery.canAccept) {
        break;
      }
    }
    return container;
  }

  test('accept success then availability refresh must not leave delivery in '
      'initial/loading (Loading Offers regression)', () async {
    final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
    offers.acceptResult = sampleAssignment();
    final assignments = FakeDeliveryAssignmentRepository();
    final availability = FakeDriverAvailabilityRepository(seed: available());
    final container = await bootProductionLike(
      offers: offers,
      assignments: assignments,
      availability: availability,
    );

    final before = container.read(deliveryControllerProvider);
    expect(before.canAccept, isTrue);

    await container
        .read(deliveryControllerProvider.notifier)
        .acceptCurrentOffer();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final delivery = container.read(deliveryControllerProvider);

    expect(
      delivery.status,
      isNot(DeliveryViewStatus.initial),
      reason:
          'DeliveryController rebuilt to initial after availability refresh; '
          'IncomingDeliveryOfferPage maps initial → Loading Offers',
    );
    expect(delivery.status, isNot(DeliveryViewStatus.loading));
    expect(delivery.status, DeliveryViewStatus.ready);
    expect(delivery.hasActiveAssignment, isTrue);
    expect(delivery.activeAssignment?.assignmentId, 'asg-1');
    expect(delivery.hasOffer, isFalse);
  });

  test('accept then availability update and controller recreation restores the '
      'single active assignment without the consumed offer', () async {
    final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
    offers.acceptResult = sampleAssignment();
    final assignments = FakeDeliveryAssignmentRepository();
    final availability = FakeDriverAvailabilityRepository(seed: available());
    final container = await bootProductionLike(
      offers: offers,
      assignments: assignments,
      availability: availability,
    );

    await container
        .read(deliveryControllerProvider.notifier)
        .acceptCurrentOffer();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(assignments.active?.assignmentId, 'asg-1');
    expect(offers.acceptCallCount, 1);

    // Simulate provider lifecycle recreation after the availability update.
    container.invalidate(deliveryControllerProvider);
    container.read(deliveryControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final restored = container.read(deliveryControllerProvider);
    expect(restored.status, isNot(DeliveryViewStatus.initial));
    expect(restored.status, isNot(DeliveryViewStatus.loading));
    expect(restored.status, DeliveryViewStatus.ready);
    expect(restored.activeAssignment?.assignmentId, 'asg-1');
    expect(restored.hasOffer, isFalse);
    expect(assignments.upsertCallCount, 1);
    expect(offers.acceptCallCount, 1);
  });
}
