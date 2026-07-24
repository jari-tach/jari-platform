# PROJECT STABILIZATION — الخطوة 2C: استرجاع عقد SecureStorageService فقط (SecureStorageService Contract Recovery Only)

> **الاعتماد على:** [docs/STABILIZATION_STEP_01_DIAGNOSIS.md](./STABILIZATION_STEP_01_DIAGNOSIS.md)، [docs/STABILIZATION_STEP_02A_DRIFT_RECOVERY.md](./STABILIZATION_STEP_02A_DRIFT_RECOVERY.md)، [docs/STABILIZATION_STEP_02B_LOGGER_RECOVERY.md](./STABILIZATION_STEP_02B_LOGGER_RECOVERY.md)
> **النطاق:** إصلاح `SecureStorageService` وجميع أخطاء التصريف الناتجة مباشرة عن عقدها أو استيراداتها فقط.
> **لم يُلمَس:** `OfflineQueue`، `SyncManager`، `ApiClient` (كخدمة)، `Certificate Pinning`، `Riverpod`، ولا أي مجموعة أخرى.
> **التاريخ:** 2026-07-24

---

## 1- عقد SecureStorageService قبل الإصلاح

```dart
import '../services/logger/logger_service.dart'; // ← مسار استيراد مكسور (services/ مكرَّرة)

abstract class SecureStorageService {
  Future<void> init();
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
  // لا توجد أي دوال Token/Session في الواجهة المجرَّدة (Abstract)
}
```

النقطة الجوهرية: التنفيذ الفعلي `SecureStorageServiceImpl` كان يحتوي **بالفعل** على كل دوال الـ Token/Session (`getAccessToken`, `getRefreshToken`, `clearAllAuthData`, وغيرها) كدوال عادية (بدون `@override` لأنها لم تكن جزءاً من العقد)، لكن أي كود يستدعيها عبر **النوع المجرَّد** `SecureStorageService` (وهو الشائع في كل نقاط الحقن Dependency Injection) كان يفشل بخطأ `undefined_method`، لأن التوقيع المعلن للنوع لا يحتوي هذه الدوال أصلاً.

---

## 2- نقاط الاستدعاء التي تم فحصها

تم فحص كل ملف مذكور في التعليمات، بالإضافة إلى بحث شامل في `lib/` كامل:

| الملف | نتيجة الفحص |
|---|---|
| `lib/core/services/storage/secure_storage_service.dart` | الملف الأساسي (العقد + التنفيذ) |
| `lib/shared/services/app_service_registry.dart` | يستخدم `_storage.init()` (متوافق)، ويستدعي `registry._storage.getAccessToken()` بشكل غير متزامن خاطئ داخل `tokenProvider` (متزامن) |
| `lib/core/di/service_locator.dart` | نفس الخطأ تماماً: `sl<SecureStorageService>().getAccessToken()` داخل `tokenProvider` متزامن. **ملاحظة:** هذا الملف غير مستورَد أو مستخدَم من أي مكان آخر في المشروع (`main.dart` لا يستدعيه)، أي أنه كود Wiring بديل غير مفعَّل حالياً، لكنه يبقى جزءاً من `lib/` ويُصرَّف معه |
| `lib/core/services/api/api_client.dart` | لا يستخدم `SecureStorageService` مباشرة؛ يستقبل `tokenProvider` كدالة متزامنة عامة فقط |
| `lib/core/services/api/api_interceptors.dart` | لا يستخدم `SecureStorageService` مباشرة (يستقبل التوكن جاهزاً عبر `tokenProvider`) |
| `lib/core/security/security_interceptors.dart` | يستخدم `_secureStorage.getAccessToken()`، `_secureStorage.getRefreshToken()`، `_secureStorage.clearAllAuthData()` — ثلاث استدعاءات فعلية عبر النوع المجرَّد |
| `auth_service.dart` | **غير موجود في المشروع حالياً** (لا يوجد ملف بهذا الاسم) |
| `main.dart` | لا يستدعي `SecureStorageService` مباشرة (يمرّ عبر `AppServiceRegistry.init()`) |
| ملفات `test/` | لا يوجد أي استخدام لـ `SecureStorageService` في `test/` حالياً (تم البحث الشامل، بدون نتائج) |
| `lib/core/routes/app_router.dart` | إشارة واحدة فقط داخل **تعليق معطَّل (Commented-out code)**: `// final isAuthenticated = sl<SecureStorageService>().getAccessToken() != null;` — غير فعّالة، لم تُلمَس |
| `lib/core/offline/sync_manager.dart` | يحمل حقل `_secureStorage` من النوع `SecureStorageService` لكنه **غير مستخدَم فعلياً** (تحذير `unused_field` موجود ولم يُلمَس، الملف بالكامل خارج نطاق هذه الخطوة) |

**قائمة العقد الفعلي المطلوب فعلياً من الاستدعاءات الحية (غير المعطَّلة/المعلَّقة) فقط:**
`init`, `write`, `read`, `delete`, `deleteAll`, `containsKey` (مستخدَمة داخلياً/في التنفيذ) + `getAccessToken`, `getRefreshToken`, `clearAllAuthData` (مستخدَمة عبر النوع المجرَّد في ملفات أخرى).

لا يوجد أي استدعاء حي عبر النوع المجرَّد لـ `saveAccessToken`, `deleteAccessToken`, `saveRefreshToken`, `deleteRefreshToken`, `saveUserId`, `getUserId`, `deleteUserId`, `saveAuthSession`, `getAuthSession`, `deleteAuthSession` — الاستدعاءات الوحيدة الموجودة لها هي داخل تعليقات معطَّلة (`// TODO` في `security_interceptors.dart`)، لذلك **لم تُضَف** إلى العقد المجرَّد التزاماً بقاعدة "لا تضف دوال مستقبلية غير مستخدمة".

---

## 3- العقد الموحَّد بعد الإصلاح

```dart
import '../logger/logger_service.dart'; // ← مسار مصحَّح

abstract class SecureStorageService {
  Future<void> init();
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);

  // Token/session helpers required by current call sites
  // (security_interceptors.dart, app_service_registry.dart).
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearAllAuthData();
}
```

تمت إضافة **3 دوال فقط** إلى العقد المجرَّد (`getAccessToken`, `getRefreshToken`, `clearAllAuthData`)، وهي الدوال الثلاث الوحيدة المطلوبة فعلياً من نقاط استدعاء حية عبر النوع المجرَّد. تم وضع `@override` عليها في `SecureStorageServiceImpl` (كانت موجودة سلفاً بنفس التوقيع والمنطق، لم يُعدَّل سلوكها الداخلي). باقي دوال التوكن/الجلسة (`saveAccessToken`, `saveRefreshToken`, ...) **بقيت كما هي تماماً** في `SecureStorageServiceImpl` كدوال ملموسة إضافية غير مفروضة في العقد المجرَّد، دون حذف أو تعديل، لأنها ليست مصدر أي خطأ تصريف.

---

## 4- عدد أخطاء SecureStorageService قبل الإصلاح

**8 أخطاء** موزّعة كالتالي (بالقياس على خط الأساس لهذه الخطوة، وهو نتيجة `flutter analyze` بعد STEP 2B — 27 خطأ):

| الملف | الخطأ | العدد |
|---|---|---|
| `lib/core/services/storage/secure_storage_service.dart:3` | `uri_does_not_exist` (استيراد Logger مكسور) | 1 |
| `lib/core/services/storage/secure_storage_service.dart:53,55` | `undefined_class LoggerService` (نتيجة مباشرة للاستيراد المكسور) | 2 |
| `lib/core/security/security_interceptors.dart:34` | `undefined_method getAccessToken` | 1 |
| `lib/core/security/security_interceptors.dart:85` | `undefined_method clearAllAuthData` | 1 |
| `lib/core/security/security_interceptors.dart:215` | `undefined_method getRefreshToken` | 1 |
| `lib/core/di/service_locator.dart:31` | `undefined_method getAccessToken` | 1 |
| `lib/shared/services/app_service_registry.dart:27` | `undefined_method getAccessToken` | 1 |
| **الإجمالي** | | **8** |

---

## 5- عدد أخطاء SecureStorageService بعد الإصلاح

**0 خطأ.** لا يظهر أي خطأ منسوب إلى `SecureStorageService` (لا استيراد، لا دالة مفقودة، لا نوع إرجاع خاطئ) في أي من الملفات السبعة أعلاه بعد نتيجة `flutter analyze` النهائية.

> ملاحظة دقيقة: إضافة الدوال الثلاث إلى العقد كشفت خطأً **جديداً من نوع مختلف تماماً** (لا علاقة له بعقد SecureStorageService نفسه) في `service_locator.dart:31` و `app_service_registry.dart:27`: تمرير نتيجة `getAccessToken()` (وهي `Future<String?>` غير متزامنة) مباشرة إلى `tokenProvider` الذي يتطلب دالة **متزامنة** (`String? Function()`). هذا خطأ استخدام غير صحيح لـ Async **في نقطة الاستدعاء**، وقد تم إصلاحه ضمن هذه الخطوة (انظر القسم 9) لأنه ضروري مباشرة لإتمام توحيد استدعاء الخدمة، دون لمس `ApiClient` أو `AuthInterceptor` (المحظورين).

---

## 6- إجمالي Errors المتبقية في المشروع

**19 خطأ** (بعد أن كانت 27 خطأ في نهاية STEP 2B). **انخفاض بمقدار 8 أخطاء (29.6%↓)** ضمن هذه الخطوة، وجميعها من مجموعة SecureStorageService حصراً.

---

## 7- إجمالي Warnings المتبقية

**6 تحذيرات** — **بدون أي تغيير** عن نهاية STEP 2B. لم تُضَف أي تحذيرات جديدة (تم تجنّب `dead_code`/`dead_null_aware_expression` عبر استبدال التعبير الخاطئ `getAccessToken() ?? ''` بتعبير سليم `() => null` بدلاً من ترك عملية `??` على قيمة غير قابلة لأن تكون Null).

---

## 8- إجمالي Info المتبقية

**29 ملاحظة** — **بدون أي تغيير** عن نهاية STEP 2B (ملاحظة `prefer_initializing_formals` الوحيدة الخاصة بـ `secure_storage_service.dart` انتقلت من السطر 61 إلى السطر 67 بسبب إضافة أسطر جديدة، دون أي تغيير في العدد أو النوع).

---

## 9- الملفات التي تم تعديلها

| # | الملف | نوع التعديل |
|---|---|---|
| 1 | `lib/core/services/storage/secure_storage_service.dart` | تصحيح مسار استيراد `logger_service.dart` + إضافة 3 دوال (`getAccessToken`, `getRefreshToken`, `clearAllAuthData`) إلى العقد المجرَّد `SecureStorageService` + وضع `@override` عليها في `SecureStorageServiceImpl` |
| 2 | `lib/shared/services/app_service_registry.dart` | تصحيح `tokenProvider` في تهيئة `ApiClient`: إزالة تمرير `Future<String?>` (نتيجة `getAccessToken()`) بشكل خاطئ إلى دالة متزامنة، والاستعاضة عنها بـ `() => null` مع تعليق توضيحي (لا يوجد تخزين مؤقت متزامن للتوكن حالياً) |
| 3 | `lib/core/di/service_locator.dart` | نفس التصحيح تماماً في `tokenProvider` عند تهيئة `ApiClient` |

**لم يُعدَّل أي ملف آخر.** لم يُلمَس `security_interceptors.dart` (استدعاءاته الثلاثة أصبحت صحيحة تلقائياً بعد توسيع العقد، دون أي تعديل يدوي عليه)، ولم يُلمَس `sync_manager.dart` أو `offline_queue.dart` أو `api_client.dart` أو `api_interceptors.dart` أو `app_router.dart`.

---

## 10- هل تم تغيير أي storage keys؟

**لا.** جميع مفاتيح التخزين بقيت كما هي حرفياً بدون أي تغيير: `access_token`, `refresh_token`, `user_id`, `auth_session`. لم تُحذف أي مفاتيح، ولم تُضَف أي مفاتيح جديدة، ولم يُعَد تسمية أي مفتاح موجود.

---

## 11- هل بقي أي استدعاء غير متوافق مع العقد؟

**لا.** تم فحص كل نقطة استدعاء حية لـ `SecureStorageService` في المشروع (`security_interceptors.dart` ×3، `app_service_registry.dart` ×1، `service_locator.dart` ×1، بالإضافة إلى استدعاءات `init/write/read/delete/deleteAll/containsKey` الداخلية)، وجميعها الآن متوافقة تماماً مع العقد الموحَّد الجديد. الإشارة الوحيدة المتبقية غير المفعَّلة هي في تعليق معطَّل داخل `app_router.dart`، وهي غير قابلة للتصريف أصلاً (Comment) ولا تُعتبر "استدعاءً".

---

## 12- هل توجد أي مخاطر أمنية متبقية داخل الخدمة؟

1. **لا يوجد تسريب لبيانات حساسة في السجلات (Logs):** جميع استدعاءات `_logger` داخل `SecureStorageServiceImpl` تسجّل فقط **اسم المفتاح** (مثل `key=access_token`) ولا تسجّل أبداً **قيمة** التوكن أو الجلسة أو `user_id` الفعلية. تم التحقق من هذا صراحة ولم يتغيّر — متوافق مع القاعدة المطلوبة.
2. **التخزين يستخدم `flutter_secure_storage` فقط** مع `encryptedSharedPreferences: true` على أندرويد، دون أي إضافة لـ `SharedPreferences` أو أي وسيط تخزين آخر غير آمن.
3. **خطر وظيفي (لا أمني مباشر) متبقٍ وخارج نطاق هذه الخطوة:** `AuthInterceptor` (في `api_interceptors.dart`، مجموعة `ApiClient` المحظورة) لا يحصل حالياً على أي توكن فعلي من `SecureStorageService` لأن `tokenProvider` أصبح `() => null` صريحاً (بعد أن كان معطوباً تصريفياً من الأساس). عملياً: **لم تتغيّر النتيجة الوظيفية الفعلية** — الميزة لم تكن تعمل قبل هذه الخطوة (كانت تُعيق التصريف بالكامل)، ولم تعمل بعدها (تُعيد `null` بشكل صريح وآمن)، لكن هذه المرة الكود **يُصرَّف بشكل صحيح** بدل أن يحمل خطأ نوع مموَّهاً. ربط توكن فعلي متزامن يتطلب تعديل `ApiClient`/`AuthInterceptor` (محظور في هذه الخطوة) أو إضافة تخزين مؤقت (Cache) في الذاكرة، وكلاهما خارج نطاق STEP 2C الحالية (يتطلب قراراً معمارياً لخطوة لاحقة).
4. **دوال Certificate Pinning غير المكتملة** في `security_interceptors.dart` (`X509Certificate.pin`, `_calculateSha256`) تبقى كما هي **دون أي تدخل**، وهي مجموعة G المحظورة صراحة في هذه الخطوة.

**الخلاصة:** لا توجد أي مخاطر أمنية **جديدة** نتجت عن هذه الخطوة، ولا توجد أي مخاطر أمنية **قائمة** داخل حدود `SecureStorageService` نفسها (التخزين، التشفير، عدم تسجيل القيم الحساسة) — المخاطر الوحيدة المتبقية (ربط التوكن الفعلي بالطلبات) تقع بنيوياً في مجموعة `ApiClient` المحظورة، وليست في `SecureStorageService`.

---

## 13- نتيجة flutter analyze المختصرة

```
Analyzing saeq_driver...
54 issues found.
```

| النوع | قبل STEP 2C | بعد STEP 2C |
|---|---|---|
| Errors | 27 | **19** |
| Warnings | 6 | **6** |
| Info | 29 | **29** |
| **الإجمالي** | **62** | **54** |

الأخطاء الـ19 المتبقية **لا علاقة لها بـ SecureStorageService إطلاقاً**، وتتوزع بالكامل على المجموعات المحظورة في هذه الخطوة: `OfflineQueue`/`SyncManager` (تعارض تسمية + `Companion`/`Value` من Drift، 13 خطأ)، `ApiClient` (استيراد مفقود في `security_interceptors.dart`، 2 خطأ)، `Certificate Pinning` (2 خطأ)، و`Riverpod`/`AppException` (حالة Switch غير مكتملة، 1 خطأ). **لم تُلمَس أي منها في هذه الخطوة.**

---

## 14- الآثار الجانبية

1. **إصلاح تلقائي (بدون تعديل مباشر) لـ 3 استدعاءات في `security_interceptors.dart`:** بمجرد توسيع العقد المجرَّد بالدوال الثلاث، أصبحت استدعاءات `_secureStorage.getAccessToken()` (سطر 34)، `_secureStorage.clearAllAuthData()` (سطر 85)، و `_secureStorage.getRefreshToken()` (سطر 215) صحيحة تلقائياً دون الحاجة لتعديل هذا الملف — وهو أثر جانبي مشروع ومتوقَّع، مماثل لما حدث في STEP 2A وSTEP 2B مع ملفات أخرى.
2. **لا توجد أي زيادة في التحذيرات أو الملاحظات** (بخلاف STEP 2B الذي كشف تحذيراً واحداً مخفياً سابقاً) — هذه الخطوة كانت "نظيفة" 100% من الآثار الجانبية السلبية.
3. **تغيير طفيف في ملفين خارج مجموعة SecureStorageService الصارمة** (`app_service_registry.dart` و `service_locator.dart`) كان **ضرورياً وأُجري بأقل قدر ممكن** (تغيير جسم Closure واحد فقط في كل ملف، مع تعليق توضيحي قصير)، بموجب الاستثناء الصريح المسموح به في التعليمات ("إلا إذا كان التعديل ضرورياً مباشرة لتوحيد استدعاء الخدمة").
4. **لا تغيير في السلوك الوظيفي الفعلي** لإرسال التوكن مع طلبات HTTP (كان معطوباً تصريفياً قبل هذه الخطوة، وأصبح "لا يُرسِل توكن" بشكل صريح وآمن بعدها) — التفاصيل في القسم 12 أعلاه.

---

*تم إنجاز STEP 2C ضمن الحدود المطلوبة تماماً: لم يُصلَح أي خطأ خارج مجموعة SecureStorageService، لم تُنشأ خدمة تخزين جديدة، لم يُستبدَل `flutter_secure_storage`، لم تُضَف `SharedPreferences`، لم تُضَف ميزة Authentication، ولم يُضَف أي منطق أعمال جديد. المشروع لا يزال غير مكتمل التصريف (19 خطأ متبقٍ)، ولم يُشغَّل `flutter test`، ولم يُشغَّل التطبيق على أي جهاز أو محاكي. تتوقف هذه الخطوة هنا بانتظار التعليمات التالية.*
