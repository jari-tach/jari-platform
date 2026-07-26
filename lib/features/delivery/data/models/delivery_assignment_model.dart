import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_status.dart';
import 'delivery_order_model.dart';

/// Data-layer DTO for [DeliveryAssignment] (PHASE 2.5).
///
/// No business rules — serialization and mapping only.
class DeliveryAssignmentModel {
  /// Creates an immutable assignment model.
  const DeliveryAssignmentModel({
    required this.assignmentId,
    required this.offerId,
    required this.driverId,
    required this.status,
    required this.order,
    required this.acceptedAt,
    this.serverRevision,
  });

  final String assignmentId;
  final String offerId;
  final String driverId;
  final String status;
  final DeliveryOrderModel order;
  final DateTime acceptedAt;
  final String? serverRevision;

  /// Maps a domain entity to this model.
  factory DeliveryAssignmentModel.fromEntity(DeliveryAssignment entity) {
    return DeliveryAssignmentModel(
      assignmentId: entity.assignmentId,
      offerId: entity.offerId,
      driverId: entity.driverId,
      status: entity.status.name,
      order: DeliveryOrderModel.fromEntity(entity.order),
      acceptedAt: entity.acceptedAt.toUtc(),
      serverRevision: entity.serverRevision,
    );
  }

  /// Maps this model to a domain entity.
  ///
  /// Throws [FormatException] when [status] is unknown.
  DeliveryAssignment toEntity() {
    return DeliveryAssignment(
      assignmentId: assignmentId,
      offerId: offerId,
      driverId: driverId,
      status: _parseDeliveryStatus(status),
      order: order.toEntity(),
      acceptedAt: acceptedAt.toUtc(),
      serverRevision: serverRevision,
    );
  }

  /// Parses JSON into a model.
  ///
  /// Throws [FormatException] when required fields are missing or invalid.
  factory DeliveryAssignmentModel.fromJson(Map<String, dynamic> json) {
    final assignmentId = json['assignmentId'];
    final offerId = json['offerId'];
    final driverId = json['driverId'];
    final status = json['status'];
    final orderRaw = json['order'];
    final acceptedAtRaw = json['acceptedAt'];

    if (assignmentId is! String || assignmentId.trim().isEmpty) {
      throw const FormatException('assignmentId missing or invalid');
    }
    if (offerId is! String || offerId.trim().isEmpty) {
      throw const FormatException('offerId missing or invalid');
    }
    if (driverId is! String || driverId.trim().isEmpty) {
      throw const FormatException('driverId missing or invalid');
    }
    if (status is! String || status.trim().isEmpty) {
      throw const FormatException('status missing or invalid');
    }
    if (orderRaw is! Map) {
      throw const FormatException('order missing or invalid');
    }
    if (acceptedAtRaw is! String) {
      throw const FormatException('acceptedAt missing or invalid');
    }

    final acceptedAt = DateTime.tryParse(acceptedAtRaw);
    if (acceptedAt == null) {
      throw const FormatException('acceptedAt must be ISO-8601');
    }

    return DeliveryAssignmentModel(
      assignmentId: assignmentId,
      offerId: offerId,
      driverId: driverId,
      status: status,
      order: DeliveryOrderModel.fromJson(Map<String, dynamic>.from(orderRaw)),
      acceptedAt: acceptedAt.toUtc(),
      serverRevision: json['serverRevision'] as String?,
    );
  }

  /// Serializes this model to JSON.
  Map<String, dynamic> toJson() => {
    'assignmentId': assignmentId,
    'offerId': offerId,
    'driverId': driverId,
    'status': status,
    'order': order.toJson(),
    'acceptedAt': acceptedAt.toUtc().toIso8601String(),
    'serverRevision': serverRevision,
  };

  static DeliveryStatus _parseDeliveryStatus(String raw) {
    for (final value in DeliveryStatus.values) {
      if (value.name == raw) return value;
    }
    throw FormatException('unknown delivery status: $raw');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryAssignmentModel &&
          assignmentId == other.assignmentId &&
          offerId == other.offerId &&
          driverId == other.driverId &&
          status == other.status &&
          order == other.order &&
          acceptedAt == other.acceptedAt &&
          serverRevision == other.serverRevision;

  @override
  int get hashCode => Object.hash(
    assignmentId,
    offerId,
    driverId,
    status,
    order,
    acceptedAt,
    serverRevision,
  );
}
