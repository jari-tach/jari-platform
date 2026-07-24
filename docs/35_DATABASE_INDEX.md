# SAEQ — Database Index

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Review Date:** 2026-07-23  
> **Next Review:** 2027-01-23  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)  

---

## فهرس قاعدة البيانات

يجمع هذا الملف جميع جداول النظام وعلاقاتها والوثائق الخاصة بها.

---

### 1. جداول قاعدة البيانات المحلية (Drift/SQLite)

| الجدول | الوصف | العلاقات | الوثيقة المرجعية |
|-------|-------|----------|-------------------|
| **orders** | طلبات التوصيل | يرتبط بـ drivers، deliveries | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| **drivers** | بيانات السائقين | يرتبط بـ orders، deliveries | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| **deliveries** | عمليات التسليم | يرتبط بـ orders، drivers | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| **products** | فهرس المنتجات | يرتبط بـ categories، brands، suppliers | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **categories** | تصنيفات المنتجات | يرتبط بـ products، parent_category | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **brands** | العلامات التجارية | يرتبط بـ products | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **suppliers** | الموردين | يرتبط بـ products | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **offline_actions** | الإجراءات المعلقة | — | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |

---

### 2. العلاقات بين الجداول

```
orders
    ├── driver_id → drivers.id
    ├── delivery_id → deliveries.id
    └── product_id → products.id (اختياري)

drivers
    └── id → orders.driver_id، deliveries.driver_id

deliveries
    ├── order_id → orders.id
    └── driver_id → drivers.id

products
    ├── category_id → categories.id
    ├── brand_id → brands.id
    └── supplier_id → suppliers.id

categories
    └── parent_id → categories.id (ذاتية الارتباط)

brands
    └── id → products.brand_id

suppliers
    └── id → products.supplier_id
```

---

### 3. جداول قاعدة البيانات المركزية (Backend)

| الجدول | الوصف | الوثيقة المرجعية |
|-------|-------|-------------------|
| **users** | جميع المستخدمين (drivers، customers، merchants، admins) | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **orders** | جميع الطلبات | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **drivers** | جميع السائقين | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **deliveries** | جميع عمليات التسليم | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **products** | فهرس المنتجات المركزي | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **categories** | تصنيفات المنتجات | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **brands** | العلامات التجارية | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) |
| **suppliers** | الموردين | [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) |
| **wholesale_orders** | طلبات الجملة | [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) |
| **traders** | التجار في سوق الجملة | [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) |
| **payments** | سجل المدفوعات | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| **notifications** | سجل الإشعارات | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **locations** | بيانات الموقع في الوقت الحقيقي | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| **ai_models** | نماذج الذكاء الاصطناعي | [21_AI_ROADMAP.md](./21_AI_ROADMAP.md) |

---

### 4. هيكل قاعدة البيانات المحلية

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

### 5. استراتيجيات قاعدة البيانات

| الاستراتيجية | الوصف | الوثيقة المرجعية |
|-------------|-------|-------------------|
| **Cache-First** | قراءة من قاعدة البيانات المحلية أولاً | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| **Write-Through** | الكتابة في كلا القاعدة المحلية والـ API | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| **Last-Write-Wins** | حل النزاعات باستخدام الطوابع الزمنية | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| **Migration** | ترحيل قاعدة البيانات بزيادة schemaVersion | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |

---

## انظر أيضًا

- [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) — معمارية قاعدة البيانات
- [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) — فهرس المنتجات
- [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) — سوق الجملة
- [34_API_INDEX.md](./34_API_INDEX.md) — فهرس واجهات برمجة التطبيقات
- [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — المرجع الرسمي للمشروع

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*