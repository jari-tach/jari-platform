import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/entities/driver_workflow_stage.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  group('DeliveryAssignment', () {
    test('equality and hashCode', () {
      final a = sampleAssignment();
      final b = sampleAssignment();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('isActive until cancelled (includes delivered summary)', () {
      expect(sampleAssignment().isActive, isTrue);
      expect(sampleAssignment().blocksNewOffers, isTrue);
      expect(
        sampleAssignment(status: DeliveryStatus.pickedUp).isActive,
        isTrue,
      );
      expect(
        sampleAssignment(status: DeliveryStatus.delivered).isActive,
        isTrue,
      );
      expect(
        sampleAssignment(status: DeliveryStatus.delivered).blocksNewOffers,
        isTrue,
      );
      expect(
        sampleAssignment(status: DeliveryStatus.cancelled).isActive,
        isFalse,
      );
      expect(
        sampleAssignment(status: DeliveryStatus.cancelled).blocksNewOffers,
        isFalse,
      );
    });

    test('summary-stage delivered assignment remains offer-blocking', () {
      final summary = sampleAssignment(
        status: DeliveryStatus.delivered,
        workflowStage: DriverWorkflowStage.summary,
      );
      expect(summary.isActive, isTrue);
      expect(summary.blocksNewOffers, isTrue);
    });

    test('copyWith preserves sovereign ids', () {
      final assignment = sampleAssignment();
      final next = assignment.copyWith(
        status: DeliveryStatus.pickedUp,
        clearServerRevision: true,
      );
      expect(next.assignmentId, assignment.assignmentId);
      expect(next.offerId, assignment.offerId);
      expect(next.driverId, assignment.driverId);
      expect(next.status, DeliveryStatus.pickedUp);
      expect(next.serverRevision, isNull);
      expect(assignment, isNot(equals(next)));
    });

    test('rejects empty identity fields', () {
      expect(
        () => sampleAssignment(assignmentId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => sampleAssignment(offerId: ' '),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => sampleAssignment(driverId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => sampleAssignment(serverRevision: ' '),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
