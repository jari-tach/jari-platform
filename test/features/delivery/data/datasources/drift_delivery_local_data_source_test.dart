import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/features/delivery/data/datasources/drift_delivery_local_data_source.dart';
import 'package:saeq_driver/features/delivery/data/models/delivery_assignment_model.dart';
import 'package:saeq_driver/features/delivery/data/repositories/local_delivery_assignment_repository.dart';
import 'package:saeq_driver/features/delivery/domain/entities/delivery_status.dart';
import 'package:saeq_driver/features/delivery/domain/failures/delivery_failure.dart';
import 'package:saeq_driver/features/driver/data/datasources/local/driver_database.dart';

import '../../helpers/delivery_fixtures.dart';

void main() {
  late DriverDatabase database;
  late DriftDeliveryLocalDataSource local;

  setUp(() {
    database = DriverDatabase.forExecutor(NativeDatabase.memory());
    local = DriftDeliveryLocalDataSource(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftDeliveryLocalDataSource', () {
    test('empty storage returns null', () async {
      final result = await local.readActiveAssignment(driverId: 'drv-1');
      expect(result, isNull);
    });

    test('upsert then read round-trip preserves model', () async {
      final original = DeliveryAssignmentModel.fromEntity(sampleAssignment());
      await local.writeActiveAssignment(original);
      final loaded = await local.readActiveAssignment(driverId: 'drv-1');
      expect(loaded, original);
      expect(loaded!.toEntity(), sampleAssignment());
    });

    test('updating an existing assignment replaces it', () async {
      await local.writeActiveAssignment(
        DeliveryAssignmentModel.fromEntity(sampleAssignment()),
      );
      final updated = DeliveryAssignmentModel.fromEntity(
        sampleAssignment(
          assignmentId: 'asg-2',
          status: DeliveryStatus.pickedUp,
          serverRevision: 'srev-2',
        ),
      );
      await local.writeActiveAssignment(updated);

      final loaded = await local.readActiveAssignment(driverId: 'drv-1');
      expect(loaded, updated);

      final rows = await database.allDeliveryAssignments;
      expect(rows, hasLength(1));
      expect(rows.single.assignmentId, 'asg-2');
    });

    test('clear removes the active assignment', () async {
      await local.writeActiveAssignment(
        DeliveryAssignmentModel.fromEntity(sampleAssignment()),
      );
      await local.clearActiveAssignment(driverId: 'drv-1');
      expect(await local.readActiveAssignment(driverId: 'drv-1'), isNull);
      expect(await database.allDeliveryAssignments, isEmpty);
    });

    test('enum and timestamp round-trip', () async {
      for (final status in DeliveryStatus.values) {
        final model = DeliveryAssignmentModel.fromEntity(
          sampleAssignment(
            status: status,
            acceptedAt: DateTime.utc(2026, 7, 26, 15, 30, 45),
          ),
        );
        await local.writeActiveAssignment(model);
        final loaded = await local.readActiveAssignment(driverId: 'drv-1');
        expect(loaded!.status, status.name);
        expect(loaded.acceptedAt.isUtc, isTrue);
        expect(loaded.acceptedAt, DateTime.utc(2026, 7, 26, 15, 30, 45));
      }
    });

    test('nested DeliveryOrder round-trip', () async {
      final model = DeliveryAssignmentModel.fromEntity(
        sampleAssignment(
          order: sampleOrder(
            orderId: 'ord-nested',
            pickupLabel: 'P1',
            dropoffLabel: 'D1',
            merchantDisplayName: 'M1',
            distanceMeters: 3210.5,
            etaMinutes: 22,
            notes: 'leave at door',
          ),
        ),
      );
      await local.writeActiveAssignment(model);
      final loaded = await local.readActiveAssignment(driverId: 'drv-1');
      expect(loaded!.order, model.order);
    });

    test('at most one active assignment is retained per driver', () async {
      await local.writeActiveAssignment(
        DeliveryAssignmentModel.fromEntity(
          sampleAssignment(assignmentId: 'asg-1'),
        ),
      );
      await local.writeActiveAssignment(
        DeliveryAssignmentModel.fromEntity(
          sampleAssignment(assignmentId: 'asg-2'),
        ),
      );
      final rows = await database.allDeliveryAssignments;
      expect(rows, hasLength(1));
      expect(rows.single.assignmentId, 'asg-2');
    });

    test('different drivers keep independent assignments', () async {
      await local.writeActiveAssignment(
        DeliveryAssignmentModel.fromEntity(
          sampleAssignment(driverId: 'drv-1', assignmentId: 'asg-a'),
        ),
      );
      await local.writeActiveAssignment(
        DeliveryAssignmentModel.fromEntity(
          sampleAssignment(driverId: 'drv-2', assignmentId: 'asg-b'),
        ),
      );
      expect(
        (await local.readActiveAssignment(driverId: 'drv-1'))!.assignmentId,
        'asg-a',
      );
      expect(
        (await local.readActiveAssignment(driverId: 'drv-2'))!.assignmentId,
        'asg-b',
      );
      expect(await database.allDeliveryAssignments, hasLength(2));
    });

    test('persistence survives datasource/database reconstruction', () async {
      await database.close();

      final dir = await Directory.systemTemp.createTemp('saeq_asg_');
      final file = File('${dir.path}/assignments.db');
      addTearDown(() async {
        await dir.delete(recursive: true).catchError((_) => dir);
      });

      final firstDb = DriverDatabase.forExecutor(NativeDatabase(file));
      final firstLocal = DriftDeliveryLocalDataSource(database: firstDb);
      final original = DeliveryAssignmentModel.fromEntity(sampleAssignment());
      await firstLocal.writeActiveAssignment(original);
      await firstDb.close();

      final secondDb = DriverDatabase.forExecutor(NativeDatabase(file));
      final secondLocal = DriftDeliveryLocalDataSource(database: secondDb);
      final loaded = await secondLocal.readActiveAssignment(driverId: 'drv-1');
      expect(loaded, original);
      await secondDb.close();

      database = DriverDatabase.forExecutor(NativeDatabase.memory());
      local = DriftDeliveryLocalDataSource(database: database);
    });

    test('corrupt payload is cleared and throws FormatException', () async {
      await database.upsertDeliveryAssignment(
        DeliveryAssignmentsCompanion.insert(
          driverId: 'drv-1',
          assignmentId: 'asg-bad',
          payloadJson: '{not-json',
        ),
      );

      await expectLater(
        local.readActiveAssignment(driverId: 'drv-1'),
        throwsA(isA<FormatException>()),
      );

      expect(await local.readActiveAssignment(driverId: 'drv-1'), isNull);
    });

    test(
      'invalid enum in payload throws FormatException after clear',
      () async {
        final valid = DeliveryAssignmentModel.fromEntity(sampleAssignment());
        final corruptJson = jsonEncode(valid.toJson()..['status'] = 'flying');
        await database.upsertDeliveryAssignment(
          DeliveryAssignmentsCompanion.insert(
            driverId: 'drv-1',
            assignmentId: valid.assignmentId,
            payloadJson: corruptJson,
          ),
        );

        await expectLater(
          local.readActiveAssignment(driverId: 'drv-1'),
          throwsA(isA<FormatException>()),
        );
        expect(await local.readActiveAssignment(driverId: 'drv-1'), isNull);
      },
    );

    test(
      'repository maps FormatException to DeliveryPersistenceFailure',
      () async {
        final repo = LocalDeliveryAssignmentRepository(localDataSource: local);
        await database.upsertDeliveryAssignment(
          DeliveryAssignmentsCompanion.insert(
            driverId: 'drv-1',
            assignmentId: 'asg-bad',
            payloadJson: '[]',
          ),
        );
        final result = await repo.getActiveAssignment(driverId: 'drv-1');
        expect(result.failureOrNull, isA<DeliveryPersistenceFailure>());
      },
    );
  });
}
