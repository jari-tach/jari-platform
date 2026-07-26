# ADR-021: Delivery Request Lifecycle

> **ADR Number:** ADR-021  
> **Title:** Delivery Request Lifecycle (Offer Decision Window)  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md](../PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md), [ADR-022](./ADR_022_DELIVERY_DEFAULT_DENY_TRANSITIONS.md)

---

## Context

PHASE 2.5 must define when a driver may decide on work and when the decision window ends, without implementing the full active-delivery step machine (PHASE 2.6).

---

## Decision

PHASE 2.5 owns the **offer decision lifecycle** only:

`none → offered → (accepting|rejecting) → terminal`

Terminal outcomes:

- `accepted` (produces `DeliveryAssignment`)  
- `rejected`  
- `expired`  
- `taken_by_other`  
- `cancelled`  

PHASE 2.6 owns post-accept operational steps (`picked_up`, `delivered`, etc.).

Server (or Fake under ADR-027) is authority for expiry and taken-by-other. Client timers are presentation aids only.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Merge 2.5+2.6 in one phase | Faster demo | Oversized risk | Rejected |
| Client-authoritative expiry | Simple | Clock skew / fraud | Rejected |

---

## Consequences

### Positive
- Bounded scope; testable SM  
- Clean handoff to 2.6  

### Negative
- Two phases share assignment entity  

---

## Related Decisions

- [ADR-020](./ADR_020_DELIVERY_OFFER_VS_ASSIGNMENT.md)  
- [ADR-022](./ADR_022_DELIVERY_DEFAULT_DENY_TRANSITIONS.md)  
