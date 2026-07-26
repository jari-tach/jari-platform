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
  String get signOutConfirmTitle => _t('Sign out?', 'تسجيل الخروج؟');
  String get signOutConfirmMessage => _t(
    'You will need to sign in again to receive delivery offers.',
    'ستحتاج لتسجيل الدخول مجددًا لاستقبال عروض التوصيل.',
  );
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
  String get homeFakeSummaryHint =>
      _t('Trial summary (Fake data)', 'ملخص تجريبي (بيانات وهمية)');
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
  String get profileOpenSettings => _t('Settings', 'الإعدادات');
  String get profileOpenSupport => _t('Support', 'الدعم');
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
