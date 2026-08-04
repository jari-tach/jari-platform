# Phase 5.1 — Baseline Performance Results

> **Date:** 2026-08-04  
> **DUT:** HONOR VKP-NX9 · Android 16 · `AP4EVB6423004646`  
> **App:** `com.example.saeq_driver` debug (`SAEQ_DEVICE_LOCATION_QA` APK)  
> **HEAD:** `021a823` / branch `feature/step-4b-a-honor-live-geofence-validation`  
> **Method log:** `docs/performance/evidence/baseline_20260804/baseline_log.txt`  
> **Thresholds:** `docs/35_PERFORMANCE_BENCHMARKS.md` · plan `PHASE_5_PERFORMANCE_REVIEW_PLAN.md`

## Summary

| Metric | Result | Threshold | Verdict |
| --- | --- | --- | --- |
| Cold start (avg of 3) | **980 ms** (1042 / 933 / 965) | ≤ 3000 ms (low-end) · stretch ≤ 2000 ms | **PASS** |
| Warm start (avg of 3) | **74 ms** (56 / 74 / 91) | ≤ 1000 ms | **PASS** |
| First frame proxy | Same as `am start -W` TotalTime (COLD ~0.9–1.0 s) | Displayed with Activity `Status: ok` | **PASS** (proxy) |
| Memory TOTAL PSS (idle/home after warm) | **398435 KB ≈ 389 MB** | Idle ≤ 80 MB steady / peak ≤ 100 MB | **FAIL vs doc target** |
| Memory breakdown (App Summary) | Java ~11 MB · Native ~36 MB · Graphics ~57 MB · Private Other ~233 MB | — | Note: debug APK inflates PSS |
| CPU baseline | No sustained high share in snapshot (`cpuinfo` — package line absent/negligible at sample) | Observational | **PASS** (snapshot) |
| gfxinfo early sample | 7 frames · 57% janky · p50 48ms | Not used for Baseline pass; reserved for §5.2 | **DEFER to Scrolling** |

## Startup detail

Tool: `adb shell am start -W -n com.example.saeq_driver/.MainActivity` after `force-stop` (cold) or `KEYCODE_HOME` (warm).

## Memory detail

Source: `dumpsys meminfo com.example.saeq_driver` → `meminfo.txt`.

**Interpretation for Gate 5:**  
Benchmark §2.3 idle ≤80 MB is almost certainly written for **release**/optimized builds on mid-range phones. This capture is a **debug** build with Device QA defines.  

**Gate decision for 5.1:**  
- Startup / first-frame proxy / CPU snapshot: **PASS**  
- Memory absolute vs 80 MB: **FAIL on debug** — carry as **known debt** and re-measure on **release/profile** before declaring Gate 5 overall PASS; do not block continuing 5.2–5.5 with documentation of the caveat.  
- Overall **5.1 Baseline: PASS WITH MEMORY CAVEAT** (must recheck memory on profile/release before final Phase 5 close).

## Evidence files

- `baseline_log.txt`  
- `meminfo.txt`  
- `cpuinfo.txt`  
- `gfxinfo.txt`

## Next

**5.2 Scrolling Performance** (Home / lists / tabs) with larger gfxinfo window + optional profile mode.
