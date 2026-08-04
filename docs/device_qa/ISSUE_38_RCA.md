# Issue #38 — Root Cause Analysis (binding sequence)

> **Status:** Device QA acceptance criteria met on HONOR (2026-08-04); Gate 4 CLOSED — PASS  
> **Date:** 2026-08-02 (updated 2026-08-04)  
> **Device:** HONOR VKP-NX9 / Android 16  
> **Branch (Driver):** `feature/step-4b-a-honor-live-geofence-validation` (`3f9ec5d`)  
> **PR #27:** unblocked for review/merge (separate owner action); Gate 4 no longer FAIL

## 1) Reproduction conditions (stable)

| Item | Value |
| --- | --- |
| Build | `1.0.0+1` debug |
| Defines | `SAEQ_BACKEND_MODE=remote`, `SAEQ_API_BASE_URL=http://127.0.0.1:3000`, `SAEQ_DEVICE_LOCATION_QA=true` |
| Backend | `enRouteToCustomer` for `SEED-DEL-0001` after Confirm pickup |
| UI after pickup | Status chip **To customer** = `DriverWorkflowStage.navToCustomer` (screenshot `c13_after_pickup.png`) |
| Mock method | `adb shell cmd location providers add/set-test-provider-*` for `test` + `gps`, re-created every ~3s |
| Observed | No transition to At customer / Confirm delivery after ≥60s dwell |

## 2) Failure-point isolation

| Layer | Result | Evidence |
| --- | --- | --- |
| A. Workflow stage after pickup | **OK** | UI chip “To customer”; Backend `enRouteToCustomer` |
| B. Watch started after confirmPickup | **Likely OK** (same process) | Code path `advanceWorkflow` → `_watchCustomerArrivalAndAdvance` on remote confirm success |
| C. Location fixes inside 80m @ acc≤50 | **FAIL** | `dumpsys location`: fused/network last fixes far from dropoff (`18*,43*` class); mock `gps`/`test` providers repeatedly **removed/disabled** between injects |
| D. Distance / geofence policy | **Not reached with valid inside fixes** | Policy only returns `arrived` after 2 inside+accurate hits |
| E. Backend arrival transition | **Not exercised** | No Confirm delivery UI; no arrival ack observed this session |
| F. Watch resume after process death | **Product gap** | `DeliveryController.initialize()` restores assignment + busy bind but **does not** call `_watchCustomerArrivalAndAdvance` when stage is `navToCustomer` |

**Primary failure point for the live FAIL:** **(C) location reception / mock stability** — fixes used for geofence evaluation were not a stable dwell inside the dropoff geofence.

**Secondary product defect (must fix for acceptance / session restore):** **(F) geofence watch not resumed on initialize.**

## 3) Root cause

### RC-1 (Device QA / platform) — primary for session FAIL

On HONOR, re-adding/removing the `gps` test provider every few seconds causes:

- `gps provider is not a test provider` when set without a successful add
- Continuous `test/gps provider removed mock provider override` / disabled

Meanwhile the app (with `SAEQ_DEVICE_LOCATION_QA`) historically forced
`forceLocationManager`, which kept reading LocationManager updates that were
**not** a stable mock at dropoff `(24.7201, 46.7201)`. Geofence policy correctly
stays `outside` / never reaches `arrived`.

**Update 2026-08-04 (`672a9eb` Device QA + follow-up):** dumpsys on HONOR
Android 16 showed mock last locations on `fused`/`test` while `gps` stayed
`null`. Product follow-up: watch stream uses Fused
(`forceLocationManager: false`) so Device QA mocks reach geofence evaluation
(Driver commit `1201719`).

**Update 2026-08-04 (Backend Device QA blocker):** After Fused watch, the app
did POST `/v1/deliveries/:id/arrival`, but Nest `ValidationPipe`
(`whitelist` + `forbidNonWhitelisted`) rejected `latitude`/`longitude`
because `ArrivalDto` had `@Type(() => Number)` only — no class-validator
decorators. HTTP access log showed misleading `statusCode:200` while
`SaeqExceptionFilter` logged `VALIDATION_ERROR`. Fix: add `@IsNumber` /
range constraints on lat/lng (and `@IsNumber` on accuracy) in
`saeq-backend` `ArrivalDto`. Evidence: Backend advanced to
`deliveryAwaitingManualConfirmation` (v29); UI unlocked **Verifying** /
**Enter delivery code** (post-arrival confirmation gate).

### RC-2 (Product) — confirmed code gap

After cold start / force-stop with an active `navToCustomer` assignment, geofence watching is never restarted. Session-restore Device QA then cannot complete arrival even if GPS is perfect.

File: `lib/features/delivery/presentation/controllers/delivery_controller.dart` — `initialize()` ends without resume of `_watchCustomerArrivalAndAdvance`.

## 4) Allowed fix plan (minimal)

1. **Product (RC-2):** In `initialize()`, after ready state with active assignment in `navToCustomer`, start `_watchCustomerArrivalAndAdvance` (same args pattern as post-confirmPickup). No API/contract/UI redesign.
2. **Device QA procedure (RC-1):** Re-test with **stable** mock: add `gps` test provider **once**, then only `set-test-provider-location` (no remove/re-add loop). Keep app on Active delivery (not Maps). Document dumpsys last location ≈ dropoff before claiming GPS PASS.
3. **No** random geofence radius / debounce / UX changes unless a new repro proves policy rejects valid inside fixes.

## 5) Acceptance (Issue #38 close)

On physical HONOR, after fix + stable mock procedure:

- GPS PASS  
- Geofence PASS  
- Arrival transition PASS  
- Confirm delivery PASS (if dependent)  
- No regression on prior PASS path (login→OTP→accept→pickup→maps→session)

PR #27 stays open until those pass + #39 handled + review.
