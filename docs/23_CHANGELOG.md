# SAEQ — Changelog

> **Version:** 1.0.0
> **Status:** Approved
> **Last Updated:** 2026-07-23
> **Author:** Senior Flutter Software Engineer
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)

---

## 1. نظرة عامة

هذا الملف يسجل جميع التغييرات الرئيسية في مشروع SAEQ.

---

## 2. [phase-2.3-driver-identity-profile] — 2026-07-25

### تمت إضافته
- Domain/Data/Presentation لملف السائق (`DriverProfile`, repositories, controllers, `ProfileScreen`).
- `SessionLifecycle` وحالة `expired` على جلسة المصادقة.
- سياسات أمنية قابلة للاختبار مع `SecurityPolicyDecision` وreason codes وإصدارات سياسة.
- حارس Fake Auth: ممنوع دائمًا في `kReleaseMode`، وممنوع في بيئة Production؛ دون أي Dart-define للتجاوز.
- منع تصنيع ملف تجريبي في Production/Release → `ProfileNotFoundError`.
- علامة provenance خفيفة `trialSynthetic` (مجال فقط، بلا Migration).
- ملاحظات التنفيذ: `PHASE_2_3_DRIVER_IDENTITY_PROFILE_NOTES.md`.
- اختبارات Domain/Data/Presentation + سياسات الأمان.

### تغيّر
- تسجيل `DriverProfileRepository` عبر `AppServiceRegistry` (ADR-010).
- مسار `/profile` يعرض الملف الحقيقي بدل Placeholder.
- توثيق حالة Stage B / PHASE 2.3 = Validated (pending commit).

### قيود معروفة
- لا Backend حقيقي؛ الملف التجريبي يُنشأ محليًا في Development/Test فقط.
- Production/Release: غياب الملف → `ProfileNotFound` دون هوية مصطنعة.
- لا Migration لـ Drift لتخزين نطاق المستأجر أو provenance.
- حراسة العميل دفاع متعمق فقط؛ الإنفاذ السلطوي Backend (Stage D).
- الحالة ليست `Done` قبل Commit المرحلة.

---

## 3. [docs-alignment-1.0] — 2026-07-25

### تمت إضافته (وثائق فقط)
- `41_OFFICIAL_BUSINESS_RULES.md` — قواعد الأعمال برموز ثابتة.
- `42_PLATFORM_DOMAIN_ARCHITECTURE.md` — Multi-Tenant، Catalog/Offer، Inventory، Order SM، Modular Monolith، AuthZ، Audit، Observability، Offline.
- `adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md` — قنوات Merchant Mobile + Web Admin + محاذاة المجال.
- `LEGACY_DI_MIGRATION_PLAN.md` — خطة إزالة `service_locator`/`get_it` لاحقًا.

### تغيّر
- مواءمة Bible / Vision / Enterprise / Catalog / Requirements / Roadmap / Offline / Data Dictionary / Index / Traceability Matrix مع القرارات المعتمدة.
- `31_TRACEABILITY_MATRIX.md` v2: ربط `BR-ORDER-*` … `BR-SEC-*` + توحيد سياسة الدفع.
- ARCH-008 (get_it) → Superseded by ADR-010.
- تنظيف trailing whitespace لنجاح `git diff --check`.
- لا تعديل Dart / لا PHASE 2.3 / لا Commit في هذه الخطوة وحدها.

---

## 4. [1.0.0] — 2026-07-23

### تمت إضافته
- **00_PROJECT_BIBLE.md:** المرجع الرسمي الوحيد للمشروع.
- **01_BUSINESS_VISION.md:** الرؤية التجارية، المهمة، المبادئ.
- **02_SYSTEM_ARCHITECTURE.md:** نظرة عامة على العمارة، الطبقات.
- **03_ENTERPRISE_ARCHITECTURE.md:** العمارة المؤسسية الكاملة (30 قسم).
- **04_CLEAN_ARCHITECTURE.md:** نمط العمارة النظيقة، الطبقات.
- **05_FOLDER_STRUCTURE.md:** التخطيط المفصل للمجلدات.
- **06_CODING_STANDARDS.md:** معايير البرمجة، التنسيق.
- **07_NAMING_CONVENTION.md:** قواعد التسمية.
- **08_UI_DESIGN_SYSTEM.md:** نظام التصميم الموحد.
- **09_DATABASE_ARCHITECTURE.md:** تصميم قاعدة البيانات.
- **10_PRODUCT_CATALOG_ARCHITECTURE.md:** فهرس المنتجات المركزي.
- **11_WHOLESALE_MARKET_ARCHITECTURE.md:** سوق الجملة.
- **12_DELIVERY_ENGINE.md:** محرك إدارة التوصيل.
- **13_API_ARCHITECTURE.md:** واجهات برمجة التطبيقات.
- **14_SECURITY_GUIDE.md:** سياسات الأمان.
- **15_OFFLINE_GUIDE.md:** سياسات العمل بدون إنترنت.
- **16_LOGGING_GUIDE.md:** سياسات التسجيل.
- **17_ERROR_HANDLING.md:** إدارة الأخطاء.
- **18_TESTING_GUIDE.md:** الاختبارات.
- **19_DEPLOYMENT_GUIDE.md:** النشر والـ CI/CD.
- **20_DEVELOPMENT_ROADMAP.md:** خريطة طريق التطوير.
- **21_AI_ROADMAP.md:** خطة دمج الذكاء الاصطناعي.
- **22_SAUDI_COMPLIANCE.md:** الامتثال السعودي.
- **23_CHANGELOG.md:** سجل التغييرات (هذا الملف).
- **24_INDEX.md:** فهرس المشروع.

### تمت تحديثه
- **ARCHITECTURE.md:** إزالة التكرار، إضافة روابط داخلية.
- **STRATEGIES.md:** إزالة التكرار، إضافة روابط داخلية.
- **CODING_STANDARDS.md:** إزالة التكرار، إضافة روابط داخلية.
- **DEVELOPMENT_ROADMAP.md:** إزالة التكرار، إضافة روابط داخلية.
- **ENTERPRISE_ARCHITECTURE.md:** إكمال جميع الأقسام.

### تمت إزالته
- لا توجد ملفات محذوفة. تمت إعادة تنظيم المحتوى إلى الوثائق الجديدة.

---

## 3. قواعد سجل التغييرات

- استخدام [Keep a Changelog](https://keepachangelog.com/).
- استخدام [الإصدار الدلالي](https://semver.org/).
- توثيق جميع التغييرات الكبيرة.
- تحديث هذا الملف مع كل إصدار.

---

## 4. الترابط مع باقي الوثائق

| الموضوع | الوثيقة المرجعية |
|---------|-------------------|
| جميع الوثائق | [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) |
| الفهرص | [24_INDEX.md](./24_INDEX.md) |

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
