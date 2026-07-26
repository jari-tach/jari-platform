import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Supported locales
const List<Locale> supportedLocales = [
  Locale('en'),
  Locale('en', 'US'),
  Locale('ar'),
  Locale('ar', 'SA'),
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
/// - English (`en`)
/// - Arabic (`ar`) with Locale-driven RTL
///
/// Unsupported language codes fall back to English.
/// See `docs/localization/localization-guidelines.md`.
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
    Locale('en'),
    Locale('en', 'US'),
    Locale('ar'),
    Locale('ar', 'SA'),
  ];

  /// True when the active locale is Arabic (`languageCode == 'ar'`).
  bool get isArabic => locale.languageCode == 'ar';

  /// Shared bilingual helper — Arabic when [isArabic], otherwise English.
  String _t(String english, String arabic) => isArabic ? arabic : english;

  // —— App shell / brand ——
  /// Brand display name — Latin in English, Arabic short name in Arabic
  /// (aligned with [AppConstants.appName] = `سائق`).
  String get appName => _t('Saeq Driver', 'سائق');
  String get appTagline => _t('Delivery Made Simple', 'التوصيل صار أبسط');
  String get pageNotFound => _t('Page not found', 'الصفحة غير موجودة');
  String pageNotFoundWithUri(String uri) =>
      _t('Page not found: $uri', 'الصفحة غير موجودة: $uri');
  String get navHome => _t('Home', 'الرئيسية');
  String get navOrders => _t('Orders', 'الطلبات');
  String get navProfile => _t('Profile', 'الملف');
  String get navSettings => _t('Settings', 'الإعدادات');
  String get exploreArchitectureScreenTitle =>
      _t('Explore Architecture', 'استكشف الهيكلة');
  String get ordersScreenTitle => _t('Orders', 'الطلبات');
  String get settingsScreenTitle => _t('Settings', 'الإعدادات');
  String screenComingSoon(String title) =>
      _t('$title screen - Coming soon', 'شاشة $title — قريبًا');
  String get loadingEllipsis => _t('...', '...');
  String get loading => _t('Loading', 'جارٍ التحميل');

  // —— Welcome ——
  String get welcomeTitle =>
      _t('Welcome to Saeq Driver', 'مرحبًا بك في سائق صَعِق');
  String get welcomeSubtitle =>
      _t('Your reliable delivery partner', 'شريكك الموثوق للتوصيل');
  String get exploreArchitecture =>
      _t('Explore Architecture', 'استكشف الهيكلة');
  String get architectureTitle => _t('Clean Architecture', 'هيكلة نظيفة');
  String get architectureSubtitle => _t(
    'Scalable and maintainable codebase',
    'قاعدة برمجية قابلة للتوسع وسهلة الصيانة',
  );
  String get readyForGrowth => _t('Ready for Growth', 'جاهز للنمو');
  String get sharedDesignSystem =>
      _t('Shared Design System', 'نظام تصميم موحّد');
  String get servicesLayer => _t('Services Layer', 'طبقة الخدمات');
  String get apiReady => _t('API Ready', 'جاهز للربط مع الواجهة البرمجية');
  String get nextStepsTitle => _t('Next Steps', 'الخطوات التالية');
  String get nextStepsSubtitle =>
      _t('Connect API and start delivering', 'اربط الواجهة وابدأ التوصيل');
  String get nextStepsFocusMessage => _t(
    'Focus now on fundamentals and architecture before adding commercial features.',
    'التركيز الآن على الأساسيات والهيكلية قبل إضافة الميزات التجارية.',
  );

  // —— Authentication ——
  String get signIn => _t('Sign In', 'تسجيل الدخول');
  String get signOut => _t('Sign Out', 'تسجيل الخروج');
  String get loginTitle => _t('Driver Sign In', 'تسجيل دخول السائق');
  String get loginSubtitle => _t(
    'Enter your phone number to continue (trial mode)',
    'أدخل رقم جوالك للمتابعة (وضع تجريبي)',
  );
  String get phoneNumberLabel => _t('Phone number', 'رقم الجوال');

  /// Format hint — same pattern in both languages (Saudi mobile format).
  String get phoneNumberHint => '05XXXXXXXX';
  String get homeWelcomeTitle =>
      _t('Signed in successfully', 'تم تسجيل الدخول بنجاح');
  String get invalidPhoneNumberMessage => _t(
    'Please enter a valid phone number (05XXXXXXXX).',
    'يرجى إدخال رقم جوال صالح (05XXXXXXXX).',
  );
  String get authenticationRejectedMessage => _t(
    'Sign-in was rejected. Please try again.',
    'تم رفض تسجيل الدخول. حاول مجددًا.',
  );
  String get sessionExpiredMessage => _t(
    'Your session has expired. Please sign in again.',
    'انتهت جلستك. سجّل الدخول مجددًا.',
  );
  String get corruptedSessionMessage => _t(
    'Your saved session could not be read. Please sign in again.',
    'تعذر قراءة الجلسة المحفوظة. سجّل الدخول مجددًا.',
  );
  String get secureStorageFailureMessage => _t(
    'Could not access secure storage. Please try again.',
    'تعذر الوصول إلى التخزين الآمن. حاول مجددًا.',
  );
  String get unexpectedAuthErrorMessage =>
      _t('Something went wrong. Please try again.', 'حدث خطأ. حاول مجددًا.');

  // —— Profile ——
  String get profileTitle => _t('Profile', 'ملف السائق');
  String get profileRetry => _t('Retry', 'إعادة المحاولة');
  String get profileEmptyTitle => _t('No profile yet', 'لا يوجد ملف بعد');
  String get profileEmptyMessage => _t(
    'Your driver profile could not be found. Please try again.',
    'تعذر العثور على ملف السائق. حاول مجددًا.',
  );
  String get profileErrorTitle =>
      _t('Could not load profile', 'تعذر تحميل الملف');
  String get profileSessionExpiredTitle =>
      _t('Session expired', 'انتهت الجلسة');
  String get profileAccountStatus => _t('Account status', 'حالة الحساب');
  String get profileEmploymentStatus => _t('Employment status', 'حالة التوظيف');
  String get profileBusinessId => _t('Business', 'المنشأة');
  String get profileBranchId => _t('Branch', 'الفرع');
  String get profileVehicleType => _t('Vehicle', 'المركبة');
  String get profileScopeUnassigned => _t('Not assigned yet', 'غير معيّن بعد');
  String get profileStatusPending =>
      _t('Pending verification', 'بانتظار التحقق');
  String get profileStatusVerified => _t('Verified', 'موثَّق');
  String get profileStatusRejected => _t('Rejected', 'مرفوض');
  String get profileStatusSuspended => _t('Suspended', 'معلّق');
  String get profileEmploymentActive => _t('Active', 'نشط');
  String get profileEmploymentInactive => _t('Inactive', 'غير نشط');
  String get profileEmploymentOnLeave => _t('On leave', 'في إجازة');
  String get profileEmploymentTerminated => _t('Terminated', 'منتهي');
  String get profileUnauthenticatedMessage =>
      _t('Please sign in to view your profile.', 'سجّل الدخول لعرض ملفك.');
  String get profileForbiddenMessage => _t(
    'You do not have access to this profile.',
    'ليس لديك صلاحية لهذا الملف.',
  );
  String get profileInvalidDataMessage => _t(
    'Profile data is incomplete. Please try again.',
    'بيانات الملف غير مكتملة. حاول مجددًا.',
  );
  String get profileSovereignMutationMessage => _t(
    'Identity fields cannot be changed from the app.',
    'لا يمكن تغيير حقول الهوية من التطبيق.',
  );
  String get profileUnexpectedMessage => _t(
    'Something went wrong while loading your profile.',
    'حدث خطأ أثناء تحميل ملفك.',
  );

  // —— Availability (PHASE 2.4 / 2.4.1) ——
  String get availabilitySectionTitle => _t('Availability', 'التوفر');
  String get availabilityStatusUnavailable =>
      _t('Unavailable for new requests', 'غير متاح لاستقبال الطلبات');
  String get availabilityStatusUnavailableDetail => _t(
    'You will not receive new delivery requests.',
    'لن تستقبل طلبات توصيل جديدة.',
  );
  String get availabilityStatusConfirmedAvailable =>
      _t('Available for new requests', 'متاح لاستقبال الطلبات');
  String get availabilityStatusConfirmedAvailableDetail => _t(
    'Confirmed — you can receive delivery requests.',
    'مؤكَّد — يمكنك استقبال طلبات التوصيل.',
  );
  String get availabilityStatusPendingAvailable =>
      _t('Confirming availability', 'جارٍ تأكيد حالة التوفر');
  String get availabilityStatusPendingAvailableDetail => _t(
    'Your available status is pending confirmation.',
    'حالة التوفر بانتظار التأكيد.',
  );
  String get availabilityStatusRestoredAvailable => _t(
    'Restored previous status — confirmation needed',
    'تمت استعادة حالة سابقة — تحتاج إلى تأكيد',
  );
  String get availabilityStatusRestoredAvailableDetail => _t(
    'A previous available status was restored and is not confirmed.',
    'تمت استعادة حالة توفر سابقة وهي غير مؤكَّدة.',
  );
  String get availabilityStatusBusy =>
      _t('Busy with an active request', 'مشغول بطلب حالي');
  String get availabilityStatusBusyDetail => _t(
    'Availability cannot be changed while a request is in progress.',
    'لا يمكن تغيير الحالة أثناء تنفيذ طلب.',
  );
  String get availabilityStatusRestoredBusy => _t(
    'Restored busy status — awaiting verification',
    'تمت استعادة حالة مشغول — بانتظار التحقق',
  );
  String get availabilityStatusRestoredBusyDetail => _t(
    'A previous busy status was restored and is not freshly confirmed.',
    'تمت استعادة حالة مشغول سابقة وليست مؤكَّدة حديثًا.',
  );
  String get availabilityStatusOffline => _t('Offline', 'غير متصل');
  String get availabilityStatusOfflineDetail => _t(
    'Connect to the internet before going available.',
    'اتصل بالإنترنت قبل تفعيل استقبال الطلبات.',
  );
  String get availabilityStatusLoading =>
      _t('Loading availability', 'جارٍ تحميل حالة التوفر');
  String get availabilityStatusLoadingDetail => _t(
    'Please wait while availability is restored.',
    'يرجى الانتظار أثناء استعادة حالة التوفر.',
  );
  String get availabilityStatusProcessing =>
      _t('Updating availability', 'جارٍ تحديث الحالة');
  String get availabilityStatusInitial =>
      _t('Availability not ready', 'حالة التوفر غير جاهزة');
  String get availabilityStatusInitialDetail => _t(
    'Sign in and wait for availability to load before changing status.',
    'سجّل الدخول وانتظر تحميل حالة التوفر قبل تغييرها.',
  );
  String get availabilityChipConfirmed => _t('Confirmed', 'مؤكَّد');
  String get availabilityChipPending =>
      _t('Pending confirmation', 'بانتظار التأكيد');
  String get availabilityChipRestored =>
      _t('Restored — unconfirmed', 'مستعادة — غير مؤكَّدة');
  String get availabilityChipBusy => _t('Busy', 'مشغول');
  String get availabilityChipOffline => _t('Offline', 'غير متصل');
  String get availabilityActionGoAvailable =>
      _t('Start receiving requests', 'بدء استقبال الطلبات');
  String get availabilityActionGoUnavailable =>
      _t('Stop receiving requests', 'إيقاف استقبال الطلبات');
  String get availabilityActionRetry => _t('Retry', 'إعادة المحاولة');
  String get availabilityActionDismissFailure => _t('Dismiss', 'إغلاق');
  String get availabilityFailureUnauthenticated => _t(
    'Your session has ended. Sign in again.',
    'انتهت الجلسة. سجّل الدخول مجددًا.',
  );
  String get availabilityFailureSecurityDenied => _t(
    'This action could not be completed for account security reasons.',
    'تعذر تنفيذ الطلب لأسباب تتعلق بأمان الحساب.',
  );
  String get availabilityFailureProfileMissing => _t(
    'Driver account readiness could not be verified yet.',
    'تعذر التحقق من جاهزية حساب السائق حاليًا.',
  );
  String get availabilityFailureAccountSuspended => _t(
    'This account is suspended and cannot go available.',
    'هذا الحساب معلّق ولا يمكن تفعيل التوفر.',
  );
  String get availabilityFailureAccountInactive => _t(
    'This account is inactive and cannot go available.',
    'هذا الحساب غير نشط ولا يمكن تفعيل التوفر.',
  );
  String get availabilityFailureEmploymentIneligible => _t(
    'Employment status does not allow going available.',
    'حالة التوظيف لا تسمح بتفعيل التوفر.',
  );
  String get availabilityFailureAssignmentConflict => _t(
    'Availability cannot change while a request is in progress.',
    'لا يمكن تغيير الحالة أثناء تنفيذ طلب.',
  );
  String get availabilityFailureManualBusyDenied => _t(
    'Busy status cannot be selected manually.',
    'لا يمكن اختيار حالة مشغول يدويًا.',
  );
  String get availabilityFailureOffline => _t(
    'Connect to the internet before going available.',
    'اتصل بالإنترنت قبل تفعيل استقبال الطلبات.',
  );
  String get availabilityFailurePersistence => _t(
    'Could not save availability on this device.',
    'تعذر حفظ حالة التوفر على الجهاز.',
  );
  String get availabilityFailureStale => _t(
    'Availability changed elsewhere. Refresh and try again.',
    'تغيّرت الحالة في مكان آخر. حدّث الحالة وحاول مجددًا.',
  );
  String get availabilityFailureSyncConflict => _t(
    'Could not reconcile the current availability status.',
    'تعذر مطابقة حالة التوفر الحالية.',
  );
  String get availabilityFailureInvalidTransition => _t(
    'That availability change is not allowed.',
    'تغيير حالة التوفر هذا غير مسموح.',
  );
  String get availabilityFailureConfirmationRequired => _t(
    'Server confirmation is still required.',
    'ما زال التأكيد من الخادم مطلوبًا.',
  );
  String get availabilityFailureUnknown => _t(
    'Something went wrong while updating availability.',
    'حدث خطأ أثناء تحديث حالة التوفر.',
  );
  String get availabilitySemanticsStatus =>
      _t('Driver availability status', 'حالة توفر السائق');
  String get availabilitySemanticsAction =>
      _t('Availability primary action', 'الإجراء الأساسي للتوفر');
  String get availabilitySemanticsFailure =>
      _t('Availability message', 'رسالة التوفر');
  String get availabilitySemanticsProgress =>
      _t('Availability update in progress', 'جارٍ تحديث التوفر');
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
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// extension for easy access to localizations
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
