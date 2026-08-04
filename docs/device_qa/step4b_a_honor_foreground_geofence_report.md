# STEP 4B-A — HONOR Foreground Geofence and Full Journey Validation

## Status

**BLOCKED — PRE-EXISTING IDEMPOTENCY-KEY CLIENT BUG (OUTSIDE STEP 4B-A SCOPE)**

After the independent auth `deviceId` fix (PR #30) was merged and this branch
was updated, Device QA was re-run from the beginning on HONOR. OTP verify now
**PASS**es. The live journey then advances through Home / Available (with a QA
DB force for an ADR-017 offline mapping quirk) to Offer Accept, where Backend
rejects the accept call because the Flutter client sends an `Idempotency-Key`
containing `:` characters.

This report must **not** be read as PASS. Owner deferral is **not permitted**.
PR ‎#27 must **not** be merged until the full live journey passes.

Pinned Head SHA for this report: `269146cd8652e91c3210d8cf4845f5fc0cf3c88d`
(compare with `gh api repos/jari-tach/jari-platform/pulls/27 --jq .head.sha`
before any merge).

---

## Unblocks completed before this retest

| Item | Result |
|---|---|
| PR [#30](https://github.com/jari-tach/jari-platform/pull/30) stable `device.deviceId` UUID | **Merged** — Merge SHA `b99e9df` (Head `398da9f`) |
| PR ‎#27 updated with `main` including PR #30 | Merge commit `572b1db` + docs `269146c` |
| Local `flutter analyze` on Head `269146c` | No issues |
| Local `flutter test` on Head `269146c` | **1085** passed |
| CI on Head `269146c` | Analyze / Test / Build Android / Build iOS — all green |
| Debug APK rebuild with three defines | Success |

---

## Environment — retest 2026-08-01 evening

| Check | Result |
|---|---|
| Device | **HONOR VKP-NX9** (`AP4EVB6423004646`), brand HONOR, Android **16** (API 36) |
| `adb devices` | `device` |
| PostgreSQL | Portable PostgreSQL **16.6** on `127.0.0.1:5432` |
| Backend | NestJS `start:dev`, Node within `engines: >=20 <25` |
| Health | `GET /health/live` → ok; `GET /health/ready` → ok |
| `adb reverse` | `tcp:3000` → host `3000` |
| Flutter Head | `269146cd8652e91c3210d8cf4845f5fc0cf3c88d` |
| Debug APK | `--dart-define=SAEQ_BACKEND_MODE=remote`, `SAEQ_API_BASE_URL=http://127.0.0.1:3000`, `SAEQ_DEVICE_LOCATION_QA=true` |
| Seed + offer | Driver `+966500000000`; delivery `SEED-DEL-0001`; pending offer via SQL |

Evidence directory (local, not committed): `docs/device_qa/evidence/`
(`r01_launch.png` … `r08_accepted.png`, `r_fail.png`, `step4ba_live_run.txt`)

---

## Live journey progress (retest after PR #30)

| Step | Result | Evidence |
|---|---|---|
| App launch on HONOR | PASS | `r01_launch.png` |
| Language → English | PASS | UI dump + tap log |
| Onboarding → Sign in | PASS | `r02_login.png` |
| OTP request `0500000000` | PASS | Backend `POST /v1/auth/otp/request` 200 |
| OTP verify `000000` with persisted UUID `deviceId` | **PASS** | Backend `POST /v1/auth/otp/verify` 200; `r04_after_verify.png` Home |
| Availability → Available | **PASS*** | `r06_available.png` shows **Stop receiving requests** |
| Open offer | PASS | `r07_offer.png` |
| Accept offer | **FAIL** | Backend `VALIDATION_ERROR — Idempotency-Key header contains unsupported characters` |
| Confirm pickup | NOT REACHED | Blocked by accept |
| En route / geofence / auto arrival / delivery confirm | NOT REACHED | Blocked by accept |

\*Availability note (environment workaround, not a product change in PR ‎#27):
Backend default status `offline` is mapped by Flutter to connectivity-offline.
ADR-017 denies `offline → available`, and connectivity recovery to local
`unavailable` cannot be sent on the wire (`toWireStatus(unavailable) == null`).
For this retest the seed row in `driver_availabilities` was forced to
`available` and the app was relaunched so `GET /availability` synced. This is
**not** claimed as a product fix and is **not** part of STEP 4B-A scope.

---

## Root cause (classified)

**Category: pre-existing code defect outside STEP 4B-A scope — not HONOR, not Geofence, not environment.**

Flutter builds offer-accept idempotency keys as:

```dart
// lib/features/delivery/presentation/controllers/delivery_controller.dart
String _commandId(...) => 'local:$driverId:$targetId:$action';
```

Example observed on the wire:

`local:e0fd2ff7-…:6306a6e1-…:accept`

Backend contract / decorator require:

`^[A-Za-z0-9._~-]+$` (no `:`).

Observed Backend response (2026-08-01 ~17:49 UTC):

- `POST /v1/offers/6306a6e1-fbaf-44b2-a74f-14f680e3008e/accept`
- `VALIDATION_ERROR — Idempotency-Key header contains unsupported characters`
- requestId `7b9d9bc1-623e-4379-8931-a14a9c76ed95`

UI shows: “Something went wrong while updating the delivery offer.” + “Reconnecting…”

This file (`delivery_controller.dart`) is **not** among the STEP 4B-A
authorized files. Fixing it inside PR ‎#27 would expand scope. Same governance
path as the prior `deviceId` bug: **independent small fix PR**, then rebase /
retest Device QA.

---

## Scenario results (device)

| Scenario | Result |
|---|---|
| App launch on HONOR | PASS |
| OTP request / Development OTP verify | **PASS** (after PR #30) |
| Driver profile + compliance load | PASS (Home reached) |
| Availability → Available | PASS* (DB force + relaunch; see note) |
| Offers load + accept | **FAIL** (Idempotency-Key `:`) |
| Active delivery + manual pickup confirmation | NOT REACHED |
| Foreground location monitoring | NOT REACHED |
| Automatic arrival exactly once | NOT REACHED |
| Manual arrival button = 0 | Automated regression only (not live device) |
| Delivery confirmation after Backend arrival ack | NOT REACHED |

## Counts (live device)

| Metric | Count |
|---|---|
| False arrivals | NOT EXECUTED |
| Duplicate arrivals | NOT EXECUTED |
| Duplicate commands | NOT EXECUTED |
| Duplicate transitions | NOT EXECUTED |
| Crashes | 0 observed |
| Freezes | 0 observed |
| Token leaks | NOT EXECUTED |
| PII leaks | NOT EXECUTED |

## Defects discovered on device

1. ~~OTP verify blocked by non-UUID `deviceId`~~ — **FIXED** in PR #30 (Merge `b99e9df`).
2. **Offer accept blocked by illegal `Idempotency-Key` characters (`:`)** —
   `DeliveryController._commandId` emits `local:…:…:…` while Backend enforces
   `^[A-Za-z0-9._~-]+$`. **Outside STEP 4B-A scope.**
3. **Availability offline mapping quirk (ADR-017 / wire gap)** — Backend
   `offline` leaves the driver unable to go available via the normal CTA in
   remote mode; QA used a DB force. Track separately; not required to claim
   STEP 4B-A PASS, but needed for a clean journey without SQL.

## Defects fixed in this branch (prior STEP 4B-A work — unchanged)

1. **Idempotent lifecycle command short-circuit** — `ConfirmPickupRemote`,
   `ReportAutomaticArrivalRemote`, and `ConfirmDeliveryRemote` honor a
   completed local command id before the stage gate.
2. Automated foreground geofence / remote-arrival regression tests under
   `test/features/step4ba/`.

## Authorized scope reminder

This STEP authorizes **foreground location only**.

Still locked / deferred:

- Background location
- Long-running foreground tracking service
- Embedded Map SDK
- Continuous location streaming
- WebSocket / Push
- Redis realtime
- Production deployment

## Merge gate

Per executive directive, STEP 4B-A merge requires:

- Flutter Analyze / Test / Build Android / Build iOS: SUCCESS on the final Head ✅ (`269146c`)
- Device QA: **PASS** on a full live journey (owner deferral withdrawn)

Auth `deviceId` unblock: **DONE** (PR #30).
Current Device QA: **BLOCKED** at offer accept by illegal `Idempotency-Key`.

**Stop condition met:** real blocker documented; PR not merged; H0 not started.

### Recommended unblock (requires owner authorization — expands beyond STEP 4B-A)

Authorize a **separate minimal PR** (e.g. `fix/delivery-idempotency-key-charset`) that changes
`DeliveryController._commandId` to emit a contract-safe key (no `:`), with
regression tests that the accept header matches `^[A-Za-z0-9._~-]{8,128}$`,
then:

1. Merge that fix to `main` with Merge Commit + pinned `expected_head_sha`.
2. Update PR ‎#27 onto the new `main`.
3. Rebuild the debug APK with the three defines and re-run Device QA from OTP
   through geofence arrival (exactly once) and delivery confirmation.
4. Only then flip this report to **PASS** and merge PR ‎#27.

Do **not** treat this report as PASS until that live geofence journey completes.
