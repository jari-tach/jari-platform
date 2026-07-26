import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/usecases/get_active_delivery.dart';

import '../../helpers/delivery_fixtures.dart';
import '../../helpers/fake_delivery_assignment_repository.dart';

void main() {
  group('GetActiveDelivery', () {
    test('returns active assignment when present', () async {
      final assignment = sampleAssignment();
      final repo = FakeDeliveryAssignmentRepository(active: assignment);
      final result = await GetActiveDelivery(repo)(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, assignment);
      expect(repo.getCallCount, 1);
    });

    test('returns null success when none', () async {
      final repo = FakeDeliveryAssignmentRepository();
      final result = await GetActiveDelivery(repo)(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('empty driverId is unauthenticated', () async {
      final repo = FakeDeliveryAssignmentRepository();
      final result = await GetActiveDelivery(repo)(driverId: ' ');
      expect(result.failureOrNull, isA<DeliveryUnauthenticated>());
      expect(repo.getCallCount, 0);
    });

    test('repository failure is passthrough', () async {
      final repo = FakeDeliveryAssignmentRepository()
        ..nextGetFailure = const DeliveryPersistenceFailure();
      final result = await GetActiveDelivery(repo)(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryPersistenceFailure>());
    });

    test('driverId mismatch is security denial', () async {
      final custom = _MismatchAssignmentRepository();
      final result = await GetActiveDelivery(custom)(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliverySecurityPolicyDenied>());
    });
  });
}

class _MismatchAssignmentRepository extends FakeDeliveryAssignmentRepository {
  @override
  Future<DeliveryResult<DeliveryAssignment?>> getActiveAssignment({
    required String driverId,
  }) async {
    getCallCount++;
    return DeliverySuccess(sampleAssignment(driverId: 'other'));
  }
}
