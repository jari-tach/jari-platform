# PROJECT STABILIZATION — الخطوة 1: تشخيص شامل لحالة التصريف (Compilation Diagnosis)

> **الحالة:** تشخيص فقط — لا يحتوي هذا المستند على أي إصلاح.
> **التاريخ:** 2026-07-24
> **الأوامر المنفَّذة بالترتيب:** `flutter clean` ← `flutter pub get` ← `flutter analyze` ← `flutter test`
> **بيئة التنفيذ:** Flutter 3.44.7 (stable) • Dart 3.12.2

---

## 1- ملخص الحالة العامة

| السؤال | الإجابة |
|---|---|
| هل المشروع Compiles بالكامل (`lib/` كاملة)؟ | **لا.** يوجد 105 خطأ تصريف (Compilation Errors) موزّعة على 12 ملفاً ضمن `lib/`. |
| هل يتوقف أثناء التحليل (`flutter analyze`)؟ | لا يتوقف بشكل كامل، بل ينهي الفحص ويطبع تقريراً كاملاً بجميع المشاكل (105 أخطاء + 8 تحذيرات + 32 ملاحظة = **145 مشكلة**)، وينتهي بـ Exit Code يشير إلى فشل البوابة. |
| هل يتوقف أثناء الاختبارات (`flutter test`)؟ | **لا** — الاختبارات الثلاثة الموجودة في `test/widget_test.dart` تنجح **3/3 (100%)**. |

**السبب المهم وراء هذا التناقض الظاهري (أخطاء تصريف كثيرة + اختبارات ناجحة):**

اختبارات `widget_test.dart` تعتمد على `test/test_bootstrap.dart` الذي يبني تطبيقاً مصغّراً (`TestApp`) يستورد فقط:
`app_localizations.dart`, `app_providers.dart`, `app_theme.dart`.

هذا المسار **لا يمرّ إطلاقاً** عبر `AppServiceRegistry`، ولا عبر `SecureStorageService`، ولا `DriverDatabase`، ولا `SyncManager`، ولا `SecurityInterceptors` — أي أن الاختبارات الحالية **لا تفحص الأجزاء المكسورة من المشروع على الإطلاق**. لذلك نجاح الاختبارات حالياً **لا يعني** أن التطبيق الحقيقي (`main.dart` → `AppServiceRegistry.init()`) يعمل أو حتى يمكن تصريفه، لأن `main.dart` نفسه يستدعي مسارات تحتوي على الأخطاء المذكورة أدناه.

**الخلاصة:** المشروع **لا يُصرَّف بالكامل** حالياً. أي محاولة تشغيل فعلية (`flutter run`) أو بناء (`flutter build`) ستفشل، رغم أن حزمة الاختبارات الحالية (الضيقة النطاق) تنجح.

---

## 2- إحصائية الأخطاء

| النوع | العدد |
|---|---|
| **Errors** | **105** |
| **Warnings** | **8** |
| **Info** | **32** |
| **الإجمالي** | **145** |

---

## 3- تصنيف الأخطاء

| # | المجموعة | عدد الأخطاء (Errors) | ملاحظات |
|---|---|---|---|
| A | **Drift / Generated Files / Part Files** — قاعدة البيانات المحلية | **~62** | أكبر مجموعة بفارق كبير؛ تشمل: `undefined_method` لـ `select/into/update/delete` (29)، `non_type_as_type_argument` لأنواع الجداول (6)، `undefined_class` لأصناف الـ Companion (5)، `undefined_identifier` لأسماء الجداول ومكتبة `sqlite3` (12 تقريباً)، `undefined_function NativeOpenParams` (1)، `uri_has_not_been_generated` لملف `.g.dart` (1)، بالإضافة إلى الأخطاء المرتبطة بها في القسم H وI أدناه |
| B | **الاستيراد المكسور لـ logger_service.dart (Imports / Missing Files)** | **3** (`uri_does_not_exist`) | يتسبب مباشرة في 3 أخطاء إضافية `undefined_class LoggerService` |
| C | **عدم تطابق توقيع LoggerService (Logging API Mismatch)** | **23** | `extra_positional_arguments_could_be_named` (17) + `undefined_named_parameter tag/data` (6) |
| D | **دوال مفقودة في SecureStorageService (Authentication / Security)** | **5** | `getAccessToken` (×3)، `getRefreshToken` (×1)، `clearAllAuthData` (×1) |
| E | **تعارض تسمية (Ambiguous Import)** | **2** | صنف `OfflineQueue` معرَّف مرتين: مرة يدوياً في `offline_queue.dart`، ومرة كجدول Drift في `driver_database.dart` |
| F | **صنف ApiClient غير معرَّف (Dio Wiring)** | **2** | استيراد مفقود داخل `security_interceptors.dart` |
| G | **Certificate Pinning غير مكتمل (Security)** | **2** | `X509Certificate.pin` غير معرَّف، `_calculateSha256` غير معرَّفة |
| H | **Null Safety** | **10** | وصول غير آمن لخصائص قد تكون `null` في `offline_queue.dart` |
| I | **Type Mismatch / Return Type** | **3** | أنواع إرجاع خاطئة في `sync_manager.dart` (متعلقة بالمجموعة A) |
| J | **Riverpod / Error Handling** | **2** | `non_exhaustive_switch_expression` على `AppException`، و`loggerServiceProvider` غير معرَّف |
| K | **GoRouter** | **0** | لا توجد أي أخطاء تصريف في `app_router.dart` حالياً |
| L | **BuildContext** | **0** | لا توجد أخطاء متعلقة بـ BuildContext عبر Async Gaps حالياً |
| — | **مجموع الأخطاء (Errors)** | **105** | |
| M | **تحذيرات (Warnings)** | **8** | متغيرات/حقول غير مستخدَمة (5)، `override` غير صحيح (2)، إلخ |
| N | **ملاحظات أسلوبية (Info / Lint)** | **32** | `prefer_initializing_formals` (22)، `use_super_parameters` (3)، `avoid_print` (2)، `recursive_getters` (3، مرتبطة بـ A)، أخرى (2) |

---

## 4- ترتيب الإصلاح (تسلسل مقترح فقط — دون تنفيذ)

1. **المجموعة B** — إصلاح مسارات الاستيراد المكسورة لـ `logger_service.dart`
2. **المجموعة A** — إضافة Annotation المفقودة لـ Drift وتوليد الكود (`driver_database.g.dart`)
3. **المجموعة E** — حل تعارض تسمية `OfflineQueue` (يعتمد على استقرار المجموعة A)
4. **المجموعة H وI** — إصلاح مشاكل Null Safety وأنواع الإرجاع في طبقة العمل بدون إنترنت (تعتمد على A)
5. **المجموعة C** — توحيد توقيع `LoggerService` مع جميع نقاط الاستخدام
6. **المجموعة D** — إضافة/كشف الدوال المفقودة في `SecureStorageService`
7. **المجموعة F** — إصلاح استيراد `ApiClient` المفقود
8. **المجموعة G** — استكمال منطق Certificate Pinning
9. **المجموعة J** — إكمال حالة `switch` على `AppException` وتعريف `loggerServiceProvider`
10. **المجموعة M** — تنظيف التحذيرات (Warnings)
11. **المجموعة N** — تنظيف الملاحظات الأسلوبية (Info/Lint)، ويمكن جزء كبير منها عبر `dart fix --apply`

**سبب هذا الترتيب:** المجموعتان B وA هما "الحاجزان البنيويان" الأساسيان اللذان تتفرّع منهما أو تتشابك معهما بقية المجموعات (E، H، I). إصلاحهما أولاً يوضّح الصورة الحقيقية لعدد الأخطاء المتبقية الفعلي، بينما بقية المجموعات (C، D، F، G، J) مستقلة نسبياً عن بعضها ويمكن إصلاحها بأي ترتيب بعد ذلك. التحذيرات والملاحظات الأسلوبية لا تمنع التصريف إطلاقاً، لذا تأتي أخيراً.

---

## 5- السبب الجذري لكل مجموعة

**A — Drift / Generated Files:**
صنف `DriverDatabase` معرَّف كـ `class DriverDatabase extends _$DriverDatabase` (سطر 18)، والصنف `_$DriverDatabase` يُفترض أن يُولَّد تلقائياً بواسطة `build_runner` من خلال Annotation باسم `@DriftDatabase(tables: [...])`. **هذه الـ Annotation غير موجودة فوق تعريف الصنف**، ولم يتم تشغيل `build_runner` لتوليد ملف `driver_database.g.dart` (المُشار إليه في `part 'driver_database.g.dart'`). نتيجة ذلك: الصنف الأساس `_$DriverDatabase` غير موجود أصلاً، وكل الدوال المتوقَّع أن يوفرها Drift تلقائياً (`select`, `into`, `update`, `delete`) تصبح غير معرَّفة، وكل أصناف الجداول (`DriverProfilesCompanion` وغيرها) غير موجودة لأنها أيضاً جزء من الكود المولَّد. كذلك، منطق فتح قاعدة البيانات في نهاية الملف يستخدم استدعاءات مباشرة لمكتبة `sqlite3` (`sqlite3.openSetOpenFlags`, `NativeOpenParams`) بأسلوب غير قياسي وغير متوافق مع الحزم المستوردة فعلياً في الملف.

**B — استيراد logger_service.dart:**
خطأ في عدد مستويات `../` في المسار النسبي. مثال: `app_error_handler.dart` موجود في `lib/core/services/error/`، والاستيراد المكتوب هو `../services/logger/logger_service.dart` والذي يُحلَّل إلى `lib/core/services/services/logger/logger_service.dart` (مسار غير موجود، لاحظ تكرار `services`)، بينما المسار الصحيح هو `../logger/logger_service.dart` فقط. نفس النمط بالضبط يتكرر في `secure_storage_service.dart`، وبفارق مستوى واحد إضافي في `driver_database.dart`.

**C — عدم تطابق توقيع LoggerService:**
واجهة `LoggerService` تتوقع معاملات مسمّاة (Named Parameters) مثل `error:`, `stackTrace:`, `metadata:`، بينما نقاط الاستدعاء في `network_monitor.dart`, `offline_queue.dart`, `sync_manager.dart`, `security_interceptors.dart`, `api_interceptors.dart` تستدعي الدالة بمعاملات موضعية (Positional) إضافية، أو بمعاملات مسمّاة غير موجودة أصلاً في التعريف (`tag`, `data`). هذا يدل على أن هذه الملفات كُتبت باعتماد على نسخة أخرى (أو مفترضة) من `LoggerService` لم تُطابق النسخة الفعلية النهائية.

**D — دوال مفقودة في SecureStorageService:**
الصنف الفعلي لا يوفر الدوال `getAccessToken`, `getRefreshToken`, `clearAllAuthData` رغم أن ثلاثة مستهلكين مختلفين (`service_locator.dart`, `security_interceptors.dart`, `app_service_registry.dart`) يفترضون وجودها. هذا يعني أن الواجهة (Interface) الفعلية لهذه الخدمة أضيق مما تتطلبه بقية طبقات الأمان والمصادقة.

**E — تعارض تسمية OfflineQueue:**
يوجد صنفان بنفس الاسم `OfflineQueue`: واحد يدوي (نموذج بيانات في `offline_queue.dart`) وآخر هو جدول Drift المولَّد داخل `driver_database.dart`. عند استيراد الملفين معاً في `sync_manager.dart` يصبح الاسم غامضاً (Ambiguous) لأن المترجم لا يعرف أيهما تقصد.

**F — ApiClient غير معرَّف:**
`security_interceptors.dart` يستخدم النوع `ApiClient` (في `TokenRefreshManager`) دون استيراد الملف الذي يعرّفه (`lib/core/services/api/api_client.dart`).

**G — Certificate Pinning غير مكتمل:**
هذا الجزء مكتوب كهيكل أولي (Skeleton) عن قصد ولم يُستكمل: لا توجد قيمة حقيقية لـ `pin` على `X509Certificate` (هذه الخاصية أصلاً غير موجودة في مكتبة `dart:io` بهذا الاسم)، ودالة حساب البصمة `_calculateSha256` غير مُعرَّفة داخل الصنف رغم استدعائها.

**H — Null Safety في offline_queue.dart:**
الكود يفترض أن نتيجة الاستعلام من Drift (Row) غير قابلة لأن تكون `null` ويصل لخصائصها مباشرة، بينما التوقيع الفعلي (الناتج عن كسر توليد Drift في المجموعة A) يُرجع نوعاً قابلاً لـ `null`. هذا الخطأ مرتبط بنيوياً بالمجموعة A ومن المتوقع أن يتغير شكله بعد إصلاحها.

**I — Type Mismatch في sync_manager.dart:**
دوال مثل `processQueue` و`getLastSyncTime` تُعرَّف بنوع إرجاع `Future<SyncResult>` أو `Future<DateTime?>`، لكن أجسامها الفعلية (بسبب استعلامات Drift غير المكتملة من المجموعة A) تُرجع قيماً من نوع مختلف (Function أو Column بدلاً من القيمة الفعلية المنتظرة بعد `await`).

**J — Riverpod / Error Handling:**
`switch` على `AppException` في `app_error_handler.dart` لا يغطي كل الحالات الفرعية المعرَّفة في الـ Sealed Class (تنقصه حالة `SerializationException`)، و`loggerServiceProvider` مُستخدَم دون أن يكون معرَّفاً كـ Riverpod Provider في أي مكان بالمشروع.

---

## 6- الملفات المتأثرة بكل مجموعة

| المجموعة | الملفات |
|---|---|
| A — Drift | `lib/features/driver/data/datasources/local/driver_database.dart`، `lib/core/offline/offline_queue.dart`، `lib/core/offline/sync_manager.dart` |
| B — استيراد logger | `lib/core/services/error/app_error_handler.dart`، `lib/core/services/storage/secure_storage_service.dart`، `lib/features/driver/data/datasources/local/driver_database.dart` |
| C — توقيع Logger | `lib/core/network/network_monitor.dart`، `lib/core/offline/offline_queue.dart`، `lib/core/offline/sync_manager.dart`، `lib/core/security/security_interceptors.dart`، `lib/core/services/api/api_interceptors.dart` |
| D — SecureStorageService | `lib/core/di/service_locator.dart`، `lib/core/security/security_interceptors.dart`، `lib/shared/services/app_service_registry.dart` |
| E — تعارض OfflineQueue | `lib/core/offline/sync_manager.dart` |
| F — ApiClient | `lib/core/security/security_interceptors.dart` |
| G — Certificate Pinning | `lib/core/security/security_interceptors.dart` |
| H — Null Safety | `lib/core/offline/offline_queue.dart` |
| I — Type Mismatch | `lib/core/offline/sync_manager.dart` |
| J — Riverpod/Error Handling | `lib/core/services/error/app_error_handler.dart` |
| M/N — تحذيرات وملاحظات | تنتشر عبر: `app_config.dart`، `network_monitor.dart`، `offline_queue.dart`، `sync_manager.dart`، `security_interceptors.dart`، `api_interceptors.dart`، `app_failure.dart`، `logger_service.dart`، `driver_database.dart`، `app_service_registry.dart` |

**ملاحظة:** الملفات `offline_queue.dart`، `sync_manager.dart`، و `driver_database.dart` مشتركة بين عدة مجموعات (A، C، E، H، I)، مما يجعلها الملفات الأكثر "تشابكاً" في المشروع، ويُنصَح بمعالجتها كوحدة واحدة مترابطة بدل معالجتها ملفاً تلو الآخر بمعزل عن الباقي.

---

## 7- عدد الأخطاء المتوقع بعد إصلاح كل مجموعة

| بعد إصلاح | العدد الحالي | الانخفاض المتوقع | الأخطاء المتبقية التقريبية |
|---|---|---|---|
| **B** (مسارات logger) | 105 | ~6 (3 uri + 3 undefined_class المباشرة) | ~99 |
| **A** (Drift + توليد الكود) | ~99 | ~55-60 (تُحل تلقائياً جميع أخطاء select/into/update/delete/Companion/non_type_as_type_argument وجزء من H وI) | ~40-45 |
| **E** (تعارض OfflineQueue) | ~42 | 2 | ~40 |
| **H** (Null Safety المتبقية) | ~40 | معظمها يُحل ضمن A، والمتبقي (إن وجد) نحو 2-4 | ~36-38 |
| **I** (Type Mismatch المتبقي) | ~37 | يُحل غالباً بالكامل ضمن A، المتبقي قريب من 0 | ~36 |
| **C** (توقيع Logger) | ~36 | 23 | ~13 |
| **D** (SecureStorageService) | ~13 | 5 | ~8 |
| **F** (ApiClient) | ~8 | 2 | ~6 |
| **G** (Certificate Pinning) | ~6 | 2 | ~4 |
| **J** (Riverpod/Error Handling) | ~4 | 2 | ~2 |
| **المتبقي النهائي المتوقع (Errors)** | | | **قريب من 0** |

> الأرقام أعلاه تقريبية وليست دقيقة رياضياً، لأن بعض الأخطاء متشابكة (مثال: إصلاح المجموعة A قد يُظهر أخطاء جديدة كامنة كانت "مخفية" خلف الخطأ الأساسي، وهو أمر معتاد عند إصلاح Codegen مكسور). الاتجاه العام صحيح: **حل A وB يزيل نحو 60% من إجمالي الأخطاء**.

---

## 8- خطة الإصلاح (تسلسل الأولويات دون تنفيذ)

| المجموعة | عدد الأخطاء | الأولوية | الوقت المتوقع | المخاطر |
|---|---|---|---|---|
| B — مسارات استيراد logger | 3 (+3 مشتقة) | حرجة (1) | قصير جداً (دقائق) | منخفضة جداً — تصحيح مسار نصي فقط |
| A — Drift Annotation + Codegen | ~62 | حرجة (2) | متوسط إلى مرتفع (ساعات) | متوسطة — قد تظهر أخطاء جديدة كامنة بعد التوليد، ويحتاج التحقق من توافق أسماء DAO مع الكود المولَّد فعلياً |
| E — تعارض OfflineQueue | 2 | عالية (3) | قصير جداً | منخفضة — يعتمد على إنجاز A أولاً |
| H/I — Null Safety وType Mismatch المتبقية | ~10-13 | عالية (4) | قصير إلى متوسط | منخفضة إلى متوسطة — مرتبطة مباشرة بنتائج A |
| C — توقيع LoggerService | 23 | متوسطة (5) | متوسط (عدد نقاط استدعاء كبير: 5 ملفات) | منخفضة — تغيير ميكانيكي متكرر، لكنه واسع الانتشار |
| D — دوال SecureStorageService | 5 | متوسطة (6) | قصير | منخفضة |
| F — ApiClient غير معرَّف | 2 | متوسطة (7) | قصير جداً | منخفضة جداً |
| G — Certificate Pinning | 2 | منخفضة (8) | قصير إلى متوسط | متوسطة — يتطلب قراراً بشأن آلية التثبيت الفعلية للشهادة |
| J — Riverpod/Error Handling | 2 | منخفضة (9) | قصير جداً | منخفضة جداً |
| M — تحذيرات (Warnings) | 8 | تجميلية (10) | قصير | معدومة |
| N — ملاحظات أسلوبية (Info) | 32 | تجميلية (11) | قصير (جزء كبير آلي عبر `dart fix --apply`) | معدومة |

---

## 9- التقييم النهائي

**هل المشروع قابل للإصلاح بالكامل؟**
نعم. جميع الأخطاء الـ 105 المكتشفة هي أخطاء **تصريف موضعية ومحدودة النطاق** (مسارات استيراد، Codegen غير مُشغَّل، عدم تطابق توقيعات دوال، دوال ناقصة في واجهة صنف)، وليست أخطاء **تصميم معماري جوهري**. لا يوجد تناقض في مبدأ Clean Architecture نفسه، ولا في اختيار Riverpod/GoRouter/Dio/Drift كتقنيات — المشكلة في **مستوى الربط والتنفيذ (Wiring & Implementation)** فقط، تماماً كما هو موصوف في توجيهات مرحلة PROJECT STABILIZATION.

**هل توجد مشاكل معمارية تمنع ذلك؟**
لا توجد عوائق معمارية تمنع الإصلاح. أقرب شيء لمشكلة بنيوية هو تعارض التسمية بين `OfflineQueue` اليدوي والمولَّد من Drift (المجموعة E)، وهذا يُحل بإعادة تسمية أو استخدام Import Prefix، وليس بإعادة تصميم.

**نقطة الانتباه الوحيدة ذات الطابع الهيكلي:** غياب `@DriftDatabase` Annotation فوق `class DriverDatabase` يعني أن أحداً لم يُشغّل `build_runner` منذ كتابة هذا الملف، أو أن الـ Annotation حُذفت بالخطأ لاحقاً. هذا ليس "مشكلة تصميم" بل "خطوة ناقصة في سير العمل".

**ما نسبة الثقة في إمكانية الإصلاح الكامل ضمن حدود PROJECT STABILIZATION (بدون ميزات جديدة)؟**

**نسبة الثقة: 90%.**

الأسباب:
- كل خطأ من الأخطاء الـ 105 له سبب جذري واضح ومحدد تم توثيقه أعلاه، دون أي "غموض" يستدعي قرار تصميم جديد.
- أكبر مجموعتين (A وC) تمثلان معاً نحو 81% من إجمالي الأخطاء، وكلاهما قابل للحل عبر إجراءات معروفة (تشغيل Codegen، وتوحيد توقيع دالة واحدة).
- نسبة الـ 10% المتبقية من عدم اليقين مصدرها احتمال ظهور أخطاء إضافية "كامنة" بعد إصلاح المجموعة A تحديداً (شائع جداً عند إصلاح Codegen مكسور)، واحتمال أن تتطلب مطابقة أسماء الأعمدة/الجداول بين DAO اليدوي والكود المولَّد بعض التعديلات الإضافية غير الظاهرة حالياً في تقرير `flutter analyze` (لأنها ستظهر فقط بعد توليد الكود لأول مرة).

---

*هذا التقرير تشخيصي بحت. لم يتم تعديل أو إنشاء أو حذف أي ملف من ملفات المشروع الأخرى، ولم يتم تنفيذ أي إصلاح.*
