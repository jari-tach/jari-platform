import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saeq_driver/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations language selection', () {
    test('English getters return English', () {
      final l10n = AppLocalizations(const Locale('en', 'US'));
      expect(l10n.isArabic, isFalse);
      expect(l10n.signIn, 'Sign In');
      expect(l10n.signOut, 'Sign Out');
      expect(l10n.loginTitle, 'Driver Sign In');
      expect(l10n.profileTitle, 'Profile');
      expect(l10n.homeWelcomeTitle, 'Signed in successfully');
      expect(l10n.navHome, 'Home');
      expect(l10n.availabilitySectionTitle, 'Availability');
      expect(l10n.nextStepsFocusMessage, contains('fundamentals'));
      expect(l10n.pageNotFound, 'Page not found');
    });

    test('Arabic getters return Arabic', () {
      final l10n = AppLocalizations(const Locale('ar'));
      expect(l10n.isArabic, isTrue);
      expect(l10n.signIn, 'تسجيل الدخول');
      expect(l10n.signOut, 'تسجيل الخروج');
      expect(l10n.loginTitle, 'تسجيل دخول السائق');
      expect(l10n.profileTitle, 'ملف السائق');
      expect(l10n.homeWelcomeTitle, 'تم تسجيل الدخول بنجاح');
      expect(l10n.navHome, 'الرئيسية');
      expect(l10n.availabilitySectionTitle, 'التوفر');
      expect(l10n.nextStepsFocusMessage, contains('الأساسيات'));
      expect(l10n.pageNotFound, 'الصفحة غير موجودة');
      expect(l10n.invalidPhoneNumberMessage, contains('جوال'));
      expect(l10n.profileEmptyTitle, 'لا يوجد ملف بعد');
      expect(l10n.availabilityActionRetry, 'إعادة المحاولة');
    });

    test('unsupported locale falls back to English', () {
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.isArabic, isFalse);
      expect(l10n.signIn, 'Sign In');
      expect(l10n.profileRetry, 'Retry');
      expect(l10n.availabilityChipBusy, 'Busy');
    });

    test('ar_SA uses Arabic', () {
      final l10n = AppLocalizations(const Locale('ar', 'SA'));
      expect(l10n.isArabic, isTrue);
      expect(l10n.navSettings, 'الإعدادات');
    });

    test('representative getters are non-empty in both locales', () {
      final en = AppLocalizations(const Locale('en'));
      final ar = AppLocalizations(const Locale('ar'));
      final getters = <String Function(AppLocalizations)>[
        (l) => l.appName,
        (l) => l.appTagline,
        (l) => l.welcomeTitle,
        (l) => l.signIn,
        (l) => l.loginSubtitle,
        (l) => l.invalidPhoneNumberMessage,
        (l) => l.authenticationRejectedMessage,
        (l) => l.sessionExpiredMessage,
        (l) => l.profileTitle,
        (l) => l.profileEmptyMessage,
        (l) => l.profileUnexpectedMessage,
        (l) => l.homeWelcomeTitle,
        (l) => l.availabilitySectionTitle,
        (l) => l.availabilityFailureUnknown,
        (l) => l.availabilitySemanticsStatus,
        (l) => l.navOrders,
        (l) => l.loading,
        (l) => l.nextStepsFocusMessage,
      ];
      for (final getter in getters) {
        expect(getter(en).trim(), isNotEmpty);
        expect(getter(ar).trim(), isNotEmpty);
      }
    });

    test('brand appName is locale-appropriate', () {
      expect(AppLocalizations(const Locale('en')).appName, 'Saeq Driver');
      expect(AppLocalizations(const Locale('ar')).appName, 'سائق');
    });

    test('phone format hint is shared (documented exception)', () {
      expect(
        AppLocalizations(const Locale('en')).phoneNumberHint,
        '05XXXXXXXX',
      );
      expect(
        AppLocalizations(const Locale('ar')).phoneNumberHint,
        '05XXXXXXXX',
      );
    });
  });
}
