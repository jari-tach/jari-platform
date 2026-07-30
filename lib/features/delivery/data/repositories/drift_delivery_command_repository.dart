import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../driver/data/datasources/local/driver_database.dart';
import '../../domain/entities/delivery_result.dart';
import '../../domain/entities/local_delivery_command.dart';
import '../../domain/failures/delivery_failure.dart';
import '../../domain/repositories/delivery_command_repository.dart';

/// Stores STEP 3 command records in the existing Drift offline queue table.
///
/// Custom `local_*` statuses deliberately keep these rows outside the dormant
/// generic SyncManager's `pending` query. No HTTP path is involved.
class DriftDeliveryCommandRepository implements DeliveryCommandRepository {
  const DriftDeliveryCommandRepository({required this.database});

  static const _entityType = 'delivery_local_command';
  static const _pendingStatus = 'local_pending';
  static const _completedStatus = 'local_completed';

  final DriverDatabase database;

  @override
  Future<DeliveryResult<LocalDeliveryCommand?>> getById({
    required String commandId,
  }) async {
    final id = commandId.trim();
    if (id.isEmpty) {
      return const DeliveryFailureResult(DeliveryInvalidCommandId());
    }
    try {
      final query = database.select(database.offlineQueue)
        ..where(
          (row) => row.entityType.equals(_entityType) & row.entityId.equals(id),
        );
      final row = await query.getSingleOrNull();
      return DeliverySuccess(row == null ? null : _decode(row));
    } catch (error) {
      return DeliveryFailureResult(
        DeliveryPersistenceFailure(error.toString()),
      );
    }
  }

  @override
  Future<DeliveryResult<void>> save(LocalDeliveryCommand command) async {
    if (command.commandId.trim().isEmpty) {
      return const DeliveryFailureResult(DeliveryInvalidCommandId());
    }
    try {
      await database.transaction(() async {
        await (database.delete(database.offlineQueue)..where(
              (row) =>
                  row.entityType.equals(_entityType) &
                  row.entityId.equals(command.commandId),
            ))
            .go();
        await database
            .into(database.offlineQueue)
            .insert(
              OfflineQueueCompanion.insert(
                operationType: 'update',
                entityType: _entityType,
                entityId: command.commandId,
                payload: jsonEncode({
                  'driverId': command.driverId,
                  'targetId': command.targetId,
                  'type': command.type.name,
                }),
                status: Value(
                  command.status == LocalDeliveryCommandStatus.completed
                      ? _completedStatus
                      : _pendingStatus,
                ),
                retryCount: const Value(0),
                createdAt: Value(command.recordedAt.toUtc()),
                processedAt:
                    command.status == LocalDeliveryCommandStatus.completed
                    ? Value(command.recordedAt.toUtc())
                    : const Value.absent(),
              ),
            );
      });
      return DeliverySuccess.unit();
    } catch (error) {
      return DeliveryFailureResult(
        DeliveryPersistenceFailure(error.toString()),
      );
    }
  }

  @override
  Future<DeliveryResult<bool>> isOfferConsumed({
    required String driverId,
    required String offerId,
  }) async {
    try {
      final query = database.select(database.offlineQueue)
        ..where(
          (row) =>
              row.entityType.equals(_entityType) &
              row.status.equals(_completedStatus),
        );
      final rows = await query.get();
      for (final row in rows) {
        final command = _decode(row);
        final consumed =
            command.driverId == driverId &&
            command.targetId == offerId &&
            (command.type == LocalDeliveryCommandType.acceptOffer ||
                command.type == LocalDeliveryCommandType.rejectOffer);
        if (consumed) return const DeliverySuccess(true);
      }
      return const DeliverySuccess(false);
    } catch (error) {
      return DeliveryFailureResult(
        DeliveryPersistenceFailure(error.toString()),
      );
    }
  }

  LocalDeliveryCommand _decode(OfflineQueueData row) {
    final decoded = jsonDecode(row.payload);
    if (decoded is! Map) {
      throw const FormatException('local command payload is invalid');
    }
    final json = Map<String, dynamic>.from(decoded);
    final driverId = json['driverId'];
    final targetId = json['targetId'];
    final typeName = json['type'];
    if (driverId is! String ||
        driverId.trim().isEmpty ||
        targetId is! String ||
        targetId.trim().isEmpty ||
        typeName is! String) {
      throw const FormatException('local command identity is invalid');
    }
    final type = LocalDeliveryCommandType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () =>
          throw const FormatException('local command type is invalid'),
    );
    return LocalDeliveryCommand(
      commandId: row.entityId,
      driverId: driverId,
      targetId: targetId,
      type: type,
      status: row.status == _completedStatus
          ? LocalDeliveryCommandStatus.completed
          : LocalDeliveryCommandStatus.pendingSync,
      recordedAt: row.createdAt.toUtc(),
    );
  }
}
