# SAEQ DRIVER — PHASE 2: خارطة تطوير الميزات
## Feature Development Roadmap (تخطيط وتوثيق فقط — لا تنفيذ)

> **نطاق المستودع:** SAEQ Driver فقط (بحسب `ADR_SEPARATE_APPLICATIONS_STRATEGY`).
> **التاريخ:** 2026-07-25
> **حالة PROJECT STABILIZATION:** مُغلَقة بالقرار **B — CLOSED WITH CONDITIONS**.
> **Baseline Commit المعتمد:** `429c140` — `chore(stabilization): establish SAEQ Driver stable baseline`
> **نوع المهمة:** تخطيط منتج وهندسي فقط. **لا تعديل كود، لا Feature، لا Commit، لا Branch.**

---

## 1. الملخص التنفيذي

هذا التقرير يضع خارطة طريق عملية لتطوير ميزات SAEQ Driver بعد إغلاق مرحلة الاستقرار. تم بناؤه على أساس **فحص كود فعلي مباشر** (لا افتراضات) لكل عنصر من عناصر المشروع الحالي: الشاشات، الـ Routes، النماذج، الخدمات، قاعدة البيانات، الشبكة، الاختبارات.

**النتيجة الجوهرية:** المشروع حاليًا هو **هيكل تأسيسي (Skeleton) مستقر تقنيًا**، لكنه **لا يحتوي على أي منطق أعمال فعلي بعد** — لا نماذج بيانات على مستوى الأعمال (Domain Models)، لا Repositories، لا Use Cases، لا شاشة واحدة تعمل بمنطق حقيقي (باستثناء شاشة Welcome الثابتة). كل الشاشات الأخرى (`Home`, `Orders`, `Profile`, `Settings`) هي Placeholder نصي "Coming soon". خدمات جوهرية (`DriverDatabase`, `NetworkMonitor`, `OfflineQueue`, `SyncManager`, `Certificate Pinning`) موجودة ومترجَمة لكنها **غير مُهيَّأة عند التشغيل بتاتًا** (تأكَّد بالبحث المباشر: لا يوجد استدعاء واحد `DriverDatabase()`, `OfflineQueue(`, `SyncManager(`, `NetworkMonitor(` في كامل `lib/`).

**اكتشاف إضافي مهم لهذه المهمة:** نظام الترجمة (`AppLocalizations`) يحتوي بنية تقنية سليمة (Delegates، `supportedLocales`)، لكن النصوص الفعلية **ثابتة بالإنجليزية بغض النظر عن اللغة المختارة** (لا تفرّع حسب `locale.languageCode` في النسخة الحالية) — أي أن الدعم العربي الفعلي **غير مكتمل على مستوى المحتوى**، رغم أن الـ RTL/Delegates جاهزة بنيويًا. يُسجَّل هذا كدين تقني يجب معالجته قبل أي شاشة تعتمد على نصوص عربية حقيقية.

**التوصية الجوهرية:** البدء بـ **PHASE 2.1 — App Bootstrap and Service Activation** وليس بالمصادقة مباشرة، لأن كل الميزات اللاحقة (بما فيها المصادقة) ستحتاج فعليًا إلى `DriverDatabase` و/أو `NetworkMonitor` للعمل بشكل صحيح دون مخاطرة معمارية.

---

## 2. حالة المشروع الحالية

| المحور | الحالة |
|---|---|
| PROJECT STABILIZATION | ✅ مُغلَقة (القرار B) |
| Baseline Commit | `429c140` |
| `flutter analyze` | 0 Errors (7 Warnings، 28 Info) |
| `flutter test` | 3/3 Passed (تغطية سطحية جدًا) |
| Debug Build | ناجح |
| Runtime على جهاز فعلي | ناجح، Navigation/Back Navigation يعملان |
| منطق أعمال فعلي | **لا يوجد أي منه بعد** |
| خدمات مؤجلة | 6 خدمات موجودة بالكود لكنها غير مُهيَّأة |

---

## 3. قرار Baseline

يُعتمَد الـ Commit `429c140` كنقطة الصفر الرسمية (Reference Point) لكل عمل تطوير لاحق. أي مرحلة تطوير مستقبلية يجب أن تكون قابلة للمقارنة رجوعًا إلى هذا الـ Commit (`git diff 429c140...HEAD`) لتقييم حجم وأثر كل تغيير. **لا يجوز تعديل هذا الـ Commit (Rebase/Amend) بأي شكل.**

---

## 4. نطاق SAEQ Driver

- المستودع الحالي يمثل **تطبيق السائق فقط** ضمن منصة SAEQ الأوسع (Driver / Customer / Merchant / Admin — كل منها تطبيق مستقل تمامًا بحسب ADR-013).
- **ممنوع** أي شاشة، Route، Model، أو منطق خاص بـ Customer، Merchant، أو Admin داخل هذا المستودع.
- أي تكامل مع تلك التطبيقات يتم فقط عبر **Backend مشترك** (API Gateway، Auth، RBAC من جهة الخادم)، لا عبر كود مشترك مباشر بين التطبيقات.
- عند تصميم أي Backend Contract في هذه الخارطة (§15)، يُفترض أن الخادم نفسه مشترك، لكن **لا يُفترض أي كود أو Model من تطبيق آخر داخل هذا المستودع**.

---

## 5. الرؤية الوظيفية

من قائمة الميزات المحتملة الـ43 المزوَّدة، تم فحص الحالة الحالية وتصنيفها ضمن الأقسام التالية (المرجع الكامل في §9). الرؤية العامة: تطبيق سائق يمكّنه من:
1. إثبات هويته والتحقق من حالة حسابه (Authentication + Verification).
2. التحكم بحالة التوفر (Online/Offline).
3. استقبال، قبول، وتنفيذ طلبات التوصيل من الاستلام حتى التسليم.
4. العمل بشكل موثوق دون اتصال دائم بالإنترنت (Offline-First).
5. مشاهدة أرباحه وتاريخ عملياته.
6. الحصول على الدعم والإشعارات اللازمة.

هذه الرؤية تتحقق تدريجيًا عبر المراحل 2.1 → 2.11 أدناه، لا دفعة واحدة.

---

## 6. تعريف MVP

### الحد الأدنى الوظيفي المطلوب (بحسب طلب المهمة):

| # | القدرة | داخل MVP؟ |
|---|---|---|
| 1 | تسجيل الدخول / التحقق من الهوية | ✅ نعم (نسخة مبسَّطة — OTP فقط، دون تسجيل حساب جديد كامل) |
| 2 | معرفة حالة الحساب | ✅ نعم (حالة تحقق أساسية: Pending/Verified/Rejected) |
| 3 | Online/Offline | ✅ نعم |
| 4 | استقبال طلب توصيل | ✅ نعم (طلب واحد نشط في كل مرة، لا قائمة عروض متعددة متزامنة) |
| 5 | قبول/رفض الطلب | ✅ نعم |
| 6 | عرض تفاصيل الطلب | ✅ نعم |
| 7 | الانتقال لموقع الاستلام | ✅ نعم (فتح تطبيق خرائط خارجي — لا خرائط مدمجة كاملة في MVP) |
| 8 | تأكيد الاستلام | ✅ نعم |
| 9 | الانتقال للعميل | ✅ نعم (نفس آلية #7) |
| 10 | تأكيد التسليم | ✅ نعم (بدون توقيع/صورة إلزامية في MVP — Proof of Delivery الكامل P2) |
| 11 | ملخص الطلب | ✅ نعم (أساسي) |
| 12 | التعامل مع انقطاع الإنترنت الأساسي | ✅ نعم (طابور Offline + مزامنة عند الاتصال) |
| 13 | استعادة الطلب النشط بعد إغلاق التطبيق | ✅ نعم (عبر `DriverDatabase`) |
| 14 | تسجيل خروج آمن | ✅ نعم |

### ما لا يدخل في MVP وسبب الاستبعاد

| الميزة | سبب الاستبعاد |
|---|---|
| تسجيل سائق جديد كامل (Driver Registration UI متكامل) | يتطلب Backend تحقق مستندات + مراجعة يدوية؛ خارج قدرة نسخة أولى، ويمكن تنفيذه Backend-side مبدئيًا (تسجيل يدوي من الإدارة) |
| رفع/إدارة المستندات (Driver Documents) | يتطلب تخزين ملفات وواجهة رفع، قيمة أقل من تشغيل التوصيل نفسه أولًا |
| معلومات المركبة التفصيلية (Vehicle Info UI) | يمكن تأجيلها لبيانات ثابتة من الخادم في MVP |
| Wallet / معاملات مالية | يتطلب تكامل دفع كامل، مخاطرة مالية وأمانية عالية لا تناسب أول إصدار |
| تقييمات (Ratings) وأداء السائق (Performance) | قيمة تحسينية، لا تمنع تشغيل التوصيل الأساسي |
| بلاغات الحوادث (Incident Reporting) | ميزة أمان تكميلية، ليست حرجة لأول رحلة توصيل ناجحة |
| Push Notifications الكاملة | يمكن الاعتماد على Polling أو تحديث يدوي في أول نسخة، مع تأجيل FCM الكامل |
| الوضع الليلي (Dark Mode) | تحسين UX، لا يمنع تشغيل التطبيق (البنية جاهزة أصلًا في `AppTheme.darkTheme`) |
| Analytics/Crash Reporting الكامل | تحسين تشغيلي، يمكن الاعتماد على `LoggerService` المحلي مبدئيًا |

### الاعتماديات اللازمة لـ MVP
`DriverDatabase` (تخزين الطلب النشط)، `NetworkMonitor` (كشف الانقطاع)، `OfflineQueue` + `SyncManager` (استرجاع/مزامنة)، `ApiClient` مع `tokenProvider` فعّال، Backend Contracts لكل من: Auth/OTP، Driver Profile الأساسي، Delivery Offers، Accept/Reject، Active Delivery، Pickup/Delivery Confirmation.

### المخاطر
غياب Backend فعلي حاليًا (لا عناوين API حقيقية) يعني أن MVP الكامل **لا يمكن اختباره طرفًا-لطرف (End-to-End)** قبل توافر خادم حقيقي أو Mock متقن (راجع §16). كذلك، تفعيل 6 خدمات مؤجلة دفعة واحدة يرفع مخاطر الانحدار (Regression) — يجب تفعيلها تدريجيًا مرحلة بمرحلة، لا جميعها في مرحلة واحدة.

---

## 7. ما يشمله MVP
(مُفصَّل بالكامل في الجدول أعلاه §6 — الأعمدة "✅ نعم")

## 8. ما لا يشمله MVP
(مُفصَّل بالكامل في الجدول أعلاه §6 — قسم "ما لا يدخل")

---

## 9. قائمة الميزات — حالة الفحص الفعلي (المرحلة 1)

### 9.1 الشاشات الحالية

| الشاشة | الحالة | الدليل |
|---|---|---|
| Welcome Screen | **PARTIALLY READY** | مُنفَّذة فعليًا (`welcome_screen.dart`) بمحتوى ثابت (بطاقة تعريفية + زر Explore)، لا منطق أعمال، لا تفاعل مع خدمات حقيقية |
| Explore Architecture (`/coming-soon`) | **PLACEHOLDER** | نص "Explore Architecture screen - Coming soon" فقط |
| Home (`/home`) | **PLACEHOLDER** | نص "Home screen - Coming soon" فقط، داخل `ShellRoute` مع Bottom Nav |
| Orders (`/orders`) | **PLACEHOLDER** | نفس النمط |
| Profile (`/profile`) | **PLACEHOLDER** | نفس النمط |
| Settings (`/settings`) | **PLACEHOLDER** | نفس النمط |
| أي شاشة مصادقة/تسجيل/تحقق OTP | **MISSING** | لا يوجد ملف واحد لها في `lib/` |
| أي شاشة تفاصيل طلب/تتبع/تسليم | **MISSING** | لا يوجد |

### 9.2 Routes الحالية
**PARTIALLY READY.** `AppRouter` (GoRouter) مُهيَّأ بالكامل بنيويًا: `welcome`, `comingSoon`, `home`, `orders`, `profile`, `settings` ضمن `ShellRoute` بشريط تنقّل سفلي. يوجد `redirect` logic **معلَّق كـ TODO** (`// TODO: Add authentication guard` — سطر 44-53 في `app_router.dart`) — **لا حماية مصادقة فعلية على أي Route حاليًا**. لا Deep Linking حقيقي مُختبَر، لا Navigation Observers فعلية.

### 9.3 Models الحالية
**MISSING.** لا يوجد أي Domain Model أو DTO (مثل `Driver`, `DeliveryOrder` على مستوى الأعمال، `AuthToken`, إلخ) في أي مكان بـ `lib/`. الكائنات الوحيدة الشبيهة بالنماذج هي **جداول Drift المولَّدة تلقائيًا** (`DriverProfile`, `DeliveryOrder` في `driver_database.g.dart`) وهي **كائنات قاعدة بيانات محلية فقط**، ليست نماذج أعمال (Domain Layer) ولا نماذج API (Data Transfer Objects) بحسب Clean Architecture.

### 9.4 Repositories الحالية
**MISSING.** لا يوجد أي ملف `*_repository.dart` أو `*Repository` interface/implementation في كامل المشروع. طبقة الـ Domain/Repository في Clean Architecture **غير موجودة فعليًا بعد** — فقط `DriverDatabase` (Data Source خام) موجود دون طبقة تجريد فوقها.

### 9.5 Services الحالية

| الخدمة | الحالة | الدليل |
|---|---|---|
| `LoggerService` / `ConsoleLoggerService` | **READY** | مُهيَّأة في `AppServiceRegistry.init()`، مستخدَمة فعليًا (سجل Runtime مؤكَّد) |
| `AppErrorHandler` | **READY (بنيويًا)** | مُهيَّأة، لكن لم تُستدعَ عمليًا بأي مسار خطأ حقيقي حتى الآن (لا أعمال تُنتج أخطاء بعد) |
| `SecureStorageService` | **READY** | مُهيَّأة وتعمل فعليًا (سجل Runtime: `"SecureStorageService: Initialized"`) |
| `ApiClient` | **PARTIALLY READY** | مُهيَّأ بنيويًا (Dio + Interceptors)، لكن `tokenProvider` يُعيد `null` دائمًا، و `baseApiUrl` روابط صورية غير حقيقية، ولا Endpoint واحد يُستدعى فعليًا |
| `AuthService` (`core/services/auth/auth_service.dart`) | **PLACEHOLDER** | كلاس تافه: `isAuthenticated()` يُعيد `false` ثابتًا دائمًا، **غير مستخدَم في أي مكان آخر** (مؤكَّد بالبحث) |
| `StorageService` (`core/services/storage/storage_service.dart`) | **PLACEHOLDER** | كلاس تافه فارغ، **غير مستخدَم في أي مكان آخر**، مكرِّر مفاهيميًا مع `SecureStorageService` الحقيقي |
| `DriverDatabase` | **DEFERRED** | الكود كامل (4 جداول)، يترجَم بنجاح، **لا استدعاء واحد `DriverDatabase()` في كل `lib/`** (مؤكَّد بالبحث المباشر) |
| `NetworkMonitor` | **DEFERRED** | نفس الحالة — لا استدعاء `NetworkMonitor(` خارج تعريفه |
| `OfflineQueue` | **DEFERRED** | نفس الحالة |
| `SyncManager` | **DEFERRED** | نفس الحالة |
| `SecurityInterceptor` / `CertificatePinning` / `JwtManager` / `TokenRefreshManager` | **DEFERRED** | موجودة، تترجَم، غير مُضافة كـ `Dio.interceptors` فعليًا |
| `service_locator.dart` (get_it) | **PARTIALLY READY / تقنية دين** | تسجيل موازٍ كامل لكل الخدمات عبر `get_it`، **لكنه غير مستخدَم في أي مكان بالتطبيق** (المسار الفعلي هو `AppServiceRegistry` فقط) — كود ميت مكرِّر يجب حسم مصيره قبل توسّع الميزات |

### 9.6 Widgets المشتركة الحالية
**READY (للنطاق الحالي فقط).** `SaeqPrimaryButton`, `SaeqSectionCard` — بسيطتان، مُستخدَمتان فعليًا في `WelcomeScreen`، لا مشاكل. لا توجد بعد أي Widgets متخصصة لقوائم الطلبات، الخرائط، أو الحالة (Status Badges، Cards للطلبات، إلخ) — هذه **MISSING** وستُبنى ضمن المراحل القادمة.

### 9.7 حالة Dependency Injection
**PARTIALLY READY.** `AppServiceRegistry` (Static Registry يدوي) هو المسار الفعلي المستخدَم ويعمل بنجاح. **يوجد مسار موازٍ ميت** (`service_locator.dart` عبر `get_it`) يجب حسم إبقائه أو إزالته (قرار هندسي مطلوب قبل PHASE 2.1، راجع §25).

### 9.8 حالة Local Database
**DEFERRED.** الكود جاهز (`DriverDatabase`, 4 جداول: `DriverProfiles`, `DeliveryOrders`, `OfflineQueue`, `SyncMetadata`)، لا Repository فوقه، لا تهيئة عند Startup، لا اختبار واحد له.

### 9.9 حالة Networking
**PARTIALLY READY.** `ApiClient`/Dio جاهز بنيويًا مع Interceptors (Auth/Logging/Retry)، لا Endpoint حقيقي واحد، لا Backend فعلي متاح.

### 9.10 حالة Offline Queue
**DEFERRED.** جاهز بنيويًا (`enqueue`, `markAsFailed`, إلخ)، غير مُهيَّأ، غير مربوط بـ `DriverDatabase` فعليًا في وقت التشغيل (يحتاج تمرير نسخة `DriverDatabase` عند الإنشاء).

### 9.11 حالة Sync
**DEFERRED.** نفس حالة Offline Queue، ويعتمد عليه وعلى `ApiClient` معًا.

### 9.12 حالة Secure Storage
**READY.** تعمل فعليًا، تدعم `read/write/delete/deleteAll/containsKey` + مساعدات Token (`getAccessToken`, `getRefreshToken`, `clearAllAuthData`).

### 9.13 حالة Localization
**PARTIALLY READY (اكتشاف جديد مهم).** البنية التقنية جاهزة (`flutter_localizations`, Delegates, `supportedLocales: [en-US, ar-SA]`)، **لكن النصوص الفعلية ثابتة بالإنجليزية بلا تفرّع حسب اللغة** (`AppLocalizationsDelegate.load()` يُعيد نفس النصوص الإنجليزية دومًا، بلا خرائط ARB أو تفرّع `locale.languageCode`). دعم عربي حقيقي **غير موجود على مستوى المحتوى بعد** رغم إعداد الـ RTL البنيوي.

### 9.14 حالة Theme
**READY.** نظام تصميم متكامل (Light/Dark، Typography كامل، Spacing/Radius Tokens) في `AppTheme`، مع طبقة توافق خلفي (`AppColors`, `AppTextStyles`) للشاشات الحالية.

### 9.15 حالة Error Handling
**READY (بنيويًا، غير مُختبَر بأعمال حقيقية).** `AppException`/`AppFailure` Sealed Classes + `AppErrorHandler` جاهزة ومُهيَّأة، لم تُمارَس بأي سيناريو خطأ حقيقي من الشبكة/قاعدة البيانات بعد.

### 9.16 حالة Logging
**READY.** يعمل فعليًا (`print`-based، دين تقني معروف من STEP 2B، مقبول للنطاق الحالي).

### 9.17 حالة Tests
**MISSING (فعليًا) / PARTIALLY READY (كبنية).** 3 اختبارات Widget/Smoke فقط، تستخدم `test_bootstrap.dart` الذي **يتجاوز `AppServiceRegistry` الحقيقي بالكامل** (`createTestableApp` يبني `MaterialApp` بسيط بلا Router/Services حقيقية). **صفر Unit Tests** لأي خدمة، صفر Repository Tests (لا Repositories أصلًا)، صفر Database Tests، صفر Integration Tests.

---

## 10. ترتيب الأولويات

| Feature | Priority | Phase | Dependencies | Backend Required | Offline Required | Security Impact | Testing Complexity | Risk | MVP Included | Reason |
|---|---|---|---|---|---|---|---|---|---|---|
| App Bootstrap & Service Activation | **P0** | 2.1 | — | لا | لا | متوسط | متوسط | متوسط | نعم (تأسيسي) | كل شيء آخر يعتمد عليه |
| Authentication (OTP) | **P0** | 2.2 | 2.1 | نعم | جزئي | عالي | عالي | عالي | نعم | لا يعمل التطبيق تجاريًا بدونه |
| Driver Profile (أساسي) | **P1** | 2.3 | 2.2 | نعم | نعم | متوسط | متوسط | متوسط | نعم | معرفة حالة الحساب من MVP |
| Driver Documents (رفع/إدارة) | **P2** | — | 2.3 | نعم | لا | متوسط | متوسط | منخفض | لا | مؤجَّلة عن MVP |
| Vehicle Information (UI تفصيلي) | **P2** | — | 2.3 | نعم | لا | منخفض | منخفض | منخفض | لا | بيانات ثابتة تكفي في MVP |
| Account Verification Status | **P1** | 2.3 | 2.2 | نعم | نعم | متوسط | منخفض | منخفض | نعم | جزء من "معرفة حالة الحساب" |
| Online/Offline Availability | **P0** | 2.4 | 2.2, 2.3 | نعم | نعم | منخفض | متوسط | متوسط | نعم | أساسي لاستقبال الطلبات |
| Incoming Delivery Requests | **P0** | 2.5 | 2.4 | نعم | نعم | متوسط | عالي | عالي | نعم | جوهر عمل السائق |
| Accept / Reject Request | **P0** | 2.5 | 2.5 | نعم | نعم | متوسط | متوسط | متوسط | نعم | جوهري |
| Order Details | **P0** | 2.5 | 2.5 | نعم | نعم | منخفض | منخفض | منخفض | نعم | جوهري |
| Pickup Navigation | **P1** | 2.6 | 2.5 | لا (خرائط خارجية) | لا | منخفض | منخفض | منخفض | نعم | مطلوب لإكمال الرحلة |
| Arrival at Merchant | **P1** | 2.6 | 2.6 | نعم | نعم | منخفض | منخفض | منخفض | نعم | جزء من دورة التسليم |
| Confirm Pickup | **P0** | 2.6 | 2.6 | نعم | نعم | متوسط | متوسط | متوسط | نعم | جوهري |
| Customer Navigation | **P1** | 2.6 | 2.6 | لا | لا | منخفض | منخفض | منخفض | نعم | نفس نمط #Pickup Navigation |
| Arrival at Customer | **P1** | 2.6 | 2.6 | نعم | نعم | منخفض | منخفض | منخفض | نعم | جزء من دورة التسليم |
| Delivery Confirmation | **P0** | 2.6 | 2.6 | نعم | نعم | متوسط | متوسط | متوسط | نعم | جوهري لإغلاق الطلب |
| Proof of Delivery (توقيع/صورة) | **P2** | — | 2.6 | نعم | نعم | متوسط | عالي | متوسط | لا | يزيد تعقيد MVP دون ضرورة فورية |
| Order Status Timeline | **P1** | 2.6 | 2.6 | نعم | نعم | منخفض | منخفض | منخفض | نعم | ملخص الطلب مطلوب في MVP |
| Active Delivery State Recovery | **P0** | 2.7 | 2.5, 2.6 | جزئي | نعم | متوسط | عالي | عالي | نعم | شرط MVP صريح |
| Offline Support (طابور + مزامنة) | **P0** | 2.7 | 2.1 | نعم | نعم | متوسط | عالي | عالي | نعم | شرط MVP صريح |
| Background Location | **P2** | — | 2.6 | نعم | نعم | عالي | عالي | عالي | لا | يتطلب صلاحيات حساسة، يمكن تأجيله لـ Foreground فقط في MVP |
| Notifications (In-App) | **P1** | 2.8 | 2.5 | نعم | لا | منخفض | متوسط | متوسط | لا (خارج القائمة الصريحة لكن مفيد) | تحسين تجربة، ليس شرط MVP الصريح |
| Push Notifications (FCM) | **P2** | — | 2.8 | نعم | لا | متوسط | عالي | عالي | لا | يمكن الاعتماد على Polling مبدئيًا |
| Earnings | **P1** | 2.9 | 2.6 | نعم | نعم | منخفض | متوسط | منخفض | لا | قيمة عالية لكن ليست شرط تشغيل أساسي |
| Wallet | **P2** | — | 2.9 | نعم | لا | عالي | عالي | عالي | لا | مخاطرة مالية عالية |
| Transaction History | **P2** | — | 2.9 | نعم | نعم | منخفض | متوسط | منخفض | لا | تابعة لـ Earnings/Wallet |
| Driver Performance | **P3** | — | 2.9 | نعم | لا | منخفض | منخفض | منخفض | لا | تحسين مستقبلي |
| Ratings | **P3** | — | 2.6 | نعم | لا | منخفض | منخفض | منخفض | لا | تحسين مستقبلي |
| Support | **P2** | — | 2.2 | نعم | لا | منخفض | منخفض | منخفض | لا | مهم بعد MVP |
| Emergency Contact | **P1** | 2.10 | 2.3 | جزئي | لا | عالي (سلامة) | منخفض | منخفض | لا (لكن يُوصى به مبكرًا لاحقًا) | أهمية سلامة عالية لكنها ليست في قائمة MVP الصريحة |
| Incident Reporting | **P3** | — | 2.10 | نعم | نعم | متوسط | متوسط | منخفض | لا | تحسين مستقبلي |
| Settings | **P2** | 2.9 | 2.3 | لا | لا | منخفض | منخفض | منخفض | لا | UI بسيطة، لا تمنع MVP |
| Language | **P2** | 2.9 | — | لا | لا | منخفض | منخفض | منخفض | لا | يتطلب أولًا إصلاح دين الترجمة (§9.13) |
| Dark Mode | **P3** | — | — | لا | لا | منخفض | منخفض | منخفض | لا | البنية جاهزة أصلًا، تفعيل بسيط لاحقًا |
| Logout (آمن) | **P0** | 2.2 | 2.2 | نعم | لا | عالي | منخفض | منخفض | نعم | شرط MVP صريح |
| Security Hardening (Cert Pinning + JWT فعليًا) | **P0** | 2.10 | 2.2 | نعم | لا | عالي جدًا | عالي | عالي | نعم (ضمني) | لا يجوز اتصال Production حقيقي بدونه |
| Analytics and Monitoring | **P2** | 2.10 | — | نعم | لا | منخفض | متوسط | منخفض | لا | تحسين تشغيلي |
| Crash Reporting | **P2** | 2.10 | — | نعم | لا | منخفض | متوسط | منخفض | لا | تحسين تشغيلي |
| Release Readiness | **P0** | 2.11 | الكل | لا | لا | عالي | عالي | عالي | نعم (بوابة إغلاق) | بوابة جودة نهائية لإصدار MVP |

---

## 11. مراحل التطوير

### PHASE 2.0 — Development Readiness
1. **الهدف:** حسم القرارات الهندسية المعلَّقة قبل أي كتابة ميزة (إزالة/إبقاء `service_locator.dart`، تثبيت اتفاقية Repository Pattern، تثبيت اتفاقية Domain Models، تثبيت استراتيجية Mock).
2. **النطاق:** توثيق قرارات فقط (ADR إذا لزم)، لا كود ميزات.
3. **الملفات/الطبقات المتوقعة:** لا شيء بعد — قرارات توثيقية.
4. **الاعتماديات:** Baseline Commit `429c140`.
5. **الخدمات الواجب تفعيلها:** لا شيء.
6. **Backend contracts:** لا شيء بعد.
7. **Security requirements:** لا شيء بعد.
8. **اختبارات Unit/Widget/Integration:** لا شيء بعد.
9. **Runtime checks:** لا شيء.
10. **Acceptance Criteria:** قرار مكتوب حول `service_locator.dart`، اتفاقية Repository، اتفاقية Domain Model، استراتيجية Mock معتمدة.
11. **Definition of Done:** كل القرارات موثَّقة في ADR أو ملاحظة هندسية معتمدة من المستخدم.
12. **المخاطر:** البدء بالتطوير دون حسم هذه القرارات يؤدي لتضخم الدين التقني (خصوصًا ازدواجية DI).
13. **ما يمنع البدء:** لا شيء — يمكن البدء فورًا.
14. **ما يمنع الإغلاق:** عدم وجود قرار صريح من المستخدم بخصوص `service_locator.dart`.
15. **تعتمد عليها:** كل المراحل اللاحقة.
16. **Mock ممكن؟** لا ينطبق (توثيق فقط).
17. **Backend فعلي مطلوب؟** لا.
18. **التقدير:** **XS**.

### PHASE 2.1 — App Bootstrap and Service Activation
1. **الهدف:** تفعيل `DriverDatabase` و `NetworkMonitor` ضمن `AppServiceRegistry.init()` بأمان، دون أي منطق أعمال جديد.
2. **النطاق:** تعديل `AppServiceRegistry` فقط لإضافة تهيئة الخدمتين + معالجة أخطاء التهيئة (Graceful Degradation إن فشلت قاعدة البيانات).
3. **الملفات المتوقعة:** `lib/shared/services/app_service_registry.dart` (تعديل)، اختبارات جديدة لهما.
4. **الاعتماديات:** PHASE 2.0.
5. **الخدمات الواجب تفعيلها:** `DriverDatabase`, `NetworkMonitor`.
6. **Backend contracts:** لا شيء.
7. **Security requirements:** لا شيء إضافي (لا بيانات حساسة في هذه المرحلة).
8. **اختبارات Unit:** تهيئة `DriverDatabase` بنجاح، فشل التهيئة يُعالَج دون Crash، `NetworkMonitor.checkConnectivity()` يعمل.
9. **اختبارات Widget:** لا يوجد جديد.
10. **اختبارات Integration:** تشغيل التطبيق مع قاعدة بيانات فعلية على جهاز/محاكي، تأكيد إنشاء ملف `.db`.
11. **Runtime checks:** تشغيل على جهاز Android فعلي، تأكيد عدم زيادة زمن Startup بشكل ملحوظ، تأكيد عدم وجود Exceptions.
12. **Acceptance Criteria:** `DriverDatabase`/`NetworkMonitor` مُهيَّأتان في السجل، `flutter analyze` = 0، `flutter test` بلا Regression.
13. **Definition of Done:** الخدمتان READY (وليس DEFERRED) بدليل تشغيلي + اختبار Unit لكل منهما.
14. **المخاطر:** فشل تهيئة قاعدة بيانات على بعض الأجهزة (صلاحيات تخزين) يجب معالجته دون Crash التطبيق كليًا.
15. **ما يمنع البدء:** إغلاق PHASE 2.0.
16. **ما يمنع الإغلاق:** أي Regression في `flutter analyze`/`flutter test`/Runtime.
17. **تعتمد عليها:** جميع المراحل من 2.2 فصاعدًا.
18. **Mock ممكن؟** لا ينطبق (خدمات محلية بحتة).
19. **Backend فعلي مطلوب؟** لا.
20. **التقدير:** **S**.

### PHASE 2.2 — Authentication Foundation
1. **الهدف:** بناء تدفق مصادقة أساسي (طلب OTP → تحقق → حفظ Token) دون شاشة تسجيل كاملة.
2. **النطاق:** Domain Model (`AuthSession`)، Repository (`AuthRepository` + تنفيذ Mock وتنفيذ API)، Use Case بسيط، شاشتا (طلب رقم الهاتف، إدخال OTP)، تفعيل `tokenProvider` الفعلي في `ApiClient`، تفعيل `SecurityInterceptor`/JWT الأساسي، إضافة `redirect` guard الحقيقي في `AppRouter` (استبدال TODO الحالي).
3. **الملفات المتوقعة:** `lib/features/auth/domain/*`, `lib/features/auth/data/*`, `lib/features/auth/presentation/*`، تعديل `app_router.dart`، تعديل `app_service_registry.dart` لتوفير Token Cache متزامن.
4. **الاعتماديات:** PHASE 2.1.
5. **الخدمات الواجب تفعيلها:** `ApiClient` (فعليًا)، `SecurityInterceptor`/`JwtManager`/`TokenRefreshManager`، Cert Pinning (على الأقل بنيويًا مفعَّل، حتى لو بشهادة Staging).
6. **Backend contracts:** `POST /auth/otp/request`, `POST /auth/otp/verify`, `POST /auth/token/refresh` (راجع §15).
7. **Security requirements:** لا تخزين OTP نصيًا، Token في `SecureStorageService` فقط، Cert Pinning مفعَّل قبل أي اتصال Production حقيقي، Rate Limiting من جهة الخادم (خارج هذا المستودع).
8. **اختبارات Unit:** `AuthRepository` (Mock + Real)، Token parsing، انتهاء صلاحية Token.
9. **اختبارات Widget:** شاشة إدخال الهاتف، شاشة OTP (حالات: صحيح/خاطئ/منتهي).
10. **اختبارات Integration:** **إلزامي** — تدفق كامل (طلب → OTP → حفظ Token → إعادة تشغيل التطبيق → استمرار الجلسة).
11. **Runtime checks:** تأكيد عدم تسرّب Token في السجلات (`LoggerService`).
12. **Acceptance Criteria:** مستخدم يمكنه تسجيل الدخول بـ OTP (Mock أو حقيقي)، الجلسة تُستعاد بعد إغلاق التطبيق، Logout يمسح كل بيانات الجلسة.
13. **Definition of Done:** كل معايير القبول + Integration Test ناجح + 0 Regression.
14. **المخاطر:** **عالية** — هذه أول مرة يتعامل التطبيق مع بيانات حساسة فعليًا وأول اتصال شبكي حقيقي محتمل.
15. **ما يمنع البدء:** عدم إغلاق PHASE 2.1، عدم توفر Backend Contract معتمد لـ OTP (على الأقل Mock).
16. **ما يمنع الإغلاق:** أي تسرّب بيانات حساسة في السجلات، غياب Integration Test.
17. **تعتمد عليها:** 2.3 → 2.11 جميعها.
18. **Mock ممكن؟** ✅ نعم — إلزامي كبداية (راجع §16).
19. **Backend فعلي مطلوب؟** لا في البداية (Mock)، **نعم** لاحقًا قبل أي Release.
20. **التقدير:** **L**.

### PHASE 2.3 — Driver Identity and Profile
1. **الهدف:** عرض بيانات السائق الأساسية وحالة التحقق (Verification Status) بعد تسجيل الدخول.
2. **النطاق:** `DriverProfile` Domain Model + Repository، شاشة Profile حقيقية (استبدال Placeholder)، ربط `DriverProfiles` table بـ Repository.
3. **الملفات المتوقعة:** `lib/features/driver/domain/*`, `lib/features/driver/data/repositories/*`, تعديل `profile` GoRoute.
4. **الاعتماديات:** 2.2.
5. **الخدمات:** `DriverDatabase` (فعليًا الآن، تخزين محلي للملف الشخصي Cache-first).
6. **Backend contracts:** `GET /driver/profile`, `GET /driver/verification-status` (راجع §15).
7. **Security requirements:** عرض بيانات شخصية فقط لمالكها (Token-scoped من الخادم).
8. **اختبارات Unit:** Repository (Cache hit/miss، تحديث محلي بعد جلب من الخادم).
9. **اختبارات Widget:** شاشة Profile بحالات (Pending/Verified/Rejected).
10. **اختبارات Integration:** جلب من Mock API → تخزين محلي → عرض بعد إعادة تشغيل بدون اتصال.
11. **Runtime checks:** عرض صحيح Offline من الكاش المحلي.
12. **Acceptance Criteria:** السائق يرى اسمه، حالة تحققه، ونوع مركبته الأساسي، مع عمل Offline من الكاش.
13. **Definition of Done:** معايير القبول + اختبارات + 0 Regression.
14. **المخاطر:** متوسطة — أول استخدام فعلي لـ Cache-first pattern.
15. **ما يمنع البدء:** عدم إغلاق 2.2.
16. **ما يمنع الإغلاق:** فشل عرض البيانات Offline من الكاش.
17. **تعتمد عليها:** 2.4.
18. **Mock ممكن؟** ✅ نعم.
19. **Backend فعلي مطلوب؟** لا (Mock كافٍ لإغلاق المرحلة).
20. **التقدير:** **M**.

### PHASE 2.4 — Driver Availability
1. **الهدف:** تمكين السائق من التحول بين Online/Offline.
2. **النطاق:** حالة توفر محلية + مزامنة مع الخادم عند التغيير، مؤشر واضح في شاشة Home.
3. **الملفات المتوقعة:** `lib/features/driver/domain/availability_status.dart` (اسم إرشادي)، Provider حالة Riverpod، تحديث `Home` GoRoute.
4. **الاعتماديات:** 2.3.
5. **الخدمات:** `NetworkMonitor` (تعطيل التبديل عند انعدام الاتصال أو وضعه في طابور)، `OfflineQueue` (تفعيل فعلي أول مرة هنا).
6. **Backend contracts:** `POST /driver/availability` (راجع §15).
7. **Security requirements:** لا بيانات حساسة إضافية.
8. **اختبارات Unit:** انتقال الحالة، سلوك عند انعدام الاتصال (طابور بدل فشل فوري).
9. **اختبارات Widget:** مفتاح Online/Offline في Home.
10. **اختبارات Integration:** تبديل الحالة أثناء انقطاع محاكى → إعادة الاتصال → مزامنة تلقائية.
11. **Runtime checks:** لا تكرار Subscriptions لـ `NetworkMonitor` عند إعادة بناء الواجهة.
12. **Acceptance Criteria:** التبديل يعمل Online، ويُصف في طابور Offline يُزامَن تلقائيًا عند الاتصال.
13. **Definition of Done:** معايير القبول + Integration Test + 0 Regression.
14. **المخاطر:** متوسطة — أول استخدام فعلي لـ `OfflineQueue` + `SyncManager` معًا.
15. **ما يمنع البدء:** عدم إغلاق 2.3.
16. **ما يمنع الإغلاق:** فقدان تحديث الحالة عند انقطاع الاتصال.
17. **تعتمد عليها:** 2.5.
18. **Mock ممكن؟** ✅ نعم.
19. **Backend فعلي مطلوب؟** لا لإغلاق المرحلة.
20. **التقدير:** **M**.

### PHASE 2.5 — Delivery Request Lifecycle
1. **الهدف:** استقبال، عرض، قبول أو رفض طلب توصيل واحد نشط.
2. **النطاق:** `DeliveryOrder` Domain Model + Repository، شاشة عرض الطلب الوارد (Modal/Screen)، منطق Accept/Reject، تحديث `Orders`/`Home` GoRoute.
3. **الملفات المتوقعة:** `lib/features/delivery/domain/*`, `lib/features/delivery/data/*`, `lib/features/delivery/presentation/*`.
4. **الاعتماديات:** 2.4.
5. **الخدمات:** `DriverDatabase` (تخزين الطلب النشط محليًا فور القبول — أساس لـ 2.7)، `SyncManager`.
6. **Backend contracts:** `GET /driver/delivery-offers` أو WebSocket/Push للعروض الجديدة، `POST /driver/delivery/{id}/accept`, `POST /driver/delivery/{id}/reject` (راجع §15).
7. **Security requirements:** Idempotency على Accept/Reject (منع قبول مضاعف لنفس الطلب من نفس السائق أو من جهازين).
8. **اختبارات Unit:** منطق Accept/Reject، تخزين محلي فور القبول.
9. **اختبارات Widget:** شاشة تفاصيل الطلب، حالات (متاح/مقبول من سائق آخر/منتهي المهلة).
10. **اختبارات Integration:** **إلزامي** — استقبال عرض → قبول → تخزين محلي → التحقق من استمراره بعد إغلاق التطبيق.
11. **Runtime checks:** لا تكرار طلبات Accept عند ضغط متكرر (Debounce/Idempotency Key).
12. **Acceptance Criteria:** السائق يستقبل عرضًا، يقبله أو يرفضه، ويُخزَّن الطلب المقبول محليًا فورًا.
13. **Definition of Done:** معايير القبول + Integration Test + 0 Regression.
14. **المخاطر:** **عالية** — أول منطق أعمال حقيقي معقّد (Concurrency بين سائقين، Idempotency، حالة الشبكة).
15. **ما يمنع البدء:** عدم إغلاق 2.4.
16. **ما يمنع الإغلاق:** أي حالة Race Condition غير محسومة (قبول مزدوج).
17. **تعتمد عليها:** 2.6، 2.7.
18. **Mock ممكن؟** ✅ نعم — محاكاة عروض توصيل (راجع §16).
19. **Backend فعلي مطلوب؟** لا لإغلاق المرحلة، **نعم** لأي اختبار حمل حقيقي (Concurrency الحقيقي بين سائقين).
20. **التقدير:** **XL**.

### PHASE 2.6 — Active Delivery Flow
1. **الهدف:** تنفيذ دورة التوصيل الكاملة من الاستلام حتى التسليم.
2. **النطاق:** شاشات: تفاصيل الرحلة النشطة، تأكيد الاستلام، تأكيد التسليم، ملخص الطلب؛ فتح تطبيق خرائط خارجي (Deep Link) للتنقل.
3. **الملفات المتوقعة:** توسيع `lib/features/delivery/presentation/*`.
4. **الاعتماديات:** 2.5.
5. **الخدمات:** `DriverDatabase` (تحديث حالة الطلب النشط في كل خطوة)، `SyncManager`.
6. **Backend contracts:** `POST /driver/delivery/{id}/confirm-pickup`, `POST /driver/delivery/{id}/confirm-delivery` (راجع §15).
7. **Security requirements:** توثيق كل انتقال حالة (Audit Trail من جهة الخادم).
8. **اختبارات Unit:** انتقالات حالة الطلب (State Machine: Accepted → PickedUp → Delivered).
9. **اختبارات Widget:** كل شاشة من الدورة.
10. **اختبارات Integration:** **إلزامي** — دورة كاملة Accepted → PickedUp → Delivered مع محاكاة انقطاع اتصال في منتصف الدورة.
11. **Runtime checks:** لا فقدان حالة عند تدوير الشاشة/الخلفية-الاستئناف في منتصف الرحلة.
12. **Acceptance Criteria:** إكمال رحلة توصيل كاملة من القبول حتى التسليم، مع نجاح استرجاع الحالة بعد إغلاق التطبيق في أي خطوة.
13. **Definition of Done:** معايير القبول + Integration Test + 0 Regression.
14. **المخاطر:** **عالية** — أطول تدفق حالة في التطبيق، أكبر سطح لأخطاء الحالة.
15. **ما يمنع البدء:** عدم إغلاق 2.5.
16. **ما يمنع الإغلاق:** فقدان حالة الرحلة في أي نقطة انقطاع.
17. **تعتمد عليها:** 2.7، 2.9.
18. **Mock ممكن؟** ✅ نعم.
19. **Backend فعلي مطلوب؟** لا لإغلاق المرحلة.
20. **التقدير:** **XL**.

### PHASE 2.7 — Offline and Recovery
1. **الهدف:** تثبيت سلوك استرجاع الحالة والعمل دون اتصال كسلوك شامل مُختبَر عبر كل المراحل السابقة (وليس ميزة منفصلة).
2. **النطاق:** اختبارات تكاملية إضافية + معالجة الحالات الحدّية (Edge Cases) لانقطاع الاتصال في كل خطوة من 2.4-2.6.
3. **الملفات المتوقعة:** لا ملفات جديدة بالضرورة — تعزيز واختبار الموجود.
4. **الاعتماديات:** 2.4, 2.5, 2.6.
5. **الخدمات:** `NetworkMonitor`, `OfflineQueue`, `SyncManager` (تعزيز واختبار شامل لتفاعلها الثلاثي).
6. **Backend contracts:** لا شيء جديد.
7. **Security requirements:** لا تكرار عمليات مالية/حالة عند إعادة المزامنة (Idempotency Keys على كل عملية في الطابور).
8. **اختبارات Unit:** كل سيناريوهات `OfflineQueue`/`SyncManager` (فشل، إعادة محاولة، نجاح متأخر).
9. **اختبارات Widget:** مؤشرات حالة الاتصال في الواجهة.
10. **اختبارات Integration:** **إلزامي** — قطع اتصال حقيقي/محاكى في كل خطوة من دورة التوصيل، تأكيد المزامنة الصحيحة عند الاتصال.
11. **Runtime checks:** اختبار على جهاز فعلي بتفعيل/تعطيل Wi-Fi/Data يدويًا.
12. **Acceptance Criteria:** لا فقدان أي عملية عند انقطاع الاتصال في أي نقطة، لا تكرار عمليات عند إعادة الاتصال.
13. **Definition of Done:** معايير القبول + Integration Test شامل + 0 Regression.
14. **المخاطر:** **عالية** — Offline-First معقّد بطبيعته، أخطاؤه صامتة وصعبة الاكتشاف.
15. **ما يمنع البدء:** عدم إغلاق 2.6.
16. **ما يمنع الإغلاق:** أي سيناريو فقدان أو تكرار عملية مؤكَّد.
17. **تعتمد عليها:** 2.11 (بوابة الجودة النهائية).
18. **Mock ممكن؟** ✅ نعم (محاكاة انقطاع الشبكة).
19. **Backend فعلي مطلوب؟** لا.
20. **التقدير:** **L**.

### PHASE 2.8 — Notifications
1. **الهدف:** إشعار السائق بعروض توصيل جديدة وتحديثات الحالة (داخل التطبيق كحد أدنى؛ FCM اختياري/مؤجَّل).
2. **النطاق:** آلية Polling أو WebSocket للعروض الجديدة (بدل الاعتماد الكامل على Push في MVP)، مركز إشعارات داخلي بسيط.
3. **الملفات المتوقعة:** `lib/features/notifications/*` (جديد).
4. **الاعتماديات:** 2.5.
5. **الخدمات:** `ApiClient` (Polling)، لاحقًا FCM Plugin (خارج MVP).
6. **Backend contracts:** `GET /driver/notifications` أو WebSocket Channel (راجع §15).
7. **Security requirements:** لا بيانات حساسة في الإشعارات المحلية.
8. **اختبارات Unit:** منطق Polling/معالجة الإشعارات الواردة.
9. **اختبارات Widget:** قائمة الإشعارات.
10. **اختبارات Integration:** استقبال عرض توصيل جديد عبر القناة المختارة يؤدي لظهوره في 2.5.
11. **Runtime checks:** لا استهلاك بطارية غير معقول من Polling المتكرر.
12. **Acceptance Criteria:** السائق يُخطَر بعرض جديد أثناء استخدام التطبيق.
13. **Definition of Done:** معايير القبول + اختبارات + 0 Regression.
14. **المخاطر:** متوسطة.
15. **ما يمنع البدء:** عدم إغلاق 2.5.
16. **ما يمنع الإغلاق:** استهلاك بطارية/بيانات مفرط غير مُقاس.
17. **تعتمد عليها:** لا مرحلة لاحقة تعتمد عليها إلزاميًا.
18. **Mock ممكن؟** ✅ نعم.
19. **Backend فعلي مطلوب؟** لا لإغلاق المرحلة.
20. **التقدير:** **M**.

### PHASE 2.9 — Earnings and History
1. **الهدف:** عرض ملخص الأرباح وتاريخ الرحلات المكتملة، بالإضافة إلى Settings/Language الأساسية.
2. **النطاق:** شاشة Earnings، شاشة تاريخ الطلبات (تحديث `Orders` GoRoute)، شاشة Settings حقيقية (استبدال Placeholder)، **إصلاح دين الترجمة (§9.13) هنا قبل تفعيل تبديل اللغة فعليًا**.
3. **الملفات المتوقعة:** `lib/features/earnings/*`, تحديث `settings`/`orders` GoRoute، إعادة كتابة محتوى `AppLocalizations` لدعم عربي/إنجليزي حقيقي (ARB أو ما يعادلها).
4. **الاعتماديات:** 2.6.
5. **الخدمات:** `DriverDatabase` (كاش تاريخ الطلبات)، `ApiClient`.
6. **Backend contracts:** `GET /driver/earnings/summary`, `GET /driver/orders/history` (راجع §15).
7. **Security requirements:** بيانات مالية للعرض فقط (لا تعديل من التطبيق).
8. **اختبارات Unit:** حسابات الملخص المعروضة (إن وُجد أي منطق تجميع محلي).
9. **اختبارات Widget:** شاشة Earnings، شاشة Settings، تبديل اللغة الفعلي.
10. **اختبارات Integration:** عرض تاريخ من الكاش المحلي دون اتصال.
11. **Runtime checks:** تبديل اللغة يُحدِّث الواجهة فورًا (RTL/LTR) دون إعادة تشغيل.
12. **Acceptance Criteria:** السائق يرى أرباحه وتاريخ رحلاته، ويمكنه تبديل اللغة فعليًا (عربي حقيقي لا نص ثابت).
13. **Definition of Done:** معايير القبول + اختبارات + 0 Regression.
14. **المخاطر:** منخفضة-متوسطة، الخطر الأساسي هو نطاق إصلاح الترجمة إن اتسع أكثر من المتوقع.
15. **ما يمنع البدء:** عدم إغلاق 2.6.
16. **ما يمنع الإغلاق:** استمرار النصوص الإنجليزية الثابتة رغم اختيار العربي.
17. **تعتمد عليها:** لا شيء إلزامي.
18. **Mock ممكن؟** ✅ نعم.
19. **Backend فعلي مطلوب؟** لا لإغلاق المرحلة.
20. **التقدير:** **M**.

### PHASE 2.10 — Security and Production Readiness
1. **الهدف:** رفع مستوى الأمان من "قابل للتصريف" إلى "فعّال ومُختبَر" قبل أي اتصال Production حقيقي.
2. **النطاق:** ربط `CertificatePinning` فعليًا بـ `Dio` (شهادات حقيقية)، تفعيل Token Refresh التلقائي الكامل، Analytics/Crash Reporting الأساسي، مراجعة أمنية شاملة (يُستحسَن Security Review subagent هنا).
3. **الملفات المتوقعة:** `lib/core/security/security_interceptors.dart` (تعديل للربط الفعلي)، `lib/shared/services/app_service_registry.dart`.
4. **الاعتماديات:** 2.2.
5. **الخدمات:** `SecurityInterceptor`, `CertificatePinning`, `JwtManager`, `TokenRefreshManager` (فعّالة بالكامل الآن).
6. **Backend contracts:** لا شيء جديد (استخدام Contracts §15 القائمة، لكن بشهادات/بيئة حقيقية).
7. **Security requirements:** **الأعلى في كل الخارطة** — Fail-Closed إلزامي، لا Bypass لأي فحص شهادة، لا تسجيل بيانات حساسة.
8. **اختبارات Unit:** فشل التحقق من الشهادة يوقف الاتصال (Fail-Closed مؤكَّد باختبار).
9. **اختبارات Widget:** لا يوجد جديد مباشر.
10. **اختبارات Integration:** **إلزامي** — محاكاة شهادة غير صحيحة ترفض الاتصال، Token منتهي يُجدَّد تلقائيًا بلا تدخل المستخدم.
11. **Runtime checks:** اختبار على بيئة Staging حقيقية قبل أي Production.
12. **Acceptance Criteria:** لا اتصال ناجح بشهادة غير مثبَّتة، تجديد Token يعمل بصمت دون قطع الجلسة.
13. **Definition of Done:** معايير القبول + مراجعة أمنية معتمَدة + 0 Regression.
14. **المخاطر:** **عالية جدًا** — أي خلل هنا خطر أمني مباشر على بيانات وحسابات حقيقية.
15. **ما يمنع البدء:** عدم إغلاق 2.2.
16. **ما يمنع الإغلاق:** أي ثغرة تسمح بتجاوز التحقق من الشهادة أو تسريب Token.
17. **تعتمد عليها:** 2.11.
18. **Mock ممكن؟** جزئيًا فقط (فحص منطق الرفض)، **لا** لبيئة حقيقية.
19. **Backend فعلي مطلوب؟** **نعم** — لا يمكن إغلاق هذه المرحلة دون بيئة Staging حقيقية على الأقل.
20. **التقدير:** **L**.

### PHASE 2.11 — MVP Final Quality Gate
1. **الهدف:** بوابة تحقق نهائية قبل اعتبار MVP جاهزًا لأي إصدار.
2. **النطاق:** تكرار منهجية `STABILIZATION_FINAL_QUALITY_GATE` مطبَّقة على نطاق MVP الكامل.
3. **الملفات المتوقعة:** تقرير جديد مماثل، لا كود.
4. **الاعتماديات:** جميع المراحل 2.1-2.10.
5. **الخدمات:** تأكيد كل الخدمات الستة المؤجلة أصبحت READY فعليًا (لا NOT TESTED).
6. **Backend contracts:** تأكيد تنفيذ فعلي (لا Mock) لكل Contract حرج في §15.
7. **Security requirements:** مراجعة أمنية نهائية شاملة (Security Review).
8. **اختبارات Unit/Widget/Integration:** مراجعة نسبة التغطية الكلية (الحد الأدنى المقترح في §18).
9. **Runtime checks:** جلسة Runtime كاملة على جهاز فعلي لكل تدفق MVP.
10. **Acceptance Criteria:** كل بوابات §21 من هذا المستند = PASS، لا Critical/High مفتوحة.
11. **Definition of Done:** تقرير Quality Gate بقرار CLOSED-APPROVED أو CLOSED-WITH CONDITIONS معتمَد.
12. **المخاطر:** تراكمية من كل المراحل السابقة إن لم تُحل.
13. **ما يمنع البدء:** عدم إغلاق 2.10.
14. **ما يمنع الإغلاق:** أي Critical/High غير محسوم.
15. **تعتمد عليها:** إصدار MVP الفعلي (خارج نطاق هذه الخارطة).
16. **Mock ممكن؟** لا — يجب تقييم الحالة الحقيقية فقط.
17. **Backend فعلي مطلوب؟** نعم.
18. **التقدير:** **M** (تحقق فقط، لا تطوير).

---

## 12. اعتماديات المراحل (رسم تتابعي)

```
2.0 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6 ─┬→ 2.7 ─┐
                                          ├→ 2.8   │
                                          └→ 2.9   │
                            2.2 ──────────────→ 2.10 ┤
                                                      └→ 2.11
```
لا يجوز بدء 2.2 قبل إغلاق 2.1. لا يجوز بدء 2.5 قبل إغلاق 2.4. المراحل 2.7/2.8/2.9 يمكن أن تتقدم بشكل متوازٍ نسبيًا بعد إغلاق 2.6، لكن 2.10 تعتمد فقط على 2.2 (يمكن البدء بالتوازي الجزئي مع 2.3-2.9 إن توفرت طاقة فريق كافية، لكنها **لا تُغلَق** إلا بعد استقرار كل ما قبلها فعليًا). 2.11 تُغلِق الجميع.

---

## 13. الخدمات المؤجلة (ملخص سريع — التفصيل الكامل في §14)

| الخدمة | الحالة الحالية |
|---|---|
| `DriverDatabase` | DEFERRED |
| `NetworkMonitor` | DEFERRED |
| `OfflineQueue` | DEFERRED |
| `SyncManager` | DEFERRED |
| `ApiClient` | PARTIALLY READY (بنية جاهزة، لا استخدام فعلي) |
| `SecureStorageService` | READY |
| `Certificate Pinning` | DEFERRED |
| `JWT Interceptor` / `Token Refresh` | DEFERRED |
| `LoggerService` | READY |
| `Error Handler` | READY (بنيويًا) |

---

## 14. خطة تفعيل الخدمات (المرحلة 5)

| الخدمة | أول Feature تعتمد عليها | المرحلة الواجب تفعيلها فيها | قبل Authentication؟ | قبل Delivery Flow؟ | الاختبارات المطلوبة | مخاطر التفعيل المبكر | مخاطر تأخير التفعيل | شروط اعتبارها READY |
|---|---|---|---|---|---|---|---|---|
| `DriverDatabase` | Active Delivery State Recovery (ضمنيًا من 2.3) | **2.1** | ✅ نعم (قبله) | ✅ نعم | Unit: CRUD لكل جدول؛ Integration: بقاء البيانات بعد إعادة تشغيل | منخفضة (خدمة محلية بحتة) | تأخيرها يمنع كل الميزات التالية دون بديل | تهيئة ناجحة + اختبار Unit شامل + استخدام فعلي من Repository واحد على الأقل |
| `NetworkMonitor` | Driver Availability | **2.1** | ✅ نعم | ✅ نعم | Unit: تغيّر الحالة؛ Integration: تبديل شبكة فعلي | منخفضة | يمنع أي منطق Offline-aware لاحق | Stream حالة يعمل + استُخدم فعليًا في قرار واحد على الأقل (مثل تعطيل زر) |
| `OfflineQueue` | Driver Availability (أول استخدام فعلي) | **2.4** | لا (بعده) | ✅ نعم (قبله) | Unit شامل لكل الحالات؛ Integration مع `SyncManager` | متوسطة إذا فُعِّلت قبل وجود بيانات فعلية للطابور (بلا فائدة حقيقية) | يمنع Offline-First كليًا | استخدام فعلي من ميزة واحدة حقيقية + Integration Test ناجح |
| `SyncManager` | Driver Availability | **2.4** | لا | ✅ نعم | Unit + Integration مع `OfflineQueue` و `ApiClient` | متوسطة (تعتمد على وجود `ApiClient` فعّال) | يمنع مزامنة أي عملية مخزَّنة محليًا | مزامنة ناجحة لعملية واحدة فعلية على الأقل بعد انقطاع محاكى |
| `ApiClient` (فعليًا، لا بنيويًا فقط) | Authentication | **2.2** | ✅ نعم (جزء منها) | ✅ نعم | Integration مع Mock API أولًا، ثم Real API لاحقًا | منخفضة (بنية موجودة، التفعيل تدريجي) | يمنع أي اتصال شبكي حقيقي لأي ميزة | Endpoint حقيقي واحد يعمل (Mock أو Real) بدون خطأ |
| `SecureStorageService` | — (READY أصلًا) | — | — | — | — | — | — | READY فعليًا الآن |
| `Certificate Pinning` | Security Hardening | **2.10** | ❌ لا (يمكن تأجيله لما بعد Auth الأولي بـ Mock) | لا | Unit (Fail-Closed)؛ Integration مع شهادة خاطئة | **عالية إذا فُعِّل بشهادة غير صحيحة** (يقطع كل الاتصال) | تأخيره يترك التطبيق عرضة لـ MITM في أي اتصال Production | شهادة Staging/Production حقيقية + اختبار رفض شهادة خاطئة ناجح |
| `JWT Interceptor` / `Token Refresh` | Authentication (الأساسي)، Security Hardening (الكامل) | **2.2** (أساسي) → **2.10** (كامل) | ✅ نعم (الأساسي) | لا | Unit: تجديد قبل الانتهاء؛ Integration: طلب بعد انتهاء Token يُجدَّد تلقائيًا | متوسطة (تعقيد Race Conditions عند طلبات متزامنة) | يمنع جلسات طويلة الأمد، يُجبر إعادة تسجيل دخول متكررة | تجديد تلقائي ناجح دون تدخل المستخدم في اختبار Integration واحد على الأقل |
| `LoggerService` | — (READY أصلًا) | — | — | — | — | — | — | READY فعليًا الآن |
| `Error Handler` | Authentication (أول استخدام فعلي حقيقي) | **2.2** | ✅ نعم | لا | Unit: تحويل كل نوع `AppException` لـ `AppFailure` | منخفضة | يمنع معالجة أخطاء موحَّدة لأي ميزة | معالجة خطأ واقعي واحد (مثل فشل شبكة) بنجاح دون Crash |

---

## 15. عقود Backend المطلوبة (مقترحات فقط — تحتاج ADR/Contract منفصل لاحقًا)

> **تنويه:** هذه مقترحات تخطيطية غير نهائية. أي منها يتطلب Backend Contract أو ADR مستقل قبل التنفيذ الفعلي. **لا يُنشأ أي API هنا.**

| Endpoint/Contract | الغرض | Method | Auth؟ | Request | Response | Error Cases | Idempotency | Offline Behavior | Security | القناة |
|---|---|---|---|---|---|---|---|---|---|---|
| `POST /auth/otp/request` | طلب رمز تحقق | POST | لا | `{phone}` | `{requestId, expiresIn}` | Rate limit، رقم غير صالح | مطلوب (منع طلبات مكررة سريعة) | يُرفَض محليًا إن لم يوجد اتصال | Rate limiting، لا تخزين OTP نصيًا | REST |
| `POST /auth/otp/verify` | تأكيد OTP وإصدار Token | POST | لا | `{requestId, code}` | `{accessToken, refreshToken, driverId}` | رمز خاطئ، منتهي، محاولات كثيرة | مطلوب (Request ID) | يُرفَض محليًا إن لم يوجد اتصال | Token في `SecureStorageService` فقط | REST |
| `POST /auth/token/refresh` | تجديد Token | POST | RefreshToken | `{refreshToken}` | `{accessToken, refreshToken}` | RefreshToken منتهي/مُبطَل → إعادة تسجيل دخول | مطلوب | لا ينطبق (لا Offline لهذا) | Refresh Token دوّار (Rotating) يُفضَّل | REST |
| `GET /driver/profile` | جلب بيانات السائق | GET | نعم | — | `DriverProfile` | 401/404 | لا ينطبق (Read) | Cache-first، يعمل من `DriverDatabase` محليًا | REST |
| `GET /driver/verification-status` | حالة التحقق | GET | نعم | — | `{status, reason?}` | 401 | لا ينطبق | Cache-first | REST أو مدمج مع Profile |
| `POST /driver/availability` | تحديث حالة التوفر | POST | نعم | `{isOnline, location?}` | `{status}` | 401، الحساب غير مُتحقَّق | مطلوب (Idempotency Key) | **يُصفّ في `OfflineQueue`** عند الانقطاع | لا بيانات حساسة إضافية | REST |
| `GET /driver/delivery-offers` | عروض توصيل جديدة | GET/Push/WS | نعم | — | `List<DeliveryOffer>` | 401، لا عروض | لا ينطبق | لا يعمل Offline (يتطلب اتصال) | — | **يُوصى بـ WebSocket أو Push لتقليل التأخير؛ Polling كـ Fallback في MVP** |
| `POST /driver/delivery/{id}/accept` | قبول طلب | POST | نعم | `{deliveryId}` | `DeliveryOrder` | 409 (مقبول من سائق آخر)، 410 (منتهي) | **إلزامي** (Idempotency Key) | يُرفَض محليًا إن لم يوجد اتصال (Race Condition حقيقية) | — | REST |
| `POST /driver/delivery/{id}/reject` | رفض طلب | POST | نعم | `{deliveryId, reason?}` | `{status}` | 404، 410 | مطلوب | يُصفّ في `OfflineQueue` | — | REST |
| `GET /driver/delivery/{id}` | تفاصيل طلب | GET | نعم | — | `DeliveryOrder` كامل | 401/404 | لا ينطبق | Cache-first | — | REST |
| `POST /driver/delivery/{id}/confirm-pickup` | تأكيد الاستلام | POST | نعم | `{deliveryId, timestamp}` | `{status}` | 409 (حالة غير صحيحة للانتقال) | **إلزامي** | يُصفّ في `OfflineQueue` | — | REST |
| `POST /driver/delivery/{id}/confirm-delivery` | تأكيد التسليم | POST | نعم | `{deliveryId, timestamp, proof?}` | `{status}` | 409 | **إلزامي** | يُصفّ في `OfflineQueue` | Proof (لاحقًا P2) قد يتطلب رفع ملف مستقل | REST (+ Upload منفصل لاحقًا) |
| `POST /driver/location` | تحديث الموقع (إن فُعِّل) | POST | نعم | `{lat, lng, timestamp}` | `{status}` | 401 | لا ينطبق (Append-only) | يُصفّ أو يُهمَل القديم عند الانقطاع الطويل | بيانات موقع حساسة — يتطلب سياسة خصوصية | REST أو WS للتتبع اللحظي (P2) |
| `GET /driver/earnings/summary` | ملخص الأرباح | GET | نعم | `{period?}` | `{total, breakdown}` | 401 | لا ينطبق | Cache-first | بيانات مالية للعرض فقط | REST |
| `GET /driver/orders/history` | تاريخ الطلبات | GET | نعم | `{page, pageSize}` | `List<DeliveryOrder>` | 401 | لا ينطبق | Cache-first | — | REST |
| `GET /driver/notifications` | الإشعارات | GET | نعم | — | `List<Notification>` | 401 | لا ينطبق | لا يعمل Offline | — | REST أو Push (P2) |
| `POST /driver/support/ticket` | فتح تذكرة دعم | POST | نعم | `{subject, message}` | `{ticketId}` | 401، حقول ناقصة | مطلوب | يُصفّ في `OfflineQueue` | — | REST |

---

## 16. Mock Strategy (المرحلة 7)

### ما يمكن تنفيذه بـ Mock قبل جاهزية Backend
- **Fake Repositories:** تنفيذ `AuthRepository`, `DeliveryRepository`, إلخ بنسخة `InMemory`/`Fake` تُعيد بيانات ثابتة أو شبه عشوائية، تُحقن عبر نفس Interface الحقيقي (لا فرق من منظور الواجهة).
- **Mock API Responses:** طبقة `Dio` بديلة (`DioAdapter` تجريبي أو Interceptor يُعيد استجابات JSON محلية) تُفعَّل فقط عبر Feature Flag.
- **Local Fixtures:** ملفات JSON ثابتة لعروض توصيل، ملفات سائق، سجل أرباح — تُستخدَم في Widget/Integration Tests وفي Mock Mode.
- **Simulated Delivery Offers:** مولِّد عروض دوري (Timer) يُنتج عروضًا افتراضية لاختبار PHASE 2.5 دون Backend حقيقي.
- **Simulated Order Lifecycle:** دفع الحالة يدويًا عبر أزرار Debug مؤقتة (خلف Feature Flag، لا تظهر في Production) لتتبّع 2.6 دون انتظار خادم فعلي.
- **Simulated Network Loss:** التحكم اليدوي بـ `NetworkMonitor` (حقن حالة مزيَّفة في وضع الاختبار) لمحاكاة الانقطاع دون تعطيل الشبكة الفعلية للجهاز.
- **Simulated Token Expiration:** Token مزيَّف بصلاحية قصيرة جدًا (ثواني) في وضع الاختبار لإثبات عمل Token Refresh دون انتظار الانتهاء الحقيقي.

### حدود استخدام Mock
- Mock **لا يُستخدَم أبدًا** لإثبات إغلاق أي مرحلة تحمل Risk = عالي/عالي جدًا نهائيًا (مثل PHASE 2.10) — فقط كخطوة انتقالية مبكرة.
- Mock لا يُستخدَم لاختبار Concurrency الحقيقي (قبول طلب من سائقين حقيقيين متزامنين) — يتطلب Backend حقيقي أو Staging.
- Mock لا يُستخدَم لأي اختبار أمني نهائي (Certificate Pinning، Rate Limiting الفعلي).

### متى يجب استبداله بـ Backend
- فور توفر أول Endpoint حقيقي مطابق لعقد §15، يُستبدَل تدريجيًا (Endpoint بـ Endpoint)، لا دفعة واحدة، مع الحفاظ على Mock كـ Fallback لبيئة التطوير/الاختبار المحلي.
- PHASE 2.10 و 2.11 **لا يجوز إغلاقهما بالاعتماد على Mock فقط**.

### كيف نمنع تسرّب Mock إلى Production
- **Feature Flag إلزامي** (مثل `AppConfig.useMockBackend`، ثابت `false` افتراضيًا، ولا يُفعَّل إلا في `Environment.dev`).
- فحص برمجي إلزامي في `AppConfig.init()`: رفض تشغيل `useMockBackend = true` إذا كان `Environment.production`.
- Lint/CI Check يفحص عدم وجود مراجع لـ Mock Repositories في مسار الاستيراد الفعلي لـ `AppServiceRegistry` عند بناء Release.

### Feature Flags المطلوبة
`useMockBackend`, `useMockDeliveryOffers`, `enableDebugStateOverride` (لدفع حالة الطلب يدويًا)، `enableCertificatePinning` (موجود أصلًا في `AppConfig`، حاليًا `false`).

### الاختبارات التي تثبت الفصل
اختبار Unit صريح: "بناء `AppServiceRegistry` في `Environment.production` مع `useMockBackend=true` يجب أن يفشل بخطأ صريح وقت التهيئة (Fail-Fast)، لا أن يعمل بصمت."

---

## 17. Offline Strategy (ملخص — التفصيل الكامل مدمج في PHASE 2.7 و §14)

مبدأ عام: **Cache-first للقراءة، Queue-and-sync للكتابة** (متوافق مع التوثيق المعماري الأصلي). كل عملية كتابة حرجة (Accept/Reject/Confirm) تُخزَّن أولًا محليًا في `DriverDatabase` ثم تُصفّ في `OfflineQueue`، ويتولى `SyncManager` إرسالها عند توفر الاتصال، مع `Idempotency Key` لكل عملية لمنع التكرار عند إعادة المحاولة.

---

## 18. Security Strategy (ملخص)

- لا اتصال Production حقيقي قبل إغلاق PHASE 2.10 (Certificate Pinning فعّال + Fail-Closed مؤكَّد).
- Token دائمًا في `SecureStorageService`، لا في الذاكرة المكشوفة لفترات طويلة، لا في السجلات.
- Token Refresh تلقائي شفّاف قبل انتهاء الصلاحية.
- لا تسجيل (`LoggerService`) لأي بيانات حساسة (Token، OTP، بيانات دفع) — يجب فحص هذا صريحًا في مراجعة كل Pull Request من PHASE 2.2 فصاعدًا.
- مراجعة أمنية (Security Review Subagent) مطلوبة قبل إغلاق PHASE 2.2 و PHASE 2.10 على الأقل.

---

## 19. Testing Strategy (المرحلة 8)

### الحد الأدنى المقترح تدريجيًا (نسبة تقريبية، وليست ضمانًا للجودة وحدها)

| المرحلة | الحد الأدنى المقترح |
|---|---|
| PHASE 2.1 | Unit Tests لكل خدمة مُفعَّلة (100% من المسارات الحرجة: نجاح/فشل التهيئة) |
| PHASE 2.2 | Unit + Widget + **Integration إلزامي** لتدفق OTP الكامل |
| PHASE 2.3-2.4 | Unit للـ Repository + Widget للشاشات + Integration لسيناريو Cache واحد |
| PHASE 2.5-2.6 | Unit + Widget + **Integration إلزامي** لكل انتقال حالة رئيسي في دورة التوصيل |
| PHASE 2.7 | **Integration إلزامي** شامل لكل سيناريوهات الانقطاع |
| PHASE 2.8-2.9 | Unit + Widget، Integration اختياري إلا لمسار البيانات المالية (Earnings) |
| PHASE 2.10 | Unit + **Integration إلزامي** للأمان (Fail-Closed، Token Refresh) |
| PHASE 2.11 | مراجعة تغطية شاملة، لا نسبة رقمية ثابتة مفروضة، بل تغطية لكل Acceptance Criteria في هذا المستند |

### أنواع الاختبارات المطلوبة عبر الخارطة
Unit Tests، Repository Tests، Service Tests، State Management Tests (Riverpod)، Widget Tests، Navigation Tests (GoRouter Guards من PHASE 2.2)، Database Tests (`DriverDatabase`)، Offline Queue Tests، Sync Tests، Authentication Tests، Token Refresh Tests، Integration Tests، Android Runtime Tests (يدوي على جهاز فعلي عند إغلاق كل مرحلة كحد أدنى).

### الميزات التي لا يجوز دمجها بدون Integration Test
- Authentication (PHASE 2.2) بالكامل.
- Accept/Reject Delivery (PHASE 2.5).
- كل دورة Active Delivery Flow (PHASE 2.6).
- كل سيناريوهات Offline/Recovery (PHASE 2.7).
- Certificate Pinning + Token Refresh (PHASE 2.10).

**تنبيه صريح:** نسبة تغطية الكود (Code Coverage %) **لا تضمن الجودة بمفردها** — الأولوية لتغطية Acceptance Criteria والمسارات الحرجة (Happy Path + أهم Edge Cases)، لا للوصول إلى نسبة رقمية شكلية.

---

## 20. Git Strategy (المرحلة 9)

- **لا عمل مباشر على Baseline Branch** (الفرع الحالي الذي يحتوي `429c140`). كل مرحلة/ميزة على Branch مستقل.
- **Naming Convention:**
  - `feature/driver-auth-foundation` (PHASE 2.2)
  - `feature/driver-profile` (PHASE 2.3)
  - `feature/driver-availability` (PHASE 2.4)
  - `feature/delivery-request-flow` (PHASE 2.5)
  - `feature/active-delivery` (PHASE 2.6)
  - `feature/offline-recovery` (PHASE 2.7)
  - `feature/driver-notifications` (PHASE 2.8)
  - `feature/earnings-history` (PHASE 2.9)
  - `feature/security-hardening` (PHASE 2.10)
  - `chore/bootstrap-service-activation` (PHASE 2.1، لأنه ليس Feature مستخدم-نهائي بل تفعيل بنيوي)
- **Commit Convention:** Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`, `docs:`, `refactor:`) — مطابق لما استُخدم في `429c140`.
- **Commit صغير ومترابط:** كل Commit يمثل تغييرًا منطقيًا واحدًا قابلًا للمراجعة والـ Revert المستقل.
- **Quality Gate قبل الدمج:** `flutter analyze` = 0 Errors، `flutter test` بلا فشل، مراجعة (Bugbot/Code Review) قبل الدمج لكل Branch.
- **عدم خلط إصلاحات غير مرتبطة:** أي إصلاح Bug غير مرتبط بالمرحلة الحالية يُفتَح له Branch/Commit مستقل (`fix/...`)، لا يُدمَج ضمن Commit ميزة.
- **`429c140` يبقى مرجع رجوع دائم** — لا Rebase أو Amend عليه، ويُستخدَم للمقارنة (`git diff 429c140...HEAD`) عند كل تقييم.

---

## 21. Quality Gates

| البوابة | متى تُفحَص |
|---|---|
| Architecture Compliance (Driver-only, لا Customer/Merchant/Admin) | نهاية كل مرحلة |
| `flutter analyze` = 0 Errors | قبل كل Merge |
| `flutter test` = جميعها ناجحة | قبل كل Merge |
| Integration Tests الإلزامية (§19) | قبل إغلاق المرحلة المعنية |
| Runtime Check على جهاز فعلي | قبل إغلاق كل مرحلة |
| Security Review | قبل إغلاق PHASE 2.2 و 2.10 |
| Mock/Production Separation مُختبَرة | قبل إغلاق PHASE 2.10 |
| لا Regression في تغطية أو سلوك سابق | قبل كل Merge |

---

## 22. Definition of Ready (لبدء أي مرحلة)
1. المرحلة السابقة مُغلَقة رسميًا (Definition of Done مستوفاة).
2. الاعتماديات المذكورة في §11 متوفرة.
3. Backend Contract (Mock على الأقل) معتمَد لو كانت المرحلة تتطلب Backend.
4. لا قرار هندسي معلَّق يخص نطاق المرحلة (راجع PHASE 2.0).
5. Branch مستقل بالاسم الصحيح (§20) جاهز للبدء.

## 23. Definition of Done (لإغلاق أي مرحلة)
1. جميع Acceptance Criteria المذكورة في وصف المرحلة (§11) مستوفاة بدليل (لا افتراض).
2. `flutter analyze` = 0 Errors، `flutter test` بلا فشل، لا Regression.
3. الاختبارات الإلزامية للمرحلة (Unit/Widget/Integration بحسب §19) منفَّذة وناجحة.
4. Runtime Check حقيقي على جهاز Android منفَّذ ومُوثَّق.
5. لا مشكلة Critical/High مفتوحة متعلقة بنطاق المرحلة.
6. توثيق قصير لما تم (تقرير أو تعليق PR) يشرح ما نُفِّذ وما تأجَّل ولماذا.

---

## 24. سجل المخاطر

| # | الخطر | الفئة | الخطورة | الأثر | الإجراء المقترح | المرحلة |
|---|---|---|---|---|---|---|
| 1 | تفعيل الخدمات المؤجلة الست دفعة واحدة يرفع مخاطر الانحدار بشدة | Architecture/Runtime | **High** | فشل غير متوقع في أكثر من نقطة معًا يصعب تتبعه | تفعيل تدريجي بحسب §14 (مرحلة واحدة كل مرة)، لا دفعة واحدة | 2.1، 2.4، 2.10 |
| 2 | دين ترجمة (النصوص ثابتة إنجليزية رغم اختيار العربي) قد يُكتشَف متأخرًا | UX/Quality | **Medium** | تجربة مستخدم مضلِّلة لمستخدم عربي حقيقي | إصلاحه صريحًا ضمن PHASE 2.9 قبل أي إعلان دعم عربي فعلي | 2.9 |
| 3 | ازدواجية DI (`AppServiceRegistry` مقابل `service_locator.dart` الميت) قد تُستخدَم بالخطأ في ميزة جديدة | Architecture | **Medium** | تضارب حالة الخدمات بين مسارين مختلفين | حسم قرار الإزالة/الدمج في PHASE 2.0 قبل أي ميزة | 2.0 |
| 4 | غياب Repository Pattern حاليًا يعني كل ميزة أولى (Auth) ستُحدِّد النمط لما بعدها | Architecture | **Medium** | نمط غير موحَّد إذا لم يُثبَّت مبكرًا | تثبيت اتفاقية Repository/Domain Model في PHASE 2.0 قبل PHASE 2.2 | 2.0 |
| 5 | Concurrency حقيقي (قبول طلب من سائقين) لا يمكن اختباره بالكامل بـ Mock | Testing | **High** | ثغرة منطقية لا تُكتشَف إلا في بيئة حقيقية/Staging | تخصيص اختبار حمل (Load Test) مبكر على Staging عند توفره لـ PHASE 2.5 | 2.5، Staging مستقبلي |
| 6 | تفعيل Certificate Pinning بشهادة خاطئة يقطع كل الاتصال فورًا (Fail-Closed) | Security | **High** | تعطّل كامل للتطبيق إذا فُعِّل بشهادة غير صحيحة في Production | اختبار مكثَّف في Staging قبل أي إصدار، خطة Rollback جاهزة (تدوير شهادة) | 2.10 |
| 7 | تغطية اختبارات ضعيفة موروثة من مرحلة الاستقرار (3 اختبارات فقط) | Testing | **Medium** | ثقة منخفضة في أي Regression مبكر | رفع التغطية تدريجيًا بحسب §19 من أول مرحلة (2.1) | جميع المراحل |
| 8 | Backend غير موجود فعليًا بعد — كل التخطيط هنا نظري حتى توفره | Delivery/Planning | **Medium** | تأخير حقيقي عند الانتقال من Mock لـ Real API | البدء بتنسيق Backend Contract (§15) مع فريق الخادم بالتوازي مع 2.0-2.1 | جميع المراحل |
| 9 | Idempotency غير مطبَّقة بعد في أي عملية فعلية (لا يوجد كود Backend حتى الآن) | Backend/Architecture | **Medium** | عمليات مكرَّرة (قبول مزدوج، تسليم مزدوج) عند إعادة المزامنة | تثبيت Idempotency Key كشرط إلزامي في كل Contract حرج (§15) من التصميم الأول | 2.5، 2.6، 2.7 |
| 10 | صلاحيات الموقع الجغرافي في الخلفية (Background Location) حساسة وتتطلب مراجعة متجر التطبيقات | Compliance/Security | **Medium** | رفض من متجر التطبيقات أو مشاكل خصوصية إن نُفِّذت دون سياسة واضحة | تأجيلها لـ P2/P3، البدء بـ Foreground Location فقط في MVP | خارج MVP |

---

## 25. الديون التقنية (موروثة + مكتشَفة في هذه المهمة)

| # | الدين | المصدر |
|---|---|---|
| 1 | مسار DI ميت مكرِّر (`service_locator.dart` عبر `get_it`) غير مستخدَم فعليًا | موروث من قبل STABILIZATION |
| 2 | كلاسات Placeholder تافهة غير مستخدَمة (`AuthService`, `StorageService`) تتداخل مفهوميًا مع الخدمات الحقيقية | موروث |
| 3 | `AppLocalizations` نصوص ثابتة إنجليزية بلا تفرّع لغوي حقيقي (اكتشاف هذه المهمة) | مكتشَف الآن |
| 4 | `AppErrorHandler`/`AppException`/`AppFailure` غير مُختبَرة بأي سيناريو خطأ حقيقي بعد | موروث |
| 5 | `ConsoleLoggerService` يستخدم `print()` مباشرة (قرار مؤقت من STEP 2B سابقًا) | موروث |
| 6 | `redirect` guard في `AppRouter` معلَّق كـ TODO، لا حماية مصادقة فعلية على أي Route حاليًا | موروث/مكتشَف الآن |
| 7 | 7 Warnings و28 Info في `flutter analyze` (موروثة من Baseline، غير مصلَحة عمدًا) | موروث (`STABILIZATION_FINAL_QUALITY_GATE.md`) |

---

## 26. التقدير النسبي للحجم (ملخص من §11)

| المرحلة | التقدير |
|---|---|
| 2.0 | XS |
| 2.1 | S |
| 2.2 | L |
| 2.3 | M |
| 2.4 | M |
| 2.5 | XL |
| 2.6 | XL |
| 2.7 | L |
| 2.8 | M |
| 2.9 | M |
| 2.10 | L |
| 2.11 | M |

**الأثقل وضوحًا: PHASE 2.5 و PHASE 2.6** (منطق أعمال معقّد + حالة متعددة الخطوات + Concurrency) — هذا متوقَّع لأنهما جوهر عمل السائق.

---

## 27. أول Feature موصى بها

### مقارنة الخيارات الخمسة

| الخيار | المخاطرة | القيمة التأسيسية | توافق مع الحالة الحالية | اعتماد على خدمات غير مهيأة | قابلية الاختبار | يحتاج Backend Production؟ | تمهيد لما بعده |
|---|---|---|---|---|---|---|---|
| 1. Authentication Foundation | متوسطة-عالية | عالية جدًا | جيد (يحتاج `ApiClient` فعّال) | متوسط (`ApiClient`, JWT الأساسي) | جيدة (Mock ممكن) | لا (Mock كافٍ للبدء) | يمهِّد لكل شيء آخر |
| 2. Driver Profile | منخفضة-متوسطة | متوسطة | جيد | يحتاج Auth أولًا فعليًا | جيدة | لا | يمهِّد لـ Availability |
| 3. Driver Availability | منخفضة-متوسطة | متوسطة | يحتاج Auth+Profile أولًا | يحتاج `OfflineQueue`/`NetworkMonitor` | جيدة | لا | يمهِّد لـ Delivery Flow |
| 4. Delivery Request Flow | **عالية** | عالية جدًا | يحتاج كل ما سبقه | يحتاج كل الخدمات تقريبًا | معقّدة (Concurrency) | نعم لاحقًا | جوهر التطبيق، لكن سابق لأوانه الآن |
| **5. App Bootstrap and Service Activation** | **منخفضة** | **عالية جدًا (تأسيسية بحتة)** | **الأنسب — لا يتطلب أي منطق أعمال جديد** | **صفر — هو نفسه تفعيل الخدمات** | **عالية (Unit فقط، محلي بالكامل)** | **لا إطلاقًا** | **يُمهِّد فعليًا لكل الميزات دون استثناء** |

### التوصية الرسمية

## **✅ PHASE 2.1 — App Bootstrap and Service Activation**

---

## 28. سبب اختيارها

1. **أقل مخاطرة بشكل واضح:** لا منطق أعمال جديد، فقط تفعيل خدمات موجودة ومترجَمة بالفعل (`DriverDatabase`, `NetworkMonitor`) ضمن `AppServiceRegistry` — نطاق محدود ومعروف تمامًا.
2. **أعلى قيمة تأسيسية:** بدون هذه الخطوة، **كل** الميزات اللاحقة (Auth، Profile، Availability، Delivery) ستحتاج إعادة فتح نفس ملف `AppServiceRegistry` بشكل متكرر ومتشابك — تفعيلها مرة واحدة الآن يمنع تكرار هذا العمل لاحقًا.
3. **لا اعتماد على خدمات غير مهيأة أصلًا** — هي بالتعريف عملية "تهيئة" الخدمات، فلا حلقة اعتماد دائرية.
4. **قابلة للاختبار بالكامل محليًا** — Unit Tests فقط، بلا Mock API، بلا Backend، بلا انتظار أي طرف خارجي.
5. **لا تحتاج Backend Production إطلاقًا** — كل ما فيها محلي (قاعدة بيانات SQLite محلية + كشف اتصال الشبكة، بلا استدعاء API فعلي).
6. **تمهيدية بامتياز** — تفتح الطريق مباشرة لـ PHASE 2.2 (Authentication) دون أي عائق تقني متبقٍ في طبقة الخدمات الأساسية.

---

## 29. ما يجب فعله قبل تنفيذها

1. إغلاق **PHASE 2.0** أولًا: حسم قرار `service_locator.dart` (إزالة أم إبقاء كمرجع تعليمي معطَّل؟) — **قرار مطلوب من المستخدم**، لأنه يؤثر على أين تُهيَّأ الخدمات الجديدة (فقط `AppServiceRegistry`، أم في المسارَين معًا؟).
2. حسم اتفاقية معالجة فشل تهيئة قاعدة البيانات (Graceful Degradation): هل يستمر التطبيق بدون قاعدة بيانات مع تحذير، أم يفشل بالكامل؟ — **قرار منتج/هندسي مطلوب** قبل الكتابة.
3. لا حاجة لأي عمل Backend أو Mock قبل هذه المرحلة تحديدًا.

## 30. ما يمنع بدءها

- عدم توفر قرار صريح بخصوص `service_locator.dart` (سيؤدي لعمل غامض النطاق).
- عدم توفر قرار بخصوص سلوك فشل تهيئة قاعدة البيانات.
- لا يوجد عائق تقني آخر — البنية والكود جاهزان بالفعل (مؤكَّد بالفحص المباشر في §9).

---

## 31. المرحلة التالية المقترحة

**PHASE 2.0 — Development Readiness** (حسم القرارات الهندسية المذكورة في §29)، تليها مباشرة **PHASE 2.1 — App Bootstrap and Service Activation** بعد موافقة المستخدم الصريحة على القرارات، ثم فقط عندها تُنشأ أول Branch فعلية (`chore/bootstrap-service-activation`) وتبدأ أول جلسة كتابة كود فعلي — **لا شيء من ذلك يبدأ في هذه المهمة**.

---

## 32. نسبة الثقة في الخطة

| الجانب | النسبة | السبب |
|---|---|---|
| دقة تقييم الحالة الحالية للكود (§9) | **97%** | فحص مباشر لكل ملف عبر Read/Grep، لا افتراضات — بما فيها اكتشاف دين الترجمة والخدمات الميتة |
| واقعية تعريف MVP (§6) | **85%** | مبني على طلب المستخدم الصريح + معرفة الحالة الحالية، لكن يعتمد على قرارات منتج مستقبلية (نطاق Proof of Delivery، إلخ) قد تتغيّر |
| دقة تقدير الحجم (§26) | **70%** | تقديرات نسبية أولية بلا تفصيل تنفيذي كامل بعد؛ عادة تتغيّر ±30% عند بدء التنفيذ الفعلي |
| دقة عقود Backend المقترحة (§15) | **65%** | مقترحات تخطيطية صريحة، تحتاج مراجعة فعلية من فريق Backend/ADR مستقل قبل الاعتماد النهائي |
| **الثقة الإجمالية في الخطة كخارطة طريق عامة** | **85%** | خطة شاملة ومبنية على أدلة كود فعلية، مع وضوح كامل حول ما هو مؤكَّد (حالة الكود) وما هو تقديري (الحجم، الجدول الزمني، تفاصيل Backend) |

---

## 33. الملفات المعدَّلة في هذه المهمة

| # | الملف | نوع التعديل |
|---|---|---|
| 1 | `docs/PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md` | **إنشاء جديد (هذا الملف فقط)** |

**لم يُعدَّل أي ملف آخر.** لا كود Dart، لا Android/iOS، لا `pubspec.yaml`، لا Dependencies، لا خدمة مؤجلة تم تفعيلها، لا API حقيقي، لا شاشة جديدة، لا UI، لا Router، لا Feature، لا `flutter clean`/`pub upgrade`، لا `git commit`/`git push`/Branch جديد، لا تعديل على `flutter_analyze_report.txt`، لا تعديل على Baseline Commit `429c140`.

---

---

## تحديث لاحق — PHASE 2.1 نُفِّذت

**تاريخ التحديث:** 2026-07-25

تم تنفيذ **PHASE 2.1 — App Bootstrap and Service Activation** على فرع `feature/app-bootstrap-service-activation` (من `429c140`). `DriverDatabase` و `NetworkMonitor` أصبحا مُفعَّلين فعليًا داخل `AppServiceRegistry` بسياسة فشل غير حرج (Non-Critical Failure Policy) مُختبَرة بالوحدة (Unit Tests) ومُتحقَّقة على جهاز Android فعلي. التفاصيل الكاملة في `docs/PHASE_2_1_APP_BOOTSTRAP_SERVICE_ACTIVATION_REPORT.md`.

**تحديث حالة الخدمات (كان في §13/§14 أعلاه "DEFERRED"):**

| الخدمة | الحالة السابقة (وقت كتابة هذا المستند) | الحالة الحالية بعد PHASE 2.1 |
|---|---|---|
| `DriverDatabase` | DEFERRED | **READY** (مُفعَّلة، بفشل غير حرج مُعالَج) |
| `NetworkMonitor` | DEFERRED | **READY** (مُفعَّلة، بفشل غير حرج مُعالَج ذاتيًا) |

لم يتغيّر أي شيء آخر في هذا المستند؛ باقي المراحل (2.2 فصاعدًا) لم تبدأ بعد.

---

## تحديث لاحق — PHASE 2.2 نُفِّذت

**تاريخ التحديث:** 2026-07-25

تم تنفيذ **PHASE 2.2 — Authentication Foundation** على فرع `feature/driver-auth-foundation` (من Commit `271af18`). أُضيفت: Domain models، `AuthenticationRepository` contract، `FakeAuthenticationRepository` (مع Production guard)، `AuthSessionStorage`، `AuthController` (Riverpod)، Navigation Guards، شاشة Login تجريبية، وLogout داخل `HomeScreen`. التفاصيل الكاملة في `docs/PHASE_2_2_AUTHENTICATION_FOUNDATION_REPORT.md`.

**تحديث حالة عناصر المصادقة:**

| العنصر | الحالة السابقة | الحالة الحالية بعد PHASE 2.2 |
|---|---|---|
| Authentication Domain Models | MISSING | **READY** |
| Authentication Repository Contract | MISSING | **READY** |
| Fake Authentication Repository | MISSING | **READY** (محمي من Production) |
| Session Persistence | MISSING | **READY** |
| Auth State Management | MISSING | **READY** |
| Startup Session Restoration | MISSING | **READY** |
| Navigation Guards | PLACEHOLDER | **READY** |
| Login / Logout UI | MISSING | **READY** (تجريبي) |
| Backend / OTP / JWT Production | — | **مؤجّل** (خارج نطاق 2.2) |

---

**نهاية التقرير. تم التوقف وفق تعليمات المهمة — بانتظار المراجعة قبل بدء PHASE 2.3.**
