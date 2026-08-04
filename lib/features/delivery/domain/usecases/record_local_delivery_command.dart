import '../entities/delivery_result.dart';
import '../entities/local_delivery_command.dart';
import '../failures/delivery_failure.dart';
import '../repositories/delivery_command_repository.dart';

/// Records a local-only command that does not mutate the delivery state
/// machine (for example, cancelling/dismissing a local form).
class RecordLocalDeliveryCommand {
  RecordLocalDeliveryCommand(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DeliveryCommandRepository _repository;
  final DateTime Function() _clock;

  Future<DeliveryResult<void>> call({
    required String commandId,
    required String driverId,
    required String targetId,
    required LocalDeliveryCommandType type,
  }) async {
    final id = commandId.trim();
    if (id.isEmpty) {
      return const DeliveryFailureResult(DeliveryInvalidCommandId());
    }
    final existing = await _repository.getById(commandId: id);
    if (existing.isFailure) {
      return DeliveryFailureResult(
        existing.failureOrNull ?? const DeliveryPersistenceFailure(),
      );
    }
    final recorded = existing.valueOrNull;
    if (recorded != null) {
      if (!recorded.matches(
        driverId: driverId,
        targetId: targetId,
        type: type,
      )) {
        return const DeliveryFailureResult(DeliveryConflict());
      }
      return DeliverySuccess.unit();
    }
    return _repository.save(
      LocalDeliveryCommand(
        commandId: id,
        driverId: driverId,
        targetId: targetId,
        type: type,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: _clock().toUtc(),
      ),
    );
  }
}
