# ADR-024: Offline Accept Policy

> **ADR Number:** ADR-024  
> **Title:** Offline Accept Policy  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [ADR-017](./ADR_017_OFFLINE_AVAILABILITY_POLICY.md), [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](../PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md) §15

---

## Context

Accepting work offline risks claiming an offer that is expired or taken, and conflicts with Backend race handling. Roadmap already states accept is rejected without connectivity.

---

## Decision

1. **Accept while offline is always denied** (`DeliveryOfflineAcceptDenied`).  
2. Do **not** queue accept intents for later replay.  
3. Reject while offline may record a local non-assignment outcome / optional queue — must not create `DeliveryAssignment` or `busy`.  
4. UI disables Accept and shows safe offline messaging when connectivity is unavailable.

This parallels ADR-017’s refusal to queue dangerous “ready for work” claims.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Queue accept offline | UX continuity | Unsafe races / false ownership | Rejected |
| Optimistic local assignment | Instant UI | Lies about authority | Rejected |

---

## Consequences

### Positive
- Safer concurrency posture  
- Clear UI affordance  

### Negative
- Driver must regain connectivity to accept  

---

## Related Decisions

- [ADR-017](./ADR_017_OFFLINE_AVAILABILITY_POLICY.md)  
- [ADR-022](./ADR_022_DELIVERY_DEFAULT_DENY_TRANSITIONS.md)  
