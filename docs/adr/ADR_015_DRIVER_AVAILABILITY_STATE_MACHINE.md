# ADR-015: Driver Availability State Machine

> **ADR Number:** ADR-015  
> **Title:** Driver Availability State Machine  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-25  
> **Author:** PHASE 2.4 Architecture  
> **Last Updated:** 2026-07-25  
> **Related:** [PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md](../PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md), [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md), [ADR-018](./ADR_018_BUSY_STATE_OWNERSHIP.md), [41_OFFICIAL_BUSINESS_RULES.md](../41_OFFICIAL_BUSINESS_RULES.md)

---

## Context

PHASE 2.4 requires an explicit, testable operational state machine for SAEQ Driver so the app can represent readiness without implementing order assignment. Informal toggles risk illegal transitions (especially user-selected busy) and unsafe “available” presentation while offline.

---

## Decision

Adopt four statuses: **`offline` | `unavailable` | `available` | `busy`**.

Transitions are evaluated by a pure **`AvailabilityTransitionPolicy`** (default deny). Actors: `user`, `system`, `server`, `connectivity`.

### Transition table (normative)

| Current | Requested | Actor | Preconditions | Result | Failure | Local persist | Sync |
|---------|-----------|-------|---------------|--------|---------|---------------|------|
| any | same | any | — | Idempotent success | — | none | none |
| unavailable | available | user | Auth+profile+eligible+online | available (confirmed path) | eligibility/offline codes | update snapshot | remote request when Backend exists |
| available | unavailable | user | Auth | unavailable | unauthenticated | update | remote when exists; may queue intent offline |
| available | busy | system/server | assignment/system event | busy | ManualBusy if user | update | server-owned |
| busy | available | system/server | assignment allows | available | ActiveAssignmentConflict / Invalid | update | server |
| busy | unavailable | system/server | safety/assignment end | unavailable | Invalid if user | update | server |
| unavailable/available/busy | offline | connectivity | link lost | offline (busy keeps busy semantics for assignment view — see notes) | — | effective flag | none |
| offline | unavailable | connectivity | link restored | unavailable | — | update effective | reconcile |
| offline | available | user | — | **Denied** | AvailabilityOffline / Invalid | none | none |
| * | busy | user | — | **Denied** | ManualBusyTransitionDenied | none | none |
| * | unavailable | system | logout/suspend/security | unavailable | — | clear/force | best-effort |

**Busy + connectivity loss:** retain **busy** as assignment-derived presentation; do not auto-convert to available; connectivity banner still shown.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Binary online/offline only | Simple | Cannot model busy | Rejected |
| User-selectable busy | Flexible UX | Unsafe; races with assignment | Rejected |
| Allow offline→available queued | Matches older roadmap AC | Unsafe without Backend protocol | Rejected (ADR-017) |

---

## Consequences

### Positive
- Explicit forbidden transitions  
- Testable pure policy  
- Aligns with busy ownership (ADR-018)

### Negative
- More UI states than a simple switch  
- Historical roadmap AC for offline available-queue superseded  

### Security / offline / testing / Backend
- Security: no user busy; release fake identity still blocked elsewhere  
- Offline: conservative (ADR-017)  
- Testing: table-driven transition tests  
- Backend: maps to future availability + assignment events  

---

## Related Decisions

- [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md)  
- [ADR-017](./ADR_017_OFFLINE_AVAILABILITY_POLICY.md)  
- [ADR-018](./ADR_018_BUSY_STATE_OWNERSHIP.md)  
