import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [Locale('ar'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _values = {
    'ar': {
      'appName': 'سائق',
      'appTagline': 'منصّة توصيل ذكية',
      'welcomeTitle': 'مرحباً بك في البنية الأساسية لسائق',
      'welcomeSubtitle':
          'تم إعداد مشروع قابل للتوسع مع دعم عربي RTL وواجهة احترافية جاهزة للمستقبل.',
      'architectureTitle': 'بنية قابلة للتطوير',
      'architectureSubtitle':
          'تم فصل الميزات والأنظمة المشتركة والخدمات الخلفية لتسهيل التوسع إلى تطبيقات العميل والتاجر واللوحة الإدارية.',
      'nextStepsTitle': 'الخطوات القادمة',
      'nextStepsSubtitle':
          'سيتم إضافة طبقات الأعمال والتعامل مع البيانات لاحقاً بشكل تدريجي.',
      'exploreArchitecture': 'استكشف البنية',
      'readyForGrowth': 'جاهز للنمو',
      'sharedDesignSystem': 'نظام تصميم مشترك',
      'servicesLayer': 'طبقة خدمات موحدة',
      'apiReady': 'جاهز للـ API',
    },
    'en': {
      'appName': 'Saeq',
      'appTagline': 'Smart delivery platform',
      'welcomeTitle': 'Welcome to the Saeq foundation',
      'welcomeSubtitle':
          'A scalable app foundation has been prepared with Arabic RTL support and a professional UI ready for growth.',
      'architectureTitle': 'Scalable architecture',
      'architectureSubtitle':
          'Features, shared systems, and backend services are separated to support future expansion into customer, merchant, and admin experiences.',
      'nextStepsTitle': 'Next steps',
      'nextStepsSubtitle':
          'Business flows and data handling will be introduced gradually in upcoming phases.',
      'exploreArchitecture': 'Explore architecture',
      'readyForGrowth': 'Ready for growth',
      'sharedDesignSystem': 'Shared design system',
      'servicesLayer': 'Shared services layer',
      'apiReady': 'API-ready foundation',
    },
  };

  String get appName => _values[locale.languageCode]!['appName']!;
  String get appTagline => _values[locale.languageCode]!['appTagline']!;
  String get welcomeTitle => _values[locale.languageCode]!['welcomeTitle']!;
  String get welcomeSubtitle =>
      _values[locale.languageCode]!['welcomeSubtitle']!;
  String get architectureTitle =>
      _values[locale.languageCode]!['architectureTitle']!;
  String get architectureSubtitle =>
      _values[locale.languageCode]!['architectureSubtitle']!;
  String get nextStepsTitle => _values[locale.languageCode]!['nextStepsTitle']!;
  String get nextStepsSubtitle =>
      _values[locale.languageCode]!['nextStepsSubtitle']!;
  String get exploreArchitecture =>
      _values[locale.languageCode]!['exploreArchitecture']!;
  String get readyForGrowth => _values[locale.languageCode]!['readyForGrowth']!;
  String get sharedDesignSystem =>
      _values[locale.languageCode]!['sharedDesignSystem']!;
  String get servicesLayer => _values[locale.languageCode]!['servicesLayer']!;
  String get apiReady => _values[locale.languageCode]!['apiReady']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
