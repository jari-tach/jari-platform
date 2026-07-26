import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_result.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/repositories/delivery_assignment_repository.dart';
import '../datasources/delivery_local_data_source.dart';
import '../models/delivery_assignment_model.dart';

/// Local [DeliveryAssignmentRepository] backed by [DeliveryLocalDataSource].
///
/// Matches the availability `Local*` repository shape: delegate + map +
/// feature-local `DeliveryResult` translation (ADR-028). No concrete DB and
/// no domain policy here. Does not use remote — accept authority stays on
/// [DeliveryOfferRepository] / remote; this port only persists snapshots.
class LocalDeliveryAssignmentRepository
    implements DeliveryAssignmentRepository {
  /// Creates a repository backed by [localDataSource].
  const LocalDeliveryAssignmentRepository({
    required DeliveryLocalDataSource localDataSource,
  }) : _local = localDataSource;

  final DeliveryLocalDataSource _local;

  @override
  Future<DeliveryResult<DeliveryAssignment?>> getActiveAssignment({
    required String driverId,
  }) async {
    try {
      final model = await _local.readActiveAssignment(driverId: driverId);
      if (model == null) {
        return const DeliverySuccess(null);
      }
      return DeliverySuccess(model.toEntity());
    } on FormatException catch (error) {
      return DeliveryFailureResult(DeliveryPersistenceFailure(error.message));
    } on DeliveryFailure catch (failure) {
      return DeliveryFailureResult(failure);
    } catch (error) {
      return DeliveryFailureResult(
        DeliveryPersistenceFailure(error.toString()),
      );
    }
  }

  @override
  Future<DeliveryResult<void>> upsertAccepted(
    DeliveryAssignment assignment,
  ) async {
    try {
      await _local.writeActiveAssignment(
        DeliveryAssignmentModel.fromEntity(assignment),
      );
      return DeliverySuccess.unit();
    } on FormatException catch (error) {
      return DeliveryFailureResult(DeliveryPersistenceFailure(error.message));
    } on DeliveryFailure catch (failure) {
      return DeliveryFailureResult(failure);
    } catch (error) {
      return DeliveryFailureResult(
        DeliveryPersistenceFailure(error.toString()),
      );
    }
  }

  @override
  Future<DeliveryResult<void>> clear({required String driverId}) async {
    try {
      await _local.clearActiveAssignment(driverId: driverId);
      return DeliverySuccess.unit();
    } on FormatException catch (error) {
      return DeliveryFailureResult(DeliveryPersistenceFailure(error.message));
    } on DeliveryFailure catch (failure) {
      return DeliveryFailureResult(failure);
    } catch (error) {
      return DeliveryFailureResult(
        DeliveryPersistenceFailure(error.toString()),
      );
    }
  }
}
