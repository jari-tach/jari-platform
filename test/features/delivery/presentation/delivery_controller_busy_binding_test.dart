import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/availability/domain/entities/availability_status.dart';
import 'package:saeq_driver/features/availability/domain/entities/driver_availability.dart';
import 'package:saeq_driver/features/availability/domain/failures/availability_failure.dart';
import 'package:saeq_driver/features/availability/domain/usecases/apply_authoritative_availability.dart';
import 'package:saeq_driver/features/availability/domain/usecases/get_driver_availability.dart';
import 'package:saeq_driver/features/availability/presentation/controllers/availability_controller.dart';
import 'package:saeq_driver/features/availability/presentation/providers/availability_providers.dart';
import 'package:saeq_driver/features/delivery/application/accept_delivery_offer_and_bind_busy.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
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

class _BoundHarness {
  _BoundHarness({required this.container, required this.refreshCount});

  final ProviderContainer container;
  final int Function() refreshCount;
}

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

  Future<_BoundHarness> bootBound({
    required FakeDeliveryOfferRepository offers,
    required FakeDeliveryAssignmentRepository assignments,
    required FakeDriverAvailabilityRepository availability,
  }) async {
    var refreshCount = 0;
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
            acceptPreconditionsReader: (_) => const DeliveryAcceptPreconditions(
              connectivityOnline: true,
              isConfirmedAvailable: true,
            ),
            availabilityRefreshReader: (_) async {
              refreshCount++;
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
    container.read(deliveryControllerProvider);
    container.read(availabilityControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return _BoundHarness(
      container: container,
      refreshCount: () => refreshCount,
    );
  }

  group('DeliveryController ADR-025 binding', () {
    test('accept success refreshes delivery and availability states', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository();
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final harness = await bootBound(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      await harness.container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final delivery = harness.container.read(deliveryControllerProvider);
      expect(delivery.status, DeliveryViewStatus.ready);
      expect(delivery.activeAssignment?.assignmentId, 'asg-1');
      expect(availability.state?.status, AvailabilityStatus.busy);
      expect(harness.refreshCount(), greaterThan(0));
    });

    test('repeated accept is prevented while processing', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository();
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final harness = await bootBound(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      final controller = harness.container.read(
        deliveryControllerProvider.notifier,
      );
      final first = controller.acceptCurrentOffer();
      final second = controller.acceptCurrentOffer();
      await Future.wait([first, second]);

      expect(offers.acceptCallCount, 1);
    });

    test('busy bind failure keeps assignment in delivery state', () async {
      final offers = FakeDeliveryOfferRepository(offers: [sampleOffer()]);
      offers.acceptResult = sampleAssignment();
      final assignments = FakeDeliveryAssignmentRepository();
      final availability = FakeDriverAvailabilityRepository(seed: available());
      availability.nextAuthoritativeFailure =
          const AvailabilityPersistenceFailure();
      final harness = await bootBound(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      await harness.container
          .read(deliveryControllerProvider.notifier)
          .acceptCurrentOffer();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final delivery = harness.container.read(deliveryControllerProvider);
      expect(delivery.failure, isA<DeliveryAvailabilityBindFailure>());
      expect(delivery.activeAssignment?.assignmentId, 'asg-1');
      expect(assignments.active?.assignmentId, 'asg-1');
      expect(delivery.activeOffer, isNull);
    });

    test('restart restores assignment and reconciles busy', () async {
      final assignment = sampleAssignment();
      final offers = FakeDeliveryOfferRepository();
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      final availability = FakeDriverAvailabilityRepository(seed: available());
      final harness = await bootBound(
        offers: offers,
        assignments: assignments,
        availability: availability,
      );

      final delivery = harness.container.read(deliveryControllerProvider);
      expect(delivery.activeAssignment?.assignmentId, 'asg-1');
      expect(availability.state?.status, AvailabilityStatus.busy);
      expect(availability.state?.activeAssignmentId, 'asg-1');
    });
  });
}
