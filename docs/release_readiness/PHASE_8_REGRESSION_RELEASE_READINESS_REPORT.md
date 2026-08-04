# Phase 8 — Regression & Release Readiness Report

> **Status:** **CLOSED — CONDITIONAL PASS** (owner selected conditional close 2026-08-04)  
> **Date:** 2026-08-04  
> **Plan:** `PHASE_8_REGRESSION_RELEASE_READINESS_PLAN.md`  
> **Branch:** `feature/step-4b-a-honor-live-geofence-validation` (PR #27)  
> **HEAD reviewed:** `98fad8e`  
> **CI on HEAD:** **GREEN** — https://github.com/jari-tach/jari-platform/actions/runs/30872894544  
> **Constraints honored:** no PR #27 merge · no Merchant · no Gate 9/10 · no commit/push this gate

## Git / scope snapshot

| Item | Result |
| --- | --- |
| Branch tracks remote | Yes (`98fad8e` pushed) |
| Dirty tracked noise | Local line-ending noise on `linux/macos/windows` generated plugin files — **not committed**, no content delta vs HEAD |
| Untracked local only | `docs/device_qa/evidence/`, `docs/performance/evidence/`, `docs/design/`, `.cursor/plans/`, `tool/parse_ui_*` — **not in Git** |
| Secrets in Git | **None** (no `.env` / keystore / pem tracked) |
| Merchant / Customer / Admin code in `main...HEAD` | **None** |
| Backend / Contracts changes in this Driver branch | **None** (Device QA noted prior backend ArrivalDto `cb11f7d` outside this repo) |

`origin/main...HEAD` product delta is Driver-only: delivery/location fixes, tests, closure docs (Gates 4–7), format hygiene.

## Technical checks (on `98fad8e` tree)

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` | **PASS** — No issues found | Local 2026-08-04 |
| `dart format --set-exit-if-changed lib test` | **PASS** — 0 changed | Local |
| `flutter test` (full) | **PASS** — **+1110** | Local |
| Focused path tests | **PASS** — geofence arrival (4), BackendConfiguration fake guards (incl. profile/release), STEP 4B-A regression (8) | Local |
| `flutter build apk --debug` | **PASS** | Local |
| GitHub CI Analyze / Test / Android / iOS | **PASS** | [run 30872894544](https://github.com/jari-tach/jari-platform/actions/runs/30872894544) on `98fad8e` |

No new commit created for Gate 8 → CI-on-latest-commit requirement remains satisfied by `98fad8e`.

## Functional regression (driver path)

Full Device QA re-run **not** required: no production-behavior commits after Device QA acceptance HEAD `3f9ec5d` except docs/format/test-stability (`021a823`…`98fad8e`). Validation = Gate 4 matrix (all 25 PASS) + automated journey/regression suites above.

| # | Path (owner list) | Gate 8 verdict | Basis |
| --- | --- | --- | --- |
| 1 | Launch + login | **PASS** | Device QA #1–3 · widget/smoke tests |
| 2 | OTP / session / refresh | **PASS** | Device QA #4/#19 · auth remote wiring unchanged post-QA |
| 3 | Online / Offline | **PASS** | Device QA #6–7/#22 |
| 4 | Receive offer | **PASS** | Device QA #8 · realtime tests green |
| 5 | Accept / Reject | **PASS** | Device QA #8–9 |
| 6 | Confirm pickup | **PASS** | Device QA #13 |
| 7 | Navigation / external maps handoff | **PASS** | Device QA #10/#24–25 · Gate 5.4 |
| 8 | Auto arrival / geofence | **PASS** | Device QA #11–12/#14 · step4 + step4ba tests |
| 9 | Confirm delivery | **PASS** | Device QA #15 |
| 10 | Report issue (+ cancel path) | **PASS** | Device QA #16–17 |
| 11 | Restore after background / kill | **PASS** | Device QA #18–19/#21 · restore geofence guards tested |
| 12 | Offline → Online | **PASS** | Device QA #6–7/#22 |
| 13 | Order-stage notifications | **PASS** | Device QA #23 |
| 14 | Network loss / restore | **PASS** | Device QA #5/#22 · Gate 5.3 |
| 15 | No Fake in profile/release | **PASS** | `BackendConfiguration` profile+release guard tests |

**Confirmed regressions discovered this gate:** none.  
**Production code changes this gate:** none.  
**Behavior changes this gate:** none.

## Build configuration review (read-only)

| Topic | Finding | Gate 8 action |
| --- | --- | --- |
| debug / profile / release separation | Standard Flutter flavors; release still uses **debug signing** | Debt → Gates 9–10 |
| Fake/Mock barred in profile/release | Enforced in `BackendConfiguration.resolve` + unit tests | OK |
| API environment | `--dart-define=SAEQ_BACKEND_MODE` + `SAEQ_API_BASE_URL` only; no hard-coded prod URL default | OK |
| Secrets in build files | No keystore secrets checked in | OK |
| Sensitive logging in ops path | `SaeqApiClient` + `HttpLogRedactor`; legacy `LoggingInterceptor` on unused-for-ops `ApiClient` | Debt |
| Location permissions | Android FINE/COARSE; iOS When-In-Use; no background location | OK |
| Android / iOS alignment | Matches current handoff + geofence model | OK |
| Local temp files in Git | Evidence/backup/design/tools **untracked**; `.backup/` gitignored | OK |

## Unified release debt inventory (from Gates 5–7 + this review)

| ID | Item | Classification | Source | Target |
| --- | --- | --- | --- | --- |
| R1 | Production `applicationId` (replace `com.example.saeq_driver`) | **RELEASE BLOCKER** | Gate 6 | Gate 9 |
| R2 | Official release signing (not debug keys) | **RELEASE BLOCKER** | Gate 6 | Gate 9 |
| R3 | Certificate pinning enabled & wired for prod hosts | **RELEASE BLOCKER** | Gate 6 / roadmap | Gate 9–10 |
| R4 | Memory re-measure on **profile/release** (debug PSS ~389 MB caveat) | **RECOMMENDED BEFORE RELEASE** | Gate 5 | Gate 9–10 |
| R5 | Legacy `LoggingInterceptor` Authorization logging if `ApiClient` exercised | **RECOMMENDED BEFORE RELEASE** | Gate 6–7 | Gate 9 |
| R6 | Dependency CVE triage / selective upgrades | **RECOMMENDED BEFORE RELEASE** | Gate 6–7 | Gate 9 |
| R7 | Launch-related TODOs (analytics, crash, request signing) | **RECOMMENDED BEFORE RELEASE** | Gate 7 | Gate 9–10 |
| R8 | Quantitative battery (%/hour) / Battery Historian | **OPTIONAL** | Gate 5 | Gate 10 if owner requires |
| R9 | Flutter Timeline formal scroll jank proof | **OPTIONAL** | Gate 5 | Gate 10 if owner requires |
| R10 | Split oversized `delivery_controller.dart` | **OPTIONAL** | Gate 7 | Post-release / ADR |
| R11 | Debug-only AppConfig URL prints / QA seed docs | **ACCEPTED RISK** (non-prod) | Gate 6–7 | Keep |
| R12 | CONDITIONAL caveats of Gates 5–7 as a set | **ACCEPTED RISK** for Driver ops | Gates 5–7 | Track via R1–R10 |

**No RELEASE BLOCKER prevents current Driver operation or debug/CI builds.** They block store/production ship (Gates 9–10).

## Overall decision

**CLOSED as CONDITIONAL PASS**

- No confirmed functional regression on the Driver journey  
- Analyze / tests / format / Android local build / CI (Android+iOS) green on `98fad8e`  
- No High/Critical new defects  
- Release blockers catalogued for Gates 9–10 only  

## Not done

- Merge PR #27  
- Merchant start  
- Gate 9 RC / Gate 10 Release  
- Executing R1–R10 remediations  
- Commit/push of this Gate 8 documentation (awaits «اعتمد الـ commit»)

## Files touched this gate (docs only)

| File | Change |
| --- | --- |
| `docs/release_readiness/PHASE_8_REGRESSION_RELEASE_READINESS_PLAN.md` | Plan |
| `docs/release_readiness/PHASE_8_REGRESSION_RELEASE_READINESS_REPORT.md` | This report |
| `docs/system-completion/DRIVER_CLOSURE_GATES.md` | Gate 8 = Regression & Release Readiness · CLOSED conditional |
