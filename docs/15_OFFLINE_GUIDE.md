# SAEQ — Offline Guide

> **Version:** 1.1.0
> **Status:** Active
> **Last Updated:** 2026-07-25
> **Author:** Senior Flutter Software Engineer
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md), [42_PLATFORM_DOMAIN_ARCHITECTURE.md](./42_PLATFORM_DOMAIN_ARCHITECTURE.md), [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](./PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md)

---

## 0. Driver Offline-First (MVP design — binding intent)

For **SAEQ Driver**, Offline-First is part of the **Driver Operational MVP** (Stage C), not an optional extra.

### Priority offline operations

- Persist / show the active order
- Confirm arrival at branch
- Confirm order pickup
- Update trip status
- Proof of delivery (including media/signature/code when used)
- Record delivery failure

### Sync requirements

Local Queue · Retry Policy · Idempotency · Operation Ordering · Conflict Resolution · Sync Status UI · Failed Operation History · Network Recovery · Duplicate Prevention (especially PoD)

Existing components in this repo (`OfflineQueue`, `SyncManager`, `NetworkMonitor`) must be **wired to the delivery lifecycle** in a later coding phase — **not** in Documentation Stage A.

### Other clients

| Client | MVP offline expectation |
|--------|-------------------------|
| Customer | Browse cache + local cart only |
| Merchant | Limited critical ops later |
| Web Admin | Server as source of truth |

---

## 1. نظرة عامة

يضمن مشروع SAEQ أن يظل **تطبيق السائق** قابلًا للاستخدام ويوفر تجربة جيدة حتى بدون اتصال إنترنت. يستخدم نهج **cache-first, network-fallback** للقراءة و **queue-and-sync** للكتابة للعمليات الحرجة أعلاه.

---

## 2. اكتشاف الاتصال

```dart
class NetworkInfo {
  final Connectivity _connectivity;

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => result != ConnectivityResult.none,
    );
  }
}
```

---

## 3. استراتيجية القراءة (Cache-First)

- قراءة من قاعدة البيانات المحلية أولاً.
- تحديث من الخادم في الخلفية.
- عرض المؤشر "stale" عندما تكون البيانات من العنصر المخزن.
- إظهار البيانات المخزنة عندما يكون غير متصل.

---

## 4. استراتيجية الكتابة (Queue-and-Sync)

- وضع جميع عمليات الكتابة في صف عندما يكون غير متصل.
- مزامنة العمليات المعلقة عند استعادة الاتصال.
- استخدام صفوف انتظار موثوقة (قاعدة بيانات محلية).
- معالجة الفشل وإعادة المحاولة.

---

## 5. مؤشرات واجهة المستخدم بدون اتصال

- إظهار شريط غير متصل في الأعلى عندما يكون غير متصل.
- إظهار مؤشر "جارٍ المزامنة" عند مزامنة العمليات المعلقة.
- إظهار طابع زمني "آخر مزامنة".
- تعطيل الميزات المتطلبة الاتصال عندما يكون غير متصل.
- إظهار البيانات المخزنة مع مؤشر "stale".

---

## 6. حل النزاعات

| الاستراتيجية | الوصف |
|-------------|-------|
| **Last-Write-Wins** | استخدام الطوابع الزمنية لتحديد الإصدار الأحدث. |
| **دمج** | دمج التغييرات من كلا المصدرين عندما يكون ذلك ممكنًا. |
| **اختيار المستخدم** | إظهار موجه للمستخدم لاختيار عندما لا يتم حل النزاع تلقائيًا. |
| **الخادم يفوز** | بالنسبة للبيانات الحرجة، استخدام دائمًا إصدار الخادم. |

---

## 7. أفضل الممارسات

- دائمًا تخزين استجابات API في قاعدة البيانات المحلية.
- استخدام `watch()` لتحديث واجهة المستخدم بشكل فعال عند تغير البيانات المخزنة.
- وضع جميع عمليات الكتابة في الصف عندما يكون غير متصل.
- مزامنة العمليات المعلقة عند استعادة الاتصال.
- إظهار حالة غير متصل للمستخدم.
- معالجة حل النزاعات بشكل مناسب.
- اختبار سيناريوهات غير متصل بشكل شامل.
- استخدام `connectivity_plus` لاكتشاف حالة الشبكة.

---

## 8. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| قاعدة البيانات | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| واجهات برمجة التطبيقات | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| محرك التوصيل | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
