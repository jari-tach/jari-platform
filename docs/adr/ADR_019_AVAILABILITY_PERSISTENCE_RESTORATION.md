# ADR-019: Availability Persistence and Restoration

> **ADR Number:** ADR-019  
> **Title:** Availability Persistence and Restoration  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-25  
> **Author:** PHASE 2.4 Architecture  
> **Last Updated:** 2026-07-25  
> **Related:** [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md), [ADR-017](./ADR_017_OFFLINE_AVAILABILITY_POLICY.md)

---

## Context

App restarts must not silently republish a driver as Backend-confirmed available. Persistence is needed for UX continuity and pending unavailable intents, without schema rush.

---

## Decision

### Persist (local, non-sovereign)

- last requested status  
- last confirmed status (if any)  
- `lastChangedAt` / `lastConfirmedAt`  
- `pendingSync`  
- optional `serverRevision`  
- optional reason code  
- optional `correlationId`  

### Do not treat as locally sovereign

- eligibility  
- busy from assignment truth  
- Backend revision supremacy  
- session validity  

### Storage

- **No Drift migration in PHASE 2.4 architecture approval.**  
- Prefer lightweight key-value (existing preferences pattern) for availability snapshot.  
- OfflineQueue may store unavailable intents without new schema if existing JSON payload fits.  
- Schema expansion requires a **separate implementation authorization**.

### Restoration

1. Load snapshot.  
2. Bind to current session `driverId` or discard.  
3. Re-evaluate eligibility + connectivity.  
4. If snapshot says available but confirmation stale/missing/offline → **effective unavailable/offline**.  
5. Never auto-call Backend “publish available” solely because of restore.

### Logout / account switch / corruption

- Clear snapshot.  
- Corruption → delete + safe default unavailable/offline.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Always Drift table now | Strong typing | Unneeded migration risk | Deferred |
| No persistence | Safest restart | Poor UX | Rejected |
| Restore as confirmed available | Seamless | Unsafe | Rejected |

---

## Consequences

### Positive
- Safe cold start  
- Clear implementation boundary on migrations  

### Negative
- Drivers may need to tap available again after restart while offline/stale  

### Security / offline / testing / Backend
- Security: reduces stale publish  
- Offline: aligns with ADR-017  
- Testing: restore scenarios mandatory  
- Backend: revision field ready  

---

## Related Decisions

- [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md)  
