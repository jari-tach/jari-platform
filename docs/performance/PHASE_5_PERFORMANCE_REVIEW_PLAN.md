# المرحلة الخامسة — Performance Review (خطة تنفيذ ملزمة)

> **تاريخ التفعيل:** 2026-08-04  
> **الحالة:** **CLOSED — CONDITIONAL PASS** (اعتماد المالك 2026-08-04)  
> **البوابة:** Gate 5 في `docs/system-completion/DRIVER_CLOSURE_GATES.md`  
> **بعد:** إغلاق Device QA (Gate 4 = PASS، `021a823`)  
> **المرجعية الرقمية:** `docs/35_PERFORMANCE_BENCHMARKS.md` (عتبات القبول)  
> **الجهاز المرجعي لهذه الجولة:** HONOR VKP-NX9 / Android 16 (DUT الحقيقي للإغلاق)  
> **التقرير الختامي:** `PHASE_5_PERFORMANCE_REVIEW_REPORT.md`

## 1) قيود معتمدة (بدون استثناء)

- لا دمج لـ **PR #27** بدون أمر مستقل.  
- لا بدء لتطبيق التاجر.  
- لا الانتقال لـ Gate 6 (Security) قبل إنهاء Performance Review وإغلاقه رسميًا.  
- لا ميزات جديدة / لا Refactor واسع / لا تغيير عقود — قياس + توثيق + إصلاح عيب أداء يحجب القبول فقط.

## 2) ترتيب التنفيذ الإلزامي

| # | محور | بنود القياس |
| --- | --- | --- |
| **5.1** | Baseline Performance | Startup Time · First Frame · Memory Baseline · CPU Baseline |
| **5.2** | Scrolling Performance | Flutter Jank · Frame Drops · Raster Time · UI Thread |
| **5.3** | Network Performance | API Latency · Retry · Cache · Offline Recovery |
| **5.4** | Map Performance | Camera Animation · Marker Rendering · GPS Updates · Route Rendering |
| **5.5** | Battery | Foreground · Background · GPS Consumption |
| **5.6** | Performance Report | PASS/FAIL · التوصيات · إغلاق المرحلة إن استوفت المعايير |

لا يُفتح محور لاحق قبل تسجيل نتائج المحور الحالي (PASS / FAIL / DEFERRED مع سبب موثّق).

## 3) عتبات القبول (ملخص من Benchmarks)

تُقاس على DUT HONOR؛ يُذكر إن كان الهدف مأخوذًا من جهاز مرجعي مختلف في الوثيقة الأم.

| فئة | عتبة موجزة | مصدر |
| --- | --- | --- |
| Cold start | ≤ 3s (low-end) · هدف طموح ≤ 2s | §2.1 |
| Warm start | ≤ 1s | §2.1 |
| Memory idle (home) | ≤ 80 MB steady · peak ≤ 100 MB | §2.3 |
| Memory map/route | ≤ 150 MB · peak ≤ 200 MB | §2.3 |
| API small payload | ≤ 500ms (4G/local LAN may be faster) | §2.5 |
| Active + GPS battery | ≤ 5%/hour (observational إن تعذّر Historian) | §2.4 |
| Frame jank | لا jank مستمر يشعر به المستخدم؛ gfxinfo / Flutter timeline كدليل | NFR + قياس |

**تعريف PASS للمحور:** كل البنود المطلوبة لها قياس موثّق ولا تتجاوز العتبة دون موافقة استثناء مكتوبة.  
**تعريف FAIL:** تجاوز عتبة حرجة أو تعذّر القياس بدون سبب موثّق أو Regression واضح بعد Device QA.

## 4) أدوات القياس المعتمدة لهذه الجولة

| أداة | استخدام |
| --- | --- |
| `adb shell am start -W` | Cold/Warm startup TotalTime |
| `adb shell dumpsys meminfo <pkg>` | Memory PSS |
| `adb shell dumpsys cpuinfo` / `top` | CPU snapshot |
| `adb shell dumpsys gfxinfo <pkg>` | Frame stats / jank proxies |
| Backend Nest HTTP logs / `curl` timing | API Latency (local Device QA stack) |
| Airplane / reverse toggles | Offline recovery (سلوك مثبت في Device QA) |
| Screenshots + log files تحت `docs/performance/evidence/` (محلي، غير متتبع إن لزم) | دليل |

Profile/`flutter run --profile` يُفضَّل للـ First Frame وTimeline عند توفره دون توسيع نطاق البناء.

## 5) مخرجات كل محور

لكل محور ملف نتائج قصير أو قسم في التقرير النهائي يتضمن: المقياس، القيمة، العتبة، PASS/FAIL، الأداة، الوقت، ملاحظات.

التقرير الختامي: `docs/performance/PHASE_5_PERFORMANCE_REVIEW_REPORT.md`

## 6) إغلاق المرحلة 5

يُغلق Gate 5 فقط إذا:

1. اكتملت المحاور 5.1→5.5 بقياس موثّق.  
2. التقرير 5.6 بحالة إجمالية **PASS** (أو PASS مع استثناءات مالك صريحة).  
3. لا دمج PR #27 ولا Security قبل هذا الإغلاق.

## 7) حالة التقدم

| محور | الحالة |
| --- | --- |
| 5.1 Baseline | **PASS WITH MEMORY CAVEAT** — `PHASE_5_1_BASELINE_RESULTS.md` |
| 5.2 Scrolling | **PASS WITH INSTRUMENTATION CAVEAT** — `PHASE_5_2_SCROLLING_RESULTS.md` |
| 5.3 Network | **PASS** — `PHASE_5_3_NETWORK_RESULTS.md` |
| 5.4 Map | **PASS** — `PHASE_5_4_MAP_RESULTS.md` |
| 5.5 Battery | **PASS WITH INSTRUMENTATION CAVEAT** — `PHASE_5_5_BATTERY_RESULTS.md` |
| 5.6 Final report | **CLOSED — CONDITIONAL PASS** — `PHASE_5_PERFORMANCE_REVIEW_REPORT.md` |
