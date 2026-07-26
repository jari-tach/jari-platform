import 'package:saeq_driver/features/delivery/domain/entities/delivery_assignment.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/repositories/delivery_assignment_repository.dart';

/// In-memory [DeliveryAssignmentRepository] for domain use-case tests only.
class FakeDeliveryAssignmentRepository implements DeliveryAssignmentRepository {
  FakeDeliveryAssignmentRepository({this.active});

  DeliveryAssignment? active;
  DeliveryFailure? nextGetFailure;
  DeliveryFailure? nextUpsertFailure;
  DeliveryFailure? nextClearFailure;

  final List<DeliveryAssignment> upserted = [];
  final List<String> clearedDriverIds = [];
  int getCallCount = 0;
  int upsertCallCount = 0;
  int clearCallCount = 0;

  @override
  Future<DeliveryResult<DeliveryAssignment?>> getActiveAssignment({
    required String driverId,
  }) async {
    getCallCount++;
    if (nextGetFailure != null) {
      return DeliveryFailureResult(nextGetFailure!);
    }
    final current = active;
    if (current == null || current.driverId != driverId) {
      return const DeliverySuccess(null);
    }
    return DeliverySuccess(current);
  }

  @override
  Future<DeliveryResult<void>> upsertAccepted(
    DeliveryAssignment assignment,
  ) async {
    upsertCallCount++;
    upserted.add(assignment);
    if (nextUpsertFailure != null) {
      return DeliveryFailureResult(nextUpsertFailure!);
    }
    active = assignment;
    return DeliverySuccess.unit();
  }

  @override
  Future<DeliveryResult<void>> clear({required String driverId}) async {
    clearCallCount++;
    clearedDriverIds.add(driverId);
    if (nextClearFailure != null) {
      return DeliveryFailureResult(nextClearFailure!);
    }
    if (active?.driverId == driverId) {
      active = null;
    }
    return DeliverySuccess.unit();
  }
}
