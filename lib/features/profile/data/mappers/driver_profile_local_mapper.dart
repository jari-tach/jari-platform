import 'package:drift/drift.dart';

import '../../../driver/data/datasources/local/driver_database.dart' as local;
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/driver_profile_provenance.dart';
import '../../domain/entities/driver_status.dart';
import '../../domain/entities/profile_error.dart';

/// Maps between domain [DriverProfile] and existing Drift `DriverProfiles`
/// rows (schema v1 — no businessId/branchId / provenance columns).
class DriverProfileLocalMapper {
  const DriverProfileLocalMapper._();

  static DriverProfile fromRow(local.DriverProfile row) {
    if (row.driverId.isEmpty || row.name.isEmpty || row.phone.isEmpty) {
      throw const ProfileInvalidDataError();
    }

    return DriverProfile(
      driverId: row.driverId,
      // Not stored in Drift v1 — reserved for Backend-assigned scopes.
      businessId: null,
      branchId: null,
      fullName: row.name,
      phoneNumber: row.phone,
      email: row.email,
      profileImageUrl: row.profileImageUrl,
      accountStatus: row.isActive == 1
          ? AccountStatus.pending
          : AccountStatus.suspended,
      employmentStatus: row.isActive == 1
          ? EmploymentStatus.active
          : EmploymentStatus.inactive,
      vehicleType: row.vehicleType.isEmpty ? null : row.vehicleType,
      vehiclePlate: row.vehiclePlate.isEmpty ? null : row.vehiclePlate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      // Provenance is domain-only; cache rows are not verified production data.
      provenance: DriverProfileProvenance.unknown,
    );
  }

  static local.DriverProfilesCompanion toCompanion(DriverProfile profile) {
    return local.DriverProfilesCompanion(
      driverId: Value(profile.driverId),
      name: Value(profile.fullName),
      phone: Value(profile.phoneNumber),
      email: Value(profile.email),
      vehicleType: Value(profile.vehicleType ?? ''),
      vehiclePlate: Value(profile.vehiclePlate ?? ''),
      licenseNumber: const Value(''),
      profileImageUrl: Value(profile.profileImageUrl),
      isActive: Value(
        profile.employmentStatus == EmploymentStatus.active ||
                profile.accountStatus != AccountStatus.suspended
            ? 1
            : 0,
      ),
      createdAt: Value(profile.createdAt),
      updatedAt: Value(profile.updatedAt),
    );
  }
}
