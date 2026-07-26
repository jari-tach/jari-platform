import '../entities/delivery_assignment.dart';
import '../entities/delivery_result.dart';

/// Local (and later sync) persistence for accepted assignments (ADR-028).
///
/// Does not issue offers. Does not claim Backend authority by itself.
abstract interface class DeliveryAssignmentRepository {
  /// Returns the active assignment for [driverId], if any.
  Future<DeliveryResult<DeliveryAssignment?>> getActiveAssignment({
    required String driverId,
  });

  /// Persists an accepted assignment snapshot for restart safety.
  Future<DeliveryResult<void>> upsertAccepted(DeliveryAssignment assignment);

  /// Clears local assignment state for [driverId] (logout / completion later).
  Future<DeliveryResult<void>> clear({required String driverId});
}
