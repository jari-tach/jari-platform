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
| 2 | إغلاق جميع PRs | **PASS — PR #27 MERGED** | Squash `5f8f1fe` · CI main [30951251719](https://github.com/jari-tach/jari-platform/actions/runs/30951251719) SUCCESS · تقرير: `docs/final_release/PR27_MERGE_CLOSURE_REPORT.md` |
| 3 | Issues Critical/High | **PASS** | #32 مُغلق مع دمج #37؛ لا Issues مفتوحة |
| 4 | Device QA كامل | **PASS — CLOSED** | اعتماد المالك 2026-08-04 · تقرير: `docs/device_qa/PHASE_4_DEVICE_QA_CLOSURE_REPORT.md` · مصفوفة: `DRIVER_CLOSURE_DEVICE_QA_MATRIX.md` |
| 5 | Performance | **PASS — CLOSED (conditional)** | تقرير: `docs/performance/PHASE_5_PERFORMANCE_REVIEW_REPORT.md` · اعتماد المالك 2026-08-04 |
| 6 | Security Review | **PASS — CLOSED (conditional)** | تقرير: `docs/security/PHASE_6_SECURITY_REVIEW_REPORT.md` · اعتماد صيغة CONDITIONAL PASS 2026-08-04 · HEAD `4e24763` |
| 7 | Code Quality | **PASS — CLOSED (conditional)** | تقرير: `docs/code_quality/PHASE_7_CODE_QUALITY_REVIEW_REPORT.md` · اعتماد CONDITIONAL PASS 2026-08-04 · baseline `4e24763` · CI أخضر لاحقًا على `98fad8e` |
| 8 | Regression & Release Readiness | **PASS — CLOSED (conditional)** | تقرير: `docs/release_readiness/PHASE_8_REGRESSION_RELEASE_READINESS_REPORT.md` · HEAD `98fad8e` · CI [30872894544](https://github.com/jari-tach/jari-platform/actions/runs/30872894544) · اعتماد CONDITIONAL PASS 2026-08-04 |
| 9 | Release Hardening & Production Preparation | **PASS — CLOSED (conditional)** | تقرير: `docs/release_hardening/PHASE_9_RELEASE_HARDENING_REPORT.md` · App ID `com.saeq.driver` · signing+pinning بنية مكتملة · أسرار الإنتاج عند المالك · CI أخضر @ `3f86900` |
| 10 | Final Release Approval | **PASS — CLOSED (conditional) — READY AFTER OPERATIONAL HANDOFF** | تقرير: `docs/final_release/PHASE_10_FINAL_RELEASE_APPROVAL_REPORT.md` · HEAD `3f86900` · لا Blockers تقنية؛ تسليم المالك مطلوب قبل النشر |
| — | بدء تطبيق التاجر | **FORBIDDEN** | السائق مكتمل تقنيًا على `main` @ `5f8f1fe`؛ التاجر/النشر يتطلبان أمرًا مستقلًا + Operational Handoff |

## §PRs (المرحلة 2)

| PR | Repo | CI | Conflicts | Review | ملاحظات |
| --- | --- | --- | --- | --- | --- |
| [#37](https://github.com/jari-tach/jari-platform/pull/37) | jari-platform | GREEN | — | MERGED | أغلق #32 |
| [#5](https://github.com/jari-tach/saeq-backend/pull/5) | saeq-backend | GREEN | — | MERGED | Phase 1 gaps |
| [#6](https://github.com/jari-tach/saeq-contracts/pull/6) | saeq-contracts | GREEN | — | MERGED | توثيق تأجيل Merchant فقط |
| [#27](https://github.com/jari-tach/jari-platform/pull/27) | jari-platform | **GREEN** على main @ `5f8f1fe` | — | **MERGED** (squash) | 2026-08-04 · حذف الفرع · CI push [30951251719](https://github.com/jari-tach/jari-platform/actions/runs/30951251719) SUCCESS |

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
