import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  group('DeliveryAssignmentModel', () {
    test('entity ↔ model round-trip for all delivery statuses', () {
      for (final status in DeliveryStatus.values) {
        final entity = sampleAssignment(status: status);
        final round = DeliveryAssignmentModel.fromEntity(entity).toEntity();
        expect(round, entity, reason: status.name);
      }
    });

    test('JSON round-trip', () {
      final model = DeliveryAssignmentModel.fromEntity(sampleAssignment());
      final decoded = DeliveryAssignmentModel.fromJson(model.toJson());
      expect(decoded, model);
      expect(decoded.toEntity(), sampleAssignment());
    });

    test('legacy JSON without workflowStage defaults to assigned', () {
      final json =
          DeliveryAssignmentModel.fromEntity(sampleAssignment()).toJson()
            ..remove('workflowStage')
            ..remove('resumeAfterIssueStage');
      final decoded = DeliveryAssignmentModel.fromJson(json).toEntity();
      expect(decoded.workflowStage.name, 'assigned');
    });

    test('invalid JSON enum value fails on toEntity', () {
      final json = DeliveryAssignmentModel.fromEntity(
        sampleAssignment(),
      ).toJson()..['status'] = 'flying';
      final model = DeliveryAssignmentModel.fromJson(json);
      expect(() => model.toEntity(), throwsA(isA<FormatException>()));
    });

    test('malformed acceptedAt throws FormatException', () {
      expect(
        () => DeliveryAssignmentModel.fromJson({
          'assignmentId': 'asg-1',
          'offerId': 'off-1',
          'driverId': 'drv-1',
          'status': 'accepted',
          'order': {
            'orderId': 'ord-1',
            'pickupLabel': 'a',
            'dropoffLabel': 'b',
          },
          'acceptedAt': 'bad-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
