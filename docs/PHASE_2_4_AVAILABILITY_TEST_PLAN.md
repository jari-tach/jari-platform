# PHASE 2.4 — Availability Test Plan

> **Status:** Spec **Accepted** — Tests **Not Implemented**  
> **Related:** [PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md](./PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md), [31_TRACEABILITY_MATRIX.md](./31_TRACEABILITY_MATRIX.md)

---

## 1. Domain / policy tests

| Test ID | Scenario | Expect | Rules |
|---------|----------|--------|-------|
| T-DOM-001 | Eligible unavailable→available (online) | Allowed | BR-AVAIL-001..003,010 |
| T-DOM-002 | Unauthenticated→available | Denied Unauthenticated | BR-AVAIL-001 |
| T-DOM-003 | Missing profile→available | Denied ProfileMissing | BR-AVAIL-002 |
| T-DOM-004 | Suspended→available | Denied Suspended | BR-AVAIL-003,017 |
| T-DOM-005 | Inactive employment→available | Denied Ineligible | BR-AVAIL-003 |
| T-DOM-006 | User→busy | Denied ManualBusy | BR-AVAIL-004 |
| T-DOM-007 | System available→busy | Allowed | BR-AVAIL-005 |
| T-DOM-008 | Same-state request | Idempotent success | BR-AVAIL-010 |
| T-DOM-009 | Invalid transition offline→available | Denied | BR-AVAIL-009,011 |
| T-DOM-010 | Stale local available not authoritative | Effective not confirmed | BR-AVAIL-007,008 |
| T-DOM-011 | Release fake identity path | Security denied | BR-AVAIL-013 |
| T-DOM-012 | Server busy overrides local available | busy wins | BR-AVAIL-015 |
| T-DOM-013 | Sovereign timestamp/id not user-editable | Structural | BR-AVAIL-014 |

**Acceptance:** All policy decisions assert `allowed` + exact `reasonCodes` + policyVersion.

---

## 2. Repository contract tests

| Test ID | Scenario |
|---------|----------|
| T-REPO-001 | restoreLocal loads snapshot without publishing confirmed available |
| T-REPO-002 | applyAuthoritative overrides local |
| T-REPO-003 | offline persist unavailable intent pendingSync |
| T-REPO-004 | offline request available denied / not queued |
| T-REPO-005 | sync conflict → server revision wins |
| T-REPO-006 | corrupted storage → safe fallback |
| T-REPO-007 | clearOnLogout removes snapshot |
| T-REPO-008 | account/session mismatch discards snapshot |
| T-REPO-009 | duplicate request deduplicated |

---

## 3. Controller / state tests

| Test ID | Scenario |
|---------|----------|
| T-CTL-001 | Initial loading |
| T-CTL-002 | Restored stale → UI not confirmed available |
| T-CTL-003 | Toggle available success |
| T-CTL-004 | Toggle unavailable success |
| T-CTL-005 | Transition lock / ignore re-entry |
| T-CTL-006 | Denial rendering with codes |
| T-CTL-007 | Retry recoverable error |
| T-CTL-008 | Connectivity loss downgrades available |
| T-CTL-009 | Connectivity restore reconcile |
| T-CTL-010 | Busy read-only rendering |
| T-CTL-011 | Server override updates stream |

---

## 4. Widget tests

| Test ID | Scenario |
|---------|----------|
| T-WID-001 | Arabic labels present |
| T-WID-002 | RTL layout |
| T-WID-003 | Status semantics / a11y |
| T-WID-004 | Control disabled while loading |
| T-WID-005 | Repeated tap protection |
| T-WID-006 | Offline banner |
| T-WID-007 | Pending sync indication ≠ confirmed |
| T-WID-008 | No busy toggle control |
| T-WID-009 | Color-independent status text |

---

## 5. Security tests

| Test ID | Scenario |
|---------|----------|
| T-SEC-001 | Fake availability blocked under release policy evaluation |
| T-SEC-002 | Tampered local available does not pass eligibility alone |
| T-SEC-003 | driverId cannot be replaced via command |
| T-SEC-004 | No bool.fromEnvironment availability bypass in sources |
| T-SEC-005 | No skipped security tests introduced |

---

## 6. Regression

| Test ID | Scenario |
|---------|----------|
| T-REG-001 | Existing auth suite passes |
| T-REG-002 | Existing profile suite passes |
| T-REG-003 | Logout still clears session |
| T-REG-004 | Profile sovereign fields unchanged |

---

## Counts

| Category | Count |
|----------|------:|
| Domain/policy | 13 |
| Repository | 9 |
| Controller | 11 |
| Widget | 9 |
| Security | 5 |
| Regression | 4 |
| **Total specified** | **51** |
