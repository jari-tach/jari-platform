# PROJECT STABILIZATION — الخطوة 2D: استرجاع عقود بنية العمل بدون إنترنت فقط (Offline Infrastructure Contract Recovery Only)

> **الاعتماد على:** [docs/STABILIZATION_STEP_01_DIAGNOSIS.md](./STABILIZATION_STEP_01_DIAGNOSIS.md)، [docs/STABILIZATION_STEP_02A_DRIFT_RECOVERY.md](./STABILIZATION_STEP_02A_DRIFT_RECOVERY.md)، [docs/STABILIZATION_STEP_02B_LOGGER_RECOVERY.md](./STABILIZATION_STEP_02B_LOGGER_RECOVERY.md)، [docs/STABILIZATION_STEP_02C_SECURE_STORAGE_RECOVERY.md](./STABILIZATION_STEP_02C_SECURE_STORAGE_RECOVERY.md)
> **النطاق:** `OfflineQueue`، `SyncManager`، `NetworkMonitor`، والعقود المباشرة بينها، واعتمادها المباشر على `DriverDatabase`/`LoggerService` فقط.
> **لم يُلمَس:** `ApiClient`، `Certificate Pinning`، `Riverpod`، `AppException`، ولا أي مجموعة أخرى. لم يُعدَّل `driver_database.dart` نفسه (مجموعة Drift الأساسية أُنجزت في STEP 2A).
> **التاريخ:** 2026-07-24

---

## 1- الأخطاء المرتبطة بالمجموعة قبل الإصلاح

بالقياس على خط الأساس لهذه الخطوة (نتيجة `flutter analyze` بعد STEP 2C — 19 خطأ)، كانت أخطاء مجموعة Offline موزّعة كالتالي:

| الملف | السطر | الخطأ | السبب |
|---|---|---|---|
| `offline_queue.dart` | 119 | `argument_type_not_assignable` (String→Value\<String\>) | تمرير قيمة خام لعمود `status` له قيمة افتراضية في `.insert()` |
| `offline_queue.dart` | 120 | `argument_type_not_assignable` (int→Value\<int\>) | نفس السبب لعمود `retryCount` |
| `offline_queue.dart` | 121 | `argument_type_not_assignable` (DateTime→Value\<DateTime\>) | نفس السبب لعمود `createdAt` |
| `offline_queue.dart` | 179 | `undefined_method 'first'` | استدعاء `_database.offlineQueue.first(id: id)` — دالة غير موجودة أصلاً في Drift |
| `offline_queue.dart` | 190 | `undefined_method 'updateOfflineQueue'` | دالة غير معرَّفة في `DriverDatabase` |
| `offline_queue.dart` | 192–194 | `undefined_method 'Value'` (×3) | صنف `Value` (من حزمة `drift`) غير مستورَد في هذا الملف |
| `sync_manager.dart` | 23، 34 | `ambiguous_import` (×2) | تعارض اسم `OfflineQueue` بين الصنف اليدوي (`offline_queue.dart`) وجدول Drift (`driver_database.dart`) |
| `sync_manager.dart` | 60، 74 | `return_of_invalid_type` (×2) | إرجاع Tear-off لدالة Factory (`SyncResult.alreadySyncing`) بدل استدعائها (`SyncResult.alreadySyncing()`) |
| `sync_manager.dart` | 156، 157 | `argument_type_not_assignable` (×2) | تمرير قيم خام لعمودي `lastSyncToken`/`totalRecords` بدون `Value(...)` |
| **الإجمالي** | | | **14 خطأ** |

`network_monitor.dart` **لم يكن يحتوي على أي خطأ** ضمن هذا الجرد (كانت استدعاءاته لـ `LoggerService` قد أصبحت متوافقة تلقائياً منذ STEP 2B دون أي تعديل يدوي عليه).

---

## 2- العقود الثلاثة قبل الإصلاح

**`NetworkMonitor`** (لم يكن به أي خطأ، يُذكر للتوثيق فقط):
```dart
class NetworkMonitor {
  NetworkMonitor({required LoggerService logger, required Connectivity connectivity});
  Future<void> init();
  Future<ConnectivityStatus> checkConnectivity();
  ConnectivityStatus get status;
  ConnectivityResult get connectionType;
  bool get isOnline;
  bool get isOffline;
  Stream<ConnectivityStatus> get statusStream;
  Future<void> dispose();
}
```

**`OfflineQueue`** (الواجهة العامة سليمة، لكن التنفيذ الداخلي مكسور):
```dart
class OfflineQueue {
  OfflineQueue({required LoggerService logger, required DriverDatabase database, int maxRetries, Duration baseRetryDelay});
  Future<int> enqueue({required OperationType operationType, required String entityType, required String entityId, required Map<String, dynamic> payload});
  Future<List<OfflineQueueItem>> getPendingOperations();
  Future<void> markAsCompleted(int id);
  Future<void> markAsFailed(int id, String errorMessage); // ← داخلياً يستدعي دوال غير موجودة في DriverDatabase
  Future<void> clear();
  Duration getRetryDelay(int retryCount);
}
```

**`SyncManager`** (الواجهة العامة سليمة، لكن التنفيذ الداخلي مكسور + تعارض تسمية على مستوى الاستيراد):
```dart
class SyncManager {
  SyncManager({required LoggerService logger, required DriverDatabase database, required ApiClient apiClient, required SecureStorageService secureStorage, required OfflineQueue offlineQueue}); // ← OfflineQueue غامض هنا
  Future<void> init();
  Future<SyncResult> processQueue(); // ← يُرجع Tear-off بدل قيمة في حالتين
  Future<DateTime?> getLastSyncTime(String entityType);
  Future<bool> isSyncNeeded(String entityType);
  Stream<SyncStatus> get statusStream;
  Future<void> dispose();
}
```

---

## 3- العقود بعد التوحيد

**العقود العامة (Public API) للثلاثة لم تتغيّر حرفياً — لا اسم دالة تغيّر، ولا توقيع Constructor تغيّر، ولا نوع إرجاع علني تغيّر.** التوحيد تم على مستوى **التنفيذ الداخلي والاستيرادات فقط**:

```dart
// NetworkMonitor: بدون أي تغيير (كان متوافقاً بالفعل)

// OfflineQueue: نفس التوقيع العلني تماماً، مع تصحيح التنفيذ الداخلي:
// - enqueue(): يستخدم الآن Value(...) الصحيح لأعمدة status/retryCount/createdAt
// - markAsFailed(): يستخدم استعلام Select/Update صحيح من Drift بدل دوال غير موجودة

// SyncManager: نفس التوقيع العلني تماماً، مع:
// - استيراد driver_database.dart مع "hide OfflineQueue" لحل تعارض التسمية
// - استدعاء SyncResult.alreadySyncing() و SyncResult.nothingToSync() بالأقواس (استدعاء حقيقي لا Tear-off)
// - استخدام Value(...) الصحيح لعمودي lastSyncToken/totalRecords
```

**قاعدة توحيد تعارض التسمية `OfflineQueue` (المطلوبة في التعليمات، بند 10):** تم حلّها بأقل تعديل ممكن عبر `import '...driver_database.dart' hide OfflineQueue;` في `sync_manager.dart` فقط — أي أن أي استخدام لاحق لاسم `OfflineQueue` في هذا الملف يُحلَّل حصرياً إلى الصنف الخدمي (`offline_queue.dart`)، وهو ما كان مقصوداً أصلاً بدلالة نوع الحقل `final OfflineQueue _offlineQueue;`. **لم يُنشأ نوع ثالث، ولم يُعَد تسمية أي صنف.**

---

## 4- الملفات التي تم تعديلها

| # | الملف | نوع التعديل |
|---|---|---|
| 1 | `lib/core/offline/offline_queue.dart` | إضافة `import 'package:drift/drift.dart';` + تصحيح `enqueue()` بتغليف 3 قيم بـ `Value(...)` + إعادة كتابة جزء من `markAsFailed()` (استعلام القراءة والتحديث) باستخدام واجهة Drift الصحيحة (`select`/`update`/`replace`) بدل دوال غير موجودة |
| 2 | `lib/core/offline/sync_manager.dart` | إضافة `import 'package:drift/drift.dart';` + إضافة `hide OfflineQueue` على استيراد `driver_database.dart` + تصحيح استدعاء `SyncResult.alreadySyncing`/`nothingToSync` بإضافة الأقواس + تغليف قيمتين بـ `Value(...)` في `_updateSyncMetadata()` |

**لم يُعدَّل `network_monitor.dart`** (لم يكن به أي خطأ). **لم يُعدَّل `driver_database.dart`** (خارج نطاق هذه الخطوة صراحة، ولم يكن الخلل فيه بل في طريقة استدعائه). **لم يُعدَّل أي ملف آخر** (`api_client.dart`، `security_interceptors.dart`، `app_service_registry.dart`، إلخ).

---

## 5- عدد أخطاء المجموعة قبل الإصلاح

**14 خطأ** (تفصيلها في القسم 1 أعلاه): 8 في `offline_queue.dart` + 6 في `sync_manager.dart`.

---

## 6- عدد أخطاء المجموعة بعد الإصلاح

**0 خطأ.** لا يظهر أي خطأ منسوب إلى `offline_queue.dart` أو `sync_manager.dart` أو `network_monitor.dart` في نتيجة `flutter analyze` النهائية.

---

## 7- إجمالي Errors المتبقية في المشروع

**5 أخطاء** (بعد أن كانت 19 خطأ في نهاية STEP 2C). **انخفاض بمقدار 14 خطأ (73.7%↓)** ضمن هذه الخطوة، وجميعها من مجموعة Offline حصراً. الأخطاء الـ5 المتبقية تنتمي بالكامل لمجموعات محظورة في هذه الخطوة:

| الملف | الخطأ | المجموعة |
|---|---|---|
| `security_interceptors.dart:119` | `pin` غير معرَّف | Certificate Pinning (محظورة) |
| `security_interceptors.dart:131` | `_calculateSha256` غير معرَّفة | Certificate Pinning (محظورة) |
| `security_interceptors.dart:202` | `ApiClient` غير معرَّف | ApiClient (محظورة) |
| `security_interceptors.dart:207` | `ApiClient` غير معرَّف | ApiClient (محظورة) |
| `app_error_handler.dart:169` | `non_exhaustive_switch_expression` | AppException/Riverpod (محظورة) |

---

## 8- إجمالي Warnings المتبقية

**7 تحذيرات** (بعد أن كانت 6 في نهاية STEP 2C). **زيادة ظاهرية بمقدار تحذير واحد**: `Unused import: 'dart:convert'` في `sync_manager.dart:2`. هذا التحذير **موجود في الكود من قبل** ولم تُنشئه هذه الخطوة، لكنه كان مخفياً لأن أخطاء `ambiguous_import`/`return_of_invalid_type` كانت تمنع المحلل من إتمام فحص الملف بالكامل — تماماً كما حدث مع `dart:io` في `app_error_handler.dart` خلال STEP 2B. **لم يُعدَّل هذا الاستيراد** التزاماً بعدم الخروج عن نطاق إصلاح الأخطاء (لا التحذيرات).

---

## 9- إجمالي Info المتبقية

**29 ملاحظة** — **بدون أي تغيير** عن نهاية STEP 2C.

---

## 10- هل تم تغيير أي سلوك فعلي؟

**نعم، في حدود ضيقة جداً وكلها تصحيحات لكود لم يكن يعمل أصلاً (لأنه لم يكن حتى يُصرَّف):**

1. **`SyncManager.processQueue()`:** قبل الإصلاح، حالتا "مزامنة جارية فعلاً" و"لا توجد عمليات معلَّقة" كانتا تُرجعان **مرجعاً لدالة (Function Tear-off)** بدل **قيمة `SyncResult` فعلية** — وهذا لم يكن يُصرَّف إطلاقاً (خطأ نوع). بعد الإصلاح، تُرجعان فعلياً القيمة الصحيحة (`SyncResult.alreadySyncing()` / `SyncResult.nothingToSync()`) كما كان مصمَّماً أصلاً بدلالة وجود الـ Factory Constructors نفسها. هذا **تصحيح لسلوك كان معطوباً بالكامل، لا إضافة سلوك جديد**.
2. **`OfflineQueue.markAsFailed()`:** قبل الإصلاح، هذه الدالة كانت تستدعي دالتين غير موجودتين أصلاً (`_database.offlineQueue.first(id:)` و `_database.updateOfflineQueue(...)`)، أي أن منطق "زيادة عداد المحاولات وحذف العملية عند تجاوز الحد الأقصى" **لم يكن يعمل مطلقاً من الأساس** (كان يمنع التصريف بالكامل). بعد الإصلاح، يعمل هذا المنطق تماماً كما كان مصمَّماً في التعليقات والتوقيع العلني للدالة، دون أي تغيير في الشرط (`newRetryCount >= _maxRetries`) أو في القيم المخزَّنة.
3. **`OfflineQueue.enqueue()`:** لا تغيير في أي قيمة فعلية تُخزَّن — فقط تصحيح شكل تمرير القيم (`Value(...)`) ليتوافق مع النوع المطلوب من Drift، مع بقاء القيم المخزَّنة (`status`, `retryCount=0`, `createdAt=DateTime.now()`) كما هي حرفياً.
4. **`SyncManager._updateSyncMetadata()`:** نفس الأمر — لا تغيير في القيم، فقط تصحيح شكل تمريرها.
5. **تعارض `OfflineQueue`:** الحل عبر `hide` لا يغيّر أي سلوك، فقط يحسم غموضاً في التصريف كان يمنع الترجمة أصلاً.

**لا تمت إضافة أي منطق أعمال جديد، ولا استراتيجية مزامنة جديدة، ولا معالجة أخطاء إضافية غير موجودة أصلاً في التصميم الحالي.**

---

## 11- هل بقي أي تعارض في OfflineQueue؟

**لا.** تم التحقق من عدم وجود أي استخدام آخر لاسم `OfflineQueue` في أي ملف آخر يستورد كلا المصدرين معاً (`offline_queue.dart` و `driver_database.dart`) في نفس الوقت. `sync_manager.dart` كان الملف الوحيد الذي يستورد الاثنين معاً، وقد تم حل التعارض فيه بالكامل عبر `hide OfflineQueue`. لا يظهر أي خطأ `ambiguous_import` في نتيجة `flutter analyze` النهائية.

---

## 12- هل بقي أي استدعاء غير متوافق؟

**لا استدعاء غير متوافق متبقٍ ضمن حدود هذه المجموعة (OfflineQueue / SyncManager / NetworkMonitor واعتمادها المباشر على DriverDatabase و LoggerService).** تم فحص كل استدعاء لـ Drift API (`select`, `update`, `into`, `delete`, `Value`, `Companion`) وكل استدعاء لـ `LoggerService` داخل الملفين المعدَّلين، وجميعها الآن صحيحة ومتوافقة.

الاستدعاءات غير المتوافقة **المتبقية في نفس الملفات** (مثل `ApiClient` في `security_interceptors.dart`، و`_secureStorage` غير المستخدَم في `sync_manager.dart`) **لا علاقة لها بعقد Offline نفسه** — الأول ينتمي لمجموعة `ApiClient` المحظورة، والثاني تحذير (لا خطأ) عن حقل تبعية مُحقَن (Injected Dependency) غير مُستخدَم داخلياً حالياً، وإزالته تتطلب تغيير توقيع الـ Constructor العلني، وهو تغيير أوسع من "إصلاح خطأ تصريف" وخارج نطاق هذه الخطوة (لم يُلمَس).

---

## 13- نتيجة flutter analyze المختصرة

```
Analyzing saeq_driver...
41 issues found.
```

| النوع | قبل STEP 2D | بعد STEP 2D |
|---|---|---|
| Errors | 19 | **5** |
| Warnings | 6 | **7** |
| Info | 29 | **29** |
| **الإجمالي** | **54** | **41** |

الأخطاء الـ5 المتبقية **لا علاقة لها بمجموعة Offline إطلاقاً**، وتتوزع بالكامل على المجموعات المحظورة في هذه الخطوة: `Certificate Pinning` (2 خطأ)، `ApiClient` (2 خطأ)، و`Riverpod`/`AppException` (1 خطأ). **لم تُلمَس أي منها في هذه الخطوة.**

---

## 14- المخاطر والآثار الجانبية

1. **تحذير واحد ظاهري جديد (Warning) وليس خطأ حقيقياً:** `Unused import: 'dart:convert'` في `sync_manager.dart` — تحذير قديم كان مخفياً بسبب أخطاء تصريف أخرى في الملف نفسه (انظر القسم 8)، لم يُنشأ بهذه الخطوة ولم يُعالَج (خارج نطاق إصلاح الأخطاء).
2. **لا توجد أي إضافة لجداول أو Queue أو Scheduler أو منطق مزامنة جديد** — تم الاعتماد كلياً على البنية الموجودة فعلياً في `DriverDatabase` (الدوال `select`/`update`/`into`/`delete` العامة المولَّدة أصلاً من Drift، وليست دوالاً جديدة أُضيفت).
3. **لا يوجد أي تشغيل فعلي لمزامنة أو استدعاء شبكي** أثناء هذه الخطوة — تم الاعتماد على التحليل الساكن (`flutter analyze`) فقط دون تشغيل التطبيق.
4. **أثر جانبي إيجابي:** إصلاح `SyncManager.processQueue()` و `OfflineQueue.markAsFailed()` يعني أن منطق "إعادة المحاولة مع تراجع أُسّي" (Exponential Backoff) و"حذف العملية بعد تجاوز الحد الأقصى للمحاولات" أصبح **قابلاً للتنفيذ الفعلي لأول مرة** بعد أن كان يمنع التصريف بالكامل — وهذا تصحيح ضمن حدود التصميم الأصلي الموجود في التعليقات والتوقيعات العلنية، لا ميزة جديدة.
5. **لا يوجد أي خطر أمني** في هذه الخطوة — لا تعامل مع بيانات حساسة في الملفات الثلاثة المفحوصة بخلاف تمرير كائن `SecureStorageService` (لم يُستخدَم فعلياً داخل `SyncManager` حالياً، تحذير موجود مسبقاً ولم يُلمَس).

---

*تم إنجاز STEP 2D ضمن الحدود المطلوبة تماماً: لم يُصلَح أي خطأ خارج مجموعة Offline، لم تُنشأ ملفات جديدة، لم تُعَد تسمية أي كلاس رئيسي، لم تُضَف Abstract Layers جديدة، لم يُستخدَم `dynamic` لإخفاء أخطاء الأنواع، ولم يُعلَّق أي استدعاء مكسور. لم يُشغَّل `flutter test`، ولم يُشغَّل التطبيق على أي جهاز أو محاكي. المشروع لا يزال غير مكتمل التصريف (5 أخطاء متبقية فقط)، وتتوقف هذه الخطوة هنا بانتظار التعليمات التالية.*
