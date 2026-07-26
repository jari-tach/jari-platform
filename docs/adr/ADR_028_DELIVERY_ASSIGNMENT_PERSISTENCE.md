# ADR-028: Delivery Assignment Persistence

> **ADR Number:** ADR-028  
> **Title:** Delivery Assignment Persistence Strategy  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [ADR-006](../27_ARCHITECTURAL_DECISIONS.md), [ADR-019](./ADR_019_AVAILABILITY_PERSISTENCE_RESTORATION.md), [ADR-020](./ADR_020_DELIVERY_OFFER_VS_ASSIGNMENT.md)

---

## Context

Roadmap requires storing an accepted delivery locally immediately (foundation for PHASE 2.7). Drift already has a scaffold `DeliveryOrders` table that does not match the PHASE 2.5 domain split (Offer vs Assignment) and may encourage wrong PII shapes.

---

## Decision

1. Persist **`DeliveryAssignment` after successful accept** as the PHASE 2.5 durability unit.  
2. Do **not** treat the existing `DeliveryOrders` scaffold as the final schema; implementation must introduce an explicit mapping/migration plan (new table or carefully migrated columns) before writing production data.  
3. Unaccepted offers are **not** required to be durably persisted; on restart, re-issue from authority/Fake rather than resurrecting a possibly expired offer.  
4. Persistence must exclude tokens/secrets; minimize personal data; never log full snapshots.  
5. Restore path: after auth, load active assignment → inform availability busy binding / 2.6 handoff.  
6. Prefer Drift (ADR-006) for assignment durability; SharedPreferences is insufficient for structured assignment snapshots.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Reuse `DeliveryOrders` as-is | Fast | Wrong model | Rejected |
| Persist every offer | Resume UX | Zombie expired offers | Rejected for MVP |
| Memory only until 2.7 | Simple | Fails restart AC | Rejected |

---

## Consequences

### Positive
- Restart-safe accepted work  
- Clear boundary vs ephemeral offers  

### Negative
- Schema work required  

### Implementation (schema)

- Drift `DriverDatabase.schemaVersion` **2** adds table `delivery_assignments`
  (`DeliveryAssignments`): unique `driver_id`, `assignment_id`, `payload_json`
  (full `DeliveryAssignmentModel` JSON), `updated_at`.
- Migration `from < 2`: `createTable(deliveryAssignments)` only — does not
  drop or rewrite existing tables (including the unused `DeliveryOrders`
  scaffold).
- Concrete port: `DriftDeliveryLocalDataSource`.

---

## Related Decisions

- [ADR-019](./ADR_019_AVAILABILITY_PERSISTENCE_RESTORATION.md)  
- [ADR-025](./ADR_025_DELIVERY_ACCEPT_BUSY_BINDING.md)  
