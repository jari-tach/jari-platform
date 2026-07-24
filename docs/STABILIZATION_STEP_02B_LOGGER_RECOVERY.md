# PROJECT STABILIZATION — الخطوة 2B: توحيد عقد LoggerService فقط (LoggerService Contract Recovery Only)

> **الاعتماد على:** [docs/STABILIZATION_STEP_01_DIAGNOSIS.md](./STABILIZATION_STEP_01_DIAGNOSIS.md) و [docs/STABILIZATION_STEP_02A_DRIFT_RECOVERY.md](./STABILIZATION_STEP_02A_DRIFT_RECOVERY.md)
> **النطاق:** توحيد عقد `LoggerService` مع نقاط الاستدعاء الفعلية فقط.
> **لم يُلمَس:** `SecureStorageService`، `SyncManager`، `OfflineQueue`، `ApiClient`، ولا أي مجموعة أخطاء أخرى.
> **التاريخ:** 2026-07-24

---

## 1- عقد LoggerService قبل الإصلاح

```dart
abstract class LoggerService {
  void debug(String message, {Map<String, dynamic>? metadata});
  void info(String message, {Map<String, dynamic>? metadata});
  void warning(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata});
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata});
  void fatal(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata});
}
```

جميع المعاملات بعد `message` كانت **معاملات مسمّاة (Named)** فقط. هذا التعريف كان يتعارض مع الغالبية العظمى من نقاط الاستدعاء الفعلية في المشروع، التي كانت تستدعي `error`/`stackTrace` كمعاملات **موضعية (Positional)**.

---

## 2- العقد الموحَّد بعد الإصلاح

```dart
abstract class LoggerService {
  void debug(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata]);
  void info(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata]);
  void warning(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata]);
  void error(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata]);
  void fatal(String message, [dynamic error, StackTrace? stackTrace, Map<String, dynamic>? metadata]);
}
```

**عقد واحد موحَّد** يُطبَّق بنفس الشكل على المستويات الخمسة (`debug`, `info`, `warning`, `error`, `fatal`): `message` مطلوب، ويليه ثلاثة معاملات موضعية اختيارية بالترتيب `error → stackTrace → metadata`. لا توجد أي معاملات مسمّاة في التعريف الجديد، وبالتالي لا يوجد أكثر من "شكل" واحد للاستدعاء عبر كل المشروع.

`ConsoleLoggerService` (التنفيذ الوحيد الموجود) عُدِّل بالتوقيع نفسه حرفياً، ويستدعي داخلياً الدالة الخاصة `_log(...)` بنفس المنطق السابق دون أي تغيير في السلوك (لا فرز جديد، لا مستوى Logging جديد، لا تكامل خارجي).

---

## 3- عدد أخطاء Logger قبل الإصلاح

بالقياس على خط الأساس الفعلي لهذه الخطوة، وهو نتيجة `flutter analyze` بعد STEP 2A (**54 خطأ**)، كانت أخطاء LoggerService (استيراد مكسور + عدم تطابق توقيع) موزّعة كالتالي:

| الملف | إجمالي أخطاء الملف (بعد 2A) | منها أخطاء Logger | ملاحظة |
|---|---|---|---|
| `lib/core/services/api/api_interceptors.dart` | 6 | **6** | معاملات `tag`/`data` غير موجودة في العقد |
| `lib/core/security/security_interceptors.dart` | 13 | **6** | استدعاءات موضعية زائدة (`error`, `stackTrace`) |
| `lib/core/offline/sync_manager.dart` | 10 | **4** | استدعاءات موضعية زائدة |
| `lib/core/offline/offline_queue.dart` | 12 | **4** | استدعاءات موضعية زائدة |
| `lib/core/services/error/app_error_handler.dart` | 5 | **4** | استيراد مكسور (`uri_does_not_exist`) + `LoggerService`/`loggerServiceProvider` غير معرَّفين |
| `lib/core/network/network_monitor.dart` | 2 | **2** | استدعاءات موضعية زائدة |
| `lib/core/services/storage/secure_storage_service.dart` | 3 | **3** | استيراد مكسور (ينتمي لمجموعة SecureStorageService المحظورة) |
| **الإجمالي** | | **29** | |

**عدد أخطاء Logger قبل هذه الخطوة: 29 خطأ** (من إجمالي 54 خطأ في المشروع عند نقطة الانطلاق).

---

## 4- عدد أخطاء Logger بعد الإصلاح

| الملف | أخطاء Logger المتبقية | السبب |
|---|---|---|
| `lib/core/services/api/api_interceptors.dart` | 0 | — |
| `lib/core/security/security_interceptors.dart` | 0 | — |
| `lib/core/offline/sync_manager.dart` | 0 | — |
| `lib/core/offline/offline_queue.dart` | 0 | — |
| `lib/core/services/error/app_error_handler.dart` | 0 | — |
| `lib/core/network/network_monitor.dart` | 0 | — |
| `lib/core/services/storage/secure_storage_service.dart` | **3** | استيراد مكسور — الملف ينتمي لمجموعة **SecureStorageService المحظور لمسها** في هذه الخطوة (تعليمات المستخدم صريحة)، ولم يُعدَّل. |

**عدد أخطاء Logger بعد هذه الخطوة: 3 خطأ**، وكلها في ملف واحد محظور التعديل ولا علاقة لها بتوقيع الدالة (بل باستيراد مكسور). **صافي الانخفاض في أخطاء Logger: 26 خطأ (89.7%↓)**.

> ملاحظة مهمة: استدعاءات `LoggerService` الفعلية داخل `secure_storage_service.dart` (مثل `_logger.error('SecureStorageService: Failed to write key=$key', e, stackTrace)`) هي بالفعل **متوافقة تماماً** مع العقد الجديد الموحَّد. الخطأ المتبقي فيه ليس "عدم تطابق توقيع"، بل استيراد نصي خاطئ (`../services/logger/logger_service.dart` بدل `../logger/logger_service.dart`) — وهذا يقع ضمن مجموعة الاستيراد/SecureStorageService، لا ضمن نطاق هذه الخطوة.

---

## 5- إجمالي Errors المتبقية في المشروع

**27 خطأ** (بعد أن كانت 54 خطأ في نهاية STEP 2A). **انخفاض بمقدار 27 خطأ (50%↓)** ضمن هذه الخطوة وحدها.

---

## 6- إجمالي Warnings المتبقية

**6 تحذيرات** (بعد أن كانت 5 في نهاية STEP 2A). **زيادة ظاهرية بمقدار تحذير واحد** — راجع القسم 12 (المخاطر والآثار الجانبية) للتفسير.

---

## 7- إجمالي Info المتبقية

**29 ملاحظة** (بدون تغيير عن نهاية STEP 2A).

---

## 8- الملفات التي تم تعديلها

| # | الملف | نوع التعديل |
|---|---|---|
| 1 | `lib/core/services/logger/logger_service.dart` | توحيد توقيع `LoggerService` (Abstract) وتنفيذه في `ConsoleLoggerService` إلى الشكل الموضعي الموحَّد |
| 2 | `lib/core/services/error/app_error_handler.dart` | تصحيح مسار استيراد `logger_service.dart` (كان يحتوي `services/` مكرَّرة) + تحويل استدعاءين من `metadata: {...}` (مسمّى) إلى معامل موضعي رابع |
| 3 | `lib/core/services/api/api_interceptors.dart` | تحويل 3 استدعاءات كانت تستخدم معاملات مسمّاة غير موجودة أصلاً في العقد (`tag`, `data`) إلى الشكل الموضعي الموحَّد (`error`, `stackTrace`, `metadata`) |

**لم يُعدَّل أي ملف آخر.** الانخفاض الإضافي في أخطاء الملفات التالية حدث تلقائياً (كأثر جانبي مشروع لتغيير تعريف الواجهة نفسها) **دون تعديل هذه الملفات إطلاقاً**:
`lib/core/network/network_monitor.dart`، `lib/core/offline/offline_queue.dart`، `lib/core/offline/sync_manager.dart`، `lib/core/security/security_interceptors.dart`.

هذا الأثر الجانبي متوقَّع ومماثل تماماً لما حدث في STEP 2A مع `offline_queue.dart` بعد إصلاح Drift: تصحيح تعريف الواجهة المركزية كشف/حلّ أخطاءً في نقاط استدعاء لم تُلمَس يدوياً.

---

## 9- سبب اختيار شكل العقد النهائي

تم فحص كل نقاط الاستدعاء الفعلية قبل اتخاذ القرار، وتبيّن أن:

- **الغالبية العظمى** من نقاط الاستدعاء (`network_monitor.dart`، `security_interceptors.dart`، `sync_manager.dart`، `offline_queue.dart`، وكذلك `secure_storage_service.dart` غير المطلوب لمسه) تستخدم فعلاً الشكل: `_logger.error('رسالة', errorObject, stackTrace)` — أي **معاملات موضعية**.
- **ملف واحد فقط** (`api_interceptors.dart`) يستخدم معاملات مسمّاة غير موجودة أصلاً في أي إصدار من العقد (`tag`, `data`).
- **ملف واحد** (`app_error_handler.dart`) يخلط بين موضعي (`error`, `stackTrace`) ومسمّى (`metadata`) في نفس الاستدعاء — وهذا **غير قابل للتحقيق في Dart أصلاً** (لا يمكن لأي دالة أن تجمع بين معاملات اختيارية موضعية `[...]` ومعاملات مسمّاة `{...}` في نفس التوقيع)، لذا كان لا بد من حسم الاتجاه لصالح أحدهما.

بناءً على قاعدة "الأولوية للأسلوب الأكثر وضوحاً والأقل تعديلاً على المشروع"، فإن اختيار **الشكل الموضعي بالكامل** يعني أن التعديل المطلوب ينحصر في **ملفين فقط** (`app_error_handler.dart` بحذف كلمة `metadata:`، و`api_interceptors.dart` بحذف `tag:`/`data:` وتمرير القيم موضعياً)، بينما اختيار الشكل المسمّى بالكامل كان سيتطلب تعديل **خمسة ملفات** (كل نقاط الاستدعاء الموضعية الحالية). كما أن الشكل الموضعي هو الأقرب لِما هو مكتوب فعلاً في 90%+ من الكود الحالي، وبالتالي الأكثر "طبيعية" بالنسبة لبقية المشروع.

---

## 10- هل بقي أي استدعاء غير متوافق مع العقد الجديد؟

**لا يوجد أي استدعاء لـ LoggerService في كامل المشروع غير متوافق مع العقد الجديد.** تم فحص كل نقاط الاستدعاء (`network_monitor.dart`, `app_service_registry.dart`, `app_error_handler.dart`, `security_interceptors.dart`, `sync_manager.dart`, `offline_queue.dart`, `secure_storage_service.dart`, `api_interceptors.dart`, `service_locator.dart`) دون استثناء.

الاستثناء الوحيد المتبقي في نتيجة `flutter analyze` هو خطأ **استيراد** (لا توقيع) في `secure_storage_service.dart`، ناتج عن مسار نصي خاطئ ينتمي لمجموعة أخرى (SecureStorageService) محظور التعديل فيها بنص التعليمات، وليس عن عدم توافق مع العقد الجديد.

---

## 11- نتيجة flutter analyze المختصرة

```
Analyzing saeq_driver...
62 issues found.
```

| النوع | قبل STEP 2B | بعد STEP 2B |
|---|---|---|
| Errors | 54 | **27** |
| Warnings | 5 | **6** |
| Info | 29 | **29** |
| **الإجمالي** | **88** | **62** |

الأخطاء الـ27 المتبقية **لا علاقة لها بـ LoggerService إطلاقاً** (باستثناء 3 أخطاء استيراد في `secure_storage_service.dart` كما وُضِّح أعلاه)، وتتوزع على مجموعات أخرى خارج نطاق هذه الخطوة: `SecureStorageService` (دوال مفقودة)، `OfflineQueue`/`SyncManager` (تعارض تسمية + Companion/Value)، `ApiClient` (استيراد مفقود)، `Certificate Pinning`، و`Riverpod`/`AppException` (حالة Switch غير مكتملة). **لم تُلمَس أي منها في هذه الخطوة.**

---

## 12- المخاطر والآثار الجانبية

1. **زيادة تحذير واحد (Warning) بشكل ظاهري فقط:** ظهر تحذير جديد `unused_import: 'dart:io'` في `lib/core/services/error/app_error_handler.dart:2`. هذا التحذير **موجود في الكود من قبل** ولم يُنشأ بهذه الخطوة، لكنه كان "مخفياً" لأن الاستيراد المكسور لـ `logger_service.dart` في نفس الملف كان يمنع المحلل من إتمام فحص الملف بالكامل. بعد تصحيح مسار الاستيراد، أصبح المحلل قادراً على فحص الملف كاملاً فكشف هذا التحذير القديم. **لم يُعدَّل هذا الاستيراد ولن يُعدَّل في هذه الخطوة** التزاماً بعدم الخروج عن نطاق LoggerService.
2. **لا يوجد أي تغيير في السلوك الفعلي للـ Logging** (نفس مستويات التسجيل، نفس تنسيق الطباعة، نفس آلية `_log`/`_printLog`)، التغيير مقصور على شكل استدعاء الدالة فقط (Signature)، دون أي منطق جديد.
3. **لا يوجد أي استخدام لـ `dynamic` لإخفاء أخطاء الأنواع** — معامل `error` بقي `dynamic` كما كان تماماً في العقد الأصلي (هذا جزء من التصميم الأصلي وليس إضافة جديدة).
4. **أثر جانبي إيجابي متوقَّع وغير خطير:** انخفاض تلقائي في أخطاء 4 ملفات لم تُلمَس (`network_monitor.dart`, `offline_queue.dart`, `sync_manager.dart`, `security_interceptors.dart`) لأن تصحيح تعريف الواجهة المركزية يُصحِّح تلقائياً كل نقطة استدعاء كانت متوافقة أصلاً مع الشكل الموضعي.
5. **لا يوجد أي خطر معماري** — لم تُنشأ خدمة جديدة، ولم يُضَف أي تكامل خارجي (Sentry/Firebase)، ولم تُحذف أي وظيفة أو مستوى تسجيل.

---

*تم إنجاز STEP 2B ضمن الحدود المطلوبة تماماً: لم يُصلَح أي خطأ خارج مجموعة LoggerService، لم تُنشأ ميزة جديدة، لم يُشغَّل `flutter test`، ولم يُشغَّل التطبيق على أي جهاز أو محاكي. المشروع لا يزال غير مكتمل التصريف (27 خطأ متبقٍ)، وتتوقف هذه الخطوة هنا بانتظار التعليمات التالية.*
