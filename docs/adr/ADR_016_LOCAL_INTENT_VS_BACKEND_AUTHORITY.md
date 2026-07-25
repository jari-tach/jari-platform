# ADR-016: Local Intent vs Backend Authority

> **ADR Number:** ADR-016  
> **Title:** Local Intent vs Backend Authority for Driver Availability  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-25  
> **Author:** PHASE 2.4 Architecture  
> **Last Updated:** 2026-07-25  
> **Related:** [PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md](../PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md), [ADR-015](./ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md), [ADR-019](./ADR_019_AVAILABILITY_PERSISTENCE_RESTORATION.md), BR-DRIVER-005, BR-SEC-*

---

## Context

Drivers will cache operational state for UX and offline resilience. Treating local cache as assignment eligibility would create false availability and safety/compliance risk. Backend will eventually be the source of truth.

---

## Decision

### Authority stack (highest wins)

1. **Backend authoritative availability** (when present, by revision)  
2. **Assignment-derived busy** (system/server events; future PHASE 2.5+)  
3. **Connectivity-safe effective status** (policy may downgrade confirmed available → offline)  
4. **Local persisted intent** (non-sovereign)  
5. **Ephemeral UI flags** (loading/pending)

### Rules

- Local state **must never** grant server-side eligibility.  
- Restored local `available` without fresh confirmation → **not** shown as confirmed available.  
- Server `busy` or newer revision overrides stale local `available`.  
- Session expiry / suspension force safe non-available effective state.  
- Until Backend exists: non-release trial may use a **local confirmer stub** that still respects eligibility + online rules; release builds never invent Fake Auth identity (PHASE 2.3).

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Local is source of truth | Simple offline | Unsafe for dispatch | Rejected |
| UI-only toggle | Fast | No domain policy | Rejected |
| Always require Backend | Strong truth | Blocks MVP without API | Deferred hybrid with stub |

---

## Consequences

### Positive
- Clear conflict resolution  
- Aligns with BR-DRIVER-005 / BR-SEC client limitation  

### Negative
- UX must distinguish confirmed vs pending/stale  

### Security / offline / testing / Backend
- Security: tamper-resistant expectations documented  
- Offline: local intent limited (ADR-017)  
- Testing: conflict matrix required  
- Backend: revision field reserved  

---

## Related Decisions

- [ADR-017](./ADR_017_OFFLINE_AVAILABILITY_POLICY.md)  
- [ADR-019](./ADR_019_AVAILABILITY_PERSISTENCE_RESTORATION.md)  
