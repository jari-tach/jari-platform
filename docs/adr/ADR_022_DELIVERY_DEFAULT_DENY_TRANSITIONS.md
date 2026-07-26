# ADR-022: Delivery Default-Deny Transitions

> **ADR Number:** ADR-022  
> **Title:** Delivery Default-Deny Transitions  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [ADR-015](./ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md), [ADR-021](./ADR_021_DELIVERY_REQUEST_LIFECYCLE.md)

---

## Context

Availability already uses default-deny transition policies. Delivery offers involve money, races, and safety; unknown transitions must not silently succeed.

---

## Decision

1. `DeliveryOfferTransitionPolicy` **denies by default**.  
2. Only an explicit allow-list of transitions succeeds.  
3. Invalid transitions return typed `DeliveryFailure` (never raw exceptions to UI).  
4. Controllers must not bypass the policy.  
5. Same spirit as availability: prefer fail-closed over optimistic corruption.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Allow-by-default with denylist | Flexible | Easy to miss holes | Rejected |
| UI-only guards | Fast | Race / replay unsafe | Rejected |

---

## Consequences

### Positive
- Predictable, testable matrix  
- Aligns with platform security posture  

### Negative
- More unit tests for each edge  

---

## Related Decisions

- [ADR-021](./ADR_021_DELIVERY_REQUEST_LIFECYCLE.md)  
- [ADR-023](./ADR_023_ONE_ACTIVE_OFFER_POLICY.md)  
