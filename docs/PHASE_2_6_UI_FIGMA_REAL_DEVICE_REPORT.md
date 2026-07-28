# PHASE 2.6 — UI Figma + Real Device Report

> **Program:** UI-First · Figma Interactive Prototype · Real Device Validation
> **Repository:** jari-tach/jari-platform
> **Main baseline:** `178c75d` (PR #9 Flutter Auth Batch 2 **MERGED**)
> **Batch 2 status:** **PASS — MERGED TO MAIN**
> **Batch 3 branch:** `feature/phase-2.6-flutter-home-availability-parity`
> **Status:** Flutter Batch 3 Home + Availability — **QG PASS · M2 Unavailable PASS · Busy preserved PASS · Batch 3 IN PROGRESS** (not fully closed)
> **Last updated:** 2026-07-29
> **Figma file:** `MNJldEpkMxVjIavCPaPBFh` (Final/Home `41:160`…`44:2159`)

---

## Deferred (owner)

| Item | Status |
|------|--------|
| Figma Present | **DEFERRED BY OWNER** |
| Screenshot comparison | **DEFERRED BY OWNER** |
| Figma Proto encoded open | **CANCELLED BY OWNER** |

---

## Batch status

| Batch | Status |
|-------|--------|
| 1 Inventory / mapping | PASS (docs) |
| 2 Auth Flutter | **PASS — MERGED** (`178c75d`) |
| 3 Home + Availability | **IN PROGRESS** |
| 4+ | NOT AUTHORIZED |

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
| **M2 close rule** | Unavailable cold-start race **device-PASS** on VKP-NX9. Busy path **device PASS** on VKP-NX9. Batch 3 still **not fully closed** (remaining screen-matrix / flow device rows PENDING; owner close not authorized by Busy alone). |

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
| Flow B Unavailable↔Available | PASS | Prior session partial / re-verify |
| M1 Offline CTA disabled | PASS | Prior session observed |
| M2 Connection restore (init race) | PASS (unit/widget) | **PASS** — Unavailable + Busy preserved (USB ADB) |
| M3 Failure Retry/Dismiss | PASS | PENDING |
| M4/M5/M7 Busy + open active | PASS | **PASS** (Busy preserved + active route) |
| M6 Restored Available | PASS | PENDING |
| M8 Logout prepare in Settings | PASS | Prior session observed |

**M2 Unavailable + Busy preserved: device PASS on HONOR VKP-NX9 (USB ADB).** Batch 3 not fully closed (matrix PENDING; Loading-offers after Accept is a separate defect).

---

## Screen matrix (Batch 3)

| Screen | Flutter | Route | Figma | State | Locale | Theme | Buttons | Device |
|--------|---------|-------|-------|-------|--------|-------|---------|--------|
| Home Available | `home_screen.dart` | `/home` | `41:160` | Available | AR/EN | L/D | CONNECTED | PENDING |
| Home Unavailable | same | `/home` | `41:273` | Unavailable | AR/EN | L/D | CONNECTED | PENDING |
| Home Busy | same | `/home` | `41:211` | Busy | AR/EN | L/D | CTA disabled + open active | PENDING |
| Home Offline | same | `/home` | `41:308` | Offline | AR/EN | L/D | CTA disabled | PENDING |
| Home Updating | same | `/home` | `41:353` | Processing | AR/EN | L/D | CTA disabled | PENDING |
| Home Failure | same | `/home` | `41:389` | Failure | AR/EN | L/D | Retry+Dismiss | PENDING |
| Home Dark | same | `/home` | `41:643` / `44:2159` | — | AR/EN | Dark | CONNECTED | PENDING |
| Home English | same | `/home` | `41:679` | — | EN | Light | CONNECTED | PENDING |
| Availability card | `driver_availability_card.dart` | `/home` | `39:2`/`39:6`/`39:13` | all | AR/EN | L/D | via controller | PENDING |

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
| Crash/Freeze (automated) | 0 observed in widget suite |
