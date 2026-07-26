import 'package:saeq_driver/features/delivery/data/datasources/delivery_local_data_source.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';

/// In-memory local datasource for repository tests only.
class InMemoryDeliveryLocalDataSource implements DeliveryLocalDataSource {
  DeliveryAssignmentModel? stored;
  Object? throwOnRead;
  Object? throwOnWrite;
  Object? throwOnClear;

  int readCount = 0;
  int writeCount = 0;
  int clearCount = 0;
  String? lastReadDriverId;
  String? lastClearedDriverId;

  @override
  Future<DeliveryAssignmentModel?> readActiveAssignment({
    required String driverId,
  }) async {
    readCount++;
    lastReadDriverId = driverId;
    if (throwOnRead != null) {
      throw throwOnRead!;
    }
    final current = stored;
    if (current == null || current.driverId != driverId) {
      return null;
    }
    return current;
  }

  @override
  Future<void> writeActiveAssignment(DeliveryAssignmentModel assignment) async {
    writeCount++;
    if (throwOnWrite != null) {
      throw throwOnWrite!;
    }
    stored = assignment;
  }

  @override
  Future<void> clearActiveAssignment({required String driverId}) async {
    clearCount++;
    lastClearedDriverId = driverId;
    if (throwOnClear != null) {
      throw throwOnClear!;
    }
    if (stored?.driverId == driverId) {
      stored = null;
    }
  }
}
