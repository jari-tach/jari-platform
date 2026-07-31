/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.1.0
/// Source SHA: a54997590bb9e481b48e890c3a3d446f260e00e3
library;

import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/driver_profile_provenance.dart';
import '../../domain/entities/driver_status.dart';

final class DriverProfileWire {
  const DriverProfileWire({
    required this.driverId,
    required this.displayName,
    required this.phoneMasked,
    required this.locale,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.vehicleType,
  });

  final String driverId;
  final String displayName;
  final String phoneMasked;
  final String locale;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? vehicleType;

  factory DriverProfileWire.fromJson(Map<String, dynamic> json) {
    final driverId = json['driverId'];
    final displayName = json['displayName'];
    final phoneMasked = json['phoneMasked'];
    final locale = json['locale'];
    final status = json['status'];
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    if (driverId is! String ||
        displayName is! String ||
        phoneMasked is! String ||
        locale is! String ||
        status is! String ||
        createdAtRaw is! String ||
        updatedAtRaw is! String) {
      throw const FormatException('DriverProfileWire: invalid fields');
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    final updatedAt = DateTime.tryParse(updatedAtRaw);
    if (createdAt == null || updatedAt == null) {
      throw const FormatException('DriverProfileWire: date parse');
    }
    final vehicleType = json['vehicleType'];
    return DriverProfileWire(
      driverId: driverId,
      displayName: displayName,
      phoneMasked: phoneMasked,
      locale: locale,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      vehicleType: vehicleType is String ? vehicleType : null,
    );
  }

  DriverProfile toDomain() {
    final (account, employment) = _mapStatus(status);
    return DriverProfile(
      driverId: driverId,
      fullName: displayName,
      phoneNumber: phoneMasked,
      accountStatus: account,
      employmentStatus: employment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      vehicleType: vehicleType,
      provenance: DriverProfileProvenance.unknown,
    );
  }

  static (AccountStatus, EmploymentStatus) _mapStatus(String status) {
    switch (status) {
      case 'active':
        return (AccountStatus.verified, EmploymentStatus.active);
      case 'inactive':
        return (AccountStatus.verified, EmploymentStatus.inactive);
      case 'suspended':
        return (AccountStatus.suspended, EmploymentStatus.inactive);
      case 'pendingCompliance':
        return (AccountStatus.pending, EmploymentStatus.active);
      default:
        throw FormatException('DriverProfileWire: unknown status $status');
    }
  }
}
