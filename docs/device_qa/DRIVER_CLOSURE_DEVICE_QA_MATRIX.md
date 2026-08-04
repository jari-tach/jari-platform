# Driver Closure — Device QA Matrix (Phase 4)

> **Status:** IN PROGRESS — journey blockers cleared 2026-08-04; formal close pending owner review  
> **Rules:** `PHASE_4_DEVICE_QA_EXECUTIVE_RULES.md` (ملزم)  
> **Device:** HONOR VKP-NX9 (`AP4EVB6423004646`), Android **16**  
> **Branch / HEAD (Driver):** `feature/step-4b-a-honor-live-geofence-validation` @ `1201719` + local cancel reason fix (pending commit)  
> **Backend:** ArrivalDto fix `cb11f7d`  
> **Build:** `1.0.0+1` debug  
> **Defines:** `SAEQ_BACKEND_MODE=remote`, `SAEQ_API_BASE_URL=http://127.0.0.1:3000`, `SAEQ_DEVICE_LOCATION_QA=true`  
> **Evidence:** `docs/device_qa/evidence/run_672a9eb/` + `.backup/device-qa-closure-20260802/`

| # | Scenario | Result | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1 | Fresh install | **PASS** | prior closure | — |
| 2 | Upgrade from previous build | **PASS** | prior closure | — |
| 3 | Login | **PASS** | prior + this session | Phone `0500000000` |
| 4 | OTP | **PASS** | prior + this session | OTP `000000` |
| 5 | Network switch | **PASS** | prior closure | — |
| 6 | Offline | **PASS** | prior closure | — |
| 7 | Online restore | **PASS** | prior closure | — |
| 8 | Accept offer | **PASS** | this session `r2_05_accepted` | — |
| 9 | Reject offer | **PASS** | `r2_03_rejected.png`; DB `rejected` | View offer → Reject |
| 10 | External navigation / Maps | **PASS** | prior closure | — |
| 11 | GPS | **PASS** | fused watch `1201719` + dumpsys mocks | LocationManager/gps path retired for watch |
| 12 | Geofence arrival | **PASS** | `DEVICE_QA_ARRIVAL_PASS_1201719.md` | Requires ArrivalDto backend fix |
| 13 | Confirm pickup | **PASS** | prior + this session | — |
| 14 | Arrival | **PASS** | Backend `deliveryAwaitingManualConfirmation` | Same as #12 |
| 15 | Confirm delivery | **PASS** | `DEVICE_QA_CONFIRM_DELIVERY_PASS.md` | UI: Enter delivery code → Confirm code → Summary |
| 16 | Cancel | **PASS** | `c16f_03_after.png`; DB `cancelled` v36 | Report a problem → Cancel; needs default `reasonCode` |
| 17 | Report issue | **PASS** | prior + cancel path opened issue page | — |
| 18 | App restart mid-trip | **PASS** | prior closure | — |
| 19 | Session restore | **PASS** | prior + post-delivery restart | — |
| 20 | Battery drain observation | **PASS** | observational | — |
| 21 | Background behaviour | **PASS** | prior closure | — |
| 22 | Reconnect after drop | **PASS** | prior closure | — |
| 23 | Notifications | **PASS** | prior closure | — |
| 24 | External links | **PASS** | Maps handoff | — |
| 25 | Maps handoff | **PASS** | prior closure | — |

## Failures closed

| ID | Case | Resolution |
| --- | --- | --- |
| F1 | GPS / Geofence / Arrival / Confirm delivery | Fused watch (`1201719`) + Backend ArrivalDto whitelist (`cb11f7d`) + confirm path PASS |
| F2 | Reject | Re-tested PASS |
| F3 | Cancel | Default `customer_request` when UI omits reasonCode |

## Gate implications

- **Device QA matrix rows:** all **PASS** on evidence above (owner formal close still required).  
- **PR #27:** still **unmerged** until owner approval + remaining closure gates (Performance → Security → Code Quality → docs → RC).  
- **Merchant app:** still **FORBIDDEN** until gates 4→10 + owner approval (`PHASE_4_DEVICE_QA_EXECUTIVE_RULES.md` §8).  
- **Pending Driver commit:** cancel `reasonCode` default (local working tree).
