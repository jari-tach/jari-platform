/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
library;

import '../../domain/entities/availability_status.dart';
import '../../domain/entities/driver_availability.dart';

final class DriverAvailabilityWire {
  const DriverAvailabilityWire({
    required this.status,
    required this.updatedAt,
    this.reason,
  });

  final String status;
  final DateTime updatedAt;
  final String? reason;

  factory DriverAvailabilityWire.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final updatedAtRaw = json['updatedAt'];
    if (status is! String || updatedAtRaw is! String) {
      throw const FormatException('DriverAvailabilityWire: invalid fields');
    }
    final updatedAt = DateTime.tryParse(updatedAtRaw);
    if (updatedAt == null) {
      throw const FormatException('DriverAvailabilityWire: date parse');
    }
    final reason = json['reason'];
    return DriverAvailabilityWire(
      status: status,
      updatedAt: updatedAt,
      reason: reason is String ? reason : null,
    );
  }

  DriverAvailability toDomain({required String driverId}) {
    return DriverAvailability(
      driverId: driverId,
      status: mapStatus(status),
      source: AvailabilitySource.server,
      lastChangedAt: updatedAt,
      lastConfirmedAt: updatedAt,
      pendingSync: false,
      reason: reason,
    );
  }

  static AvailabilityStatus mapStatus(String status) {
    switch (status) {
      case 'available':
        return AvailabilityStatus.available;
      case 'busy':
        return AvailabilityStatus.busy;
      case 'offline':
        return AvailabilityStatus.offline;
      case 'suspended':
        return AvailabilityStatus.unavailable;
      default:
        throw FormatException('DriverAvailabilityWire: unknown status $status');
    }
  }

  static String? toWireStatus(AvailabilityStatus status) {
    switch (status) {
      case AvailabilityStatus.available:
        return 'available';
      case AvailabilityStatus.offline:
        return 'offline';
      case AvailabilityStatus.busy:
      case AvailabilityStatus.unavailable:
        return null;
    }
  }
}
