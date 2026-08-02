# بوابات إغلاق تطبيق السائق (ملزم)

> **تاريخ التفعيل:** 2026-08-02  
> **الحالة:** ACTIVE — Scope Freeze  
> **قاعدة ذهبية:** يُمنع بدء أي تطوير في تطبيق التاجر قبل إغلاق جميع البوابات أدناه وموافقة المالك على الإطلاق.

## تجميد النطاق (المرحلة 1) — نافذ الآن

| ممنوع | مسموح فقط |
| --- | --- |
| ميزات جديدة | إصلاح أخطاء |
| تعديل UX إلا لإصلاح عيب | استقرار / أداء |
| تغيير عقود / DB / API عام | إصلاحات أمنية |
| مكتبات جديدة (إلا ضرورة قصوى) | إغلاق PR / CI / QA / توثيق الإغلاق |

**ممنوع:** مشروع التاجر، حزم Merchant OpenAPI التنفيذية، أي توسعة نطاق.

## لوحة الحالة (تحديث مستمر)

| # | المرحلة | الحالة | دليل |
| --- | --- | --- | --- |
| 1 | Scope Freeze | **ACTIVE** | هذا الملف |
| 2 | إغلاق جميع PRs | **IN PROGRESS** | #37/#5/#6 مدمجة؛ يبقى [#27](https://github.com/jari-tach/jari-platform/pull/27) مربوطًا بـ Device QA |
| 3 | Issues Critical/High | **PASS** | #32 مُغلق مع دمج #37؛ لا Issues مفتوحة |
| 4 | Device QA كامل | **READY TO RUN** | مصفوفة جاهزة — كل بند PASS/FAIL على جهاز فعلي |
| 5 | Performance | **NOT STARTED** | |
| 6 | Security Review | **NOT STARTED** | دين: TODOs أمنية + debugPrint في مسارات تشغيلية |
| 7 | Code Quality | **PARTIAL** | Analyzer نظيف على main؛ TODOs/debugPrint متبقية |
| 8 | Documentation Freeze | **NOT STARTED** | |
| 9 | Release Candidate | **BLOCKED** | يعتمد 2 + 4–8 |
| 10 | Release Gate + موافقة المالك | **BLOCKED** | |
| — | بدء تطبيق التاجر | **FORBIDDEN** | حتى 10 = PASS |

## §PRs (المرحلة 2)

| PR | Repo | CI | Conflicts | Review | ملاحظات |
| --- | --- | --- | --- | --- | --- |
| [#37](https://github.com/jari-tach/jari-platform/pull/37) | jari-platform | GREEN | — | MERGED | أغلق #32 |
| [#5](https://github.com/jari-tach/saeq-backend/pull/5) | saeq-backend | GREEN | — | MERGED | Phase 1 gaps |
| [#6](https://github.com/jari-tach/saeq-contracts/pull/6) | saeq-contracts | GREEN | — | MERGED | توثيق تأجيل Merchant فقط |
| [#27](https://github.com/jari-tach/jari-platform/pull/27) | jari-platform | كان GREEN؛ أُعيد مزامنته مع main | يُحدَّث بعد الدفع | — | STEP 4B-A؛ **لا دمج بلا Device QA PASS** |

شروط إغلاق كل PR: محدّث مع `main`، بدون تعارض، CI أخضر، Review مكتمل، بلا Requested Changes، بلا TODO/FIXME/Debug في diff التشغيلي.

## §Issues Critical/High (المرحلة 3)

| Issue | شدة | أثر على رحلة السائق | حالة |
| --- | --- | --- | --- |
| [#32](https://github.com/jari-tach/jari-platform/issues/32) | High | كان يمنع offline→available | **CLOSED** عبر #37 |

لا Issues Critical/High مفتوحة حاليًا. أي Bug جديد يمنع الرحلة يعيد المرحلة إلى FAIL.

## §Device QA (المرحلة 4) — قائمة إلزامية

كل بند: **PASS** أو **FAIL** مع دليل (لقطات/سجلات). لا «تقريبي».

تثبيت جديد · تحديث من نسخة قديمة · تسجيل الدخول · OTP · تغيير الشبكة · Offline · Online · قبول · رفض · ملاحة · GPS · Geofence · استلام · وصول · تسليم · إلغاء · إبلاغ مشكلة · إعادة تشغيل · استعادة جلسة · بطارية · خلفية · استعادة اتصال · إشعارات · روابط خارجية · خرائط.

ملف النتائج: `docs/device_qa/DRIVER_CLOSURE_DEVICE_QA_MATRIX.md`

## §ما بعد الإغلاق فقط

ترتيب تطبيق التاجر (ممنوع البدء الآن): MVP scope → عقود مشتركة → Design System فزعة للتاجر → هيكل المشروع → رحلة التاجر → Backend تدريجي → Device QA + نفس البوابات.

## Definition of Done (لكل مرحلة)

- لا Critical/High مفتوحة تمنع الرحلة  
- اختبارات المرحلة ناجحة  
- توثيق محدث  
- لا Fake/Placeholder في المسارات التشغيلية للإصدار  
- لا تغيير خارج نطاق المرحلة  
- Git قابل للتتبع + مراجعات مكتملة  
