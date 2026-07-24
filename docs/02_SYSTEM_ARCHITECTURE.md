# SAEQ — System Architecture

> **Version:** 1.0.0  
> **Status:** Approved  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)، [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md)، [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md)  

---

## 1. نظرة عامة على العمارة

### 1.1 نمط العمارة

يعتمد مشروع SAEQ على **العمارة النظيفة (Clean Architecture)** — المعروفة أيضًا بـ **Onion Architecture** أو **Hexagonal Architecture** — فوق تنظيم **Feature-First Organization**.

> التفاصيل الكاملة للعمارة النظيقة موجودة في [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md)

### 1.2 الطبقات

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Feature   │  │   Feature   │  │   Feature   │              │
│  │  (UI +      │  │  (UI +      │  │  (UI +      │              │
│  │  State)     │  │  State)     │  │  State)     │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                     │
│         ▼                ▼                ▼                     │
│  ┌──────────────────────────────────────────────────┐           │
│  │              DOMAIN LAYER                         │           │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐            │           │
│  │  │Entities │  │UseCases │  │Repositories│         │           │
│  │  │(Business│  │(Business│  │(Abstract) │         │           │
│  │  │ Logic)  │  │ Logic)  │  │           │         │           │
│  │  └─────────┘  └─────────┘  └─────────┘            │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │    API      │  │  Local DB   │  │   Cache     │              │
│  │ (Remote)    │  │ (SQLite)    │  │ (InMemory)  │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                     │
│         ▼                ▼                ▼                     │
│  ┌──────────────────────────────────────────────────┐           │
│  │              REPOSITORY IMPLEMENTATIONS          │           │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐            │           │
│  │  │RemoteRepo│  │LocalRepo│  │CacheRepo│            │           │
│  │  └─────────┘  └─────────┘  └─────────┘            │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE LAYER                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Dio       │  │  Drift/     │  │  Secure     │              │
│  │  Client     │  │  SQLite     │  │  Storage    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 تدفق الاعتماديات

```
Presentation → Domain ← Data → Infrastructure
```

- **Presentation** يعتمقد على **Domain** (use cases، entities).
- **Data** يعتمقد على **Domain** (repository interfaces).
- **Infrastructure** يُستخدم من قبل **Data** (implementations ملموسة).
- **Domain** ليس له أي اعتماديات على طبقات أخرى.

---

## 2. التنظيم Feature-First

### 2.1 نظرة عامة

كل ميزة هي وحدة مستقلة ذات مكوّناتها الخاصة:

```
features/<feature_name>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── viewmodels/
└── <feature_name>_feature.dart        # تسجيل الميزة
```

### 2.2 الميزات الحالية

| الميزة | الوصف | المرحلة |
|-------|-------|---------|
| **auth** | تسجيل الدخول، المصادقة، إدارة الجلسات | المرحلة 1 |
| **onboarding** | جولة التطبيق، الأذونات، إعداد الملف الشخصي | المرحلة 1 |
| **orders** | قائمة الطلبات، تفاصيل الطلب، إدارة الحالة | المرحلة 2 |
| **driver** | تبديل الحالة، تتبع الموقع، التوافر | المرحلة 2 |
| **delivery** | تدفق التسليم النشط، تأكيد الاستلام/التسليم، إثبات التسليم | المرحلة 3 |
| **profile** | إدارة الملف الشخصي، معلومات المركبة، المستندات، الإعدادات | المرحلة 4 |
| **ai_services** | تحسين التوجيه، التنبؤ بالطلبات | المرحلة 5 |

---

## 3. الاهتمامات العرضية (Cross-Cutting Concerns)

### 3.1 هيكل lib/

```
lib/
├── core/                              # البنية المشتركة والأساسيات
│   ├── config/                        # إعدادات البيئة
│   ├── constants/                     # ثوابت التطبيق
│   ├── di/                            # حقن الاعتماديات (get_it)
│   ├── error/                         # أخطاء وإدارة الأخطاء
│   ├── localization/                  # التدوين اللغوي
│   ├── logging/                       # بنية التسجيل
│   ├── network/                       # أدوات الشبكة (interceptors، connectivity)
│   ├── providers/                     # مزودات Riverpod العالمية
│   ├── routes/                        # إعداد GoRouter
│   ├── services/                      # الخدمات الأساسية (API، auth، storage)
│   ├── theme/                         # نظام التصميم (الألوان، الطباعة، المسافات)
│   ├── utils/                         # الامتدادات، المساعدات، المتحققات
│   └── platform/                      # الكود الخاص بالمنصة
├── shared/                            # مكوّنات قابلة لإعادة الاستخدام عبر الميزات
│   ├── widgets/                       # أدوات واجهة مستخدم مشتركة
│   ├── services/                      # خدمات مشتركة
│   └── utils/                         # أدوات مشتركة
├── features/                          # وحدات الميزات (انظر أعلاه)
└── main.dart                          # نقطة دخول التطبيق
```

### 3.2 الخدمات الأساسية

| الخدمة | الوصف | الطبقة |
|-------|-------|--------|
| **ApiClient** | عميل HTTP على أساس Dio | البنية |
| **StorageService** | التخزين الآمن والمفاتيح القيم | البنية |
| **AuthService** | إدارة المصادقة والجلسات | البنية |
| **LoggerService** | تسجيل هيكلي | البنية |
| **NetworkInfo** | اكتشاف الاتصال | البنية |
| **AppConfig** | إعدادات البيئة والـ Flavors | البنية |

---

## 4. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| العمارة النظيقة التفصيلية | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) |
| هيكل المجلدات | [05_FOLDER_STRUCTURE.md](./05_FOLDER_STRUCTURE.md) |
| معايير البرمجة | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| قاعدة البيانات | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| واجهات برمجة التطبيقات | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| الأمان | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| العمل بدون إنترنت | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| العمارة المؤسسية | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |

---

*هذه الوثيقة جزء من المرجع الرسمي لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
