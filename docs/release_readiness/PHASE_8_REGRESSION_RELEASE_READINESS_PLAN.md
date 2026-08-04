# Phase 8 — Regression & Release Readiness Validation Plan

> **الحالة:** **CLOSED — CONDITIONAL PASS** (اعتماد المالك 2026-08-04)  
> **البوابة:** Gate 8 في `docs/system-completion/DRIVER_CLOSURE_GATES.md`  
> **الفرع:** `feature/step-4b-a-honor-live-geofence-validation` (PR #27)  
> **HEAD عند البدء والإغلاق:** `98fad8e`  
> **قيود ملزمة:** لا دمج PR #27 · لا تاجر · لا Gate 9/10 · لا commit/push إلا بأمر صريح

## الهدف

التحقق من عدم وجود Regression وظيفي بعد تراكم Gates 4–7، وتجميع جاهزية السائق وديون الإطلاق قبل RC، مع نتيجة: **PASS / CONDITIONAL PASS / FAIL**.

## محاور التحقق

| # | المحور | طريقة التحقق |
| --- | --- | --- |
| 8.1 | انحدار وظيفي (مسار السائق) | مصفوفة Device QA + اختبارات آلية + مراجعة diff التشغيلي |
| 8.2 | فحوصات تقنية | `flutter analyze` · `dart format` · `flutter test` · CI (Android+iOS) |
| 8.3 | إعدادات البناء | مراجعة فقط: Fake guard · API define · secrets · permissions · logging |
| 8.4 | ديون الإصدار الموحدة | جرد من Gates 5–7 مع تصنيف Blocker/Recommended/Optional/Accepted |
| 8.5 | نطاق الفرع | لا Merchant/Customer/Admin · لا evidence في Git · لا churn generated غير مقصود |
| 8.6 | تقرير نهائي | `PHASE_8_REGRESSION_RELEASE_READINESS_REPORT.md` |

## قواعد الإصلاح

إصلاح Regression مؤكد فقط، محدود ومغطى باختبار. لا ديون إطلاق، لا pinning/signing/app id، لا UI redesign.

## معايير الإغلاق

| النتيجة | الشرط |
| --- | --- |
| **PASS** | لا تحفظات مؤجلة تُنقل لـ 9–10 |
| **CONDITIONAL PASS** | لا Regression؛ تحفظات إطلاق موثقة تذهب لـ Gates 9–10 |
| **FAIL** | Regression مؤكد أو Analyze/Tests/CI/Build فاشلة أو High/Critical جديد |
