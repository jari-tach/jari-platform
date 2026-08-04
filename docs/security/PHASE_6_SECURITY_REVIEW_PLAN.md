# Phase 6 — Security Review Plan

> **الحالة:** **CLOSED — CONDITIONAL PASS** (اعتماد المالك على صيغة التحفظات 2026-08-04)  
> **البوابة:** Gate 6 في `docs/system-completion/DRIVER_CLOSURE_GATES.md`  
> **الفرع:** `feature/step-4b-a-honor-live-geofence-validation`  
> **HEAD عند الإغلاق:** `4e24763`  
> **قيود ملزمة:** لا دمج PR #27 · لا تطبيق تاجر · لا أكواد خارج إصلاح أمني/توثيق هذا الباب

## الهدف

مراجعة أمنية مقيدة لتطبيق SAEQ Driver (فزعة) فقط قبل المتابعة إلى Gate 7 Code Quality، مع مخرجات: **PASS / CONDITIONAL PASS / FAIL**.

## المحاور (إلزامية)

| # | المحور | طريقة التحقق |
| --- | --- | --- |
| 6.1 | الأسرار والمفاتيح وملفات البيئة | بحث أنماط secrets · `.gitignore` · عدم تتبّع `.env` / `.backup` |
| 6.2 | المصادقة والجلسات والتخزين المحلي | `SecureAuthTokenStore` · access token ذاكرة · Fake guard |
| 6.3 | صلاحيات Android / iOS | Manifest + Info.plist (موقع foreground فقط) |
| 6.4 | الاتصال الآمن TLS / الشبكة | لا `usesCleartextTraffic` · pinning flags · BackendConfiguration |
| 6.5 | التسجيلات وتسريب البيانات الحساسة | `HttpLogRedactor` في المسار التشغيلي · `LoggingInterceptor` القديم |
| 6.6 | الاعتماديات والثغرات المعروفة | `flutter pub outdated` (مراجعة سطحية؛ بدون ترقية قسرية) |
| 6.7 | الحماية من العبث / هندسة الإصدار | `applicationId` · توقيع release · minify |
| 6.8 | تقرير نهائي | `PHASE_6_SECURITY_REVIEW_REPORT.md` |

## خارج النطاق

- دمج PR #27  
- بدء تطبيق التاجر  
- تفعيل Certificate Pinning فعليًا في هذه المرحلة (دين مُتتبع لما قبل الإصدار)  
- ترقية كبرى للاعتماديات دون أمر مستقل  

## معايير الإغلاق

| النتيجة | الشرط |
| --- | --- |
| **PASS** | لا ثغرة medium+ مُثبتة في مسار السائق التشغيلي، ولا تحفظات مؤجلة تؤثر على الأمان عند الإطلاق |
| **CONDITIONAL PASS** | لا ثغرة medium+ في المسار التشغيلي الحالي، مع ديون موثّقة تُعالَج قبل Gates 9–10 |
| **FAIL** | ثغرة high/critical أو مسار Fake/secret قابل للتشغيل في profile/release |

## المراجع

- مراجعة فرع (Security Review subagent): ملخص داخل التقرير النهائي  
- ADR-027 Fake Offer Security · `docs/14_SECURITY_GUIDE.md` · `docs/33_SECURITY_INDEX.md`
