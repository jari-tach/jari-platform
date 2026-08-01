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
| 2 | إغلاق جميع PRs | **IN PROGRESS** | انظر §PRs |
| 3 | Issues Critical/High | **IN PROGRESS** | Issue #32 مفتوح |
| 4 | Device QA كامل | **NOT STARTED** | يلزم PASS/FAIL موثّق لكل بند |
| 5 | Performance | **NOT STARTED** | |
| 6 | Security Review | **NOT STARTED** | |
| 7 | Code Quality | **PARTIAL** | CI أخضر على #37؛ دين TODO/Fake خارج المسار التشغيلي |
| 8 | Documentation Freeze | **NOT STARTED** | |
| 9 | Release Candidate | **BLOCKED** | يعتمد 2–8 |
| 10 | Release Gate + موافقة المالك | **BLOCKED** | |
| — | بدء تطبيق التاجر | **FORBIDDEN** | حتى 10 = PASS |

## §PRs (المرحلة 2)

| PR | Repo | CI | Conflicts | Review | ملاحظات |
| --- | --- | --- | --- | --- | --- |
| [#37](https://github.com/jari-tach/jari-platform/pull/37) | jari-platform | GREEN | MERGEABLE | لا مراجعة بعد | Issue #32 + Maps؛ عليه commits محلية غير مدفوعة (هوية فزعة + polish) |
| [#27](https://github.com/jari-tach/jari-platform/pull/27) | jari-platform | — | MERGEABLE | — | STEP 4B-A؛ مرتبط Device QA — لا يُغلق بلا PASS ميداني |
| [#5](https://github.com/jari-tach/saeq-backend/pull/5) | saeq-backend | **RED** | MERGEABLE | — | يجب إصلاح CI |
| [#6](https://github.com/jari-tach/saeq-contracts/pull/6) | saeq-contracts | **RED** | MERGEABLE | — | docs مستقبلية؛ CI أحمر |

شروط إغلاق كل PR: محدّث مع `main`، بدون تعارض، CI أخضر، Review مكتمل، بلا Requested Changes، بلا TODO/FIXME/Debug في diff التشغيلي.

## §Issues Critical/High (المرحلة 3)

| Issue | شدة | أثر على رحلة السائق | حالة |
| --- | --- | --- | --- |
| [#32](https://github.com/jari-tach/jari-platform/issues/32) | High (journey blocker) | يمنع offline→available | إصلاح في #37 — غير مدمج |

لا يُسمح بأي Bug يمنع: OTP → توفر → قبول/رفض → استلام → وصول → تسليم → إلغاء/مشكلة → خروج.

## §Device QA (المرحلة 4) — قائمة إلزامية

كل بند: **PASS** أو **FAIL** مع دليل (لقطات/سجلات). لا «تقريبي».

تثبيت جديد · تحديث من نسخة قديمة · تسجيل الدخول · OTP · تغيير الشبكة · Offline · Online · قبول · رفض · ملاحة · GPS · Geofence · استلام · وصول · تسليم · إلغاء · إبلاغ مشكلة · إعادة تشغيل · استعادة جلسة · بطارية · خلفية · استعادة اتصال · إشعارات · روابط خارجية · خرائط.

ملف النتائج: `docs/device_qa/DRIVER_CLOSURE_DEVICE_QA_MATRIX.md` (يُنشأ عند بدء التشغيل).

## §ما بعد الإغلاق فقط

ترتيب تطبيق التاجر (ممنوع البدء الآن): MVP scope → عقود مشتركة → Design System فزعة للتاجر → هيكل المشروع → رحلة التاجر → Backend تدريجي → Device QA + نفس البوابات.

## Definition of Done (لكل مرحلة)

- لا Critical/High مفتوحة تمنع الرحلة  
- اختبارات المرحلة ناجحة  
- توثيق محدث  
- لا Fake/Placeholder في المسارات التشغيلية للإصدار  
- لا تغيير خارج نطاق المرحلة  
- Git قابل للتتبع + مراجعات مكتملة  
