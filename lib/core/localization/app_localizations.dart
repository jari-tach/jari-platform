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
