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
  String get appTagline => _t(
    'Professional delivery for drivers',
    'منصة التوصيل الاحترافية للسائقين',
  );
  String get pageNotFound => _t('Page not found', 'الصفحة غير موجودة');
  String pageNotFoundWithUri(String uri) =>
      _t('Page not found: $uri', 'الصفحة غير موجودة: $uri');
  String get navHome => _t('Home', 'الرئيسية');
  String get navDeliveries => _t('Deliveries', 'التوصيلات');
  String get navEarnings => _t('Earnings', 'الأرباح');
  String get navNotifications => _t('Alerts', 'التنبيهات');
  String get navProfile => _t('Profile', 'الملف');
  String get navSettings => _t('Settings', 'الإعدادات');

  /// Legacy alias — bottom nav now uses [navDeliveries].
  String get navOrders => navDeliveries;
  String get exploreArchitectureScreenTitle =>
      _t('Explore Architecture', 'استكشف الهيكلة');
  String get deliveriesScreenTitle => _t('Deliveries', 'التوصيلات');
  String get earningsScreenTitle => _t('Earnings', 'الأرباح');
  String get notificationsScreenTitle => _t('Notifications', 'الإشعارات');
  String get ordersScreenTitle => deliveriesScreenTitle;
  String get settingsScreenTitle => _t('Settings', 'الإعدادات');
  String get supportScreenTitle => _t('Support', 'الدعم');
  String get activeDeliveryScreenTitle =>
      _t('Active delivery', 'التوصيل النشط');
  String get deliveryVerifyScreenTitle =>
      _t('Verify delivery', 'تأكيد التسليم');
  String get deliveryIssueScreenTitle =>
      _t('Report an issue', 'الإبلاغ عن مشكلة');
  String get deliveryMapsAction => _t('Copy maps link', 'نسخ رابط الخرائط');
  String get deliveryMapsCopied =>
      _t('Maps link copied', 'تم نسخ رابط الخرائط');
  String get deliveryReportIssueAction =>
      _t('Report a problem', 'الإبلاغ عن مشكلة');
  String get deliveryResumeIssueAction =>
      _t('Resume delivery', 'استئناف التوصيل');
  String get deliveryVerifyCodeLabel => _t('Delivery code', 'رمز التسليم');
  String get deliveryVerifyCodeHint => '1234';
  String get deliveryVerifySubmit => _t('Confirm code', 'تأكيد الرمز');
  String get deliveryVerifyHintMessage => _t(
    'Enter the trial delivery code (Fake).',
    'أدخل رمز التسليم التجريبي (وهمي).',
  );
  String get deliveryDismissSummary =>
      _t('Finish and return home', 'إنهاء والعودة للرئيسية');
  String get deliveryIssueCategoryDelay =>
      _t('Unexpected delay', 'تأخير غير متوقع');
  String get deliveryIssueCategoryMerchant =>
      _t('Merchant issue', 'مشكلة لدى التاجر');
  String get deliveryIssueCategoryCustomer =>
      _t('Customer issue', 'مشكلة لدى العميل');
  String get deliveryIssueCategoryOther => _t('Other', 'أخرى');
  String get deliveryIssueSubmit => _t('Submit issue', 'إرسال البلاغ');
  String get deliveryStageAssigned => _t('Assigned', 'تم التعيين');
  String get deliveryStageNavPickup => _t('To pickup', 'إلى نقطة الاستلام');
  String get deliveryStageArrivedPickup => _t('At pickup', 'عند الاستلام');
  String get deliveryStageWaitingPickup =>
      _t('Waiting for order', 'بانتظار الطلب');
  String get deliveryStageCollected => _t('Collected', 'تم الاستلام');
  String get deliveryStageNavCustomer => _t('To customer', 'إلى العميل');
  String get deliveryStageArrivedCustomer => _t('At customer', 'عند العميل');
  String get deliveryStageVerifying => _t('Verifying', 'جارٍ التحقق');
  String get deliveryStageDelivered => _t('Delivered', 'تم التسليم');
  String get deliveryStageSummary => _t('Summary', 'الملخص');
  String get deliveryStageIssueOpen => _t('Issue open', 'مشكلة مفتوحة');
  String get deliveryActionStartPickup =>
      _t('Start trip to pickup', 'بدء التوجه للاستلام');
  String get deliveryActionArrivedPickup =>
      _t('I arrived at pickup', 'وصلت لنقطة الاستلام');
  String get deliveryActionWaitPickup =>
      _t('Waiting for handoff', 'بانتظار التسليم من التاجر');
  String get deliveryActionConfirmPickup =>
      _t('Confirm pickup', 'تأكيد الاستلام');
  String get deliveryActionStartCustomer =>
      _t('Start trip to customer', 'بدء التوجه للعميل');
  String get deliveryActionArrivedCustomer =>
      _t('I arrived at customer', 'وصلت للعميل');
  String get deliveryActionStartVerify =>
      _t('Enter delivery code', 'إدخال رمز التسليم');
  String get deliveryActionShowSummary => _t('View summary', 'عرض الملخص');
  String get deliveryWorkflowFailureMessage =>
      _t('This step is not available right now.', 'هذه الخطوة غير متاحة الآن.');
  String get deliveryVerificationFailureMessage => _t(
    'Invalid delivery code. Try again.',
    'رمز التسليم غير صالح. حاول مجددًا.',
  );
  String screenComingSoon(String title) =>
      _t('$title screen - Coming soon', 'شاشة $title — قريبًا');
  String get shellPlaceholderMessage => _t(
    'This section will be ready in a later increment.',
    'هذا القسم سيكون جاهزًا في زيادة لاحقة.',
  );
  String get loadingEllipsis => _t('...', '...');
  String get loading => _t('Loading', 'جارٍ التحميل');
  String get cancelAction => _t('Cancel', 'إلغاء');
  String get confirmAction => _t('Confirm', 'تأكيد');
  String get offlineBannerMessage => _t(
    'You are offline. Some actions may be unavailable.',
    'أنت غير متصل. قد تكون بعض الإجراءات غير متاحة.',
  );

  // —— History / Earnings / Notifications (PHASE 2.6 Inc 3) ——
  String get historyFilterAll => _t('All', 'الكل');
  String get historyFilterDelivered => _t('Delivered', 'مُسلَّم');
  String get historyFilterCancelled => _t('Cancelled', 'ملغى');
  String get historyStatusDelivered => _t('Delivered', 'مُسلَّم');
  String get historyStatusCancelled => _t('Cancelled', 'ملغى');
  String get historyEmptyTitle =>
      _t('No deliveries yet', 'لا توجد توصيلات بعد');
  String get historyEmptyMessage =>
      _t('Completed trips will appear here.', 'ستظهر الرحلات المكتملة هنا.');
  String get historyErrorTitle =>
      _t('Could not load history', 'تعذر تحميل السجل');
  String get historyErrorMessage =>
      _t('Please try again.', 'يرجى المحاولة مجددًا.');
  String get historyDetailTitle => _t('Delivery details', 'تفاصيل التوصيل');

  String get earningsFilterAll => _t('All', 'الكل');
  String get earningsFilterToday => _t('Today', 'اليوم');
  String get earningsFilterWeek => _t('This week', 'هذا الأسبوع');
  String get earningsFilterMonth => _t('This month', 'هذا الشهر');
  String get earningsEmptyTitle => _t('No earnings yet', 'لا توجد أرباح بعد');
  String get earningsEmptyMessage =>
      _t('Earnings summaries will appear here.', 'ستظهر ملخصات الأرباح هنا.');
  String get earningsErrorTitle =>
      _t('Could not load earnings', 'تعذر تحميل الأرباح');
  String get earningsErrorMessage =>
      _t('Please try again.', 'يرجى المحاولة مجددًا.');
  String get earningsDetailTitle => _t('Earnings details', 'تفاصيل الأرباح');

  String get notificationsEmptyTitle =>
      _t('No notifications', 'لا توجد إشعارات');
  String get notificationsEmptyMessage =>
      _t('Updates will appear here.', 'ستظهر التحديثات هنا.');
  String get notificationsErrorTitle =>
      _t('Could not load notifications', 'تعذر تحميل الإشعارات');
  String get notificationsErrorMessage =>
      _t('Please try again.', 'يرجى المحاولة مجددًا.');
  String get notificationDetailTitle => _t('Notification', 'إشعار');
  String get notificationRead => _t('Read', 'مقروء');
  String get notificationUnread => _t('Unread', 'غير مقروء');
  String get notificationMarkRead => _t('Mark as read', 'تعليمليم كمقروء');
  String get notificationTitleOffer =>
      _t('New delivery offer', 'عرض توصيل جديد');
  String get notificationTitlePayout => _t('Payout update', 'تحديث الأرباح');
  String get notificationTitleSystem => _t('System notice', 'تنبيه النظام');
  String get notificationBodyOffer => _t(
    'A new offer is available while you are online.',
    'يتوفر عرض جديد أثناء اتصالك.',
  );
  String get notificationBodyPayout => _t(
    'Your trial earnings summary was updated.',
    'تم تحديث ملخص أرباحك التجريبي.',
  );
  String get notificationBodySystem => _t(
    'Keep the app updated for the best experience.',
    'أبقِ التطبيق محدّثًا لأفضل تجربة.',
  );

  // —— Splash / Onboarding / Welcome (Phase 2.6 Batch 2) ——
  String get splashTitle => _t('Saeq Driver', 'سائق سايق');
  String get splashSubtitle =>
      _t('Professional delivery platform', 'منصة التوصيل الاحترافية');
  String get splashTapToContinue => _t('Tap to continue', 'اضغط للمتابعة');
  String get onboardingTitle => _t('Welcome to Saeq', 'مرحباً بك في سايق');
  String get onboardingSubtitle => _t(
    'Track offers, earn with confidence, and manage deliveries easily.',
    'تابع الطلبات، اربح بثقة، وادِر توصيلاتك بسهولة.',
  );
  String get onboardingContinueAction => _t('Continue', 'متابعة');
  String get onboardingSkipAction => _t('Skip', 'تخطي');
  String get backAction => _t('Back', 'رجوع');
  String get changePhoneAction =>
      _t('Change mobile number', 'تغيير رقم الجوال');
  String get sessionExpiredTitle => _t('Session expired', 'انتهت الجلسة');
  String get sessionExpiredLoginAgain => _t('Sign in', 'تسجيل الدخول');
  String get simulateSessionExpiredAction =>
      _t('Simulate session expired', 'محاكاة انتهاء الجلسة');

  // —— Welcome / First Launch (Figma Final/Auth/First Launch) ——
  String get firstLaunchTitle => _t('Saeq Driver', 'سائق سايق');
  String get firstLaunchSubtitle => _t(
    'Professional delivery platform for drivers',
    'منصة التوصيل الاحترافية للسائقين',
  );
  String get firstLaunchStartAction => _t('Start', 'ابدأ');
  String get firstLaunchSwitchToEnglish => _t('English', 'English');
  String get firstLaunchSwitchToArabic => _t('العربية', 'العربية');
  String get welcomeTitle => firstLaunchTitle;
  String get welcomeSubtitle => firstLaunchSubtitle;
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
  String get signOutConfirmTitle => _t('Sign out?', 'تسجيل الخروج؟');
  String get signOutConfirmMessage => _t(
    'You will need to sign in again to receive delivery offers.',
    'ستحتاج لتسجيل الدخول مجددًا لاستقبال عروض التوصيل.',
  );
  String get loginTitle => _t('Sign in', 'تسجيل الدخول');
  String get loginSubtitle =>
      _t('Enter your Saudi mobile number', 'أدخل رقم الجوال السعودي');
  String get phoneNumberLabel => _t('Mobile number', 'رقم الجوال');

  /// Format hint — same pattern in both languages (Saudi mobile format).
  String get phoneNumberHint => '05xxxxxxxx';
  String get homeWelcomeTitle => _t('Welcome back', 'مرحبًا بعودتك');
  String get homeTodayEarningsLabel => _t("Today's earnings", 'أرباح اليوم');
  String get homeTripsTodayLabel => _t('Trips today', 'رحلات اليوم');
  String get homeAcceptanceRateLabel => _t('Acceptance rate', 'نسبة القبول');
  String homeEarningsValue(String amount) => _t('SAR $amount', '$amount ر.س');
  String homeTripsValue(int count) => _t('$count trips', '$count رحلة');
  String homeAcceptanceValue(int percent) => _t('$percent%', '$percent%');
  String get homeQuickActionsTitle => _t('Quick actions', 'إجراءات سريعة');
  String get homeQuickActionDeliveries =>
      _t('View deliveries', 'عرض التوصيلات');
  String get homeQuickActionEarnings => _t('View earnings', 'عرض الأرباح');
  String get homeQuickActionNotifications => _t('Notifications', 'الإشعارات');
  String get homeOpenNotificationsTooltip =>
      _t('Open notifications', 'فتح الإشعارات');
  String get homeSummarySectionTitle => _t("Today's summary", 'ملخص اليوم');

  /// Shown when Home has no offer/assignment banner (Final/Home/Available).
  String get homeNoOfferMessage =>
      _t('No offer right now', 'لا يوجد عرض حالياً');

  /// Legacy key kept for older tests; prefer [homeSummarySectionTitle].
  String get homeFakeSummaryHint => homeSummarySectionTitle;
  String get fakeAlphaDataHint =>
      _t('Trial data for preview only', 'بيانات تجريبية للعرض فقط');
  String get availabilityOpenActiveDeliveryAction =>
      _t('Open active delivery', 'فتح التوصيل النشط');
  String get invalidPhoneNumberMessage =>
      _t('Invalid mobile number', 'رقم الجوال غير صالح');
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
  String get secureStorageFailureTitle => _t('Could not save', 'تعذر الحفظ');
  String get secureStorageFailureMessage => _t(
    'Could not save the session on this device',
    'تعذر حفظ الجلسة على الجهاز',
  );
  String get networkFailureTitle => _t('Connection failed', 'تعذر الاتصال');
  String get networkFailureMessage => _t(
    'Check your network, then try again',
    'تحقق من الشبكة ثم أعد المحاولة',
  );
  String get rateLimitTitle => _t('Limit exceeded', 'تم تجاوز الحد');
  String get otpRateLimitedMessage => _t(
    'Too many send attempts. Try again later.',
    'تم تجاوز عدد محاولات الإرسال. حاول لاحقاً.',
  );
  String get authRetryAction => _t('Try again', 'إعادة المحاولة');
  String get unexpectedAuthErrorMessage =>
      _t('Something went wrong. Please try again.', 'حدث خطأ. حاول مجددًا.');

  String get otpTitle => _t('Enter verification code', 'أدخل رمز التحقق');
  String get otpSubtitle => _t(
    'Enter the 6-digit code sent to your phone.',
    'أدخل الرمز المكوّن من 6 أرقام المرسل إلى جوالك.',
  );
  String otpSentToMasked(String maskedPhone) =>
      _t('We sent a code to $maskedPhone', 'أرسلنا رمزاً إلى $maskedPhone');
  String get otpCodeLabel => _t('Verification code', 'رمز التحقق');
  String get otpCodeHint => _t('6-digit code', 'رمز من 6 أرقام');
  String get otpVerifyAction => _t('Verify', 'تحقق');
  String get otpResendAction => _t('Resend', 'إعادة الإرسال');
  String otpResendCooldown(int seconds) =>
      otpResendCountdown(_formatSecondsAsMmSs(seconds));
  String otpResendCountdown(String mmSs) =>
      _t('Resend in $mmSs', 'إعادة الإرسال خلال $mmSs');
  String get otpResendReadyMessage =>
      _t('You can resend now', 'يمكنك إعادة الإرسال الآن');
  String _formatSecondsAsMmSs(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final m = (safe ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get invalidOtpMessage => _t('Incorrect code', 'رمز غير صحيح');
  String get expiredOtpMessage => _t('Code expired', 'انتهت صلاحية الرمز');
  String get incompleteOtpMessage => _t(
    'Enter the full 6-digit code.',
    'أدخل الرمز المكوّن من 6 أرقام كاملًا.',
  );
  String get otpRequestAction => _t('Send code', 'إرسال رمز التحقق');

  // —— Profile ——
  String get profileTitle => _t('Profile', 'الملف الشخصي');
  String get profileOpenSettings => _t('Settings', 'الإعدادات');
  String get profileOpenSupport => _t('Support', 'الدعم');
  String get profileMenuVehicle => _t('Vehicle', 'المركبة');
  String get profileMenuDocuments => _t('Documents', 'المستندات');
  String get profileMenuSafety => _t('Safety', 'السلامة');
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
  String get profileEditAction => _t('Edit profile', 'تعديل الملف');
  String get profileEditTitle => _t('Edit profile', 'تعديل الملف');
  String get profileEditFullNameLabel => _t('Full name', 'الاسم الكامل');
  String get profileEditFullNameRequired =>
      _t('Full name is required.', 'الاسم الكامل مطلوب.');
  String get profileEditEmailLabel =>
      _t('Email (optional)', 'البريد (اختياري)');
  String get profileEditEmailHint => _t('name@example.com', 'name@example.com');
  String get profileEditEmailInvalid =>
      _t('Enter a valid email address.', 'أدخل بريداً إلكترونياً صالحاً.');
  String get profileEditSaveAction => _t('Save changes', 'حفظ التغييرات');
  String get profileEditSuccessMessage =>
      _t('Profile updated.', 'تم تحديث الملف.');
  String get profileEditFailureMessage => _t(
    'Could not update profile. Please try again.',
    'تعذر تحديث الملف. حاول مجددًا.',
  );
  String get profileEditHint => _t(
    'Phone number and account status cannot be changed here.',
    'لا يمكن تغيير رقم الجوال وحالة الحساب من هنا.',
  );

  // —— Vehicle (STEP 2A Fake UI) ——
  String get vehicleTitle => _t('Vehicle', 'المركبة');
  String get vehicleLoadingTitle => _t('Loading vehicle', 'جارٍ تحميل المركبة');
  String get vehicleLoadingMessage => _t(
    'Fetching your registered vehicle details.',
    'جارٍ جلب تفاصيل مركبتك المسجّلة.',
  );
  String get vehicleEmptyTitle =>
      _t('No vehicle on file', 'لا توجد مركبة مسجّلة');
  String get vehicleEmptyMessage => _t(
    'Add your vehicle to continue onboarding checks.',
    'أضف مركبتك لمتابعة فحوصات التسجيل.',
  );
  String get vehicleAddAction => _t('Add vehicle', 'إضافة مركبة');
  String get vehicleOfflineTitle =>
      _t('Vehicle unavailable offline', 'المركبة غير متاحة دون اتصال');
  String get vehicleOfflineMessage => _t(
    'Connect to the internet to load or update vehicle details.',
    'اتصل بالإنترنت لتحميل أو تحديث تفاصيل المركبة.',
  );
  String get vehicleErrorTitle =>
      _t('Could not load vehicle', 'تعذر تحميل المركبة');
  String get vehicleErrorMessage =>
      _t('Please try again.', 'يرجى المحاولة مجددًا.');
  String get vehicleEditAction => _t('Edit vehicle', 'تعديل المركبة');
  String get vehicleEditTitle => _t('Edit vehicle', 'تعديل المركبة');
  String get vehicleMakeLabel => _t('Make', 'الشركة المصنّعة');
  String get vehicleModelLabel => _t('Model', 'الموديل');
  String get vehicleYearLabel => _t('Year', 'السنة');
  String get vehicleColorLabel => _t('Color', 'اللون');
  String get vehiclePlateLabel => _t('Plate number', 'رقم اللوحة');
  String get vehicleTypeLabel => _t('Vehicle type', 'نوع المركبة');
  String vehicleTypeValue(String type) => _t('Type: $type', 'النوع: $type');
  String get vehicleSaveAction => _t('Save vehicle', 'حفظ المركبة');
  String get vehicleSavingAction => _t('Saving…', 'جارٍ الحفظ…');
  String get vehicleSaveSuccess => _t('Vehicle saved.', 'تم حفظ المركبة.');
  String get vehicleSaveFailure => _t(
    'Could not save vehicle. Please try again.',
    'تعذر حفظ المركبة. حاول مجددًا.',
  );
  String get vehicleValidationMessage => _t(
    'Enter valid vehicle details before saving.',
    'أدخل تفاصيل مركبة صالحة قبل الحفظ.',
  );

  // —— Documents (STEP 2A Fake UI) ——
  String get documentsTitle => _t('Documents', 'المستندات');
  String get documentsLoadingTitle =>
      _t('Loading documents', 'جارٍ تحميل المستندات');
  String get documentsLoadingMessage => _t(
    'Fetching uploaded driver documents.',
    'جارٍ جلب مستندات السائق المرفوعة.',
  );
  String get documentsEmptyTitle =>
      _t('No documents yet', 'لا توجد مستندات بعد');
  String get documentsEmptyMessage => _t(
    'Upload your required documents to complete verification.',
    'ارفع المستندات المطلوبة لإكمال التحقق.',
  );
  String get documentsErrorTitle =>
      _t('Could not load documents', 'تعذر تحميل المستندات');
  String get documentsErrorMessage =>
      _t('Please try again.', 'يرجى المحاولة مجددًا.');
  String get documentsOfflineTitle =>
      _t('Documents unavailable offline', 'المستندات غير متاحة دون اتصال');
  String get documentsOfflineMessage => _t(
    'Connect to the internet to view or upload documents.',
    'اتصل بالإنترنت لعرض أو رفع المستندات.',
  );
  String get documentsUploadAction => _t('Upload document', 'رفع مستند');
  String get documentDetailTitle => _t('Document details', 'تفاصيل المستند');
  String get documentTypeLabel => _t('Document type', 'نوع المستند');
  String get documentNumberLabel => _t('Document number', 'رقم المستند');
  String get documentIssueDateLabel => _t('Issue date', 'تاريخ الإصدار');
  String get documentExpiryLabel => _t('Expiry date', 'تاريخ الانتهاء');
  String get documentRejectionReasonLabel =>
      _t('Rejection reason', 'سبب الرفض');
  String get documentEligibilityImpactLabel =>
      _t('Eligibility impact', 'تأثير الأهلية');
  String get documentTypeNationalId => _t('National ID', 'الهوية الوطنية');
  String get documentTypeDriverLicense => _t('Driver license', 'رخصة القيادة');
  String get documentTypeVehicleRegistration =>
      _t('Vehicle registration', 'تسجيل المركبة');
  String get documentTypeInsurance => _t('Insurance', 'التأمين');
  String get documentImpactNone => _t('No impact', 'لا يوجد تأثير');
  String get documentImpactBlocksAvailability => _t(
    'Going available may be blocked until review completes.',
    'قد يُحجب التحول إلى متاح حتى يكتمل المراجعة.',
  );
  String get documentImpactBlocksVehicleApproval => _t(
    'Vehicle approval may remain blocked.',
    'قد يبقى اعتماد المركبة محجوبًا.',
  );
  String get documentImpactRequiresRenewal => _t(
    'Renew this document soon to avoid eligibility loss.',
    'جدّد هذا المستند قريبًا لتجنب فقدان الأهلية.',
  );
  String get documentUploadTitle => _t('Upload document', 'رفع مستند');
  String get documentUploadHint => _t(
    'Trial upload only — no camera or file picker in this increment.',
    'رفع تجريبي فقط — لا كاميرا ولا منتقي ملفات في هذه الزيادة.',
  );
  String get documentUploadSelectAction =>
      _t('Select trial file', 'اختيار ملف تجريبي');
  String get documentFakeFileLabel => _t('Selected file', 'الملف المحدد');
  String get documentUploadSubmitAction => _t('Submit upload', 'إرسال الرفع');
  String get documentUploadingAction => _t('Uploading…', 'جارٍ الرفع…');
  String get documentUploadSuccess =>
      _t('Document uploaded.', 'تم رفع المستند.');
  String get documentUploadFailure =>
      _t('Upload failed. Please try again.', 'فشل الرفع. حاول مجددًا.');
  String get documentValidationMessage => _t(
    'Select a trial file before submitting.',
    'اختر ملفًا تجريبيًا قبل الإرسال.',
  );

  // —— Shared review statuses (STEP 2A) ——
  String get statusApproved => _t('Approved', 'مقبول');
  String get statusUnderReview => _t('Under review', 'قيد المراجعة');
  String get statusRejected => _t('Rejected', 'مرفوض');
  String get statusExpiringSoon => _t('Expiring soon', 'ينتهي قريبًا');
  String get statusExpired => _t('Expired', 'منتهي');

  // —— Settings (PHASE 2.6 Inc 4) ——
  String get settingsAppearanceSectionTitle => _t('Appearance', 'المظهر');
  String get settingsAppearanceSectionSubtitle => _t(
    'Choose how SAEQ Driver looks on this device.',
    'اختر مظهر تطبيق سائق على هذا الجهاز.',
  );
  String get settingsThemeSystem => _t('System', 'النظام');
  String get settingsThemeLight => _t('Light', 'فاتح');
  String get settingsThemeDark => _t('Dark', 'داكن');
  String get settingsLanguageSectionTitle => _t('Language', 'اللغة');
  String get settingsLanguageSectionSubtitle => _t(
    'Switch between Arabic and English.',
    'التبديل بين العربية والإنجليزية.',
  );
  String get settingsLanguageArabic => _t('Arabic', 'العربية');
  String get settingsLanguageEnglish => _t('English', 'English');
  String get settingsAboutSectionTitle => _t('About', 'حول التطبيق');
  String get settingsAboutSectionSubtitle =>
      _t('Application information.', 'معلومات التطبيق.');
  String settingsAppVersionLabel(String version) =>
      _t('Version $version', 'الإصدار $version');
  String get settingsAccountSectionTitle => _t('Account', 'الحساب');
  String get settingsAccountSectionSubtitle =>
      _t('Sign out of this device.', 'تسجيل الخروج من هذا الجهاز.');

  // —— Support (PHASE 2.6 Inc 4) ——
  String get supportFaqSectionTitle =>
      _t('Frequently asked questions', 'الأسئلة الشائعة');
  String get supportFaq1Question =>
      _t('How do I receive delivery offers?', 'كيف أستقبل عروض التوصيل؟');
  String get supportFaq1Answer => _t(
    'Turn on availability from Home and stay signed in while online.',
    'فعّل التوفر من الرئيسية وابقَ مسجّل الدخول أثناء الاتصال.',
  );
  String get supportFaq2Question =>
      _t('Why can I not go available?', 'لماذا لا أستطيع التحول إلى متاح؟');
  String get supportFaq2Answer => _t(
    'Check your profile status, connectivity, and that you are not busy on an active delivery.',
    'تحقق من حالة ملفك والاتصال وأنك لست مشغولًا بتوصيل نشط.',
  );
  String get supportFaq3Question =>
      _t('Who can I contact for help?', 'من أتواصل معه للمساعدة؟');
  String get supportFaq3Answer => _t(
    'Support channels appear here when configured by the platform. Until then, use in-app guidance and your fleet coordinator.',
    'تظهر قنوات الدعم هنا عند تهيئتها من المنصة. حتى ذلك الحين، استخدم الإرشادات داخل التطبيق أو منسّق الأسطول.',
  );
  String get supportContactSectionTitle =>
      _t('Contact support', 'التواصل مع الدعم');
  String get supportContactUnavailableTitle =>
      _t('Support unavailable', 'الدعم غير متاح');
  String get supportContactUnavailableMessage => _t(
    'Contact channels are not configured yet. Check back after platform setup.',
    'قنوات التواصل غير مهيّأة بعد. عد لاحقًا بعد إعداد المنصة.',
  );
  String get supportContactPhoneLabel => _t('Phone', 'الهاتف');
  String get supportContactEmailLabel => _t('Email', 'البريد');
  String get supportContactHelpUrlLabel => _t('Help center', 'مركز المساعدة');
  String get supportAboutSectionTitle => _t('About SAEQ Driver', 'حول سائق');
  String get supportSafetyTipsAction => _t('Safety tips', 'نصائح السلامة');
  String get supportSafetyScreenTitle => _t('Safety tips', 'نصائح السلامة');
  String get supportSafetyIntro =>
      _t('Stay safe while delivering.', 'ابقَ آمنًا أثناء التوصيل.');
  String get supportSafetyTip1 => _t(
    'Follow traffic rules and wear required safety gear.',
    'التزم بقواعد المرور وارتدِ معدات السلامة المطلوبة.',
  );
  String get supportSafetyTip2 => _t(
    'Verify the customer and delivery code before handing over the order.',
    'تحقق من العميل ورمز التسليم قبل تسليم الطلب.',
  );
  String get supportSafetyTip3 => _t(
    'Report issues from the active delivery screen instead of bypassing workflow steps.',
    'أبلغ عن المشاكل من شاشة التوصيل النشط بدلًا من تجاوز خطوات سير العمل.',
  );

  // —— Availability (PHASE 2.4 / 2.4.1) ——
  String get availabilitySectionTitle => _t('Availability', 'التوفر');
  String get availabilityStatusUnavailable =>
      _t('Unavailable for new requests', 'غير متاح لاستقبال الطلبات');
  String get availabilityStatusUnavailableDetail => _t(
    'Enable availability to receive orders.',
    'فعّل التوفر لاستقبال الطلبات.',
  );
  String get availabilityStatusConfirmedAvailable =>
      _t('Available for orders', 'متاح للطلبات');
  String get availabilityStatusConfirmedAvailableDetail => _t(
    'You can receive delivery offers now.',
    'يمكنك استقبال عروض التوصيل الآن.',
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
  String get availabilityStatusBusy => _t('Busy', 'مشغول');
  String get availabilityStatusBusyDetail => _t(
    'You will not receive new offers during delivery.',
    'لن تستقبل عروض جديدة أثناء التوصيل.',
  );
  String get availabilityStatusRestoredBusy => _t(
    'Restored busy status — awaiting verification',
    'تمت استعادة حالة مشغول — بانتظار التحقق',
  );
  String get availabilityStatusRestoredBusyDetail => _t(
    'A previous busy status was restored and is not freshly confirmed.',
    'تمت استعادة حالة مشغول سابقة وليست مؤكَّدة حديثًا.',
  );
  String get availabilityStatusOffline => _t('Offline', 'بدون اتصال');
  String get availabilityStatusOfflineDetail => _t(
    'Check the network then try again.',
    'تحقق من الشبكة ثم أعد المحاولة.',
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

  // —— Delivery offer (PHASE 2.5 / ADR-026) ——
  String get deliveryOfferTitle => _t('New delivery offer', 'عرض توصيل جديد');
  String get deliveryOfferStoreLabel => _t('Store', 'المتجر');
  String get deliveryOfferPickupLabel => _t('Pickup', 'الاستلام');
  String get deliveryOfferDropoffLabel => _t('Delivery', 'التسليم');
  String get deliveryOfferDistanceLabel =>
      _t('Estimated distance', 'المسافة التقديرية');
  String get deliveryOfferEarningsLabel =>
      _t('Estimated earnings', 'الأرباح التقديرية');
  String get deliveryOfferEarningsUnavailable =>
      _t('Not available', 'غير متاح');
  String get deliveryOfferCountdownLabel =>
      _t('Time remaining', 'الوقت المتبقي');
  String get deliveryOfferCountdownExpired => _t('Expired', 'انتهى الوقت');
  String deliveryOfferCountdownValue(int minutes, int seconds) {
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return _t('$mm:$ss', '$mm:$ss');
  }

  String deliveryOfferDistanceMeters(int meters) =>
      _t('$meters m', '$meters م');
  String deliveryOfferDistanceKilometers(String kilometers) =>
      _t('$kilometers km', '$kilometers كم');
  String get deliveryOfferDistanceUnavailable =>
      _t('Not available', 'غير متاح');
  String get deliveryOfferUnknownStore => _t('Store', 'متجر');

  String get deliveryAccept => _t('Accept', 'قبول');
  String get deliveryReject => _t('Reject', 'رفض');
  String get deliveryAccepting => _t('Accepting…', 'جارٍ القبول…');
  String get deliveryRejecting => _t('Rejecting…', 'جارٍ الرفض…');
  String get deliveryRetry => _t('Retry', 'إعادة المحاولة');
  String get deliveryDismissFailure => _t('Dismiss', 'إغلاق');
  String get deliveryRefreshing => _t('Refreshing…', 'جارٍ التحديث…');

  String get deliveryLoadingTitle => _t('Loading offers', 'جارٍ تحميل العروض');
  String get deliveryLoadingMessage => _t(
    'Checking for available delivery offers.',
    'جارٍ التحقق من عروض التوصيل المتاحة.',
  );

  String get deliveryEmptyTitle =>
      _t('No available offers', 'لا توجد عروض متاحة');
  String get deliveryEmptyMessage => _t(
    'There are no delivery offers right now. Pull to refresh or try again later.',
    'لا توجد عروض توصيل الآن. حدّث القائمة أو حاول لاحقًا.',
  );

  String get deliveryErrorTitle =>
      _t('Could not load offers', 'تعذر تحميل العروض');
  String get deliveryErrorGenericMessage => _t(
    'Something went wrong while loading delivery offers.',
    'حدث خطأ أثناء تحميل عروض التوصيل.',
  );

  String get deliveryAcceptedTitle =>
      _t('Delivery accepted', 'تم قبول التوصيل');
  String get deliveryAcceptedMessage => _t(
    'You are assigned to this delivery. Continue when you are ready.',
    'تم تعيينك لهذا التوصيل. تابع عندما تكون جاهزًا.',
  );
  String get deliveryContinueDelivery =>
      _t('Continue Delivery', 'متابعة التوصيل');
  String get deliveryAssignmentIdLabel => _t('Assignment', 'التعيين');
  String get deliveryOrderIdLabel => _t('Order', 'الطلب');

  String get deliveryHomeOfferBannerTitle =>
      _t('Incoming delivery offer', 'عرض توصيل وارد');
  String get deliveryHomeOfferBannerAction => _t('View offer', 'عرض التفاصيل');
  String get deliveryHomeAssignmentBannerTitle =>
      _t('Active delivery', 'توصيل نشط');
  String get deliveryHomeAssignmentBannerAction =>
      _t('View delivery', 'عرض التوصيل');

  String get deliveryFailureUnauthenticated => _t(
    'Your session has ended. Sign in again.',
    'انتهت الجلسة. سجّل الدخول مجددًا.',
  );
  String get deliveryFailureOfflineAccept => _t(
    'Connect to the internet before accepting an offer.',
    'اتصل بالإنترنت قبل قبول العرض.',
  );
  String get deliveryFailureNotAvailable => _t(
    'Start receiving requests before accepting an offer.',
    'ابدأ استقبال الطلبات قبل قبول العرض.',
  );
  String get deliveryFailureOfferNotFound =>
      _t('This offer is no longer available.', 'هذا العرض لم يعد متاحًا.');
  String get deliveryFailureOfferExpired =>
      _t('This offer has expired.', 'انتهت صلاحية هذا العرض.');
  String get deliveryFailureOfferTaken =>
      _t('Another driver accepted this offer.', 'قبل سائق آخر هذا العرض.');
  String get deliveryFailureConflict => _t(
    'This offer changed. Refresh and try again.',
    'تغيّر هذا العرض. حدّث وحاول مجددًا.',
  );
  String get deliveryFailureInvalidTransition =>
      _t('That offer action is not allowed.', 'إجراء العرض هذا غير مسموح.');
  String get deliveryFailureActiveOfferConflict =>
      _t('Another offer is already active.', 'يوجد عرض نشط بالفعل.');
  String get deliveryFailureActiveAssignmentExists =>
      _t('You already have an active delivery.', 'لديك توصيل نشط بالفعل.');
  String get deliveryFailurePersistence => _t(
    'Could not save the delivery on this device.',
    'تعذر حفظ التوصيل على الجهاز.',
  );
  String get deliveryFailureSecurityDenied => _t(
    'This action could not be completed for account security reasons.',
    'تعذر تنفيذ الطلب لأسباب تتعلق بأمان الحساب.',
  );
  String get deliveryFailureAvailabilityBind => _t(
    'Delivery was accepted, but availability could not be updated to busy. Your assignment was saved.',
    'تم قبول التوصيل، لكن تعذر تحديث التوفر إلى مشغول. تم حفظ التعيين.',
  );
  String get deliveryFailureUnknown => _t(
    'Something went wrong while updating the delivery offer.',
    'حدث خطأ أثناء تحديث عرض التوصيل.',
  );

  String get deliverySemanticsOffer =>
      _t('Delivery offer details', 'تفاصيل عرض التوصيل');
  String get deliverySemanticsCountdown =>
      _t('Offer time remaining', 'الوقت المتبقي للعرض');
  String get deliverySemanticsAccept =>
      _t('Accept delivery offer', 'قبول عرض التوصيل');
  String get deliverySemanticsReject =>
      _t('Reject delivery offer', 'رفض عرض التوصيل');
  String get deliverySemanticsFailure =>
      _t('Delivery offer message', 'رسالة عرض التوصيل');
  String get deliverySemanticsProgress =>
      _t('Delivery update in progress', 'جارٍ تحديث التوصيل');
  String get deliverySemanticsAssignment =>
      _t('Active delivery assignment', 'تعيين التوصيل النشط');
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
