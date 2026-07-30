# STEP 2D — Backend / Domain Handoff

> **Status:** DRAFT CONTRACTS ONLY — Frontend review complete for STEP 2D closeout
> **Official source package:** `STEP2D_Backend_Domain_Handoff.md` (ChatGPT Domain/Contract owner)
> **Supporting draft package:** `saeq-backend-contracts` `0.1.0-draft`
> **Flutter baseline (STEP 2D merge):** `e2b6ec4bf15541c02de86291176545c567da60e1`
> **Backend implementation:** **NOT STARTED** — locked until STEP 5
> **Production connection:** **NOT CONNECTED**
> **Production OpenAPI:** NOT APPROVED
> **Realtime transport:** NOT SELECTED
> **Flutter files modified by this handoff:** **0** (documentation only)

This document is the official Frontend integration of the ChatGPT
`STEP2D_Backend_Domain_Handoff` package into SAEQ Driver docs. It does **not**
start a Backend server, does **not** approve production OpenAPI, and does
**not** invent live HTTP endpoints for the Flutter app.

Layering remains mandatory:

```text
Presentation
→ Controller / Notifier
→ Use Case
→ Repository Interface
→ Fake / Local / Remote Adapter
```

UI must never call HTTP, database, or WebSocket directly.

---

## 1. Domain inventory

ChatGPT package status: **COMPLETE — DRAFT FOR FRONTEND REVIEW**.

| Domain | Current client source | Future Backend authority | Target step | Production |
|--------|----------------------|--------------------------|-------------|------------|
| Authentication | Fake + secure local session | Identity & Access | STEP 5 | NOT CONNECTED |
| Driver Profile | Fake / Drift local projection | Driver Profile service | STEP 5 | NOT CONNECTED |
| Availability | Local SharedPreferences projection | Availability aggregate | STEP 5/6 | NOT CONNECTED |
| Offers | Fake remote (`FakeDeliveryRemoteDataSource`) | Offer aggregate | STEP 3 → STEP 5/6 | NOT CONNECTED |
| Single Delivery | Local Drift assignment + Fake accept authority | Delivery aggregate | STEP 3 → STEP 5/6 | NOT CONNECTED |
| Batch Delivery | In-memory Fake batch | Batch aggregate | STEP 5/6 | NOT CONNECTED |
| Customer Contact | Synthetic UI / Fake batch projection | Protected contact projection | STEP 5 | NOT CONNECTED |
| Location / Map | Fake location + CustomPaint map | Device adapter + optional arrival proof | STEP 4/5 | NOT CONNECTED |
| Vehicle | Fake UI metadata | Compliance / vehicle service | STEP 7 | NOT CONNECTED |
| Documents | Fake UI metadata | KYC / document storage | STEP 7 | NOT CONNECTED |
| History | Fake in-memory | Driver history service | STEP 8 | NOT CONNECTED |
| Earnings | Fake in-memory | Driver ledger service | STEP 8 | NOT CONNECTED |
| Notifications | Fake in-memory | Push / notification service | STEP 6/8 | NOT CONNECTED |
| Support | Unavailable Fake config | Support channels | STEP 8 | NOT CONNECTED |
| Safety | Static localized tips | Governed safety content | STEP 8 | NOT CONNECTED |

Draft schema artifacts (contracts package, not production APIs):

| Domain | Draft schema ID / path |
|--------|------------------------|
| Auth | `contracts/auth/request-otp.schema.json`, `verify-otp.schema.json` |
| Availability | `contracts/availability/driver-availability.schema.json` |
| Offers | `contracts/offers/delivery-offer.schema.json` |
| Delivery | `contracts/delivery/delivery-state.schema.json` |
| Batch | `contracts/batch/batch-assignment.schema.json` |
| Customer contact | `urn:saeq:customer-contact:projection:0.1.0` |
| Profile | `contracts/profile/driver-profile.schema.json` |
| Events | `contracts/events/event-envelope.schema.json` |
| Errors | `contracts/common/error.schema.json` |

---

## 2. Controller → Repository → Future API mapping

ChatGPT package status: **COMPLETE**.

| Domain | Controller / Provider | Repository / service interface | Current adapter | Future remote (STEP 5+) |
|--------|----------------------|--------------------------------|-----------------|-------------------------|
| Auth | `authControllerProvider` | `AuthenticationRepository` | `FakeAuthenticationRepository` + `AuthSessionStorage` | Identity OTP / session API — **DRAFT only** |
| Profile | `profileControllerProvider` | `DriverProfileRepository` | `FakeDriverProfileRepository` (+ Drift cache) | Profile REST — **DRAFT only** |
| Availability | `availabilityControllerProvider` | `DriverAvailabilityRepository` | `LocalDriverAvailabilityRepository` | Availability aggregate REST/realtime — **DRAFT only** |
| Offers | `deliveryControllerProvider` | `DeliveryOfferRepository` / `DeliveryRemoteDataSource` | `RemoteDeliveryOfferRepository` → **Fake** remote | Offer aggregate REST/stream — **DRAFT only** |
| Single delivery | `deliveryControllerProvider` | `DeliveryAssignmentRepository` | `LocalDeliveryAssignmentRepository` (Drift) | Delivery aggregate REST — **DRAFT only** |
| Batch | `batchControllerProvider` | `BatchService` | `FakeBatchService` | Batch aggregate REST/realtime — **DRAFT only** |
| Customer contact | `batchControllerProvider` | No separate repository (projection on batch state) | Synthetic localization fixtures | Protected contact projection API — **DRAFT only** |
| Location | `locationControllerProvider` | `LocationService` | `FakeLocationService` | Device GPS / proof — STEP 4/5 |
| Map | `mapPreviewControllerProvider` | `MapPreviewService` | `FakeMapPreviewService` | Map SDK / nav — STEP 4 |
| Vehicle | `vehicleControllerProvider` | `VehicleRepository` | `FakeVehicleRepository` | Compliance API — STEP 7 |
| Documents | documents controllers | `DocumentsRepository` | `FakeDocumentsRepository` | KYC upload API — STEP 7 |
| History | `historyControllerProvider` | `DeliveryHistoryRepository` | `FakeDeliveryHistoryRepository` | History API — STEP 8 |
| Earnings | `earningsControllerProvider` | `EarningsRepository` | `FakeEarningsRepository` | Ledger API — STEP 8 |
| Notifications | `notificationsControllerProvider` | `NotificationsRepository` | `FakeNotificationsRepository` | Push/inbox API — STEP 6/8 |
| Support | `supportConfigProvider` | `SupportRepository` | `FakeSupportRepository` (`unavailable`) | Support channels — STEP 8 |

Canonical Flutter route/controller evidence:
[`route_controller_test_matrix.md`](./route_controller_test_matrix.md).

**Rule:** no Flutter UI talks to HTTP/DB/WebSocket. Future remote adapters are
added behind repository interfaces only after STEP 5 repositories and
`saeq-contracts` are approved.

---

## 3. Fake / Local / Remote boundaries

ChatGPT package status: **COMPLETE**.

Canonical Flutter evidence:
[`fake_local_remote_boundaries.md`](./fake_local_remote_boundaries.md).

| Layer | Meaning in SAEQ Driver today |
|-------|------------------------------|
| Fake | In-memory fixtures / synthetic policies used for UI-first development |
| Local | Secure storage, SharedPreferences, or Drift — device-local persistence |
| Remote | Production Backend adapter | **NONE wired** |

Facts:

- `ApiClient` is constructed by `AppServiceRegistry` but **no feature
  repository consumes it**.
- `SyncManager` can call HTTP but is **not instantiated** in the runtime graph.
- Auth and delivery Fake remotes have hard release/production guards.
- Most other Fakes return `null` under `AppConfig.isProduction`.
- All fifteen domains remain **NOT CONNECTED**.

---

## 4. Customer PII classification

ChatGPT package status: **COMPLETE** (PII policy draft).

| Data | Classification | Current source | Allowed in Flutter today |
|------|----------------|----------------|--------------------------|
| Driver phone (entered) | Driver PII | Auth Fake / session | Local session only |
| Driver name / email / plate | Driver PII | Fake profile / vehicle | Synthetic trial data |
| Customer display name | Customer PII | Synthetic batch localization | Current stop only when revealed |
| Customer phone | Customer PII | Synthetic fixture | Current stop only when revealed |
| Customer address / notes | Customer PII | Synthetic fixture | Current stop only when revealed |
| Next-customer contact | Customer PII | Must stay hidden | Never revealed early |
| Closed-order contact | Customer PII | Must stay closed | Hidden after deliver/cancel |

Policy constraints for future Backend:

- Phone/address/notes must never appear in logs, analytics, crash reports,
  channel names, or push bodies.
- Backend authorization must validate
  `driverId` + `activeAssignmentId` + `currentOrderId` + delivery state.
- Staging must use synthetic data only.

Draft policy source: contracts package `docs/policies/pii-policy.md`.

---

## 5. Customer-contact visibility rules

Aligned with Hotfix PR #16 and Figma journey contract `150:427` /
`BatchCustomerContactVisibility`.

| Rule | State |
|------|-------|
| Before manual pickup confirmation | `locked` |
| Immediately after `pickupConfirmedManually` | current customer `revealed` |
| While `enRouteToCustomer` | remains `revealed` |
| After `arrivedAutomaticallyByLocation` | remains `revealed` |
| While `customerUnavailable` (current stop) | remains `revealed` until outcome |
| After `deliveredConfirmedManually` or cancelled | `closed` |
| Next-customer PII | hidden until that order becomes current |
| Delivery confirm CTA | armed only after automatic arrival (independent of reveal) |

Draft schema: `urn:saeq:customer-contact:projection:0.1.0`
(`visibility`: `locked` | `revealed` | `closed`).

Flutter evidence: `BatchState.currentContactVisibility` in
`lib/features/batch/batch_feature.dart` (merged Hotfix).

ADR draft: `ADR-002-customer-contact-window.md`.

---

## 6. STEP 5 REST prerequisites

ChatGPT package status: **COMPLETE**.

Target repositories (owner directive):

| Repository | Role |
|------------|------|
| `jari-tach/saeq-backend` | Backend server implementation |
| `jari-tach/saeq-contracts` | Shared contracts (OpenAPI / schemas / events) |
| `jari-tach/jari-platform` | SAEQ Driver Flutter client only |

Checklist before STEP 5 implementation:

1. Approve Backend stack.
2. Create `saeq-backend` repository.
3. Create / approve `saeq-contracts` location.
4. Approve API versioning and stable error format.
5. Approve authentication / session model.
6. Approve RBAC / resource ownership.
7. Approve delivery aggregate / state machine (ADR if changed).
8. Approve idempotency retention / conflict behavior.
9. Approve PII encryption / redaction / retention.
10. Approve database schema and migrations.
11. Approve staging synthetic-data policy.
12. Add Backend and Flutter contract tests.

Contract lifecycle (draft):
`DRAFT → REVIEW → APPROVED → IMPLEMENTED → INTEGRATED → DEPRECATED`
(SemVer: MAJOR breaking / MINOR additive / PATCH clarification).

**Forbidden in Flutter repo:** Backend server code, production secrets,
real customer data, direct DB wiring from UI.

---

## 7. STEP 6 realtime prerequisites

ChatGPT package status: **COMPLETE**.

Before STEP 6:

1. Select realtime transport (NOT SELECTED today).
2. Approve event envelope fields (draft ADR-005):
   `eventId`, `eventType`, `aggregateType`, `aggregateId`, `aggregateVersion`,
   `sequence`, `occurredAt`, `correlationId`, `causationId`, `payload`.
3. Approve offer / assignment / availability event catalog.
4. Approve reconnect, replay, and at-least-once handling.
5. Approve that PII never appears in channel names or push bodies.
6. Keep Flutter behind repository/stream abstractions — no Widget WebSocket.

STEP 6 must not start before STEP 5 REST authority exists for the same
aggregates.

---

## 8. Idempotency requirements

ChatGPT package / ADR-003 status: **DRAFT**.

Required for commands:

- Accept offer
- Reject offer
- Confirm pickup
- Arrival proof (later / STEP 4+)
- Confirm delivery
- Report issue
- Cancel
- Upload (STEP 7)

Expectations:

- Client sends stable `commandId`.
- Duplicate submit with same `commandId` does not double-apply.
- Conflict on invalid state returns typed domain error.
- Retention/conflict policy must be approved in STEP 5.

STEP 3 may simulate **local** command IDs only. That is not final Backend
idempotency.

---

## 9. Offline Outbox requirements

ChatGPT package / ADR-004 status: **DRAFT**.

- Local outbox is allowed for queued commands while offline.
- Backend remains authoritative after sync.
- Outbox entries must carry command identity, aggregate refs, and timestamps.
- Failed sync must be retryable without duplicating applied commands.
- Flutter already has dormant `OfflineQueue` / `SyncManager` sketches; they are
  **not runtime-wired** and must not be treated as production sync.

STEP 3 may add local pending-sync simulation for single delivery. Full outbox
authority is STEP 5/6.

---

## 10. ADR backlog

ChatGPT package status: **COMPLETE** (draft ADRs).

| ADR | Title | Status | Notes |
|-----|-------|--------|-------|
| ADR-001 | Contract-First layering | DRAFT | Presentation → … → Adapter |
| ADR-002 | Customer contact visibility window | DRAFT | Reveal after manual pickup |
| ADR-003 | Idempotent commands | DRAFT | commandId semantics |
| ADR-004 | Offline outbox | DRAFT | Local queue; Backend authoritative |
| ADR-005 | Event envelope | DRAFT | Realtime/event bus shape |

These drafts live in the contracts package today. Promoting them into
`jari-platform/docs/adr/` or `saeq-contracts` requires a separate accepted ADR
pass — **not** part of this docs closeout beyond recording the backlog.

Existing platform ADRs (ADR-013 separate apps, ADR-014 channels, etc.) remain
higher-ranked decision sources for repository scope.

---

## 11. Backend implementation status

| Item | Status |
|------|--------|
| Backend server | **NOT STARTED** |
| `saeq-backend` repository | Not created in this phase |
| `saeq-contracts` repository | Not created in this phase |
| Production OpenAPI | **NOT APPROVED** |
| Realtime transport | **NOT SELECTED** |
| Database / migrations | Not started |
| Auth / OTP SMS provider | Not started |
| Flutter remote adapters | Not started |

Locked until STEP 5 authorization after STEP 3/4 gates as directed by the owner.

---

## 12. Production connection

| Claim | Value |
|-------|-------|
| Production Backend | **NOT CONNECTED** |
| Feature repositories using real HTTP | **0** |
| Real customer PII in repo | **0** |
| Secrets / API keys in Git | **0** (forbidden) |
| UI direct HTTP/DB/WebSocket | **Forbidden / not present for domains** |

---

## Package provenance

| Artifact | Role |
|----------|------|
| `STEP2D_Backend_Domain_Handoff.md` | Official ChatGPT Domain/Contract handoff source (status COMPLETE drafts) |
| `saeq-backend-contracts` `0.1.0-draft` | Supporting draft schemas, examples, ADRs, PII policy |
| This file (`docs/step2d/backend_domain_handoff.md`) | Frontend-owned integration into `jari-platform` |

Validation note from draft package: `scripts/validate_contracts.py` had a
syntax error in the shipped draft; basic Python contract tests passed. Repair
belongs in `saeq-contracts`, not in Flutter.

---

## Explicit non-goals of this handoff

- No STEP 3 Loading Offers fix here.
- No STEP 4 GPS/maps.
- No STEP 5 Backend server in Flutter repo.
- No invented production endpoint URLs, verbs, or auth headers for live calls.
- No change to Flutter runtime behavior.
