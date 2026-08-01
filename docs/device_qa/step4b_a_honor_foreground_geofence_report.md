# STEP 4B-A — HONOR Foreground Geofence and Full Journey Validation

## Status

**BLOCKED — ENVIRONMENT NOT AVAILABLE**

Live HONOR Device QA was **not executed**. This report must not be read as PASS.

## Environment probe (2026-07-31)

| Check | Result |
|---|---|
| Flutter repository | `jari-tach/jari-platform` |
| Flutter baseline (branch start) | `4ed9b65e36d07984f9a821887a7de0d18916faf0` |
| Contracts | `contracts-v0.1.0` / `a54997590bb9e481b48e890c3a3d446f260e00e3` |
| Backend main SHA | `c27f33fa2fa59de8b1d56388f2d800046c2b9544` |
| Flutter mode intended | remote + `SAEQ_API_BASE_URL=http://127.0.0.1:3000` |
| Node runtime on engineer host | `v24.18.0` (required: Node 20 per `.nvmrc`) |
| Docker / `docker compose` | **NOT AVAILABLE** on PATH / Desktop not installed |
| PostgreSQL (`127.0.0.1:5432`) | **NOT LISTENING** |
| Backend (`127.0.0.1:3000` health) | **NOT LISTENING** |
| ADB binary | Found at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` |
| `adb devices` | Empty — **no device in `device` state** |
| HONOR device model | **NOT DETECTED** |
| Android version | **NOT DETECTED** |
| Mock location environment | **NOT AVAILABLE / NOT DOCUMENTED** |
| Physical/stable mock location | **NOT EXECUTED** |

## Environment re-probe (2026-08-01 — after sync with `main` @ STEP 6-C)

Branch was synced with `origin/main` (merge of `5eddb42`, STEP 6-C included) with
**zero conflicts** and no change to the five STEP 4B-A files. Live Device QA was
re-attempted the same day; the environment remains unavailable:

| Check | Result |
|---|---|
| `adb devices -l` (`%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`) | Empty — **no physical device attached** |
| `flutter devices` | Windows desktop / Chrome / Edge only — no Android target |
| HONOR device model / Android version | **NOT DETECTED** |
| Docker | **NOT INSTALLED** (not on PATH) |
| PostgreSQL | **NOT INSTALLED** (no service, no `psql`, no `C:\Program Files\PostgreSQL`) |
| Node runtime | `v24.18.0` — satisfies backend `engines` (`>=20.0.0 <25`), though `.nvmrc` pins 20 |
| Backend startable | **NO** — blocked on PostgreSQL |

**Owner directive (2026-08-01):** owner deferral is explicitly **not permitted**
for this gate. Device QA must be executed on a real physical Android device
(HONOR preferred) with a complete local Backend (Node 20-compatible +
PostgreSQL). Until that environment is provided, this PR **stops at the review
gate and must not be merged**.

To unblock: attach the HONOR (or equivalent Android) device with USB debugging
authorized, and provide PostgreSQL (native install or Docker Desktop) so the
Backend can be started at `127.0.0.1:3000`.

## Blocking reasons

1. No HONOR (or any Android) device attached via ADB.
2. Docker is unavailable, so `docker compose up -d postgres` cannot run.
3. Backend cannot be started to the required local health endpoints without Postgres.
4. Host Node is 24, not the CI-required Node 20.
5. Without Backend + ADB reverse + device, OTP → full delivery journey and live foreground geofence cannot be executed.

## Scenario results (device)

All live scenarios are recorded as **BLOCKED**, not PASS:

| Scenario | Result |
|---|---|
| App launch on HONOR | BLOCKED |
| OTP request / Development OTP verify | BLOCKED |
| Driver profile + compliance load | BLOCKED |
| Availability → Available | BLOCKED |
| Offers load + accept | BLOCKED |
| Active delivery + manual pickup confirmation | BLOCKED |
| Backend acknowledgment → current customer PII visible | BLOCKED |
| Upcoming customer PII hidden | BLOCKED |
| External navigation round-trip | BLOCKED |
| Foreground location monitoring | BLOCKED |
| Accuracy policy + required dwell | BLOCKED |
| Automatic arrival exactly once | **NOT EXECUTED** |
| Manual arrival button = 0 | Automated regression only (not live device) |
| Delivery confirmation after Backend arrival ack | BLOCKED |
| Contact cleared after delivery | BLOCKED |
| Location monitoring stopped after delivery | BLOCKED |
| App restart does not resurrect completed delivery | BLOCKED |
| Logout clears tokens + PII | BLOCKED |

## Counts (live device)

| Metric | Count |
|---|---|
| False arrivals | NOT EXECUTED |
| Duplicate arrivals | NOT EXECUTED |
| Duplicate commands | NOT EXECUTED |
| Duplicate transitions | NOT EXECUTED |
| Crashes | NOT EXECUTED |
| Freezes | NOT EXECUTED |
| Token leaks | NOT EXECUTED |
| PII leaks | NOT EXECUTED |

## Defects discovered on device

None — live journey was not reachable.

## Defects fixed in this branch

1. **Idempotent lifecycle command short-circuit** — `ConfirmPickupRemote`, `ReportAutomaticArrivalRemote`, and `ConfirmDeliveryRemote` now honor a completed local command id before the stage gate, so a same-Idempotency-Key retry after Backend acknowledgment cannot fail with `INVALID_DELIVERY_TRANSITION`.

Automated foreground geofence / remote-arrival regression tests were added under `test/features/step4ba/` to keep CI coverage for the authorized foreground-only scope.

## Authorized scope reminder

This STEP authorizes **foreground location only**.

Still locked / deferred:

- Background location
- Long-running foreground tracking service
- Embedded Map SDK
- Continuous location streaming
- WebSocket / SSE / Push
- Redis realtime
- Production deployment

## Merge gate

Per executive directive, STEP 4B-A merge requires:

- Flutter Analyze / Test / Build Android / Build iOS: SUCCESS
- Device QA: **PASS** **or** an **explicit owner deferral**

Current Device QA: **BLOCKED — ENVIRONMENT NOT AVAILABLE** (re-confirmed 2026-08-01)

Per owner directive of 2026-08-01, the deferral option is **withdrawn**: Device
QA must actually run and PASS before merge. Awaiting a physical Android device
(HONOR preferred) over ADB plus a PostgreSQL instance for the local Backend.
