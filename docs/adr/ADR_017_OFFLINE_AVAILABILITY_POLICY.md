# ADR-017: Offline Availability Policy

> **ADR Number:** ADR-017  
> **Title:** Offline Availability Policy  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-25  
> **Author:** PHASE 2.4 Architecture  
> **Last Updated:** 2026-07-25  
> **Related:** [PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md](../PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md), [ADR-015](./ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md), NetworkMonitor / OfflineQueue (core)

---

## Context

Earlier PHASE 2 roadmap text suggested queuing availability toggles while offline then syncing. Without a secure Backend reconciliation protocol, queuing **→ available** can replay a dangerous “I’m ready for work” claim after long offline periods or on another device.

---

## Decision

1. **Do not queue offline transitions to `available`.** Require connectivity for confirmed available.  
2. **May queue / retain local intent for `unavailable`** (`pendingSync=true`) and reconcile on reconnect.  
3. Losing connectivity while **available** → **effective `offline`** (not confirmed available).  
4. Losing connectivity while **busy** → keep busy presentation; block user path to available.  
5. Losing connectivity while **unavailable** → show offline/unavailable safely.  
6. **Logout offline** clears local availability; server notify is best-effort later.  
7. Confirmation freshness **assumed TTL = 5 minutes** until product revises.  
8. Deduplicate identical pending intents; idempotent same-state requests.  
9. First use of OfflineQueue in 2.4 is **optional and limited** to unavailable (or generic ops) — not available activation.

This **supersedes** the historical acceptance criterion “queue online/offline toggle while offline then auto-sync” **for the available direction**.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Queue both directions | Matches old AC | Unsafe available replay | Rejected for →available |
| Never any offline intent | Simplest | Poor UX for go-unavailable | Rejected |
| Optimistic available offline | Instant UX | False dispatch eligibility | Rejected |

---

## Consequences

### Positive
- Conservative safety default  
- Clear UI: cannot look “confirmed available” offline  

### Negative
- Driver must be online to go available  
- Roadmap AC wording needs alignment note  

### Security / offline / testing / Backend
- Security: reduces forged offline available claims  
- Offline: explicit matrix  
- Testing: connectivity loss cases mandatory  
- Backend: future protocol could revisit queueing via new ADR  

---

## Related Decisions

- [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md)  
- [ADR-019](./ADR_019_AVAILABILITY_PERSISTENCE_RESTORATION.md)  
