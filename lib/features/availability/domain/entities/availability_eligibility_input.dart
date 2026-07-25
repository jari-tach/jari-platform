import '../../../profile/domain/entities/driver_status.dart';

/// Immutable input for [AvailabilityEligibilityPolicy] (PHASE 2.4).
class AvailabilityEligibilityInput {
  const AvailabilityEligibilityInput({
    required this.authenticated,
    required this.profileExists,
    required this.accountStatus,
    required this.employmentStatus,
    required this.hasActiveAssignment,
    required this.connectivityAvailable,
    required this.securityPolicyAllows,
    this.locationPermissionGranted,
  });

  final bool authenticated;
  final bool profileExists;
  final AccountStatus accountStatus;
  final EmploymentStatus employmentStatus;
  final bool hasActiveAssignment;
  final bool connectivityAvailable;

  /// When false, eligibility for confirmed available is denied (BR-AVAIL-013).
  final bool securityPolicyAllows;

  /// Architecture: location is deferred for PHASE 2.4 — ignored by policy.
  final bool? locationPermissionGranted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityEligibilityInput &&
          authenticated == other.authenticated &&
          profileExists == other.profileExists &&
          accountStatus == other.accountStatus &&
          employmentStatus == other.employmentStatus &&
          hasActiveAssignment == other.hasActiveAssignment &&
          connectivityAvailable == other.connectivityAvailable &&
          securityPolicyAllows == other.securityPolicyAllows &&
          locationPermissionGranted == other.locationPermissionGranted;

  @override
  int get hashCode => Object.hash(
    authenticated,
    profileExists,
    accountStatus,
    employmentStatus,
    hasActiveAssignment,
    connectivityAvailable,
    securityPolicyAllows,
    locationPermissionGranted,
  );
}

/// Suggested next step when eligibility is denied.
enum AvailabilityRequiredAction {
  none,
  signIn,
  completeProfile,
  waitConnectivity,
  contactSupport,
  waitAssignment,
}
