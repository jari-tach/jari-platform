/// Typed availability failures (PHASE 2.4). Safe for logs — no tokens/PII.
sealed class AvailabilityFailure implements Exception {
  const AvailabilityFailure(this.message);

  final String message;

  /// Deterministic machine-readable identity (BR-AVAIL-011).
  String get code;

  @override
  String toString() => '[$code] $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityFailure &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, code, message);
}

final class AvailabilityUnauthenticated extends AvailabilityFailure {
  const AvailabilityUnauthenticated([
    super.message = 'Authenticated session required for availability.',
  ]);

  @override
  String get code => 'availability.unauthenticated';
}

final class DriverProfileMissing extends AvailabilityFailure {
  const DriverProfileMissing([
    super.message = 'Driver profile is required before available.',
  ]);

  @override
  String get code => 'availability.profile_missing';
}

final class DriverAccountSuspended extends AvailabilityFailure {
  const DriverAccountSuspended([
    super.message = 'Suspended account cannot become available.',
  ]);

  @override
  String get code => 'availability.account_suspended';
}

final class DriverAccountInactive extends AvailabilityFailure {
  const DriverAccountInactive([
    super.message = 'Inactive or blocked account cannot become available.',
  ]);

  @override
  String get code => 'availability.account_inactive';
}

final class DriverEmploymentIneligible extends AvailabilityFailure {
  const DriverEmploymentIneligible([
    super.message = 'Employment status is not eligible for available.',
  ]);

  @override
  String get code => 'availability.employment_ineligible';
}

final class ActiveAssignmentConflict extends AvailabilityFailure {
  const ActiveAssignmentConflict([
    super.message = 'Active assignment prevents this availability transition.',
  ]);

  @override
  String get code => 'availability.active_assignment_conflict';
}

final class ManualBusyTransitionDenied extends AvailabilityFailure {
  const ManualBusyTransitionDenied([
    super.message = 'Drivers cannot select busy manually.',
  ]);

  @override
  String get code => 'availability.manual_busy_denied';
}

final class InvalidAvailabilityTransition extends AvailabilityFailure {
  const InvalidAvailabilityTransition([
    super.message = 'Availability transition is not allowed.',
  ]);

  @override
  String get code => 'availability.invalid_transition';
}

final class AvailabilityOffline extends AvailabilityFailure {
  const AvailabilityOffline([
    super.message =
        'Confirmed available requires connectivity; offline→available denied.',
  ]);

  @override
  String get code => 'availability.offline';
}

final class AvailabilityConfirmationRequired extends AvailabilityFailure {
  const AvailabilityConfirmationRequired([
    super.message = 'Server or online confirmation is required.',
  ]);

  @override
  String get code => 'availability.confirmation_required';
}

final class AvailabilityStateStale extends AvailabilityFailure {
  const AvailabilityStateStale([
    super.message = 'Local availability state is stale.',
  ]);

  @override
  String get code => 'availability.state_stale';
}

final class AvailabilitySyncConflict extends AvailabilityFailure {
  const AvailabilitySyncConflict([
    super.message = 'Local and server availability conflict.',
  ]);

  @override
  String get code => 'availability.sync_conflict';
}

final class AvailabilityPersistenceFailure extends AvailabilityFailure {
  const AvailabilityPersistenceFailure([
    super.message = 'Failed to persist availability state.',
  ]);

  @override
  String get code => 'availability.persistence_failure';
}

final class AvailabilitySecurityPolicyDenied extends AvailabilityFailure {
  const AvailabilitySecurityPolicyDenied([
    super.message =
        'Security policy denied availability (e.g. release fake path).',
  ]);

  @override
  String get code => 'availability.security_policy_denied';
}

final class AvailabilityUnknownFailure extends AvailabilityFailure {
  const AvailabilityUnknownFailure([
    super.message = 'Unexpected availability failure.',
  ]);

  @override
  String get code => 'availability.unknown';
}
