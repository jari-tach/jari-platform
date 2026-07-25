import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Supported locales
const List<Locale> supportedLocales = [
  Locale('en', 'US'), // English
  Locale('ar', 'SA'), // Arabic (Saudi Arabia)
];

/// Localization delegates
const List<LocalizationsDelegate> localizationsDelegates = [
  AppLocalizationsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// App localizations
///
/// Supports:
/// - English (en)
/// - Arabic (ar) with RTL support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Get current localizations instance
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Localizations delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ar', 'SA'),
  ];

  /// App name
  String get appName => 'Saeq Driver';

  /// App tagline
  String get appTagline => 'Delivery Made Simple';

  /// Welcome screen strings
  String get welcomeTitle => 'Welcome to Saeq Driver';
  String get welcomeSubtitle => 'Your reliable delivery partner';

  /// Architecture section
  String get exploreArchitecture => 'Explore Architecture';
  String get architectureTitle => 'Clean Architecture';
  String get architectureSubtitle => 'Scalable and maintainable codebase';

  /// Feature cards
  String get readyForGrowth => 'Ready for Growth';
  String get sharedDesignSystem => 'Shared Design System';
  String get servicesLayer => 'Services Layer';
  String get apiReady => 'API Ready';

  /// Next steps
  String get nextStepsTitle => 'Next Steps';
  String get nextStepsSubtitle => 'Connect API and start delivering';

  /// Authentication (PHASE 2.2 — trial/mock sign-in, no production backend)
  String get signIn => 'Sign In';
  String get signOut => 'Sign Out';
  String get loginTitle => 'Driver Sign In';
  String get loginSubtitle =>
      'Enter your phone number to continue (trial mode)';
  String get phoneNumberLabel => 'Phone number';
  String get phoneNumberHint => '05XXXXXXXX';
  String get homeWelcomeTitle => 'Signed in successfully';
  String get invalidPhoneNumberMessage =>
      'Please enter a valid phone number (05XXXXXXXX).';
  String get authenticationRejectedMessage =>
      'Sign-in was rejected. Please try again.';
  String get sessionExpiredMessage =>
      'Your session has expired. Please sign in again.';
  String get corruptedSessionMessage =>
      'Your saved session could not be read. Please sign in again.';
  String get secureStorageFailureMessage =>
      'Could not access secure storage. Please try again.';
  String get unexpectedAuthErrorMessage =>
      'Something went wrong. Please try again.';

  /// Profile (PHASE 2.3)
  String get profileTitle => 'Profile';
  String get profileRetry => 'Retry';
  String get profileEmptyTitle => 'No profile yet';
  String get profileEmptyMessage =>
      'Your driver profile could not be found. Please try again.';
  String get profileErrorTitle => 'Could not load profile';
  String get profileSessionExpiredTitle => 'Session expired';
  String get profileAccountStatus => 'Account status';
  String get profileEmploymentStatus => 'Employment status';
  String get profileBusinessId => 'Business';
  String get profileBranchId => 'Branch';
  String get profileVehicleType => 'Vehicle';
  String get profileScopeUnassigned => 'Not assigned yet';
  String get profileStatusPending => 'Pending verification';
  String get profileStatusVerified => 'Verified';
  String get profileStatusRejected => 'Rejected';
  String get profileStatusSuspended => 'Suspended';
  String get profileEmploymentActive => 'Active';
  String get profileEmploymentInactive => 'Inactive';
  String get profileEmploymentOnLeave => 'On leave';
  String get profileEmploymentTerminated => 'Terminated';
  String get profileUnauthenticatedMessage =>
      'Please sign in to view your profile.';
  String get profileForbiddenMessage =>
      'You do not have access to this profile.';
  String get profileInvalidDataMessage =>
      'Profile data is incomplete. Please try again.';
  String get profileSovereignMutationMessage =>
      'Identity fields cannot be changed from the app.';
  String get profileUnexpectedMessage =>
      'Something went wrong while loading your profile.';

  /// Availability (PHASE 2.4) — English strings match existing AppLocalizations
  /// convention (Arabic ARB migration remains deferred).
  String get availabilitySectionTitle => 'Availability';
  String get availabilityStatusUnavailable => 'Unavailable for new requests';
  String get availabilityStatusUnavailableDetail =>
      'You will not receive new delivery requests.';
  String get availabilityStatusConfirmedAvailable =>
      'Available for new requests';
  String get availabilityStatusConfirmedAvailableDetail =>
      'Confirmed — you can receive delivery requests.';
  String get availabilityStatusPendingAvailable => 'Confirming availability';
  String get availabilityStatusPendingAvailableDetail =>
      'Your available status is pending confirmation.';
  String get availabilityStatusRestoredAvailable =>
      'Restored previous status — confirmation needed';
  String get availabilityStatusRestoredAvailableDetail =>
      'A previous available status was restored and is not confirmed.';
  String get availabilityStatusBusy => 'Busy with an active request';
  String get availabilityStatusBusyDetail =>
      'Availability cannot be changed while a request is in progress.';
  String get availabilityStatusRestoredBusy =>
      'Restored busy status — awaiting verification';
  String get availabilityStatusRestoredBusyDetail =>
      'A previous busy status was restored and is not freshly confirmed.';
  String get availabilityStatusOffline => 'Offline';
  String get availabilityStatusOfflineDetail =>
      'Connect to the internet before going available.';
  String get availabilityStatusLoading => 'Loading availability';
  String get availabilityStatusLoadingDetail =>
      'Please wait while availability is restored.';
  String get availabilityStatusProcessing => 'Updating availability';
  String get availabilityStatusInitial => 'Availability not ready';
  String get availabilityStatusInitialDetail =>
      'Sign in and wait for availability to load before changing status.';
  String get availabilityChipConfirmed => 'Confirmed';
  String get availabilityChipPending => 'Pending confirmation';
  String get availabilityChipRestored => 'Restored — unconfirmed';
  String get availabilityChipBusy => 'Busy';
  String get availabilityChipOffline => 'Offline';
  String get availabilityActionGoAvailable => 'Start receiving requests';
  String get availabilityActionGoUnavailable => 'Stop receiving requests';
  String get availabilityActionRetry => 'Retry';
  String get availabilityActionDismissFailure => 'Dismiss';
  String get availabilityFailureUnauthenticated =>
      'Your session has ended. Sign in again.';
  String get availabilityFailureSecurityDenied =>
      'This action could not be completed for account security reasons.';
  String get availabilityFailureProfileMissing =>
      'Driver account readiness could not be verified yet.';
  String get availabilityFailureAccountSuspended =>
      'This account is suspended and cannot go available.';
  String get availabilityFailureAccountInactive =>
      'This account is inactive and cannot go available.';
  String get availabilityFailureEmploymentIneligible =>
      'Employment status does not allow going available.';
  String get availabilityFailureAssignmentConflict =>
      'Availability cannot change while a request is in progress.';
  String get availabilityFailureManualBusyDenied =>
      'Busy status cannot be selected manually.';
  String get availabilityFailureOffline =>
      'Connect to the internet before going available.';
  String get availabilityFailurePersistence =>
      'Could not save availability on this device.';
  String get availabilityFailureStale =>
      'Availability changed elsewhere. Refresh and try again.';
  String get availabilityFailureSyncConflict =>
      'Could not reconcile the current availability status.';
  String get availabilityFailureInvalidTransition =>
      'That availability change is not allowed.';
  String get availabilityFailureConfirmationRequired =>
      'Server confirmation is still required.';
  String get availabilityFailureUnknown =>
      'Something went wrong while updating availability.';
  String get availabilitySemanticsStatus => 'Driver availability status';
  String get availabilitySemanticsAction => 'Availability primary action';
  String get availabilitySemanticsFailure => 'Availability message';
  String get availabilitySemanticsProgress => 'Availability update in progress';
}

/// Localizations delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // In a real app, load translations from ARB files
    // For now, return instance with locale
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// extension for easy access to localizations
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
