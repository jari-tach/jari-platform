# ADR-018: Busy State Ownership

> **ADR Number:** ADR-018  
> **Title:** Busy State Ownership  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-25  
> **Author:** PHASE 2.4 Architecture  
> **Last Updated:** 2026-07-25  
> **Related:** [ADR-015](./ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md), BR-AVAIL-004, BR-AVAIL-005, BR-AVAIL-018

---

## Context

If drivers can mark themselves busy, the app conflicts with assignment engines, hides capacity incorrectly, and invites fraud/races. PHASE 2.4 must not implement assignment, but must reserve busy correctly.

---

## Decision

- **`busy` is system/server-owned only.**  
- UI must not offer a busy toggle.  
- User requests to `busy` → `ManualBusyTransitionDenied`.  
- In PHASE 2.4, production path to busy may be **unreachable** until assignment events exist; tests simulate system/server transitions.  
- `activeAssignmentId` may exist as a nullable reference field but **no assignment workflow** is implemented (BR-AVAIL-018).  
- Server/system busy overrides local available (ADR-016).

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| User busy toggle | Simple break mode | Conflicts with dispatch | Rejected |
| Derive busy only in 2.5 with no enum now | Less surface | Harder forward compat | Rejected |

---

## Consequences

### Positive
- Clear ownership; prevents PHASE 2.5 rework  

### Negative
- Busy UI still needed for future; show read-only when forced  

### Security / offline / testing / Backend
- Security: prevents self-declared capacity hiding  
- Offline: busy retained under connectivity loss  
- Testing: manual busy denial required  
- Backend: assignment service owns busy transitions  

---

## Related Decisions

- [ADR-015](./ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md)  
