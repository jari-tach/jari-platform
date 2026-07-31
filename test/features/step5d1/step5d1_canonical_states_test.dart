import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_lifecycle_ack.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';

void main() {
  group('CanonicalDeliveryStates wire contract names (STEP 5D-1)', () {
    test('lifecycle state constants match the exact required strings', () {
      expect(
        CanonicalDeliveryStates.pickupAwaitingManualConfirmation,
        'pickupAwaitingManualConfirmation',
      );
      expect(
        CanonicalDeliveryStates.pickupConfirmedManually,
        'pickupConfirmedManually',
      );
      expect(CanonicalDeliveryStates.enRouteToCustomer, 'enRouteToCustomer');
      expect(
        CanonicalDeliveryStates.arrivedAutomaticallyByLocation,
        'arrivedAutomaticallyByLocation',
      );
      expect(
        CanonicalDeliveryStates.deliveryAwaitingManualConfirmation,
        'deliveryAwaitingManualConfirmation',
      );
      expect(
        CanonicalDeliveryStates.deliveredConfirmedManually,
        'deliveredConfirmedManually',
      );
    });

    test('contactAllowed contains exactly the post-pickup-ack states', () {
      expect(CanonicalDeliveryStates.contactAllowed, {
        'pickupConfirmedManually',
        'enRouteToCustomer',
        'arrivedAutomaticallyByLocation',
        'deliveryAwaitingManualConfirmation',
      });
      expect(
        CanonicalDeliveryStates.contactAllowed,
        isNot(contains('pickupAwaitingManualConfirmation')),
      );
      expect(
        CanonicalDeliveryStates.contactAllowed,
        isNot(contains('deliveredConfirmedManually')),
      );
    });

    test('local workflow stages map onto canonical Backend states', () {
      expect(
        canonicalDeliveryStateForStage(DriverWorkflowStage.waitingPickup),
        'pickupAwaitingManualConfirmation',
      );
      expect(
        canonicalDeliveryStateForStage(DriverWorkflowStage.collected),
        'pickupConfirmedManually',
      );
      expect(
        canonicalDeliveryStateForStage(DriverWorkflowStage.navToCustomer),
        'enRouteToCustomer',
      );
      expect(
        canonicalDeliveryStateForStage(DriverWorkflowStage.arrivedCustomer),
        'arrivedAutomaticallyByLocation',
      );
      expect(
        canonicalDeliveryStateForStage(DriverWorkflowStage.verifying),
        'deliveryAwaitingManualConfirmation',
      );
      expect(
        canonicalDeliveryStateForStage(DriverWorkflowStage.summary),
        'deliveredConfirmedManually',
      );
      expect(
        canonicalDeliveryStateForStage(DriverWorkflowStage.issueOpen),
        isNull,
      );
    });
  });
}
