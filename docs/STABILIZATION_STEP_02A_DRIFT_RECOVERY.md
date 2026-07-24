# PROJECT STABILIZATION — الخطوة 2A: إصلاح تصريف Drift فقط (Drift Compilation Recovery Only)

> **الاعتماد على:** [docs/STABILIZATION_STEP_01_DIAGNOSIS.md](./STABILIZATION_STEP_01_DIAGNOSIS.md)
> **النطاق:** ملف واحد فقط — `lib/features/driver/data/datasources/local/driver_database.dart`
> **لم يُلمَس:** `LoggerService`، `SecureStorageService`، `core/offline/offline_queue.dart`، `core/offline/sync_manager.dart`، ولا أي مجموعة أخطاء أخرى.
> **التاريخ:** 2026-07-24

---

## 1- عدد أخطاء Drift قبل الإصلاح

**42 خطأ** كانت موجودة مباشرة داخل `driver_database.dart` نفسه (من إجمالي 105 خطأ في المشروع كما ورد في تقرير التشخيص الأول)، وتشمل:
- غياب Annotation الخاصة بـ `@DriftDatabase` (السبب الجذري لكل ما يلي)
- `uri_has_not_been_generated` لملف `driver_database.g.dart`
- `undefined_method` لـ `select/into/update/delete` (غير معرَّفة لأن `_$DriverDatabase` لم يكن موجوداً)
- `non_type_as_type_argument` لأنواع الجداول (`DriverProfile`, `DeliveryOrder`, `OfflineQueueItem`)
- `undefined_class` لأصناف الـ Companion المولَّدة
- `undefined_identifier` لأسماء الجداول ومكتبة `sqlite3` غير الصحيحة (`sqlite3.openSetOpenFlags`, `NativeOpenParams`, إلخ)
- `uri_does_not_exist` لاستيراد `logger_service.dart` غير المستخدَم أصلاً في هذا الملف

## 2- عدد أخطاء Drift بعد الإصلاح

**0 خطأ** — لا يظهر أي خطأ (Error) منسوب مباشرة إلى `driver_database.dart` في نتيجة `flutter analyze` النهائية.

(الملف مذكور مرتين فقط في النتيجة النهائية، وكلاهما ضمن رسالة خطأ `ambiguous_import` **موجودة فعلياً في ملف آخر** — `lib/core/offline/sync_manager.dart` — وهي خارج نطاق هذه الخطوة ولم تُعالَج، لأن حلها يتطلب تعديل `sync_manager.dart` المحظور لمسه في STEP 2A.)

## 3- إجمالي Errors المتبقية في المشروع

**54 خطأ** (بعد أن كانت 105 خطأ في خط الأساس — انخفاض بمقدار 51 خطأ، أي ما يعادل **48.6%** من إجمالي أخطاء المشروع).

**تفصيل مصدر الانخفاض:**
- **42 خطأ** أُزيلت مباشرة من داخل `driver_database.dart` (الملف المُعدَّل).
- **9 أخطاء إضافية** اختفت تلقائياً من `lib/core/offline/offline_queue.dart` (من 21 خطأ إلى 12 خطأ) دون تعديل هذا الملف إطلاقاً — وذلك لأن 10 من أخطائه القديمة كانت من نوع `unchecked_use_of_nullable_value` بسبب اعتمادها على نوع بيانات (Row Type) لم يكن معرَّفاً بشكل صحيح قبل توليد كود Drift؛ بعد التوليد الصحيح أصبح النوع معروفاً ودقيقاً، فاختفت هذه الأخطاء تلقائياً كنتيجة جانبية مشروعة، مع ظهور 3 أخطاء بديلة أدق (`argument_type_not_assignable`) تعكس الآن الاستخدام الخاطئ الحقيقي لواجهة `Companion` في ذلك الملف (خارج نطاق هذه الخطوة).

## 4- إجمالي Warnings المتبقية

**5 تحذيرات** (بعد أن كانت 8 في خط الأساس).

## 5- إجمالي Info المتبقية

**29 ملاحظة** (بعد أن كانت 32 في خط الأساس). الفرق (3) هو اختفاء ملاحظات `recursive_getters` الثلاث التي كانت مرتبطة مباشرة بمشكلة تعارض أسماء الدوال مع أسماء الوصول التلقائي في `driver_database.dart`، والتي حُلَّت ضمن هذه الخطوة.

## 6- الملفات التي تم تعديلها

| الملف | نوع التعديل |
|---|---|
| `lib/features/driver/data/datasources/local/driver_database.dart` | الملف الوحيد المُعدَّل مباشرة |

**تفصيل التعديلات داخله:**
1. إضافة `@DriftDatabase(tables: [DriverProfiles, DeliveryOrders, OfflineQueue, SyncMetadata])` فوق `class DriverDatabase`.
2. حذف استيراد `sqlite3_flutter_libs` المباشر (غير مستخدَم بشكل صحيح أصلاً) وحذف استيراد `logger_service.dart` غير المستخدَم إطلاقاً في الملف، وإضافة `import 'dart:io';` لأجل `File`.
3. إعادة تسمية 3 دوال مساعدة كانت تتعارض أسماؤها مع أسماء الوصول التلقائي الذي يولّده Drift (`deliveryOrders` → `allDeliveryOrders`، `offlineQueue` → `allOfflineQueueItems`، `syncMetadata` → `allSyncMetadata`) دون تغيير أي منطق.
4. تصحيح `_openConnection()` لاستخدام `NativeDatabase.createInBackground(file)` القياسي فقط، وإزالة استدعاءات غير موجودة أصلاً في الحزم المستخدَمة (`sqlite3.openSetOpenFlags`, `NativeOpenParams`, `inMemoryVfs`).
5. تصحيح أنواع الإرجاع لتطابق الأنواع المولَّدة فعلياً بواسطة Drift: `OfflineQueueItem` → `OfflineQueueData`، و `SyncMetadata` (كنوع صف بيانات) → `SyncMetadataData`، وذلك في التوقيعات التي كانت تستخدم اسم الجدول (Table Class) خطأً بدل اسم صنف الصف (Data Class) المولَّد.
6. تصحيح `updateDriverProfile` و `updateDeliveryOrder` بحيث يستخدمان `Future<int>` الفعلي الذي تُرجعه `update(...).write(...)` داخلياً، مع تحويله إلى `bool` عبر `rows > 0` للحفاظ على التوقيع العلني `Future<bool>` كما كان دون تغيير تصميمي.
7. تصحيح `deleteDeliveryOrder(int id)` و `deleteOfflineOperation(int id)` لاستخدام صياغة `delete(table)..where((t) => t.id.equals(id))).go()` الصحيحة في Drift بدلاً من استدعاء `.delete(id)` غير الصالح، دون تغيير التوقيع العلني للدالتين.

لم يُعدَّل أي ملف آخر في المشروع.

## 7- الملفات المولَّدة بواسطة build_runner

| الملف | الحالة |
|---|---|
| `lib/features/driver/data/datasources/local/driver_database.g.dart` | **تم توليده بنجاح** لأول مرة |

بالإضافة إلى ذلك، أظهر سجل التنفيذ توليد/تحديث عدد إجمالي **62 مخرجاً (outputs)** عبر المشروع بواسطة أدوات `build_runner`/`drift_dev`/`source_gen` القياسية العاملة على كامل مدخلات المشروع (140 ملف مدخل)، وهو سلوك طبيعي ومتوقَّع لأداة `build_runner` نفسها (فحص شامل لكل المشروع)، ولا يعني أن أي ملف آخر غير `driver_database.dart` قد **عُدِّل يدوياً** بواسطتي — كل الملفات الأخرى المولَّدة/المتخطاة هي نتاج تلقائي بحت لعملية Build القياسية ولم يُطلَب أو يُنفَّذ أي تعديل يدوي عليها.

## 8- الأمر المستخدَم لتوليد الكود

```
dart run build_runner build --delete-conflicting-outputs
```

**ملاحظة تقنية:** ظهر تحذير من الأداة نفسها يفيد بأن الخيار `--delete-conflicting-outputs` "تمت إزالته وتم تجاهله" (`These options have been removed and were ignored: --delete-conflicting-outputs`) في إصدار `build_runner` الحالي المستخدَم في هذا المشروع، إلا أن الأمر أكمل التنفيذ بنجاح رغم ذلك ووُلِّد الملف المطلوب بلا أي تعارضات فعلية.

## 9- هل نجح Code Generation؟

**نعم، نجح بالكامل.** انتهى الأمر بالرسالة:
```
Built with build_runner/aot in 61s; wrote 62 outputs.
```
وتم التحقق فعلياً من وجود `driver_database.g.dart` على القرص بعد التنفيذ.

## 10- هل توجد مشكلة Drift متبقية؟

**لا توجد أي مشكلة Drift متبقية داخل الملف الذي كان نطاق هذه الخطوة** (`driver_database.dart`) — صفر أخطاء منسوبة إليه.

**لكن** توجد مشكلتان متبقيتان في **ملفات أخرى خارج نطاق هذه الخطوة**، وهما مرتبطتان بـ Drift لكن سبب استمرارهما ليس في `driver_database.dart`:
- تعارض تسمية (`ambiguous_import`) بين `OfflineQueue` اليدوي في `offline_queue.dart` و `OfflineQueue` المولَّد من Drift — الحل يتطلب تعديل `offline_queue.dart` أو `sync_manager.dart` (محظور في هذه الخطوة).
- استخدامات إضافية غير صحيحة لواجهة `Companion`/`Value` من Drift داخل `offline_queue.dart` و `sync_manager.dart` (محظور تعديلها في هذه الخطوة).

هاتان المشكلتان تنتميان إلى مجموعة "OfflineQueue" التي حدَّد المستخدم صراحة عدم لمسها في STEP 2A، وستُترَكان لخطوة لاحقة مخصَّصة.

## 11- نتيجة flutter analyze الكاملة المختصرة (بعد إصلاح Drift فقط)

```
Analyzing saeq_driver...
88 issues found.
```

| النوع | العدد |
|---|---|
| Errors | 54 |
| Warnings | 5 |
| Info | 29 |
| **الإجمالي** | **88** |

**توزيع الأخطاء المتبقية الـ54 حسب الملف (دون أي تعديل عليها):**

| الملف | عدد الأخطاء المتبقية |
|---|---|
| `lib/core/offline/offline_queue.dart` | 12 |
| `lib/core/offline/sync_manager.dart` | 10 |
| `lib/core/security/security_interceptors.dart` | 13 |
| `lib/core/services/api/api_interceptors.dart` | 6 |
| `lib/core/services/error/app_error_handler.dart` | 5 |
| `lib/core/services/storage/secure_storage_service.dart` | 3 |
| `lib/core/network/network_monitor.dart` | 2 |
| `lib/core/di/service_locator.dart` | 1 |
| `lib/shared/services/app_service_registry.dart` | 1 |
| `lib/features/driver/data/datasources/local/driver_database.dart` | **0** |

---

## خلاصة الخطوة

تم إنجاز **STEP 2A** بنجاح ضمن الحدود المطلوبة تماماً: لم تُنشأ أي ميزة جديدة، لم يُعَد تصميم قاعدة البيانات، لم تُنشأ جداول جديدة، ولم يُلمَس أي ملف خارج `driver_database.dart`. تراجع إجمالي أخطاء المشروع من **105 إلى 54** (48.6%↓)، واختفت مجموعة Drift المستهدَفة بالكامل من الملف المحدَّد.

المشروع **لا يزال غير مكتمل التصريف** (54 خطأ متبقٍ)، والمجموعات المتبقية (LoggerService، SecureStorageService، OfflineQueue/SyncManager، ApiClient، Certificate Pinning، Riverpod Provider) تحتاج خطوات STABILIZATION لاحقة منفصلة كما هو مخطَّط.

---

*لم يتم الانتقال إلى LoggerService أو أي مجموعة أخرى. لم يُشغَّل التطبيق على أي جهاز أو محاكي. تتوقف هذه الخطوة هنا بانتظار التعليمات التالية.*
