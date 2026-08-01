/// Wire mapping for Driver Availability (contracts Driver API).
///
/// Issue #32: Backend wire status `offline` means "driver not receiving
/// offers" (domain [AvailabilityStatus.unavailable]). Domain
/// [AvailabilityStatus.offline] is reserved for connectivity-offline
/// (ADR-017) and must never be confused with the Backend wire value.
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
        // Backend "offline" = not available for offers (not connectivity).
        return AvailabilityStatus.unavailable;
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
      case AvailabilityStatus.unavailable:
        return 'offline';
      case AvailabilityStatus.busy:
      case AvailabilityStatus.offline:
        // Connectivity-offline and busy are never PUT by the client.
        return null;
    }
  }
}
