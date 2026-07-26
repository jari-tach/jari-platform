import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';
import 'package:saeq_driver/features/delivery/data/repositories/local_delivery_assignment_repository.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';

import '../../helpers/delivery_fixtures.dart';
import '../../helpers/in_memory_delivery_local_data_source.dart';

void main() {
  late InMemoryDeliveryLocalDataSource local;
  late LocalDeliveryAssignmentRepository repo;

  setUp(() {
    local = InMemoryDeliveryLocalDataSource();
    repo = LocalDeliveryAssignmentRepository(localDataSource: local);
  });

  group('LocalDeliveryAssignmentRepository', () {
    test('getActiveAssignment delegates and maps', () async {
      local.stored = DeliveryAssignmentModel.fromEntity(sampleAssignment());
      final result = await repo.getActiveAssignment(driverId: 'drv-1');
      expect(result.valueOrNull, sampleAssignment());
      expect(local.readCount, 1);
      expect(local.lastReadDriverId, 'drv-1');
    });

    test('getActiveAssignment returns null when missing', () async {
      final result = await repo.getActiveAssignment(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('upsertAccepted maps entity to model and writes', () async {
      final result = await repo.upsertAccepted(sampleAssignment());
      expect(result.isSuccess, isTrue);
      expect(local.writeCount, 1);
      expect(local.stored!.toEntity(), sampleAssignment());
    });

    test('clear delegates to local clear', () async {
      local.stored = DeliveryAssignmentModel.fromEntity(sampleAssignment());
      final result = await repo.clear(driverId: 'drv-1');
      expect(result.isSuccess, isTrue);
      expect(local.clearCount, 1);
      expect(local.stored, isNull);
    });

    test('FormatException maps to DeliveryPersistenceFailure', () async {
      local.stored = DeliveryAssignmentModel.fromJson(
        DeliveryAssignmentModel.fromEntity(sampleAssignment()).toJson()
          ..['status'] = 'flying',
      );
      final result = await repo.getActiveAssignment(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryPersistenceFailure>());
    });

    test('DeliveryFailure passthrough', () async {
      local.throwOnWrite = const DeliverySecurityPolicyDenied();
      final result = await repo.upsertAccepted(sampleAssignment());
      expect(result.failureOrNull, isA<DeliverySecurityPolicyDenied>());
    });

    test('unknown exception maps to DeliveryPersistenceFailure', () async {
      local.throwOnClear = StateError('disk full');
      final result = await repo.clear(driverId: 'drv-1');
      expect(result.failureOrNull, isA<DeliveryPersistenceFailure>());
      expect(result.failureOrNull!.message, contains('disk full'));
    });
  });
}
