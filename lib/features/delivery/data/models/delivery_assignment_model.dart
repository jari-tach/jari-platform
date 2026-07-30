import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/driver_workflow_stage.dart';
import 'delivery_order_model.dart';

/// Data-layer DTO for [DeliveryAssignment] (PHASE 2.5 / 2.6).
///
/// No business rules — serialization and mapping only.
/// [workflowStage] is optional in legacy JSON (defaults to `assigned`).
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
    this.workflowStage = 'assigned',
    this.resumeAfterIssueStage,
    this.completedCommandIds = const <String>[],
    this.pendingSync = false,
  });

  final String assignmentId;
  final String offerId;
  final String driverId;
  final String status;
  final DeliveryOrderModel order;
  final DateTime acceptedAt;
  final String? serverRevision;
  final String workflowStage;
  final String? resumeAfterIssueStage;
  final List<String> completedCommandIds;
  final bool pendingSync;

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
      workflowStage: entity.workflowStage.name,
      resumeAfterIssueStage: entity.resumeAfterIssueStage?.name,
      completedCommandIds: entity.completedCommandIds.toList(growable: false)
        ..sort(),
      pendingSync: entity.pendingSync,
    );
  }

  /// Maps this model to a domain entity.
  ///
  /// Throws [FormatException] when [status] / stage is unknown.
  DeliveryAssignment toEntity() {
    return DeliveryAssignment(
      assignmentId: assignmentId,
      offerId: offerId,
      driverId: driverId,
      status: _parseDeliveryStatus(status),
      order: order.toEntity(),
      acceptedAt: acceptedAt.toUtc(),
      serverRevision: serverRevision,
      workflowStage: _parseWorkflowStage(workflowStage),
      resumeAfterIssueStage: resumeAfterIssueStage == null
          ? null
          : _parseWorkflowStage(resumeAfterIssueStage!),
      completedCommandIds: completedCommandIds.toSet(),
      pendingSync: pendingSync,
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

    final stageRaw = json['workflowStage'];
    final workflowStage = stageRaw is String && stageRaw.trim().isNotEmpty
        ? stageRaw
        : DriverWorkflowStage.assigned.name;

    final resumeRaw = json['resumeAfterIssueStage'];
    final resumeAfterIssueStage =
        resumeRaw is String && resumeRaw.trim().isNotEmpty ? resumeRaw : null;
    final completedRaw = json['completedCommandIds'];
    final completedCommandIds = completedRaw == null
        ? const <String>[]
        : completedRaw is List &&
              completedRaw.every(
                (value) => value is String && value.trim().isNotEmpty,
              )
        ? completedRaw.cast<String>()
        : throw const FormatException('completedCommandIds must be strings');
    final pendingSyncRaw = json['pendingSync'];
    if (pendingSyncRaw != null && pendingSyncRaw is! bool) {
      throw const FormatException('pendingSync must be a boolean');
    }

    return DeliveryAssignmentModel(
      assignmentId: assignmentId,
      offerId: offerId,
      driverId: driverId,
      status: status,
      order: DeliveryOrderModel.fromJson(Map<String, dynamic>.from(orderRaw)),
      acceptedAt: acceptedAt.toUtc(),
      serverRevision: json['serverRevision'] as String?,
      workflowStage: workflowStage,
      resumeAfterIssueStage: resumeAfterIssueStage,
      completedCommandIds: completedCommandIds,
      pendingSync: pendingSyncRaw as bool? ?? false,
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
    'workflowStage': workflowStage,
    'resumeAfterIssueStage': resumeAfterIssueStage,
    'completedCommandIds': completedCommandIds,
    'pendingSync': pendingSync,
  };

  static DeliveryStatus _parseDeliveryStatus(String raw) {
    for (final value in DeliveryStatus.values) {
      if (value.name == raw) return value;
    }
    throw FormatException('unknown delivery status: $raw');
  }

  static DriverWorkflowStage _parseWorkflowStage(String raw) {
    for (final value in DriverWorkflowStage.values) {
      if (value.name == raw) return value;
    }
    throw FormatException('unknown workflow stage: $raw');
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
          serverRevision == other.serverRevision &&
          workflowStage == other.workflowStage &&
          resumeAfterIssueStage == other.resumeAfterIssueStage &&
          _listEquals(completedCommandIds, other.completedCommandIds) &&
          pendingSync == other.pendingSync;

  @override
  int get hashCode => Object.hash(
    assignmentId,
    offerId,
    driverId,
    status,
    order,
    acceptedAt,
    serverRevision,
    workflowStage,
    resumeAfterIssueStage,
    Object.hashAll(completedCommandIds),
    pendingSync,
  );

  static bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
