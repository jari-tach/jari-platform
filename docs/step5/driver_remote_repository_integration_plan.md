# Driver Remote Repository Integration Plan

> **Status:** Architecture plan only — **no Flutter REST code in STEP 5A**
> **Date:** 2026-07-31
> **Gate:** STEP 5C (owner authorization after contracts + Backend tests)
> **Related:** [ADR-030](../adr/ADR_030_backend_stack_and_repository_strategy.md), [driver_api_contract_handoff.md](./driver_api_contract_handoff.md)

---

## Target layering (binding)

```text
Presentation
→ Controller / Notifier
→ Use Case
→ Repository Interface
→ Fake / Local / Remote Adapter
```

### Rules

- UI must not call HTTP directly.
- Controller must not call HTTP directly.
- Widgets must not know endpoint URLs.
- Remote adapters must implement existing repository interfaces.
- Fake and Local implementations must remain available for tests.
- Production must never run Fake remotes (ADR-027 and existing Fake policies).

---

## Existing seams in Driver (do not redesign)

| Port / repository | Current live adapter | Future remote adapter (STEP 5C) |
|-------------------|----------------------|---------------------------------|
| `AuthenticationRepository` | `FakeAuthenticationRepository` | `RemoteAuthenticationRepository` (or equivalent) |
| `DriverProfileRepository` | `FakeDriverProfileRepository` | Remote profile adapter |
| `DeliveryRemoteDataSource` | `FakeDeliveryRemoteDataSource` | HTTP remote DS behind `RemoteDeliveryOfferRepository` |
| `DeliveryAssignmentRepository` | Local Drift (`LocalDeliveryAssignmentRepository`) | Remains local for durability; sync with Backend active assignment |
| `DriverAvailabilityRepository` | Local SharedPreferences | Extend with Backend authoritative apply/reconcile |
| History / Earnings / Notifications / Support repositories | Fake providers | Remote adapters when contracts include those domains |

Networking scaffolding (`ApiClient` / Dio) already exists but is unused by
feature remotes. STEP 5C will wire a real token provider from session — **not
now**.

---

## Forbidden in STEP 5A (and until STEP 5C opens)

- REST Adapters
- HTTP Calls from feature code
- Remote Repositories wired into production DI
- Production Base URLs
- `useMockBackend` switching logic changes
- Backend authentication integration
- Secrets / API keys in Git
- WebSocket / SSE / Push clients

---

## STEP 5C entry criteria

Flutter remote integration starts only after:

1. Canonical contracts merged in `jari-tach/saeq-contracts`
2. Backend implemented in `jari-tach/saeq-backend`
3. Contract tests passing
4. Backend integration tests passing
5. Explicit owner authorization for STEP 5C

Recommended order once authorized:

1. Auth remote (OTP / refresh / logout) behind `AuthenticationRepository`
2. Profile + compliance remote
3. Availability authoritative sync
4. Delivery remote DS (offers accept/reject + active assignment fetch)
5. Pickup / arrive / confirm-delivery / cancel / issue commands
6. Customer-contact endpoint respecting Backend disclosure
7. Batch endpoints if contracts include them in the same increment

Each increment keeps Fake overrides for tests and fails closed in production.

---

## Testing expectations for STEP 5C (preview)

- Unit tests for remote DTO ↔ domain mapping
- Repository tests with HTTP mock (no live network in CI unit jobs)
- Existing Fake production-gate tests remain green
- Widget/controller tests continue to override Fake adapters
- No reduction of test count without documented reason

---

## Decision summary

STEP 5A documents the integration architecture only.
STEP 5C will implement Remote adapters after contracts and Backend gates pass.
STEP 6 Realtime remains locked.
