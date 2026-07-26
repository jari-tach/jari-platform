# ADR-020: DeliveryOffer vs DeliveryAssignment

> **ADR Number:** ADR-020  
> **Title:** DeliveryOffer vs DeliveryAssignment  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md](../PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md), [ADR-018](./ADR_018_BUSY_STATE_OWNERSHIP.md)

---

## Context

The codebase and docs mix terms: orders placeholder, Drift `DeliveryOrders`, roadmap `DeliveryOrder` / offers, and availability `activeAssignmentId`. Without a crisp split, PHASE 2.5 risks treating an unaccepted invitation as owned work.

---

## Decision

1. **`DeliveryOffer`** — time-bounded invitation. Never implies assignment or `busy`.  
2. **`DeliveryAssignment`** — authoritative driver↔delivery binding created only after successful accept.  
3. Domain and APIs use these names; UI may say “طلب” / “request” in copy without collapsing the model.  
4. Existing Drift `DeliveryOrders` scaffold is **not** the domain model; persistence redesign is ADR-028.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Single `DeliveryOrder` for all stages | Fewer types | Blurs ownership | Rejected |
| Reuse Drift table as domain | Fast | Wrong schema / PII shape | Rejected |

---

## Consequences

### Positive
- Clear busy/assignment ownership handoff  
- Safer expiry of offers without corrupting assignments  

### Negative
- More types and mappers  

---

## Related Decisions

- [ADR-021](./ADR_021_DELIVERY_REQUEST_LIFECYCLE.md)  
- [ADR-025](./ADR_025_DELIVERY_ACCEPT_BUSY_BINDING.md)  
- [ADR-028](./ADR_028_DELIVERY_ASSIGNMENT_PERSISTENCE.md)  
