# PHASE 2.6 — UI Figma + Real Device Report

> **Program:** UI-First · Figma Interactive Prototype · Real Device Validation
> **Repository:** jari-tach/jari-platform
> **Main baseline:** `5a4015e` (PR [#11](https://github.com/jari-tach/jari-platform/pull/11) Flutter Batch 3 Home + Availability **MERGED**)
> **Batch 2 status:** **PASS — MERGED TO MAIN** (PR #9)
> **PR #10:** **MERGED**
> **PR #11:** **MERGED** (`5a4015e` on `main`, merge commit `5a4015ed577a9dd0b700841ad123f4f4510599b5`, mergedAt `2026-07-29T01:38:22Z`)
> **Batch 3 branch:** `feature/phase-2.6-flutter-home-availability-parity` → **MERGED TO MAIN**
> **Status:** Flutter Batch 3: **PASS — MERGED TO MAIN** · M2/Busy/Flow B/M1–M8 **PASS** · Matrix **PASS** · NOT CONNECTED=**0** · Crash=**0** · Freeze=**0**
> **STEP 1:** **AWAITING PR #12 ONLY** · **STEP 2 LOCKED**
> **Figma preparation for STEP 2:** **READY — NOT IMPLEMENTED IN FLUTTER**
> **Last updated:** 2026-07-29
> **Figma file:** `MNJldEpkMxVjIavCPaPBFh` (Final/Home `41:160`…`44:2159`)

---

## Deferred (owner)

| Item | Status |
|------|--------|
| Figma Present | **DEFERRED BY OWNER** |
| Screenshot comparison | **DEFERRED BY OWNER** |
| Figma Proto encoded open | **CANCELLED BY OWNER** |
| Loading offers (after Accept) | **KNOWN DEFECT — Deferred STEP 3** (do **not** claim fixed) |

---

## Batch status

| Batch | Status |
|-------|--------|
| 1 Inventory / mapping | PASS (docs) |
| 2 Auth Flutter | **PASS — MERGED** (`178c75d`) |
| 3 Home + Availability | **PASS — MERGED TO MAIN** (PR #10 + PR #11 → `5a4015e`) |
| 4+ / STEP 2 | **LOCKED** (awaiting PR #12 close of STEP 1 docs only) |

---

## Batch 3 implementation summary

| Area | Change |
|------|--------|
| Home | Greeting first · summary without QA Trial label · removed fixed Sign Out · no-offer hint · notifications + quick actions wired |
| Availability | Figma Final card fills (Available/Busy/Offline) · Failure Retry+Dismiss · Busy → Open active delivery CTA · purple busy tokens |
| Connectivity | Level reconciliation + post-init replay (`AvailabilityConnectivityBridge`) |
| Logout | Settings/Profile only + `prepareForLogout()` before `signOut()` |

---

## Batch 3 — Connectivity / Availability init race (M2)

| Field | Detail |
|-------|--------|
| **Issue** | Connectivity event arrived before Availability initialization completed. |
| **Root cause** | The bridge latched Online before persisted offline restoration, then did not replay the latest state after initialization. |
| **Fix** | Replay/reconcile the latest connectivity snapshot after Availability initialization; latest state wins (`_latestConnectivity` + force reconcile on `isInitialized`; controller `_connectivityEpoch` drops stale async). |
| **Regression test** | `test/features/availability/presentation/connectivity_init_race_test.dart` — Persisted Offline + Online-before-init-complete (Tests 1–9) **PASS** |
| **Domain reconnect** | Online clears connectivity-offline → **unavailable** (never auto-available); Busy preserved |
| **Device result (VKP-NX9)** | **PASS (Unavailable path)** — USB ADB retest on HONOR VKP-NX9 (`AP4EVB6423004646`), transport_id:1 stable with Wi-Fi OFF. Package `com.example.saeq_driver`; APK `build\app\outputs\flutter-apk\app-debug.apk` install Success. Commit noted `178c75d` (dirty working tree). Persisted Offline → Online during init → Offline banner cleared, Availability → Unavailable, not auto-Available, no restart/navigation. Evidence: `.backup/device-qa-ui-first-20260728/batch3-m2/` (`m2-online-after-init.png`, `m2-seed-offline.png`, `results.json`, `qa_log.txt`) — not git-added. Prior wireless ADB FAIL retained as history only: `.backup/device-qa-connectivity-race-20260729/`. |
| **Busy preserved** | **PASS** — HONOR VKP-NX9 USB ADB; Busy+Active assignment seed (Accept bind + relaunch); Offline→force-stop→cold start→Online during init; Busy remained Busy; Active banner visible; `/delivery/active` PASS. Evidence: `.backup/device-qa-ui-first-20260728/batch3-m2/m2-busy-preserved.png` (+ xml/results) — local only.
| **M2 close rule** | Unavailable cold-start race **device-PASS**; Busy preserved **device-PASS**; Flow B / M1–M8 **PASS**. Batch 3 Flutter **PASS — MERGED TO MAIN**. Known defect **Loading offers** after Accept → **Deferred STEP 3** (not claimed fixed). |

---

## Buttons (Home / Availability)

| Class | Items |
|-------|-------|
| CONNECTED | Home notif, quick×3, bottom nav×5, availability primary, retry, dismiss, open active delivery, offer/assignment banner |
| INTENTIONALLY DISABLED | Availability CTA while processing / offline / busy |
| NOT CONNECTED | **0** (target) |

---

## Flow results (widget suite)

| Flow | Widget | Device (VKP-NX9) |
|------|--------|------------------|
| Flow B Unavailable→Available | PASS | **PASS** |
| M1 Offline CTA disabled | PASS | **PASS** |
| M2 Connection restore (init race) | PASS (unit/widget) | **PASS** — Unavailable + Busy preserved (USB ADB) |
| M3 Failure Retry/Dismiss | PASS | **PASS** |
| M4/M5/M7 Busy + open active | PASS | **PASS** (Busy preserved + active route) |
| M6 Restored Available | PASS | **PASS** |
| M8 Logout prepare in Settings | PASS | **PASS** |

**M2 / Busy / Flow B / M1–M8: PASS** on HONOR VKP-NX9 (USB ADB). Flutter Batch 3: **PASS — MERGED TO MAIN** (PR #11). Known defect: **Loading offers** after Accept → **Deferred STEP 3** (do **not** claim fixed). Matrix **PASS**; NOT CONNECTED=**0**; Crash=**0**; Freeze=**0**. STEP 1: **AWAITING PR #12 ONLY**; STEP 2 **LOCKED**.

---

## Screen matrix (Batch 3)

| Screen | Flutter | Route | Figma | State | Locale | Theme | Buttons | Device |
|--------|---------|-------|-------|-------|--------|-------|---------|--------|
| Home Available | `home_screen.dart` | `/home` | `41:160` | Available | AR/EN | L/D | CONNECTED | **PASS** |
| Home Unavailable | same | `/home` | `41:273` | Unavailable | AR/EN | L/D | CONNECTED | **PASS** |
| Home Busy | same | `/home` | `41:211` | Busy | AR/EN | L/D | CTA disabled + open active | **PASS** |
| Home Offline | same | `/home` | `41:308` | Offline | AR/EN | L/D | CTA disabled | **PASS** |
| Home Updating | same | `/home` | `41:353` | Processing | AR/EN | L/D | CTA disabled | **PASS** |
| Home Failure | same | `/home` | `41:389` | Failure | AR/EN | L/D | Retry+Dismiss | **PASS** |
| Home Dark | same | `/home` | `41:643` / `44:2159` | — | AR/EN | Dark | CONNECTED | **PASS** |
| Home English | same | `/home` | `41:679` | — | EN | Light | CONNECTED | **PASS** |
| Availability card | `driver_availability_card.dart` | `/home` | `39:2`/`39:6`/`39:13` | all | AR/EN | L/D | via controller | **PASS** |

---

## Quality Gate (post race fix · 2026-07-29)

| Check | Result |
|-------|--------|
| `dart format` | PASS |
| `flutter analyze` | **No issues found** |
| `flutter test` | **697 passed** |
| `git diff --check` | PASS |
| `flutter build apk --debug` | PASS |
| APK install VKP-NX9 | PASS (`AP4EVB6423004646`) — `app-debug.apk` install Success; USB ADB stable (transport_id:1, Wi-Fi OFF) |
| M2 device race (Unavailable) | **PASS** — cold-start Offline→Online during init; banner cleared → Unavailable; no auto-Available; no restart/navigation |
| Busy preserved (device) | **PASS** — Busy remained Busy after Offline cold-start race; Active banner + route PASS |
| Prior wireless ADB attempt | **FAIL** historically (`ADB_NOT_CONNECTED`) — superseded by USB retest PASS for Unavailable path |
| Crash | **0** |
| Freeze | **0** |
| NOT CONNECTED | **0** |
| Screen matrix (Batch 3) | **PASS** |
| Loading offers (Accept) | **KNOWN DEFECT — Deferred STEP 3** (not fixed) |
| STEP 1 | **AWAITING PR #12 ONLY** |
| STEP 2 | **LOCKED** |

---

## STEP 1 — Docs gate (post PR #11 merge)

| Field | Value |
|-------|-------|
| Flutter Batch 3 | **PASS — MERGED TO MAIN** |
| PR #10 | **MERGED** |
| PR #11 | **MERGED** (`5a4015e`) |
| PR #12 | **OPEN** — docs only (this PR); **DO NOT MERGE until owner authorizes** |
| M2 / Busy / Flow B / M1–M8 | **PASS** |
| Matrix | **PASS** |
| NOT CONNECTED | **0** |
| Crash / Freeze | **0** / **0** |
| Loading offers | **KNOWN DEFECT — Deferred STEP 3** (not claimed fixed) |
| Figma preparation for STEP 2 | **READY — NOT IMPLEMENTED IN FLUTTER** |
| STEP 1 decision | **AWAITING PR #12 ONLY** |
| STEP 2 | **LOCKED** |
