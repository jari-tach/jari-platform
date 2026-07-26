import '../models/delivery_assignment_model.dart';

/// Local persistence port for accepted assignments (PHASE 2.5 / ADR-028).
///
/// Concrete storage: [DriftDeliveryLocalDataSource] on Drift `DeliveryAssignments`.
/// No caching policy or domain rules belong here.
abstract interface class DeliveryLocalDataSource {
  /// Returns the stored active assignment for [driverId], if any.
  Future<DeliveryAssignmentModel?> readActiveAssignment({
    required String driverId,
  });

  /// Writes/replaces the active assignment snapshot.
  Future<void> writeActiveAssignment(DeliveryAssignmentModel assignment);

  /// Clears the active assignment for [driverId].
  Future<void> clearActiveAssignment({required String driverId});
}
