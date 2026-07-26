import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../driver/data/datasources/local/driver_database.dart';
import '../models/delivery_assignment_model.dart';
import 'delivery_local_data_source.dart';

/// Drift-backed [DeliveryLocalDataSource] (PHASE 2.5 / ADR-028).
///
/// Persists at most one accepted assignment per driver in
/// [DriverDatabase.deliveryAssignments]. Uses the existing
/// [DeliveryAssignmentModel] JSON document for nested order / enum / timestamp
/// fidelity. No business policy — storage and decode only.
class DriftDeliveryLocalDataSource implements DeliveryLocalDataSource {
  /// Creates a datasource bound to [database].
  const DriftDeliveryLocalDataSource({required this.database});

  /// Injected Drift database (production singleton or test executor).
  final DriverDatabase database;

  @override
  Future<DeliveryAssignmentModel?> readActiveAssignment({
    required String driverId,
  }) async {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw const FormatException('driverId missing or invalid');
    }

    final row = await database.getActiveDeliveryAssignment(id);
    if (row == null) return null;

    try {
      return _decodePayload(row.payloadJson, expectedDriverId: id);
    } on FormatException {
      // Corrupt snapshot cannot be trusted — clear then rethrow so the
      // repository maps to DeliveryPersistenceFailure (availability pattern).
      try {
        await database.clearDeliveryAssignment(id);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> writeActiveAssignment(DeliveryAssignmentModel assignment) async {
    final driverId = assignment.driverId.trim();
    if (driverId.isEmpty) {
      throw const FormatException('assignment.driverId missing or invalid');
    }

    final payload = jsonEncode(assignment.toJson());
    await database.upsertDeliveryAssignment(
      DeliveryAssignmentsCompanion.insert(
        driverId: driverId,
        assignmentId: assignment.assignmentId,
        payloadJson: payload,
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> clearActiveAssignment({required String driverId}) async {
    final id = driverId.trim();
    if (id.isEmpty) {
      throw const FormatException('driverId missing or invalid');
    }
    await database.clearDeliveryAssignment(id);
  }

  DeliveryAssignmentModel _decodePayload(
    String raw, {
    required String expectedDriverId,
  }) {
    if (raw.trim().isEmpty) {
      throw const FormatException('assignment payload is empty');
    }

    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('assignment payload decode failed: $error');
    }

    if (decoded is! Map) {
      throw const FormatException('assignment payload is not a JSON object');
    }

    final model = DeliveryAssignmentModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (model.driverId != expectedDriverId) {
      throw const FormatException(
        'persisted assignment driverId does not match requested driverId',
      );
    }
    // Ensure status/order decode is valid for domain construction.
    model.toEntity();
    return model;
  }
}
