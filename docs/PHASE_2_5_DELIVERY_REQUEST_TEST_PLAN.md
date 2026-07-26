# PHASE 2.5 — Delivery Request Lifecycle Test Plan

> **Status:** Architecture companion — Implementation **Complete** (PHASE 2.5 closeout)  

> **Date:** 2026-07-26  
> **Base:** `main` @ `88685fd`  
> **Related:** [PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md](./PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md), [ADR-020…028](./adr/), [PHASE_2_4_AVAILABILITY_TEST_PLAN.md](./PHASE_2_4_AVAILABILITY_TEST_PLAN.md), [localization/localization-guidelines.md](./localization/localization-guidelines.md)

---

## 1. Purpose

Define the minimum mandatory test matrix for PHASE 2.5 before and during implementation.  
Mirror conventions from availability/auth/profile suites: explicit `locale:`, typed failures, no host-locale dependence, no weakened assertions.

---

## 2. Conventions

| Rule | Detail |
|------|--------|
| Location | `test/features/delivery/**` (+ shared helpers) |
| Naming | `*_test.dart`; Arabic UI suites `*_arabic_localization_test.dart` |
| Fakes | Test doubles under `test/`; app Fake under `lib/` only with ADR-027 guards |
| CI | `.github/workflows/flutter-ci.yml` — analyze → test → builds |
| Quality gate | Business Logic → Localization → Accessibility → Testing |

Do **not** flag route paths, enum names, or domain English failure messages as UI copy.

---

## 3. Unit Tests

### 3.1 State machine / policies

| ID | Case |
|----|------|
| T-DOM-001 | Allowed `none → offered` |
| T-DOM-002 | Allowed `offered → accepting → accepted` |
| T-DOM-003 | Allowed `offered → rejecting → rejected` |
| T-DOM-004 | Allowed `offered → expired` / `taken_by_other` / `cancelled` |
| T-DOM-005 | Unknown transitions denied (ADR-022) |
| T-DOM-006 | One-active-offer: second distinct offer ignored while active (ADR-023) |
| T-DOM-007 | Duplicate same `offerId` idempotent |

### 3.2 Use cases

| ID | Case |
|----|------|
| T-UC-001 | Accept success produces assignment |
| T-UC-002 | Accept offline denied (ADR-024) |
| T-UC-003 | Accept when not confirmed-available denied |
| T-UC-004 | Accept idempotent retry safe |
| T-UC-005 | Accept maps 409 → taken_by_other |
| T-UC-006 | Accept maps 410 → expired |
| T-UC-007 | Reject success clears offer |
| T-UC-008 | Expire handler terminalizes offer |
| T-UC-009 | Unauthenticated deny |

### 3.3 Repository

| ID | Case |
|----|------|
| T-REPO-001 | Fake watch emits configured offers |
| T-REPO-002 | Fake accept/reject/conflict behaviors |
| T-REPO-003 | Local assignment upsert/get/clear |
| T-REPO-004 | Fake construction blocked in simulated release/production (ADR-027) |

---

## 4. State Machine Tests

Dedicated policy suite covering the full allow-list matrix and a representative sample of denied edges (not only happy path). Include concurrent “accepting” guards (cannot accept twice in parallel logically).

---

## 5. Repository Tests

- Contract compliance for Fake and local assignment store.  
- No raw exceptions as expected business outcomes.  
- Persistence round-trip of accepted assignment snapshot (ADR-028).

---

## 6. Offline Tests

| ID | Case |
|----|------|
| T-OFF-001 | Accept denied when NetworkMonitor offline |
| T-OFF-002 | Accept button disabled / safe copy when offline |
| T-OFF-003 | Reject offline does not create assignment/busy |
| T-OFF-004 | No queued accept replay on reconnect |

---

## 7. Widget Tests

| ID | Case |
|----|------|
| T-WID-001 | Full-screen offer shows summary + Accept/Reject |
| T-WID-002 | Processing disables duplicate Accept |
| T-WID-003 | Expired/taken states show safe messages |
| T-WID-004 | Offline disables Accept |
| T-WID-005 | English locale regression (no Arabic app-owned labels) |
| T-WID-006 | Arabic locale regression (no English app-owned labels) |
| T-WID-007 | RTL Directionality under `Locale('ar')` |
| T-WID-008 | LTR under `Locale('en')` |
| T-WID-009 | textScale 1.6 no overflow exception |

---

## 8. Localization Tests

| ID | Case |
|----|------|
| T-L10N-001 | Offer/action/failure getters non-empty AR+EN |
| T-L10N-002 | Unsupported locale falls back to English |
| T-L10N-003 | Typed failure mapper Arabic-only under `ar` |
| T-L10N-004 | No hard-coded user-visible literals in new presentation files (manual checklist + limited regression guard if extended) |

---

## 9. Accessibility Tests

| ID | Case |
|----|------|
| T-A11Y-001 | Semantic labels present for status and primary actions |
| T-A11Y-002 | Status not color-only (text/chip asserted) |
| T-A11Y-003 | Progress/busy state has semantic cue |
| T-A11Y-004 | Large text safety (shared with T-WID-009) |

---

## 10. Integration Tests

**Mandatory for phase close** (roadmap):

| ID | Case |
|----|------|
| T-INT-001 | Offer → Accept → local assignment persisted → still present after app restart harness |
| T-INT-002 | Accept → availability becomes busy with assignment id |
| T-INT-003 | Offer → Reject → no assignment / no busy |
| T-INT-004 | Session loss mid-offer fails safe |
| T-INT-005 | Simulated 409 during accept |

---

## 11. Availability / Auth Integration Tests

| ID | Case |
|----|------|
| T-X-001 | Cannot accept when availability unavailable/offline/busy |
| T-X-002 | Accept success invokes busy binding path (ADR-025) |
| T-X-003 | Active assignment conflicts with free →available (existing policy) |
| T-X-004 | Eligibility default-deny not bypassed by Fake offers in guarded builds |

---

## 12. Controller Tests

| ID | Case |
|----|------|
| T-CTL-001 | State progression offered → accepting → accepted |
| T-CTL-002 | Failure banner + dismiss/retry where applicable |
| T-CTL-003 | Single-flight accept |
| T-CTL-004 | Logout/clear offer |

---

## 13. CI Requirements

Before merge of PHASE 2.5 implementation:

1. `flutter analyze` — **0 issues**  
2. `flutter test` — all suites green (including prior 312+ baseline; no deletes/skips)  
3. CI workflow jobs: Flutter Analyze, Flutter Test, Build Android, Build iOS — SUCCESS  
4. No `pubspec` / platform changes unless separately authorized  
5. No production Fake offer path without ADR-027 guards verified by tests  

---

## 14. Traceability (summary)

| ADR / concern | Primary tests |
|---------------|---------------|
| ADR-020 Offer vs Assignment | T-UC-001, T-REPO-003 |
| ADR-021 Lifecycle | T-DOM-*, T-CTL-* |
| ADR-022 Default-deny | T-DOM-005 |
| ADR-023 One offer | T-DOM-006/007 |
| ADR-024 Offline accept | T-OFF-*, T-UC-002 |
| ADR-025 Busy binding | T-X-002, T-INT-002 |
| ADR-026 Full-screen UI | T-WID-*, T-A11Y-* |
| ADR-027 Fake security | T-REPO-004, T-X-004 |
| ADR-028 Persistence | T-REPO-003, T-INT-001 |

---

## 15. Out of scope for this plan

- Real multi-driver Staging load tests (documented deferred)  
- PHASE 2.6 pickup/delivery step tests  
- FCM notification delivery tests (2.8)  

---

*Tests must not be authored until implementation increments are authorized.*
