# SAEQ — Database Architecture

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)، [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md)  

---

## 1. نظرة عامة

يستخدم مشروع SAEQ **Drift (SQLite)** للتخزين المحلي المنظم. يوفر Drift طبقة تخزين نوعية، متفاعلة، وصديقة للترحيل.

### 1.1 الهيكل

```
┌─────────────────────────────────────────────┐
│  Domain Layer                               │
│  ┌─────────────┐                           │
│  │ Repository  │                           │
│  │ Interface   │                           │
│  └──────┬──────┘                           │
│         │                                  │
│         ▼                                  │
│  ┌──────────────────────────────────┐      │
│  │  Data Layer                       │      │
│  │  ┌─────────────┐                 │      │
│  │  │ Repository  │                 │      │
│  │  │ Impl        │                 │      │
│  │  └──────┬──────┘                 │      │
│  │         │                        │      │
│  │         ▼                        │      │
│  │  ┌────────────────────────────────┐ │      │
│  │  │  Local Data Source             │ │      │
│  │  │  ┌─────────────┐               │ │      │
│  │  │  │ DAO         │               │ │      │
│  │  │  │ (Drift)     │               │ │      │
│  │  │  └─────────────┘               │ │      │
│  │  └────────────────────────────────┘ │      │
│  └──────────────────────────────────┘      │
└─────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────┐
│  Infrastructure Layer                       │
│  ┌─────────────┐                           │
│  │ Drift       │                           │
│  │ Database    │                           │
│  └─────────────┘                           │
└─────────────────────────────────────────────┘
```

---

## 2. تصميم قاعدة البيانات

### 2.1 الجداول

| الجدول | الوصف |
|-------|-------|
| `orders` | طلبات التوصيل |
| `drivers` | بيانات السائقين |
| `deliveries` | عمليات التسليم |
| `products` | فهرس المنتجات |
| `categories` | تصنيفات المنتجات |
| `brands` | العلامات التجارية |
| `suppliers` | الموردين |
| `offline_actions` | الإجراءات المعلقة |

### 2.2 مثال على التعريف

```dart
@DriftDatabase(tables: [Orders, Drivers, Deliveries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAllTables();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // معالجة الترقيات
        },
      );
}
```

---

## 3. نمط DAO

```dart
@DriftAccessor(tables: [Orders])
class OrdersDao {
  final AppDatabase db;

  OrdersDao(this.db);

  Future<List<Order>> getAllOrders() {
    return (db.select(db.orders)).get();
  }

  Future<Order?> getOrderById(String id) {
    return (db.select(db.orders)..where((t) => db.isSameValue(t.id, id))).getSingleOrNull();
  }

  Future<void> insertOrder(OrderCompanion order) {
    return db.into(db.orders).insert(order, mode: InsertMode.insertOrReplace);
  }

  Stream<List<Order>> watchAllOrders() {
    return (db.select(db.orders)).watch();
  }
}
```

---

## 4. مزامنة البيانات

### 4.1 استراتيجية القراءة (Cache-First)

- قراءة من قاعدة البيانات المحلية أولاً.
- تحديث من الخادم في الخلفية.
- عرض المؤشر "stale" عندما تكون البيانات من العنصر المخزن.

### 4.2 استراتيجية الكتابة (Write-Through)

- الكتابة في كلا من قاعدة البيانات المحلية والـ API.
- استخدام صفوف انتظارية عندما يكون غير متصل.

### 4.3 حل النزاعات

- **Last-Write-Wins:** استخدام الطوابع الزمنية لتحديد الإصدار الأحدث.
- **دمج:** دمج التغييرات من كلا المصدرين عندما يكون ذلك ممكنًا.
- **اختيار المستخدم:** إظهار موجه للمستخدم لاختيار عندما لا يتم حل النزاع تلقائيًا.
- **الخادم يفوز:** بالنسبة للبيانات الحرجة، استخدام دائمًا إصدار الخادم.

---

## 5. استراتيجية الترحيل

- زيادة `schemaVersion` دائمًا عند إجراء تغييرات على المخطط.
- استخدام `MigrationStrategy` لـ `onCreate` و `onUpgrade`.
- اختبار الترحيلات بشكل شامل.
- عدم حذف البيانات في الترحيلات (تعيينها كمهملة بدلاً من ذلك).
- توفير سكريبتات التراجع للترحيلات الحرجة.

---

## 6. أفضل الممارسات

- استخدام المعاملات لعمليات ذات الترابط.
- استخدام `watch()` للاستعلامات التفاعلية.
- استخدام `batch()` لعمليات الإدراج/التحديث الجماعي.
- فهرسة الأعمدة التي يتم استعلامها بشكل متكرر.
- استخدام `InsertMode.insertOrReplace` لعمليات upsert.
- حصر نتائج الاستعلام للترقيم.
- استخدام `Future` للاستعلامات المرة الواحدة، `Stream` للاستعلامات التفاعلية.
- تشفير قاعدة البيانات للبيانات الحساسة (عند الموافقة).

---

## 7. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| العمارة العامة | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) |
| العمل بدون إنترنت | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| معايير البرمجة | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |

---

*هذه الوثيقة جزء من المرجع الرسمي لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
