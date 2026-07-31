# STEP 5 — Backend Domain Scope

> **Status:** STEP 5A Documentation Handoff
> **Date:** 2026-07-31
> **Baseline:** `8bb129a83e489d348de7469a1b32243c62245199`
> **ADR:** [ADR-030](../adr/ADR_030_backend_stack_and_repository_strategy.md)
> **Backend repo:** `jari-tach/saeq-backend` (not started in this PR)
> **Contracts repo:** `jari-tach/saeq-contracts` (not started in this PR)
> **STEP 6 Realtime:** LOCKED

---

## Purpose

Define the Stage D / STEP 5 Backend Modular Monolith domain scope for Driver
operations. This document is architecture handoff only. It does not implement
NestJS, Prisma, Docker, or Flutter REST adapters.

---

## In scope for STEP 5 Backend

| Domain module | Driver-facing responsibility |
|---------------|------------------------------|
| Identity / Access | OTP request/verify, session tokens, refresh, logout, driver role |
| Driver Profile | Profile read/update, compliance status |
| Driver Availability | Authoritative available / unavailable / busy |
| Delivery Offers | List/detail, expiry, accept, reject |
| Delivery Assignments | Active assignment lifecycle and transitions |
| Pickup | Manual pickup confirmation |
| Arrival | Automatic arrival by location (Backend records authoritative result) |
| Delivery Confirmation | Manual delivery confirmation after automatic arrival |
| Cancellation / Issues | Cancel and issue reporting with typed errors |
| Batch Assignments | Multi-stop batch assignment and current-stop contact rules |
| Audit | Request tracing, transition audit, idempotency records |

Tenant isolation, Business Scope, and Branch Scope remain Backend-owned from
day one (ADR-014).

---

## Explicitly out of scope for STEP 5

- WebSocket / SSE / Push / Redis Realtime (STEP 6)
- Merchant Mobile MVP
- Customer Mobile MVP
- Web Admin operational console
- Microservices split / Kafka
- Embedding Backend inside `jari-platform`
- Flutter REST adapters before contracts + Backend gates
- Background Always location / Map SDK (STEP 4B deferred)

---

## Authoritative vs local intent

Backend is the source of truth for:

- Session validity
- Availability eligibility and busy ownership
- Offer expiry / taken-by-other
- Assignment creation and transition legality
- Customer-contact disclosure
- Delivery completion / cancellation outcomes

Driver local persistence (ADR-016 / ADR-028) may restore UI continuity. It must
never grant server-side eligibility or invent Backend authority.

---

## Delivery lifecycle mapping (mandatory)

Future Backend states must align with the Driver journey:

```text
offered
→ accepted
→ pickupAwaitingManualConfirmation
→ pickupConfirmedManually
→ enRouteToCustomer
→ arrivedAutomaticallyByLocation
→ deliveryAwaitingManualConfirmation
→ deliveredConfirmedManually
```

### Binding rules

| Rule | Owner |
|------|-------|
| Pickup confirmation is manual | Driver action + Backend validation |
| Arrival is automatic by location | Device geofence intent + Backend authoritative record |
| No manual arrival button | Product / Figma / ADR-029 |
| Delivery confirmation is manual | Driver action after automatic arrival |
| Delivery remains locked until automatic arrival | Backend transition policy |

---

## Customer contact protection

| Moment | Visibility |
|--------|------------|
| Before pickup confirmation | Customer data hidden |
| After pickup confirmation | Current customer only, for the assigned driver |
| Next customer | Always hidden until that stop becomes current |
| After delivery or cancel | Contact closed |
| Another driver | No access |

Backend decides disclosure. Flutter must not invent contact visibility that
Backend has not authorized.

---

## Stack reminder (ADR-030)

- Runtime: Node.js LTS
- Language: TypeScript
- Framework: NestJS
- Database: PostgreSQL
- ORM: Prisma
- API: REST + OpenAPI 3.1
- Tests: Jest
- Local: Docker Compose

---

## Next documents

- [driver_api_contract_handoff.md](./driver_api_contract_handoff.md)
- [driver_backend_endpoint_matrix.md](./driver_backend_endpoint_matrix.md)
- [driver_remote_repository_integration_plan.md](./driver_remote_repository_integration_plan.md)
- [step5_execution_sequence.md](./step5_execution_sequence.md)
