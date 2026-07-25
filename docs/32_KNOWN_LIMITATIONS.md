# SAEQ — Known Limitations

> **Version:** 1.1.0
> **Status:** Approved
> **Last Updated:** 2026-07-25
> **Author:** Senior Flutter Software Engineer
> **Review Date:** 2026-07-25
> **Next Review:** 2027-01-23
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md), [LEGACY_DI_MIGRATION_PLAN.md](./LEGACY_DI_MIGRATION_PLAN.md)

---

## القيود المعروفة

توثق هذه الصفحة جميع القيود الحالية في مشروع SAEQ. يتم مراجعة هذه القائمة كل 6 أشهر أو عند أي تغيير معماري كبير.

### 0. DI Legacy (Driver)

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **`service_locator.dart` / get_it** | مسار DI موازٍ غير مستخدم؛ يتعارض مع ADR-010 (`AppServiceRegistry`) | Legacy / Candidate for later removal — **لا حذف في Stage A** | [LEGACY_DI_MIGRATION_PLAN.md](./LEGACY_DI_MIGRATION_PLAN.md) |
| **OfflineQueue / SyncManager** | موجودان وغير موصولين بدورة التوصيل بعد | Limitation / deferred wiring | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |

> **Web Admin** للمنصة يبقى Web (ليس قيدًا يحتاج Windows Desktop). قيد «لا Desktop» أدناه يخص عميل Driver الحالي، لا يلغي Web Admin.

---

### 1. قيود التطوير

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **عدد المنصات** | يدعم Android و iOS فقط. Web و Desktop غير مدعومة بعد. | قيد التخطيط | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |
| **اللغات** | يدعم العربية والإنجليزية. الهندية والبنغالية قيد التنفيذ. | قيد التنفيذ | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |
| **حجم قاعدة البيانات** | Drift (SQLite) مناسب للبيانات المحلية. لا يدعم بيانات كبيرة جدًا. | مقبول | [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md) |
| **التخزين السحابي** | لا يوجد تخزين سحابي مباشر. يعتمم على API. | مقبول | [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) |
| **الذكاء الاصطناعي** | خدمات الذكاء الاصطناعي غير مدمجة بعد. | قيد التخطيط | [21_AI_ROADMAP.md](./21_AI_ROADMAP.md) |
| **الويب** | لا يوجد دعم للويب في الوقت الحالي. | غير مبدوء | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |
| **سطح المكتب** | لا يوجد دعم لسطح المكتب في الوقت الحالي. | غير مبدوء | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |

---

### 2. قيود الأمان

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **Certificate Pinning** | يجب تنفيذه في الإنتاج. | قيد التنفيذ | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **تشفير قاعدة البيانات** | يجب تفعيله للبيانات الحساسة. | قيد التخطيط | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **كشف التلاعب** | يجب إضافة كشف الأجهزة المروّجة/المقرصنة. | قيد التخطيط | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **ProGuard/R8** | يجب تفعيله في الإنتاج. | قيد التخطيط | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |
| **تدقيق أمني** | يجب إجراء تدقيق أمني دوري. | غير مبدوء | [14_SECURITY_GUIDE.md](./14_SECURITY_GUIDE.md) |

---

### 3. قيود الأداء

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **حجم التطبيق** | قد يزداد حجم التطبيق مع إضافة المكتبات. | مراقبة | [06_CODING_STANDARDS.md](./06_CODING_STANDARDS.md) |
| **استهلاك البطارية** | قد يؤثر تتبع الموقع على البطارية. | مراقبة | [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md) |
| **استههلاك الذاكرة** | هدف < 200MB في الحالة الثابتة. | مراقبة | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **زمن الاستجابة** | هدف < 500ms (95th percentile). | مراقبة | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |

---

### 4. قيود التصميم

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **نظام التصميم** | قيد الإكمال. بعض المكوّنات غير مُنفذة بعد. | قيد التنفيذ | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| **الوضع الليلي** | مدعوم جزئيًا. يحتاج إلى مراجعة. | قيد التنفيذ | [08_UI_DESIGN_SYSTEM.md](./08_UI_DESIGN_SYSTEM.md) |
| **الوضعية غير المتصلة** | مؤشرات UI غير متصل قيد التنفيذ. | قيد التنفيذ | [15_OFFLINE_GUIDE.md](./15_OFFLINE_GUIDE.md) |
| **التكبير الديناميكي** | دعم التكبير يحتاج إلى مراجعة. | قيد التنفيذ | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |

---

### 5. قيود التوطيد

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **اللغات** | الهندية والبنغالية غير مكتملة بعد. | قيد التنفيذ | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |
| **النصوص** | بعض النصوص تحتاج إلى مراجعة ترجمة. | قيد التنفيذ | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |
| **الاتجام** | دعم RTL مكتمل. لكن بعض المكوّنات الثالثة قد لا تدعمه. | مراقبة | [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md) |

---

### 6. قيود النشر

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **CI/CD** | خط CI/CD غير مُنشأ بعد. | قيد التنفيذ | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| **البيئات** | بيئات dev/staging/prod مُعرّفة لكن غير مُنشأة بعد. | قيد التنفيذ | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| **النشر التلقائي** | النشر التلقائي غير مُفعّل بعد. | غير مبدوء | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |
| **التحديثات السريعة** | CodePush غير مُدمج بعد. | غير مبدوء | [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md) |

---

### 7. قيود أخرى

| القيد | الوصف | الحالة | الوثيقة المرجعية |
|-------|-------|--------|-------------------|
| **التوثيق** | بعض الوثائق تحتاج إلى تحديث. | قيد المراجعة | [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) |
| **الاختبارات** | تغطية الاختبارات لم تصل إلى 80% بعد. | قيد التنفيذ | [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md) |
| **الاعتماديات** | بعض الاعتماديات المقترحة غير مُعتمدة بعد. | قيد المراجعة | [03_ENTERPRISE_ARCHITECTURE.md](./03_ENTERPRISE_ARCHITECTURE.md) |
| **التكامل الحكومي** | التكامل مع ZATCA/Nafath غير مُنفّذ بعد. | غير مبدوء | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |
| **الدفع** | بوابات الدفع غير مُنفّذة بعد. | غير مبدوء | [22_SAUDI_COMPLIANCE.md](./22_SAUDI_COMPLIANCE.md) |

---

## سياسة المراجعة

يتم مراجعة هذه القائمة:

- **كل 6 أشهر** — كجزء من [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — Documentation Review Policy.
- **عند أي تغيير معماري كبير** — يتم تحديث القيود المرتبطة.
- **عند إغلاق أي قيد** — يتم نقله إلى [23_CHANGELOG.md](./23_CHANGELOG.md).

---

## انظر أيضًا

- [24_INDEX.md](./24_INDEX.md) — فهرس المشروع
- [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) — المرجع الرسمي للمشروع
- [23_CHANGELOG.md](./23_CHANGELOG.md) — سجل التغييرات

---

*هذه الوثيقة جزء من المرجع الرسمية لمشروع SAEQ. راجع [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md) للحصول على النظرة العامة الكاملة.*
