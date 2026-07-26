import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'driver_database.g.dart';

/// Driver database for offline-first data persistence.
///
/// Stores:
/// - Driver profile
/// - Delivery orders scaffold (legacy; not PHASE 2.5 domain)
/// - Accepted delivery assignments (ADR-028 / schema v2)
/// - Offline queue
/// - Sync metadata
///
/// Schema versions:
/// - 1: initial tables (profiles, orders scaffold, offline queue, sync)
/// - 2: adds [DeliveryAssignments] for restart-safe accepted work (ADR-028)
@DriftDatabase(
  tables: [
    DriverProfiles,
    DeliveryOrders,
    DeliveryAssignments,
    OfflineQueue,
    SyncMetadata,
  ],
)
class DriverDatabase extends _$DriverDatabase {
  static final DriverDatabase _instance = DriverDatabase._internal();

  factory DriverDatabase() => _instance;

  DriverDatabase._internal() : super(_openConnection());

  /// Creates a database bound to [executor] (tests / alternate open paths).
  ///
  /// Does **not** replace the production [DriverDatabase] singleton.
  @visibleForTesting
  DriverDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // v1 → v2: add DeliveryAssignments only. Do not drop or rewrite
      // existing tables (profiles / scaffold orders / queue / sync).
      if (from < 2) {
        await m.createTable(deliveryAssignments);
      }
    },
  );

  // Tables
  Future<List<DriverProfile>> get driverProfile => select(driverProfiles).get();

  Future<List<DeliveryOrder>> get allDeliveryOrders =>
      select(deliveryOrders).get();

  Future<List<DeliveryAssignment>> get allDeliveryAssignments =>
      select(deliveryAssignments).get();

  Future<List<OfflineQueueData>> get allOfflineQueueItems =>
      select(offlineQueue).get();

  Future<List<SyncMetadataData>> get allSyncMetadata =>
      select(syncMetadata).get();

  // Driver Profile operations
  Future<DriverProfile?> getActiveDriver() async {
    final query = select(driverProfiles)..where((t) => t.isActive.equals(1));
    return await query.getSingleOrNull();
  }

  Future<DriverProfile?> getDriverByDriverId(String driverId) async {
    final query = select(driverProfiles)
      ..where((t) => t.driverId.equals(driverId));
    return await query.getSingleOrNull();
  }

  Future<int> insertDriverProfile(DriverProfilesCompanion insert) {
    return into(driverProfiles).insert(insert);
  }

  /// Insert or replace by unique [DriverProfiles.driverId].
  Future<void> upsertDriverProfile(DriverProfilesCompanion insert) async {
    await into(driverProfiles).insertOnConflictUpdate(insert);
  }

  Future<bool> updateDriverProfile(DriverProfilesCompanion insert) async {
    final rows = await update(driverProfiles).write(insert);
    return rows > 0;
  }

  // Delivery Order operations
  Future<List<DeliveryOrder>> getPendingOrders() async {
    final query = select(deliveryOrders)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return await query.get();
  }

  Future<int> insertDeliveryOrder(DeliveryOrdersCompanion insert) {
    return into(deliveryOrders).insert(insert);
  }

  Future<bool> updateDeliveryOrder(DeliveryOrdersCompanion insert) async {
    final rows = await update(deliveryOrders).write(insert);
    return rows > 0;
  }

  Future<int> deleteDeliveryOrder(int id) {
    return (delete(deliveryOrders)..where((t) => t.id.equals(id))).go();
  }

  // Delivery Assignment operations (ADR-028)
  Future<DeliveryAssignment?> getActiveDeliveryAssignment(
    String driverId,
  ) async {
    final query = select(deliveryAssignments)
      ..where((t) => t.driverId.equals(driverId));
    return query.getSingleOrNull();
  }

  /// Atomically replaces any existing row for [insert.driverId].
  Future<void> upsertDeliveryAssignment(
    DeliveryAssignmentsCompanion insert,
  ) async {
    await transaction(() async {
      final driverId = insert.driverId.value;
      await (delete(
        deliveryAssignments,
      )..where((t) => t.driverId.equals(driverId))).go();
      await into(deliveryAssignments).insert(insert);
    });
  }

  Future<int> clearDeliveryAssignment(String driverId) {
    return (delete(
      deliveryAssignments,
    )..where((t) => t.driverId.equals(driverId))).go();
  }

  // Offline Queue operations
  Future<int> enqueueOperation(OfflineQueueCompanion insert) {
    return into(offlineQueue).insert(insert);
  }

  Future<List<OfflineQueueData>> getPendingOperations() async {
    final query = select(offlineQueue)
      ..where((t) => t.status.equals('pending'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return await query.get();
  }

  Future<int> deleteOfflineOperation(int id) {
    return (delete(offlineQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<int> clearOfflineQueue() {
    return delete(offlineQueue).go();
  }

  // Sync Metadata operations
  Future<SyncMetadataData?> getLastSync(String entityType) async {
    final query = select(syncMetadata)
      ..where((t) => t.entityType.equals(entityType));
    return await query.getSingleOrNull();
  }

  Future<int> upsertSyncMetadata(SyncMetadataCompanion insert) {
    return into(syncMetadata).insertOnConflictUpdate(insert);
  }
}

// Table definitions
class DriverProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get driverId => text().unique()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get vehicleType => text()();
  TextColumn get vehiclePlate => text()();
  TextColumn get licenseNumber => text()();
  TextColumn get profileImageUrl => text().nullable()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class DeliveryOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text().unique()();
  TextColumn get customerName => text()();
  TextColumn get customerPhone => text()();
  TextColumn get deliveryAddress => text()();
  TextColumn get latitude => text()();
  TextColumn get longitude => text()();
  TextColumn get items => text()(); // JSON string
  RealColumn get totalAmount => real()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Accepted [DeliveryAssignment] snapshots (PHASE 2.5 / ADR-028).
///
/// One row per [driverId] (unique). Payload is the full model JSON so nested
/// [DeliveryOrder] fields round-trip without inventing a second schema.
/// Distinct from the scaffold [DeliveryOrders] table.
class DeliveryAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Authenticated driver — at most one active assignment row.
  TextColumn get driverId => text().unique()();

  /// Authoritative assignment id (also availability `activeAssignmentId`).
  TextColumn get assignmentId => text()();

  /// Full [DeliveryAssignmentModel.toJson] document (no tokens/secrets).
  TextColumn get payloadJson => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class OfflineQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()(); // CREATE, UPDATE, DELETE
  TextColumn get entityType => text()(); // delivery_order, driver_profile, etc.
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON payload
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, syncing, completed, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
}

class SyncMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text().unique()();
  DateTimeColumn get lastSyncAt => dateTime()();
  TextColumn get lastSyncToken => text().nullable()();
  IntColumn get totalRecords => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// Connection helper
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'saeq_driver.db'));
    return NativeDatabase.createInBackground(file);
  });
}
