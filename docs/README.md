# SAEQ — Documentation Hub

> **Version:** 1.0.0
> **Status:** Approved
> **Last Updated:** 2026-07-23
> **Author:** Senior Flutter Software Engineer
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)

---

## 1. تعريف بالمشروع

**SAEQ** هي منصة تقنية متكاملة (Enterprise Platform) تقدم خدمات توصيل شاملة تخدم المملكة العربية السعودية، وتدعم التوسع الإقليمي المستقبلي.

تتكوّن المنصة من أربع تطبيقات رئيسية:

| # | التطبيق | الاسم الإنجليزي | المسؤولية |
|---|---------|-----------------|-----------|
| 1 | جاري | **Jari** (Customer Mobile) | طلبات العملاء، التتبع، المدفوعات |
| 2 | فزعة | **Fazaa Driver** (Driver Mobile) | توصيل الطلبات، التنقل، الأرباح |
| 3 | منفعة | **Manafa Merchant** (Merchant Mobile) | الإدارة اليومية للفروع والطلبات |
| 4 | لوحة التحكم | **SAEQ Web Admin** | حوكمة المنصة لملاك SAEQ فقط |

بالإضافة إلى التطبيقات الأربعة، تشمل المنصة: قاعدة بيانات مركزية، فهررس منتجات مركزي، سوق الجملة، خدمات الذكاء الاصطناعي، والتكامل مع الجهات الحكومية السعودية.

---

## 2. طريقة استخدام الوثائق

### 2.1 نقطة الدخول الرسيسة

- **للمطورين الجدد:** ابدأ بـ [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) ثم [41_OFFICIAL_BUSINESS_RULES.md](./41_OFFICIAL_BUSINESS_RULES.md) و[ADR-014](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md).
- **للمراجعة السريعة:** استخدم [24_INDEX.md](./24_INDEX.md) — فهرس جميع الوثائق.
- **للبحث عن قرار معماري:** [27_ARCHITECTURAL_DECISIONS.md](./27_ARCHITECTURAL_DECISIONS.md) وملفات `docs/adr/`.
- **نموذج المجال / Multi-Tenant:** [42_PLATFORM_DOMAIN_ARCHITECTURE.md](./42_PLATFORM_DOMAIN_ARCHITECTURE.md).

### 2.2 تنسيق الأسماء

جميع الوثائق تستخدم التنسيق التالي:

```
NN_DOCUMENT_NAME.md
```

حيث `NN` هو رقم الترتيب (00، 01، 02، ... 35).

### 2.3 الترتيب الرسمي للقراءة

انظر قسم [3. ترتيب القراءة](#3-ترتيب-القراءة) أدناه.

---

## 3. ترتيب القراءة

للبدء العمل على المشروع، اقرأ الوثائق بالترتيب التالي:

| الترتيب | الملف | الوصف |
|---------|-------|-------|
| 1 | [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) | المرجع الرسمي الوحيد للمشروع |
| 2 | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) | الرؤية التجارية، المهمة، المبادئ |
| 3 | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) | نظرة عامة على العمارة، الطبقات |
| 4 | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) | العمارة المؤسسية الكاملة |
| 5 | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) | نمط العمارة النظيقة، الطبقات |
| 6 | [05_FOLDER_STRUCTURE.md](./05_FOLDER_STRUCTURE.md) | التخطيط المفصل للمجلدات |
| 7 | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) | معايير البرمجة، التنسيق |
| 8 | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) | قواعد التسمية |
| 9 | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) | نظام التصميم الموحد |
| 10 | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) | تصميم قاعدة البيانات |
| 11 | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) | فهرس المنتجات المركزي |
| 12 | [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) | سوق الجملة |
| 13 | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) | محرك إدارة التوصيل |
| 14 | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) | واجهات برمجة التطبيقات |
| 15 | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | سياسات الأمان |
| 16 | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) | سياسات العمل بدون إنترنت |
| 17 | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) | سياسات التسجيل |
| 18 | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) | إدارة الأخطاء |
| 19 | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) | الاختبارات |
| — | [localization/localization-guidelines.md](./localization/localization-guidelines.md) | إرشادات التعريب (PHASE 2.4.1) |
| 20 | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) | النشر والـ CI/CD |
| 21 | [20_DEVELOPMENT_ROADMAP.md](./20_DEVELOPMENT_ROADMAP.md) | خريطة طريق التطوير |
| 22 | [21_AI_ROADMAP.md](./21_AI_ROADMAP.md) | خطة دمج الذكاء الاصطناعي |
| 23 | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) | الامتثال السعودي |
| 24 | [23_CHANGELOG.md](./23_CHANGELOG.md) | سجل التغييرات |
| 25 | [24_INDEX.md](./24_INDEX.md) | فهرس المشروع |

---

## 4. شرح دور كل ملف

| الرقم | الوثيقة | الدور |
|-------|---------|-------|
| 00 | [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) | المرجع الرسمي الوحيد. يحتوي على الرؤية، المبادئ، قواعد المشروع، جدول القرارات المعمارية، وفهرس جميع الوثائق. |
| 01 | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) | الرؤية التجارية، المهمة، الأهداف، المنصات، اللغات، نظام التصميم. |
| 02 | [02_SYSTEM_ARCHITECTURE.md](./02_SYSTEM_ARCHITECTURE.md) | نظرة عامة على العمارة، الطبقات، تدفق الاعتماديات، التنظيم Feature-First. |
| 03 | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) | العمارة المؤسسية الكاملة (30 قسم): منصات، محركات، خدمات، أمان، مراقبة، نشر. |
| 04 | [04_CLEAN_ARCHITECTURE.md](./04_CLEAN_ARCHITECTURE.md) | نمط العمارة النظيقة، الطبقات، مبادئ الاعتماد، التنظيم Feature-First. |
| 05 | [05_FOLDER_STRUCTURE.md](./05_FOLDER_STRUCTURE.md) | التخطيط المفصل للمجلدات، قواعد التسمية للملفات والمجلدات. |
| 06 | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) | معايير البرمجة، التنسيق، جودة الكود، اختبارات، استيرادات، أداء، Riverpod، GoRouter. |
| 07 | [07_NAMING_CONVENTION.md](./07_NAMING_CONVENTION.md) | قواعد التسمية للكلاسات، الدوال، المتغيرات، الملفات، المزودات، الأدوات. |
| 08 | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) | نظام التصميم: ألوان، خطوط، أزرار، بطاقات، حقول، تنبيهات، أيقونات، حركة، وضع ليلي. |
| 09 | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) | تصميم قاعدة البيانات (Drift/SQLite)، DAO، مزامنة، ترحيل، أفضل ممارسات. |
| 10 | [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md) | فهرس المنتجات المركزي، الباركود، الصور، المواصفات، العلامات، الموردين، الوحدات. |
| 11 | [11_WHOLESALE_MARKET_ARCHITECTURE.md](./11_WHOLESALE_MARKET_ARCHITECTURE.md) | سوق الجملة، الموردين، التجار، الأسعار، الكميات، الطلبات، الصلاحيات. |
| 12 | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) | محرك إدارة التوصيل: التدفق النشط، تأكيد الاستلام، تأكيد التسليم، إثبات التسليم، التنقل. |
| 13 | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) | واجهات برمجة التطبيقات: Dio، Interceptors، Retrofit، Serialization، نقاط API. |
| 14 | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) | سياسات الأمان: التخزين، الشبكة، المصادقة، التفويض، التحقق، التشفير، الخصوصية. |
| 15 | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) | سياسات العمل بدون إنترنت: الكاش، صفوف الانتظار، حل النزاعات، UI غير المتصل. |
| 16 | [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md) | سياسات التسجيل: المستويات، السياق، ما يتم تسجيله وما لا يتم، الاحتفاظ. |
| 17 | [17_ERROR_HANDLING.md](./17_ERROR_HANDLING.md) | إدارة الأخطاء: التسلسل الهرمي، التدفق، قواعد التنفيذ، عرض الأخطاء، التعافي. |
| 18 | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) | الاختبارات: الهرم، أنواع الاختبارات، المحاكاة، التغطية، أفضل الممارسات. |
| 19 | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) | النشر: CI/CD، البيئات، الـ Flavors، بوابات الجودة، الإصدارات. |
| 20 | [20_DEVELOPMENT_ROADMAP.md](./20_DEVELOPMENT_ROADMAP.md) | خريطة طريق التطوير: المراحل 0-5، المكتمل، قيد الانتظار. |
| 21 | [21_AI_ROADMAP.md](./21_AI_ROADMAP.md) | خطة دمج الذكاء الاصطناعي: الخدمات، المراحل، التقنيات، المتطلبات. |
| 22 | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) | الامتثال السعودي: ZATCA، وصل، بلدي، نفاذ، عنوان، دفع، خرائط، SMS، WhatsApp. |
| 23 | [23_CHANGELOG.md](./23_CHANGELOG.md) | سجل جميع التغييرات الرئيسية في المشروع. |
| 24 | [24_INDEX.md](./24_INDEX.md) | فهرس المشروع الكامل، مقسم حسب الفئات، مع تدفق القراءة. |
| 25 | [25_GLOSSARY.md](./25_GLOSSARY.md) | المصطلحات المستخدمة في المشروع. |
| 26 | [26_ABBREVIATIONS.md](./26_ABBREVIATIONS.md) | الاختصارات المستخدمة في المشروع. |
| 27 | [27_DECISION_TREE.md](./27_DECISION_TREE.md) | شجرة القرارات: أين تجد الملف المناسب لتعديل جزء معين. |
| 28 | [28_DEPENDENCY_MAP.md](./28_DEPENDENCY_MAP.md) | خريطة اعتماد جميع الملفات على بعضها. |
| 29 | [29_DOCUMENT_CHECKLIST.md](./29_DOCUMENT_CHECKLIST.md) | قائمة مراجعة قبل اعتماد أي وثيقة. |
| 30 | [30_DIAGRAM_INDEX.md](./30_DIAGRAM_INDEX.md) | فهرس جميع الرسومات المستخدمة في المشروع. |
| 31 | [31_TRACEABILITY_MATRIX.md](./31_TRACEABILITY_MATRIX.md) | مصفوفة التتبع: المتطلبات → العمارة → التنفيذ → الاختبار → النشر. |
| 32 | [32_KNOWN_LIMITATIONS.md](./32_KNOWN_LIMITATIONS.md) | القيود الحالية في المشروع. |
| 33 | [33_SECURITY_INDEX.md](./33_SECURITY_INDEX.md) | فهرس جميع سياسات الأمان. |
| 34 | [34_API_INDEX.md](./34_API_INDEX.md) | فهرس جميع خدمات النظام وواجهات برمجة التطبيقات. |
| 35 | [35_DATABASE_INDEX.md](./35_DATABASE_INDEX.md) | فهرس جميع جداول النظام وعلاقاتها. |

---

## 5. البنية المجلدية للوثائق

```
docs/
├── 00_PROJECT_BIBLE.md          # المرجع الرسمي الوحيد
├── 01_BUSINESS_VISION.md        # الرؤية التجارية
├── ...
├── 24_INDEX.md                  # فهرس المشروع
├── 25_GLOSSARY.md               # المصطلحات
├── 26_ABBREVIATIONS.md          # الاختصارات
├── 27_DECISION_TREE.md          # شجرة القرارات
├── 28_DEPENDENCY_MAP.md         # خريطة الاعتماديات
├── 29_DOCUMENT_CHECKLIST.md     # قائمة مراجعة الوثائق
├── 30_DIAGRAM_INDEX.md          # فهرس الرسومات
├── 31_TRACEABILITY_MATRIX.md    # مصفوفة التتبع
├── 32_KNOWN_LIMITATIONS.md      # القيود المعروفة
├── 33_SECURITY_INDEX.md         # فهرس الأمان
├── 34_API_INDEX.md              # فهرس واجهات برمجة التطبيقات
├── 35_DATABASE_INDEX.md         # فهرس قاعدة البيانات
├── README.md                    # هذا الملف — نقطة الدخول
├── templates/
│   └── DOCUMENT_TEMPLATE.md     # قالب الوثائق
├── adr/
│   └── ADR_TEMPLATE.md          # قالب قرار معماري
├── diagrams/                    # الرسومات (لا توجد رسومات داخل ملفات Markdown)
│   ├── system/
│   ├── database/
│   ├── sequence/
│   ├── deployment/
│   └── ui/
├── images/                      # الصور (لا توجد صور داخل ملفات Markdown)
│   ├── branding/
│   ├── ui/
│   ├── architecture/
│   ├── screenshots/
│   └── icons/
└── archive/                     # الملفات القديمة المؤرشفة
    └── README.md
```

---

## 6. رابط إلى PROJECT_BIBLE

للحصول على النظرة العامة الكاملة للمشروع، راجع:

👉 **[00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md)**

---

*هذه الوثيقة نقطة الدخول الرسمية لوثائق مشروع SAEQ. أي مطور جديد يجب أن يبدأ قراءتها أولًا.*
