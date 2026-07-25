import '../../../../core/localization/app_localizations.dart';
import '../../domain/failures/availability_failure.dart';

/// Maps typed [AvailabilityFailure] values to localized UI copy.
///
/// Presentation-only — no domain policy, storage, or repository knowledge.
String availabilityFailureMessage(
  AvailabilityFailure failure,
  AppLocalizations l10n,
) {
  return switch (failure) {
    AvailabilityUnauthenticated() => l10n.availabilityFailureUnauthenticated,
    AvailabilitySecurityPolicyDenied() =>
      l10n.availabilityFailureSecurityDenied,
    DriverProfileMissing() => l10n.availabilityFailureProfileMissing,
    DriverAccountSuspended() => l10n.availabilityFailureAccountSuspended,
    DriverAccountInactive() => l10n.availabilityFailureAccountInactive,
    DriverEmploymentIneligible() =>
      l10n.availabilityFailureEmploymentIneligible,
    ActiveAssignmentConflict() => l10n.availabilityFailureAssignmentConflict,
    ManualBusyTransitionDenied() => l10n.availabilityFailureManualBusyDenied,
    AvailabilityOffline() => l10n.availabilityFailureOffline,
    AvailabilityPersistenceFailure() => l10n.availabilityFailurePersistence,
    AvailabilityStateStale() => l10n.availabilityFailureStale,
    AvailabilitySyncConflict() => l10n.availabilityFailureSyncConflict,
    InvalidAvailabilityTransition() =>
      l10n.availabilityFailureInvalidTransition,
    AvailabilityConfirmationRequired() =>
      l10n.availabilityFailureConfirmationRequired,
    AvailabilityUnknownFailure() => l10n.availabilityFailureUnknown,
  };
}
