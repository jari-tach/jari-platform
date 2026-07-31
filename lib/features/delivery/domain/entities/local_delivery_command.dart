/// STEP 3 local command categories. They are not Backend contracts.
enum LocalDeliveryCommandType {
  acceptOffer,
  rejectOffer,
  confirmPickup,
  reportArrival,
  confirmDelivery,
  reportIssue,
  cancel,
}

enum LocalDeliveryCommandStatus { pendingSync, completed }

/// Restart-safe local command ledger entry.
class LocalDeliveryCommand {
  const LocalDeliveryCommand({
    required this.commandId,
    required this.driverId,
    required this.targetId,
    required this.type,
    required this.status,
    required this.recordedAt,
    this.payload,
  });

  final String commandId;
  final String driverId;
  final String targetId;
  final LocalDeliveryCommandType type;
  final LocalDeliveryCommandStatus status;
  final DateTime recordedAt;

  /// Optional replay payload (STEP 5D-1). Must never contain PII or tokens.
  final Map<String, Object?>? payload;

  bool matches({
    required String driverId,
    required String targetId,
    required LocalDeliveryCommandType type,
  }) =>
      this.driverId == driverId &&
      this.targetId == targetId &&
      this.type == type;

  LocalDeliveryCommand copyWith({LocalDeliveryCommandStatus? status}) =>
      LocalDeliveryCommand(
        commandId: commandId,
        driverId: driverId,
        targetId: targetId,
        type: type,
        status: status ?? this.status,
        recordedAt: recordedAt,
        payload: payload,
      );
}
