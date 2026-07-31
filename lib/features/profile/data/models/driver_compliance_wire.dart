/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
library;

final class DriverComplianceWire {
  const DriverComplianceWire({
    required this.overallStatus,
    required this.requirements,
    required this.blockingReasons,
    required this.lastEvaluatedAt,
  });

  final String overallStatus;
  final List<ComplianceRequirementWire> requirements;
  final List<String> blockingReasons;
  final DateTime lastEvaluatedAt;

  factory DriverComplianceWire.fromJson(Map<String, dynamic> json) {
    final overallStatus = json['overallStatus'];
    final requirementsRaw = json['requirements'];
    final blockingRaw = json['blockingReasons'];
    final lastRaw = json['lastEvaluatedAt'];
    if (overallStatus is! String ||
        requirementsRaw is! List ||
        blockingRaw is! List ||
        lastRaw is! String) {
      throw const FormatException('DriverComplianceWire: invalid fields');
    }
    final lastEvaluatedAt = DateTime.tryParse(lastRaw);
    if (lastEvaluatedAt == null) {
      throw const FormatException('DriverComplianceWire: date parse');
    }
    return DriverComplianceWire(
      overallStatus: overallStatus,
      requirements: requirementsRaw
          .map(
            (e) => ComplianceRequirementWire.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(growable: false),
      blockingReasons: blockingRaw.map((e) => e.toString()).toList(),
      lastEvaluatedAt: lastEvaluatedAt,
    );
  }
}

final class ComplianceRequirementWire {
  const ComplianceRequirementWire({
    required this.code,
    required this.status,
    this.message,
  });

  final String code;
  final String status;
  final String? message;

  factory ComplianceRequirementWire.fromJson(Map<String, dynamic> json) {
    final code = json['code'];
    final status = json['status'];
    if (code is! String || status is! String) {
      throw const FormatException('ComplianceRequirementWire');
    }
    final message = json['message'];
    return ComplianceRequirementWire(
      code: code,
      status: status,
      message: message is String ? message : null,
    );
  }
}
