# STEP 4B-A — HONOR Foreground Geofence and Full Journey Validation

## Status

**PENDING RETEST — AUTH FIX MERGED (PR #30); LIVE JOURNEY NOT YET RE-RUN**

A prior Device QA attempt on HONOR was blocked at OTP verify by a pre-existing
auth client bug (hardcoded non-UUID `deviceId`). That bug was fixed in an
**independent** PR:

- PR [#30](https://github.com/jari-tach/jari-platform/pull/30) —
  `fix(auth): stable persisted UUID as device.deviceId in OTP verify`
- Merge SHA: `b99e9df` (Merge Commit of Head `398da9f`)

This STEP 4B-A branch has been updated with that `main`. This report must
**not** be read as PASS until the full live journey is re-executed and
evidenced. Owner deferral is **not permitted**.

Previous blocked Head: `55f586927f543229febcedf6cab1490dee2c0c60`
Current Head (post PR #30 merge into this branch): see git HEAD at push time.

---

## Environment — unlocked on 2026-08-01 (evening resume)

| Check | Result |
|---|---|
| Device | **HONOR VKP-NX9** (`AP4EVB6423004646`), brand HONOR, Android **16** (API 36) |
| `adb devices` | `device` |
| `flutter devices` | `VKP NX9 (mobile) • AP4EVB6423004646 • android-arm64` |
| Battery / location mode | level 52; `location_mode=3` (on) |
| PostgreSQL | Portable PostgreSQL **16.6** on `127.0.0.1:5432` (after VC++ Redistributable install) |
| Backend | NestJS `start:dev`, Node `v24.18.0` (within `engines: >=20 <25`) |
| Health | `GET /health/live` → ok; `GET /health/ready` → ok (database ok) |
| `adb reverse` | `tcp:3000` → host `3000` |
| Flutter Head | `55f586927f543229febcedf6cab1490dee2c0c60` (unchanged vs prior CI-green Head) |
| Local checks | `flutter analyze` No issues; `flutter test` **1078** passed |
| CI on Head | Analyze / Test / Build Android / Build iOS — all green (prior run) |
| Debug APK | Built with `--dart-define=SAEQ_BACKEND_MODE=remote`, `SAEQ_API_BASE_URL=http://127.0.0.1:3000`, `SAEQ_DEVICE_LOCATION_QA=true` |
| Seed + offer | Driver `+966500000000`; delivery `SEED-DEL-0001`; pending offer created via SQL (no offer-create API exists) |
| Scope vs `main` | Still **exactly 5 files** (3 usecases + regression test + this report) |

Evidence directory (local, not committed): `docs/device_qa/evidence/`

---

## Live journey progress (device)

| Step | Result | Evidence |
|---|---|---|
| App launch on HONOR | PASS | `evidence/01_launch.png` |
| Language → English | PASS | `evidence/02_english.png` |
| Onboarding → Sign in | PASS | `evidence/03_login.png` |
| OTP request `0500000000` → Backend | PASS | Backend log `POST /v1/auth/otp/request` 200, Dart UA via `adb reverse` |
| OTP screen shows 6 digits | PASS | Digits filled with `000000` |
| OTP verify | **FAIL** | Backend `VALIDATION_ERROR — Request validation failed` on `POST /v1/auth/otp/verify` |
| Availability / offers / pickup / geofence / arrival | **NOT REACHED** | Blocked by OTP verify |

---

## Root cause (classified)

**Category: pre-existing code defect outside STEP 4B-A scope — not environment, not HONOR, not location permissions.**

Flutter remote auth client sends a non-UUID `deviceId`:

```dart
// lib/features/auth/data/repositories/remote_authentication_repository.dart
device: const {
  'deviceId': 'saeq-driver-flutter',  // NOT a UUID
  'platform': 'android',
  'appVersion': '1.0.0',
},
```

Backend DTO requires a UUID:

```ts
// saeq-backend src/modules/auth/api/dto/otp-verify.dto.ts
export class DeviceInfoDto {
  @IsUUID()
  deviceId!: string;
  ...
}
```

Observed Backend responses (2026-08-01 ~16:45 UTC):

- `POST /v1/auth/otp/verify` → handled as `VALIDATION_ERROR — Request validation failed` (requestIds `6cb5fa1f-…`, `9099d241-…`)

This file is **not** among the five STEP 4B-A authorized files. Fixing it would expand PR ‎#27 beyond the approved STEP 4B-A scope (lifecycle usecase short-circuit + foreground geofence regression + this report). Per executive directive, out-of-scope fixes were not applied.

---

## Scenario results (device)

| Scenario | Result |
|---|---|
| App launch on HONOR | PASS |
| OTP request / Development OTP verify | **FAIL** (verify validation) |
| Driver profile + compliance load | NOT REACHED |
| Availability → Available | NOT REACHED |
| Offers load + accept | NOT REACHED |
| Active delivery + manual pickup confirmation | NOT REACHED |
| Foreground location monitoring | NOT REACHED |
| Automatic arrival exactly once | NOT REACHED |
| Manual arrival button = 0 | Automated regression only (not live device) |
| Delivery confirmation after Backend arrival ack | NOT REACHED |
| App restart / Logout checks | NOT REACHED |

## Counts (live device)

| Metric | Count |
|---|---|
| False arrivals | NOT EXECUTED |
| Duplicate arrivals | NOT EXECUTED |
| Duplicate commands | NOT EXECUTED |
| Duplicate transitions | NOT EXECUTED |
| Crashes | 0 observed before OTP block |
| Freezes | 0 observed before OTP block |
| Token leaks | NOT EXECUTED |
| PII leaks | NOT EXECUTED |

## Defects discovered on device

1. **OTP verify blocked by non-UUID `deviceId`** — Flutter `remote_authentication_repository.dart` hardcodes `saeq-driver-flutter`; Backend `@IsUUID()` rejects it. Blocks all remote Device QA journeys. **Outside STEP 4B-A scope.**

## Defects fixed in this branch (prior STEP 4B-A work — unchanged)

1. **Idempotent lifecycle command short-circuit** — `ConfirmPickupRemote`, `ReportAutomaticArrivalRemote`, and `ConfirmDeliveryRemote` honor a completed local command id before the stage gate.
2. Automated foreground geofence / remote-arrival regression tests under `test/features/step4ba/`.

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

- Flutter Analyze / Test / Build Android / Build iOS: SUCCESS on the final Head
- Device QA: **PASS** on a full live journey (owner deferral withdrawn)

Auth unblock: **DONE** via independent PR #30 (Merge SHA `b99e9df`).
Current Device QA: **PENDING RETEST** — full journey from OTP → availability →
offer → accept → pickup → en route → geofence arrival (exactly once) →
delivery confirmation must be re-run on HONOR with a rebuild that includes
PR #30. Do **not** treat this report as PASS and do **not** merge PR ‎#27
until that retest succeeds with evidence. H0 remains blocked.
