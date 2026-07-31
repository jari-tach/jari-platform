import 'package:saeq_driver/features/delivery/domain/entities/delivery_result.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/delivery/domain/repositories/delivery_command_repository.dart';

class FakeDeliveryCommandRepository implements DeliveryCommandRepository {
  final Map<String, LocalDeliveryCommand> commands = {};
  DeliveryFailure? nextFailure;

  @override
  Future<DeliveryResult<LocalDeliveryCommand?>> getById({
    required String commandId,
  }) async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    return DeliverySuccess(commands[commandId]);
  }

  @override
  Future<DeliveryResult<bool>> isOfferConsumed({
    required String driverId,
    required String offerId,
  }) async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    return DeliverySuccess(
      commands.values.any(
        (command) =>
            command.driverId == driverId &&
            command.targetId == offerId &&
            command.status == LocalDeliveryCommandStatus.completed &&
            (command.type == LocalDeliveryCommandType.acceptOffer ||
                command.type == LocalDeliveryCommandType.rejectOffer),
      ),
    );
  }

  @override
  Future<DeliveryResult<void>> save(LocalDeliveryCommand command) async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    commands[command.commandId] = command;
    return DeliverySuccess.unit();
  }

  @override
  Future<DeliveryResult<List<LocalDeliveryCommand>>> listPending({
    required String driverId,
  }) async {
    final failure = nextFailure;
    if (failure != null) return DeliveryFailureResult(failure);
    final pending =
        commands.values
            .where(
              (command) =>
                  command.driverId == driverId &&
                  command.status == LocalDeliveryCommandStatus.pendingSync,
            )
            .toList()
          ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return DeliverySuccess(List.unmodifiable(pending));
  }
}
