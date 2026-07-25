/// Allowed client-side profile updates (PHASE 2.3).
///
/// Sovereign fields (`driverId`, `businessId`, `branchId`, `phoneNumber`,
/// `employmentStatus`, `accountStatus`, `createdAt`) are intentionally
/// absent — mutations must go through Backend later.
class DriverProfileUpdate {
  const DriverProfileUpdate({this.fullName, this.email, this.profileImageUrl});

  final String? fullName;
  final String? email;
  final String? profileImageUrl;

  bool get hasChanges =>
      fullName != null || email != null || profileImageUrl != null;
}
