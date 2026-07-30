import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/repositories/drift_delivery_command_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/local_delivery_command.dart';
import 'package:saeq_driver/features/driver/data/datasources/local/driver_database.dart';

void main() {
  late DriverDatabase database;
  late DriftDeliveryCommandRepository repository;

  setUp(() {
    database = DriverDatabase.forExecutor(NativeDatabase.memory());
    repository = DriftDeliveryCommandRepository(database: database);
  });

  tearDown(() => database.close());

  test('command record survives repository recreation', () async {
    final recordedAt = DateTime.utc(2026, 7, 30, 12);
    await repository.save(
      LocalDeliveryCommand(
        commandId: 'accept-1',
        driverId: 'drv-1',
        targetId: 'off-1',
        type: LocalDeliveryCommandType.acceptOffer,
        status: LocalDeliveryCommandStatus.completed,
        recordedAt: recordedAt,
      ),
    );

    final recreated = DriftDeliveryCommandRepository(database: database);
    final restored = await recreated.getById(commandId: 'accept-1');
    expect(restored.valueOrNull?.driverId, 'drv-1');
    expect(restored.valueOrNull?.targetId, 'off-1');
    expect(restored.valueOrNull?.status, LocalDeliveryCommandStatus.completed);
    expect(
      (await recreated.isOfferConsumed(
        driverId: 'drv-1',
        offerId: 'off-1',
      )).valueOrNull,
      isTrue,
    );
  });

  test(
    'pending sync marker persists and can be completed idempotently',
    () async {
      final command = LocalDeliveryCommand(
        commandId: 'pickup-1',
        driverId: 'drv-1',
        targetId: 'asg-1',
        type: LocalDeliveryCommandType.confirmPickup,
        status: LocalDeliveryCommandStatus.pendingSync,
        recordedAt: DateTime.utc(2026, 7, 30, 12),
      );
      await repository.save(command);
      expect(
        (await repository.getById(
          commandId: command.commandId,
        )).valueOrNull?.status,
        LocalDeliveryCommandStatus.pendingSync,
      );

      await repository.save(
        command.copyWith(status: LocalDeliveryCommandStatus.completed),
      );
      await repository.save(
        command.copyWith(status: LocalDeliveryCommandStatus.completed),
      );
      expect(
        (await repository.getById(
          commandId: command.commandId,
        )).valueOrNull?.status,
        LocalDeliveryCommandStatus.completed,
      );
      expect(
        database.allOfflineQueueItems.then((rows) => rows.length),
        completion(1),
      );
    },
  );
}
