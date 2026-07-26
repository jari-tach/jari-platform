# ADR-025: Delivery Accept Busy Binding

> **ADR Number:** ADR-025  
> **Title:** Delivery Accept Busy Binding  
> **Status:** ✅ Accepted — **Implemented (PHASE 2.5)**  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [ADR-018](./ADR_018_BUSY_STATE_OWNERSHIP.md), [ADR-015](./ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md), BR-AVAIL-004/005/006

---

## Context

ADR-018 established that `busy` is system/server-owned and that PHASE 2.4 would not implement assignment. PHASE 2.5 introduces the first legitimate producer of assignment-linked busy.

---

## Decision

1. ADR-018 remains in force: **no user busy toggle**.  
2. Successful **accept** must apply an **authoritative/system availability update** to `busy` with non-null `activeAssignmentId`.  
3. Use existing availability apply/reconcile pathways — do not invent a parallel availability SM.  
4. Reject/expire/taken/cancel must **not** set busy.  
5. While assignment active, availability policy continues to deny free user transitions that conflict with `hasActiveAssignment`.

### Implementation (PHASE 2.5)

- Application coordinator: `AcceptDeliveryOfferAndBindBusy`  
  (`lib/features/delivery/application/`).  
- **Operation order:** `AcceptDeliveryOffer` (accept + local persist) →  
  `ApplyAuthoritativeAvailability` (`busy` + `activeAssignmentId`).  
- Delivery and Availability domains stay independent; repositories do not  
  cross-depend. Orchestration is application-layer only.  
- Presentation uses the coordinator via `DeliveryController` +  
  `AppServiceRegistry.acceptDeliveryOfferAndBindBusy`.  

### Compensation on busy-bind failure

ADR-025 does not define assignment rollback. **Implemented rule:** if accept  
and assignment persistence succeed but busy binding fails:

1. Keep the accepted assignment locally (no clear/delete).  
2. Surface typed `DeliveryAvailabilityBindFailure` (localized in UI).  
3. Do not claim capacity/`busy` incorrectly.

Already-busy with the **same** `activeAssignmentId` is treated as success  
(idempotent; no duplicate authoritative write).

Restart: after restoring a persisted assignment, reconcile busy via  
`bindBusyForAssignment` so availability reflects the active delivery.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Keep available after accept | Simpler demo | Breaks capacity model | Rejected |
| User sets busy manually after accept | Familiar | Violates ADR-018 | Rejected |

---

## Consequences

### Positive
- Completes ADR-018’s reserved path  
- Single capacity model across features  

### Negative
- Cross-feature coupling tests required  

---

## Related Decisions

- [ADR-018](./ADR_018_BUSY_STATE_OWNERSHIP.md)  
- [ADR-020](./ADR_020_DELIVERY_OFFER_VS_ASSIGNMENT.md)  
