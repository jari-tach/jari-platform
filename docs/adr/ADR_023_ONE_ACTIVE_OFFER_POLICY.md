# ADR-023: One Active Offer Policy

> **ADR Number:** ADR-023  
> **Title:** One Active Offer Policy  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](../PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md) § MVP, [ADR-021](./ADR_021_DELIVERY_REQUEST_LIFECYCLE.md)

---

## Context

MVP roadmap requires one active delivery at a time. Concurrent incoming offers would complicate UX, races, and availability binding.

---

## Decision

1. A driver session may have **at most one** non-terminal `DeliveryOffer` (`offered` / `accepting` / `rejecting`).  
2. Additional offer events for a different `offerId` while one is active are **ignored or deferred** by policy (implementation: drop or hold until clear — default **ignore** with log code).  
3. Duplicate events for the **same** `offerId` are idempotent no-ops.  
4. An active `DeliveryAssignment` implies no new actionable offer until cleared by a later phase’s completion rules.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Offer queue / multi-offer UI | More choice | Out of MVP; complex | Deferred |
| Replace active offer with newer | Dispatch flexibility | Confusing UX / races | Rejected for MVP |

---

## Consequences

### Positive
- Matches MVP; simpler tests and UI  

### Negative
- May drop dispatch opportunities while deciding  

---

## Related Decisions

- [ADR-020](./ADR_020_DELIVERY_OFFER_VS_ASSIGNMENT.md)  
- [ADR-026](./ADR_026_FULL_SCREEN_OFFER_UI.md)  
