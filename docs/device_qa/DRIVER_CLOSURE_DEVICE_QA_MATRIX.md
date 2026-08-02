# Driver Closure — Device QA Matrix (Phase 4)

> **Status:** IN PROGRESS — partial results; **NOT** Release Gate  
> **Rules:** `PHASE_4_DEVICE_QA_EXECUTIVE_RULES.md` (ملزم)  
> **Device:** HONOR VKP-NX9 (`AP4EVB6423004646`), Android **16**  
> **Branch / HEAD:** `feature/step-4b-a-honor-live-geofence-validation` @ `9f7e5f6`  
> **Build:** `1.0.0+1` debug  
> **Defines:** `SAEQ_BACKEND_MODE=remote`, `SAEQ_API_BASE_URL=http://127.0.0.1:3000`, `SAEQ_DEVICE_LOCATION_QA=true`  
> **Tester:** Cursor agent (ADB)  
> **Session:** 2026-08-02 ~03:04–03:25 Asia/Riyadh  
> **Evidence:** `.backup/device-qa-closure-20260802/` (local)

| # | Scenario | Result | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1 | Fresh install | **PASS** | `screens/c01_fresh_launch.png` | uninstall + install Success; Welcome shown |
| 2 | Upgrade from previous build | **PASS** | `screens/c02_upgrade_launch.png` | `adb install -r` Success; launch OK |
| 3 | Login | **PASS** | `screens/c03_login.png` → home | Phone `0500000000` |
| 4 | OTP | **PASS** | `screens/c04_after_verify.png` | Dev OTP `000000` → Home |
| 5 | Network switch | **PASS** | `c06_offline` / `c07_online` | Airplane on→off cycle |
| 6 | Offline | **PASS** | `screens/c06_offline.png` | Offline/Reconnecting UI |
| 7 | Online restore | **PASS** | `screens/c07_online.png` | Shell restored online |
| 8 | Accept offer | **PASS** | `screens/c08_accepted.png` | Seeded pending offer; Active delivery |
| 9 | Reject offer | **FAIL** | — | Not re-tested cleanly; driver remained Busy with active assignment after accept path |
| 10 | External navigation / Maps | **PASS** | `screens/c10_maps_copy.png` → Maps | “Copy maps link” opened Google Maps at dropoff coords (~24.72,46.72). Route-not-found is Maps/env, not missing handoff |
| 11 | GPS | **FAIL** | `c12_*`, dumpsys | App registered for GPS (83 fixes); stable mock on named `gps` provider rejected by HONOR (`gps provider is not a test provider`). Auto-arrival not observed |
| 12 | Geofence arrival | **FAIL** | `screens/c12_after_dwell.png`, `c12_geofence_final` | Remained `Collected` / en-route UI; no Confirm delivery / verification after ≥60s mock dwell. **Blocks PR #27** |
| 13 | Confirm pickup | **PASS** | `screens/c13_after_pickup.png` | Advanced to To customer / customer visible |
| 14 | Arrival | **FAIL** | same as #12 | Blocked by geofence |
| 15 | Confirm delivery | **FAIL** | — | Not reached (blocked by #12/#14) |
| 16 | Cancel | **FAIL** | — | Cancel control not exercised on active trip this session |
| 17 | Report issue | **PASS** | `screens/c17_report.png` | Report a problem UI opened |
| 18 | App restart mid-trip | **PASS** | `screens/c19_restore.png` | force-stop → relaunch; Busy + Active delivery banner |
| 19 | Session restore | **PASS** | `screens/c19_restore.png` | Auth + assignment restored |
| 20 | Battery drain observation | **PASS** | session ~20m | Observational: no crash/ANR; no quantitative drain meter |
| 21 | Background behaviour | **PASS** | `screens/c21_bg.png` | HOME then relaunch OK |
| 22 | Reconnect after drop | **PASS** | `c06`/`c07` | After airplane restore |
| 23 | Notifications | **PASS** | `screens/c23_notifications.png` | Open notifications entry |
| 24 | External links | **PASS** | Maps handoff | Same as #10 |
| 25 | Maps handoff | **PASS** | Maps screenshot | Coordinates handoff succeeded |

## Failures logged (Phase 4 rule §2)

| ID | Case | Severity | Next |
| --- | --- | --- | --- |
| F1 | #12 Geofence / #11 GPS / #14 Arrival / #15 Delivery | High — blocks driver journey completion & PR #27 | GitHub Issue + root-cause → minimal fix only |
| F2 | #9 Reject | Medium — matrix incomplete | Re-run after clearing assignment / dedicated reject seed |
| F3 | #16 Cancel | Medium — matrix incomplete | Re-run on active trip with cancel path |

## Gate implications

- **PR #27 remains OPEN** — geofence Device QA **FAIL**.  
- **Merchant app:** still **FORBIDDEN**.  
- **Phases 5–7:** not started (blocked until Phase 4 complete per executive rules).  
- No product code changes in this session beyond documentation (Scope: Device QA only).
