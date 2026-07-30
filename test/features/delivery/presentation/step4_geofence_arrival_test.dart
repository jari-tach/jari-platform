import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';
import 'package:saeq_driver/features/delivery/domain/policies/driver_workflow_transition_policy.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/advance_delivery_workflow.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';
import 'package:saeq_driver/features/delivery/presentation/controllers/delivery_controller.dart';
import 'package:saeq_driver/features/delivery/presentation/providers/delivery_providers.dart';
import 'package:saeq_driver/features/delivery/presentation/state/delivery_controller_state.dart';
import 'package:saeq_driver/features/location/data/fake_location_gateway.dart';
import 'package:saeq_driver/features/location/domain/geo_point.dart';
import 'package:saeq_driver/features/location/domain/location_fix.dart';
import 'package:saeq_driver/features/location/location_providers.dart';

import '../helpers/delivery_fixtures.dart';
import '../helpers/fake_delivery_assignment_repository.dart';

void main() {
  test(
    'fresh accurate dwell advances to verifying and cleans stream',
    () async {
      final target = const GeoPoint(latitude: 24.72, longitude: 46.68);
      final order = sampleOrder(
        dropoffLatitude: target.latitude,
        dropoffLongitude: target.longitude,
        pickupLatitude: target.latitude,
        pickupLongitude: target.longitude,
      );
      final assignment = sampleAssignment(
        order: order,
        workflowStage: DriverWorkflowStage.waitingPickup,
        status: DeliveryStatus.accepted,
      );
      final assignments = FakeDeliveryAssignmentRepository(active: assignment);
      final gateway = _TrackingLocationGateway();
      addTearDown(gateway.close);

      final container = ProviderContainer(
        overrides: [
          locationGatewayProvider.overrideWithValue(gateway),
          deliveryControllerProvider.overrideWith(
            () => DeliveryController(
              getActiveReader: (_) => GetActiveDelivery(assignments),
              advanceWorkflowReader: (_) =>
                  AdvanceDeliveryWorkflow(assignments),
              driverIdReader: (_) => 'drv-1',
              acceptPreconditionsReader: (_) =>
                  const DeliveryAcceptPreconditions(
                    connectivityOnline: true,
                    isConfirmedAvailable: true,
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(deliveryControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await container
          .read(deliveryControllerProvider.notifier)
          .advanceWorkflow(DriverWorkflowCommand.confirmPickup);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final at = DateTime.now().toUtc();
      gateway.emit(
        LocationFix(point: target, recordedAt: at, accuracyMeters: 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      gateway.emit(
        LocationFix(
          point: target,
          recordedAt: DateTime.now().toUtc(),
          accuracyMeters: 10,
        ),
      );

      DriverWorkflowStage? stage;
      for (var i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        stage = container
            .read(deliveryControllerProvider)
            .activeAssignment
            ?.workflowStage;
        if (stage == DriverWorkflowStage.verifying) break;
      }

      expect(stage, DriverWorkflowStage.verifying);
      expect(
        container.read(deliveryControllerProvider).status,
        DeliveryViewStatus.ready,
      );
      await Future<void>.delayed(Duration.zero);
      expect(gateway.wasCancelled, isTrue);
    },
  );

  test('low accuracy never triggers automatic arrival', () async {
    final target = const GeoPoint(latitude: 24.72, longitude: 46.68);
    final assignment = sampleAssignment(
      order: sampleOrder(
        dropoffLatitude: target.latitude,
        dropoffLongitude: target.longitude,
        pickupLatitude: target.latitude,
        pickupLongitude: target.longitude,
      ),
      workflowStage: DriverWorkflowStage.waitingPickup,
      status: DeliveryStatus.accepted,
    );
    final assignments = FakeDeliveryAssignmentRepository(active: assignment);
    final gateway = _TrackingLocationGateway();
    final container = ProviderContainer(
      overrides: [
        locationGatewayProvider.overrideWithValue(gateway),
        deliveryControllerProvider.overrideWith(
          () => DeliveryController(
            getActiveReader: (_) => GetActiveDelivery(assignments),
            advanceWorkflowReader: (_) => AdvanceDeliveryWorkflow(assignments),
            driverIdReader: (_) => 'drv-1',
            acceptPreconditionsReader: (_) => const DeliveryAcceptPreconditions(
              connectivityOnline: true,
              isConfirmedAvailable: true,
            ),
          ),
        ),
      ],
    );

    container.read(deliveryControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await container
        .read(deliveryControllerProvider.notifier)
        .advanceWorkflow(DriverWorkflowCommand.confirmPickup);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final at = DateTime.now().toUtc();
    gateway.emit(
      LocationFix(point: target, recordedAt: at, accuracyMeters: 110),
    );
    gateway.emit(
      LocationFix(
        point: target,
        recordedAt: at.add(const Duration(seconds: 2)),
        accuracyMeters: 110,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final stage = container
        .read(deliveryControllerProvider)
        .activeAssignment
        ?.workflowStage;
    expect(stage, DriverWorkflowStage.navToCustomer);
    expect(stage, isNot(DriverWorkflowStage.arrivedCustomer));
    expect(stage, isNot(DriverWorkflowStage.verifying));
    expect(gateway.wasCancelled, isFalse);

    container.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(gateway.wasCancelled, isTrue);
    await gateway.close();
  });
}

class _TrackingLocationGateway extends FakeLocationGateway {
  _TrackingLocationGateway() {
    _controller = StreamController<LocationFix>.broadcast(
      onCancel: () => wasCancelled = true,
    );
  }

  late final StreamController<LocationFix> _controller;
  bool wasCancelled = false;

  void emit(LocationFix fix) => _controller.add(fix);

  Future<void> close() => _controller.close();

  @override
  Stream<LocationFix> watchFixes({
    Duration interval = const Duration(seconds: 2),
  }) => _controller.stream;
}
