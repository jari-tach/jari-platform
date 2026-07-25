import 'driver_profile_provenance.dart';
import 'driver_profile_update.dart';
import 'driver_status.dart';

/// Driver identity + profile (PHASE 2.3).
///
/// [businessId] and [branchId] are optional by design: Fake Auth / trial
/// sources may not provide them yet. Backend will be the source of truth
/// for tenant binding (BR-DRIVER-001). Clients must never invent or trust
/// self-assigned scopes for authorization.
///
/// Does NOT contain session tokens, passwords, or OTP codes.
class DriverProfile {
  const DriverProfile({
    required this.driverId,
    required this.fullName,
    required this.phoneNumber,
    required this.accountStatus,
    required this.employmentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.businessId,
    this.branchId,
    this.email,
    this.profileImageUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.provenance = DriverProfileProvenance.unknown,
  });

  final String driverId;

  /// Optional until Backend assigns the driver to a business (nullable OK).
  final String? businessId;

  /// Optional until Backend assigns the driver to a branch (nullable OK).
  final String? branchId;

  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? profileImageUrl;
  final AccountStatus accountStatus;
  final EmploymentStatus employmentStatus;
  final String? vehicleType;
  final String? vehiclePlate;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Domain-only origin marker. Not Drift-persisted. Never means verified
  /// production provenance.
  final DriverProfileProvenance provenance;

  bool get hasBusinessScope => businessId != null && businessId!.isNotEmpty;
  bool get hasBranchScope => branchId != null && branchId!.isNotEmpty;

  bool get isTrialSynthetic =>
      provenance == DriverProfileProvenance.trialSynthetic;

  /// Fields that must never be changed by client-side profile edits.
  static const sovereignFieldNames = {
    'driverId',
    'businessId',
    'branchId',
    'phoneNumber',
    'employmentStatus',
    'accountStatus',
    'createdAt',
  };

  /// Client-editable fields only (PHASE 2.3).
  static const clientEditableFieldNames = {
    'fullName',
    'email',
    'profileImageUrl',
  };

  /// Applies a non-sovereign [DriverProfileUpdate]. Sovereign fields,
  /// vehicle fields, and provenance are never taken from the update.
  DriverProfile applyClientUpdate(
    DriverProfileUpdate update, {
    DateTime? updatedAt,
  }) {
    if (!update.hasChanges) return this;

    final nextName = update.fullName?.trim();
    return copyWith(
      fullName: (nextName == null || nextName.isEmpty) ? null : nextName,
      email: update.email,
      profileImageUrl: update.profileImageUrl,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Client-safe copy: only [fullName], [email], [profileImageUrl], and
  /// [updatedAt] may change. Sovereign fields have no parameters here.
  DriverProfile copyWith({
    String? fullName,
    String? email,
    String? profileImageUrl,
    DateTime? updatedAt,
  }) {
    return DriverProfile(
      driverId: driverId,
      businessId: businessId,
      branchId: branchId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      accountStatus: accountStatus,
      employmentStatus: employmentStatus,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      provenance: provenance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverProfile &&
          driverId == other.driverId &&
          businessId == other.businessId &&
          branchId == other.branchId &&
          fullName == other.fullName &&
          phoneNumber == other.phoneNumber &&
          email == other.email &&
          profileImageUrl == other.profileImageUrl &&
          accountStatus == other.accountStatus &&
          employmentStatus == other.employmentStatus &&
          vehicleType == other.vehicleType &&
          vehiclePlate == other.vehiclePlate &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          provenance == other.provenance;

  @override
  int get hashCode => Object.hash(
    driverId,
    businessId,
    branchId,
    fullName,
    phoneNumber,
    email,
    profileImageUrl,
    accountStatus,
    employmentStatus,
    vehicleType,
    vehiclePlate,
    createdAt,
    updatedAt,
    provenance,
  );

  @override
  String toString() =>
      'DriverProfile(driverId: $driverId, businessId: $businessId, '
      'branchId: $branchId, accountStatus: $accountStatus, '
      'provenance: $provenance)';
}
