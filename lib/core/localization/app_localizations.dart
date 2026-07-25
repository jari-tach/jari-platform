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
