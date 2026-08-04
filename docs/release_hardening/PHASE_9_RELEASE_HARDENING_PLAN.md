# Phase 9 — Release Hardening & Production Preparation Plan

> **الحالة:** **CLOSED — CONDITIONAL PASS**  
> **البوابة:** Gate 9 في `docs/system-completion/DRIVER_CLOSURE_GATES.md`  
> **الفرع:** `feature/step-4b-a-honor-live-geofence-validation`  
> **HEAD عند البدء:** `38633c4`  
> **قيود:** لا دمج PR #27 · لا Gate 10 · لا تاجر · لا commit/push إلا بأمر صريح · لا أسرار في Git

## خط الأساس

| بند | قيمة |
| --- | --- |
| Branch | `feature/step-4b-a-honor-live-geofence-validation` (متزامن مع origin) |
| HEAD | `38633c4` |
| CI | GREEN — run `30874151118` |
| محلي خارج النطاق | evidence / design / plans / parse tools / generated CRLF noise — **لا تُدرج** |

## محاور إلزامية

| # | المحور | المعيار |
| --- | --- | --- |
| 9.1 | Application ID / Bundle ID | إزالة `com.example` → `com.saeq.driver` |
| 9.2 | Release signing | لا debug signing في release؛ أسرار محلية + مثال |
| 9.3 | Certificate pinning | على `SaeqApiClient` للإنتاج/HTTPS مع pins قابلة للتدوير |
| 9.4 | Logging / Fake / Network / Permissions | إغلاق ديون Gate 6–8 المرتبطة بالإصدار |
| 9.5 | اعتماديات انتقائية | لا Critical/High مفتوحة تؤثر بالمسار الحي |
| 9.6 | اختبارات + builds + تقرير | Docs في `docs/release_hardening/` |

## Application ID المعتمد (مالك)

- قديم Android: `com.example.saeq_driver`
- قديم iOS: `com.example.saeqDriver`
- **جديد:** `com.saeq.driver` (وتطبيق الاختبارات `com.saeq.driver.RunnerTests`)

## تعريف الإغلاق

| النتيجة | الشرط |
| --- | --- |
| **PASS** | كل blockers مغلقة بالكامل بما فيها مفاتيح إنتاج فعلية داخل البنية (نادر دون تسليم مالك) |
| **CONDITIONAL PASS** | البنية الإنتاجية مكتملة؛ المتبقي تسليم keystore/pins/شهادات تشغيلية من المالك |
| **FAIL** | blocker غير معالج أو تحليل/اختبارات/بناء فاشل |
