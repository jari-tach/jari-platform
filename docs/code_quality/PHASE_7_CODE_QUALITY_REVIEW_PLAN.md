# Phase 7 — Code Quality Review Plan

> **الحالة:** **CLOSED — CONDITIONAL PASS** (اعتماد المالك 2026-08-04)  
> **البوابة:** Gate 7 في `docs/system-completion/DRIVER_CLOSURE_GATES.md`  
> **الفرع:** `feature/step-4b-a-honor-live-geofence-validation` (PR #27)  
> **HEAD عند البدء:** `4e24763`  
> **قيود ملزمة:** لا دمج PR #27 · لا تاجر · لا Gate 8 · لا commit إلا بأمر «اعتمد الـ commit»

## الهدف

مراجعة جودة الكود وقابلية الصيانة والاستقرار على فرع PR #27، مع إغلاق موثّق: **PASS / CONDITIONAL PASS / FAIL**.

## نطاق التحقق

| # | الفحص | معيار النجاح |
| --- | --- | --- |
| 7.1 | `flutter analyze` | بدون أخطاء جديدة؛ صفر issues إن أمكن |
| 7.2 | `flutter test` (الجناح الكامل) | كل الاختبارات ناجحة |
| 7.3 | تنسيق / ثبات معتمد | `dart format --set-exit-if-changed` على المسارات المتأثرة إن لزم |
| 7.4 | CI الكامل (`.github/workflows/flutter-ci.yml`) | اخضر محليًا أو عبر `gh` run |
| 7.5 | مراجعة جودة (قائمة المالك) | لا High/Critical مفتوحة بدون إصلاح أو توثيق استثناء صريح |
| 7.6 | تقرير نهائي | `PHASE_7_CODE_QUALITY_REVIEW_REPORT.md` |

## قواعد الإصلاح

- إصلاح مشكلات Gate 7 المؤكدة فقط.  
- لا إعادة هيكلة واسعة ولا تجميل واسع.  
- أي سلوك متغيّر: محدود + موثّق + اختبار.  
- لا إخفاء تحذيرات دون السبب الجذري.

## خارج النطاق

- ديون Gate 5 (ذاكرة profile، Timeline، Battery Historian)  
- ديون Gate 6 (pinning، توقيع release، `com.example`) إلا إن منعت Analyze/CI  
- Contracts / Backend  
- Documentation Freeze (Gate 8)

## معايير الإغلاق

| النتيجة | الشرط |
| --- | --- |
| **PASS** | Analyze + tests + CI خضراء؛ لا High/Critical؛ لا تحفظات جوهرية |
| **CONDITIONAL PASS** | الفحوصات خضراء؛ تحفظات Low/Medium موثّقة لا تمنع الاستقرار |
| **FAIL** | Analyze/tests/CI فاشلة، أو High/Critical غير مُعالَج |
