# Phase 5.2 — Scrolling Performance Results

> **Date:** 2026-08-04  
> **DUT:** HONOR VKP-NX9 · Android 16  
> **Build:** debug Device QA APK  
> **Evidence:** `docs/performance/evidence/scroll_20260804/`

## Method

1. `dumpsys gfxinfo <pkg> reset`  
2. Scroll Home (↑↓) · open **Deliveries** · scroll · **Earnings** · scroll · return **Home**  
3. `dumpsys gfxinfo <pkg>` + `dumpsys meminfo`

## Results

| Metric | Value | Notes | Verdict |
| --- | --- | --- | --- |
| Total frames (gfxinfo) | **6** | Under-sampled — Flutter often bypasses classic View frame counters | Low confidence |
| Janky frames | **0 (0%)** | On the 6 recorded frames | **PASS** (observational) |
| Frame time p50 / p90 / p99 | **8 / 9 / 9 ms** | Well under 16.6 ms | **PASS** (observational) |
| Missed Vsync | **0** | — | **PASS** |
| GPU p50 / p99 | **7 / 9 ms** | Raster proxy | **PASS** (observational) |
| UI thread | No ANR; swipes + tab switches completed | Subjective smoothness OK | **PASS** |
| Memory after scroll TOTAL PSS | ~399 MB | Same debug memory class as Baseline | Caveat (debug) |

## Limitations

- `dumpsys gfxinfo` is a weak Flutter source of truth on Android 16 / Impeller·Skia.  
- Before **final Gate 5 close**, capture one **profile** Timeline (`flutter run --profile`) on Home/Deliveries scroll, or accept owner waiver of instrumentation gap.

## Gate 5.2

**PASS WITH INSTRUMENTATION CAVEAT** — no user-visible hitch in ADB session; formal jank proof deferred to profile Timeline if required at Phase close.
