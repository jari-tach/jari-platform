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
| 2 | إغلاق جميع PRs | **IN PROGRESS** | #37/#5/#6 مدمجة؛ يبقى [#27](https://github.com/jari-tach/jari-platform/pull/27) بانتظار مراجعة/دمج منفصلة بعد PASS Device QA |
| 3 | Issues Critical/High | **PASS** | #32 مُغلق مع دمج #37؛ لا Issues مفتوحة |
| 4 | Device QA كامل | **PASS — CLOSED** | اعتماد المالك 2026-08-04 · تقرير: `docs/device_qa/PHASE_4_DEVICE_QA_CLOSURE_REPORT.md` · مصفوفة: `DRIVER_CLOSURE_DEVICE_QA_MATRIX.md` |
| 5 | Performance | **PASS — CLOSED (conditional)** | تقرير: `docs/performance/PHASE_5_PERFORMANCE_REVIEW_REPORT.md` · اعتماد المالك 2026-08-04 |
| 6 | Security Review | **PASS — CLOSED (conditional)** | تقرير: `docs/security/PHASE_6_SECURITY_REVIEW_REPORT.md` · اعتماد صيغة CONDITIONAL PASS 2026-08-04 · HEAD `4e24763` |
| 7 | Code Quality | **PASS — CLOSED (conditional)** | تقرير: `docs/code_quality/PHASE_7_CODE_QUALITY_REVIEW_REPORT.md` · اعتماد CONDITIONAL PASS 2026-08-04 · baseline `4e24763` · CI أخضر لاحقًا على `98fad8e` |
| 8 | Regression & Release Readiness | **PASS — CLOSED (conditional)** | تقرير: `docs/release_readiness/PHASE_8_REGRESSION_RELEASE_READINESS_REPORT.md` · HEAD `98fad8e` · CI [30872894544](https://github.com/jari-tach/jari-platform/actions/runs/30872894544) · اعتماد CONDITIONAL PASS 2026-08-04 |
| 9 | Release Hardening & Production Preparation | **PASS — CLOSED (conditional)** | تقرير: `docs/release_hardening/PHASE_9_RELEASE_HARDENING_REPORT.md` · App ID `com.saeq.driver` · signing+pinning بنية مكتملة · أسرار الإنتاج عند المالك · HEAD أساس `38633c4` |
| 10 | Release Gate + موافقة المالك | **BLOCKED** | يعتمد Gate 9 + أمر صريح؛ تسليم keystore/pins/شهادات iOS |
| — | بدء تطبيق التاجر | **FORBIDDEN** | حتى 10 = PASS |

## §PRs (المرحلة 2)

| PR | Repo | CI | Conflicts | Review | ملاحظات |
| --- | --- | --- | --- | --- | --- |
| [#37](https://github.com/jari-tach/jari-platform/pull/37) | jari-platform | GREEN | — | MERGED | أغلق #32 |
| [#5](https://github.com/jari-tach/saeq-backend/pull/5) | saeq-backend | GREEN | — | MERGED | Phase 1 gaps |
| [#6](https://github.com/jari-tach/saeq-contracts/pull/6) | saeq-contracts | GREEN | — | MERGED | توثيق تأجيل Merchant فقط |
| [#27](https://github.com/jari-tach/jari-platform/pull/27) | jari-platform | **GREEN** @ `98fad8e` | MERGEABLE | — | Gates 4–8 لا تحجب الدمج فنّيًا؛ **لا يُدمج إلا بأمر صريح مستقل** |

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
