# PHASE 2.5 — Delivery Request Lifecycle Architecture

> **Status:** Architecture **Accepted** — Implementation **Complete** (PHASE 2.5 closeout)  
> **Date:** 2026-07-26  
> **Base:** `main` @ `88685fd` (PHASE 2.4.1 merged)  
> **Scope of this task:** Documentation only — no `lib/`, `test/`, packages, schema, CI, commit, or push  
> **Related:** [ADR-020…028](./adr/), [PHASE_2_5_DELIVERY_REQUEST_TEST_PLAN.md](./PHASE_2_5_DELIVERY_REQUEST_TEST_PLAN.md), [PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md](./PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md), [ADR-015…019](./adr/), [41_OFFICIAL_BUSINESS_RULES.md](./41_OFFICIAL_BUSINESS_RULES.md), [localization/localization-guidelines.md](./localization/localization-guidelines.md), [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](./PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md)

---

## 1. Purpose

Enable an authenticated SAEQ Driver to **receive, review, accept, or reject exactly one incoming delivery offer at a time**, with:

- deterministic, default-deny lifecycle transitions  
- Backend authority for assignment races and expiry  
- safe integration with PHASE 2.4 availability (`busy` / `activeAssignmentId`)  
- no weakening of availability default-deny eligibility  
- Fake/simulated offers that cannot leak into Release/Production  
- localization and accessibility as mandatory quality gates  

**PHASE 2.5 ends** when an offer is resolved to a durable **accepted assignment** (persisted) or a terminal non-accept outcome (rejected / expired / taken / cancelled).  
**PHASE 2.6** owns pickup → delivery execution UI and step machine.

---

## 2. Scope

### In scope

- `DeliveryOffer` presentation and decision lifecycle  
- `DeliveryAssignment` created only after successful accept authority  
- Accept / Reject use cases with idempotency  
- Expiration and conflict mapping (410 / 409 class outcomes)  
- One-active-offer policy  
- Full-screen offer UI (not a floating modal-only UX)  
- Local persistence of the **accepted** assignment for restart / future offline (2.7)  
- Availability binding: accept → system/server `busy` + assignment id  
- Domain / data / presentation contracts under `lib/features/delivery/`  
- Fake offer source for non-production environments  
- Bilingual localization keys and tests (per 2.4.1 gate)

### Out of scope

- Active delivery steps (confirm pickup/delivery) — PHASE 2.6  
- Maps / GPS tracking UI  
- Push/FCM productization — PHASE 2.8 (local in-app presentation only)  
- Payments, ratings, wallet  
- Customer / Merchant / Admin apps or shared Flutter packages extraction  
- Authoritative availability eligibility adapter (separate track; must not invent eligibility)  
- Weakening default-deny availability or Fake Auth/Profile Release guards  

### Document map

| Deliverable | Location |
|-------------|----------|
| Architecture (this file) | Hub |
| Test plan | [PHASE_2_5_DELIVERY_REQUEST_TEST_PLAN.md](./PHASE_2_5_DELIVERY_REQUEST_TEST_PLAN.md) |
| Offer vs Assignment | [ADR-020](./adr/ADR_020_DELIVERY_OFFER_VS_ASSIGNMENT.md) |
| Lifecycle | [ADR-021](./adr/ADR_021_DELIVERY_REQUEST_LIFECYCLE.md) |
| Default-deny transitions | [ADR-022](./adr/ADR_022_DELIVERY_DEFAULT_DENY_TRANSITIONS.md) |
| One active offer | [ADR-023](./adr/ADR_023_ONE_ACTIVE_OFFER_POLICY.md) |
| Offline accept | [ADR-024](./adr/ADR_024_OFFLINE_ACCEPT_POLICY.md) |
| Busy binding on accept | [ADR-025](./adr/ADR_025_DELIVERY_ACCEPT_BUSY_BINDING.md) |
| Full-screen UI | [ADR-026](./adr/ADR_026_FULL_SCREEN_OFFER_UI.md) |
| Fake offer security | [ADR-027](./adr/ADR_027_FAKE_OFFER_SECURITY.md) |
| Persistence | [ADR-028](./adr/ADR_028_DELIVERY_ASSIGNMENT_PERSISTENCE.md) |

---

## 3. Terminology

| Term | Meaning |
|------|---------|
| **DeliveryOffer** | Time-bounded, non-owned invitation for a driver to accept work. Not an assignment. |
| **DeliveryAssignment** | Authoritative binding of a driver to a delivery after successful accept. Owns `busy`. |
| **Offer window** | Server-defined interval during which accept is valid. |
| **Terminal offer outcome** | `rejected`, `expired`, `taken_by_other`, `cancelled`, or transition to assignment. |
| **Active offer** | At most one non-terminal `offered` instance for the driver session (ADR-023). |
| **Active assignment** | At most one in-progress assignment (MVP); blocks free availability (BR-AVAIL-006). |
| **Local intent** | Client-side optimistic UI only; never sovereign over Backend truth (ADR-016 pattern). |

Avoid using Drift’s scaffold table name `DeliveryOrders` as the domain name — see ADR-020 / ADR-028.

---

## 4. Architecture

### 4.1 Feature placement

Primary feature module: **`lib/features/delivery/`** (expand the existing empty marker).

Do **not** implement offer lifecycle under `orders/` (keep `/orders` as shell placeholder until product decides list history in a later phase).

### 4.2 Layers (match Auth / Profile / Availability)

```text
lib/features/delivery/
  domain/
    entities/
    policies/
    failures/
    repositories/
    usecases/
  data/
    datasources/
    models/
    repositories/
    mappers/
  presentation/
    controllers/
    providers/
    mappers/          # failure → AppLocalizations
    screens/          # full-screen offer
    widgets/
```

### 4.3 Wiring

- Construction via `AppServiceRegistry` (ADR-010).  
- Riverpod `Notifier` controllers with `repositoryReader` (no direct Fake construction in UI).  
- Cross-feature: call existing availability authoritative update / conflict paths — do not fork a second availability SM.  
- Auth: require non-expired session matching `driverId`.

### 4.4 Authority model

| Fact | Authority |
|------|-----------|
| Offer issuance / expiry / taken-by-other | Backend (or Fake under ADR-027) |
| Accept success / 409 / 410 | Backend |
| Busy + `activeAssignmentId` | System/server via availability (ADR-018, ADR-025) |
| Eligibility to become available | Existing availability reader (default-deny until adapter) |
| Localized UI strings | `AppLocalizations` |

---

## 5. Folder Structure

| Path | Responsibility |
|------|----------------|
| `domain/entities/delivery_offer.dart` | Offer aggregate / VO |
| `domain/entities/delivery_assignment.dart` | Post-accept assignment |
| `domain/entities/delivery_offer_status.dart` | Offer SM states |
| `domain/policies/delivery_offer_transition_policy.dart` | Default-deny transitions |
| `domain/policies/one_active_offer_policy.dart` | ADR-023 enforcement helpers |
| `domain/failures/delivery_failure.dart` | Sealed typed failures |
| `domain/repositories/delivery_offer_repository.dart` | Contract |
| `domain/usecases/watch_incoming_offers.dart` | Stream/poll boundary |
| `domain/usecases/accept_delivery_offer.dart` | Accept |
| `domain/usecases/reject_delivery_offer.dart` | Reject |
| `domain/usecases/handle_offer_expiration.dart` | Expire |
| `data/repositories/fake_delivery_offer_repository.dart` | Non-prod only (ADR-027) |
| `data/repositories/local_delivery_assignment_repository.dart` | Persist accepted assignment |
| `presentation/controllers/delivery_offer_controller.dart` | UI state |
| `presentation/screens/incoming_delivery_offer_screen.dart` | Full-screen UI |

Exact filenames may vary slightly at implementation; responsibilities must not.

---

## 6. Domain Model

### 6.1 `DeliveryOffer`

| Field | Notes |
|-------|-------|
| `offerId` | Stable id (server or fake) |
| `driverId` | Must match session |
| `status` | See state machine |
| `issuedAt` / `expiresAt` | Server clocks preferred |
| `revision` | Opaque conflict token if provided |
| `summary` | Safe display fields only (no secrets) |
| `correlationId` | Optional tracing |

**Summary fields (MVP, non-exhaustive):** pickup label, dropoff label, rough distance/ETA if provided by server, merchant display name if allowed — **no** unrestricted customer PII dumps in logs.

### 6.2 `DeliveryAssignment`

| Field | Notes |
|-------|-------|
| `assignmentId` | Authoritative id |
| `offerId` | Provenance |
| `driverId` | Session match |
| `status` | `accepted` (2.5); richer statuses in 2.6 |
| `acceptedAt` | |
| `serverRevision` | |
| `payloadSnapshot` | Minimal persisted snapshot for restart |

### 6.3 Invariants

1. Offer and assignment `driverId` == authenticated session.  
2. At most one non-terminal offer (ADR-023).  
3. Accept denied offline (ADR-024).  
4. Accept denied unless availability is **confirmed available** (not restored-unconfirmed, not busy, not offline).  
5. User cannot create `busy` except via successful accept/system path (ADR-025 / ADR-018).  
6. Unknown transitions denied (ADR-022).  
7. Domain failures never include tokens or raw exceptions for UI.

---

## 7. State Machine

Full rules: [ADR-021](./adr/ADR_021_DELIVERY_REQUEST_LIFECYCLE.md), [ADR-022](./adr/ADR_022_DELIVERY_DEFAULT_DENY_TRANSITIONS.md).

### Offer states

| State | Meaning |
|-------|---------|
| `none` | No active offer |
| `offered` | Visible decision window |
| `accepting` | Accept in flight (local processing) |
| `rejecting` | Reject in flight |
| `accepted` | Terminal success → assignment exists |
| `rejected` | Terminal driver reject |
| `expired` | Terminal timeout / server expire |
| `taken_by_other` | Terminal conflict (409 class) |
| `cancelled` | Terminal system/merchant cancel during offer |
| `failed` | Recoverable presentation failure (safe message) |

### Allowed transitions (summary)

```text
none → offered
offered → accepting | rejecting | expired | taken_by_other | cancelled
accepting → accepted | offered (retryable fail) | taken_by_other | expired | failed
rejecting → rejected | offered (retryable fail) | expired | failed
accepted | rejected | expired | taken_by_other | cancelled → none (clear / next)
```

All other transitions: **deny**.

---

## 8. Lifecycle

1. Driver is authenticated and **confirmed available**.  
2. Offer source emits at most one `offered` (ADR-023).  
3. Full-screen UI shows offer (ADR-026).  
4. Driver Accept → online + idempotency key → Backend/Fake authority.  
5. On success: persist assignment (ADR-028); bind availability busy (ADR-025); clear offer.  
6. Driver Reject → may proceed offline with queued intent **only if** product keeps roadmap allowance; **Accept never queues** (ADR-024).  
7. Expiry / taken / cancel → clear offer; no assignment; availability unchanged.  
8. Logout / session loss → clear local offer presentation; do not invent assignment.

---

## 9. Repository Contracts

### `DeliveryOfferRepository`

- `Stream<DeliveryOffer?> watchActiveOffer({required String driverId})`  
- `Future<DeliveryResult<DeliveryAssignment>> accept({required AcceptOfferRequest request})`  
- `Future<DeliveryResult<void>> reject({required RejectOfferRequest request})`  
- Optional: `Future<DeliveryResult<void>> acknowledgeExpired(...)`

### `DeliveryAssignmentRepository` (local)

- `Future<DeliveryAssignment?> getActiveAssignment(String driverId)`  
- `Future<void> upsertAccepted(DeliveryAssignment assignment)`  
- `Future<void> clear(String driverId)` (logout / future complete flows)

Implementations: Fake offer repo (ADR-027); local persistence (ADR-028). Production HTTP adapter later without changing domain contracts.

---

## 10. Use Cases

| Use case | Responsibility |
|----------|----------------|
| `WatchIncomingOffers` | Subscribe; enforce one-active; ignore duplicates |
| `AcceptDeliveryOffer` | Validate preconditions; idempotent accept; map failures |
| `RejectDeliveryOffer` | Validate; reject; clear offer |
| `HandleOfferExpiration` | Apply terminal expire when clock/server says so |
| `RestoreAcceptedAssignment` | On startup after auth, restore local accepted for 2.6 handoff |
| `ClearOfferOnLogout` | Presentation + local offer clear; assignment policy per logout rules |

Use cases call policies first (default-deny). Controllers stay thin.

---

## 11. Availability Integration

| Event | Availability effect |
|-------|---------------------|
| Offer shown | No status change |
| Accept success | Authoritative/system update → `busy` + `activeAssignmentId` (ADR-025) |
| Reject / expire / taken / cancel | No busy; remain available if still confirmed |
| Active assignment present | Eligibility/`hasActiveAssignment` blocks free →available (existing policy) |
| Availability becomes unavailable/offline while offered | Deny accept; clear or hold offer per product — **default: deny accept; allow reject; expire naturally** |

**Must not:** synthesize eligibility to go available in order to test offers in production builds. Tests/dev may override eligibility readers explicitly (existing availability test pattern).

---

## 12. Authentication Integration

- Protected presentation behind authenticated session.  
- `driverId` mismatch → security denial failure.  
- Session expired mid-offer → fail safe; navigate via existing auth guards.  
- No offer accept without session.

---

## 13. Offline Policy

See [ADR-024](./adr/ADR_024_OFFLINE_ACCEPT_POLICY.md).

| Action | Offline |
|--------|---------|
| Receive new offer | Do not present as actionable accept (no false capacity) |
| Accept | **Denied** |
| Reject | Allowed to record local reject intent / queue if implemented; must not imply assignment |
| Expire (local timer) | May mark expired for UI; server remains authority on reconnect |

Aligns with ADR-017 spirit: never claim work-readiness or ownership offline.

---

## 14. Persistence Strategy

See [ADR-028](./adr/ADR_028_DELIVERY_ASSIGNMENT_PERSISTENCE.md).

- Persist **accepted assignment** only in PHASE 2.5 (MVP).  
- Do **not** treat current Drift `DeliveryOrders` scaffold as final schema — redesign/migrate under implementation increment with explicit migration plan.  
- Offer stream state may be ephemeral; optional cache is non-sovereign.  
- Secure: no tokens in tables; minimize PII; no plaintext secrets.

---

## 15. UI Architecture

See [ADR-026](./adr/ADR_026_FULL_SCREEN_OFFER_UI.md).

- Full-screen offer route/screen (primary).  
- Enter from Home when offer becomes active (push or go — prefer stack that preserves Home under offer).  
- Primary actions: Accept / Reject; show countdown if `expiresAt` known.  
- Disable Accept when offline, not available, or processing.  
- Status never by color alone (chip + text).  
- `/orders` remains placeholder in 2.5 unless explicitly expanded later.

---

## 16. Localization

Per `docs/localization/localization-guidelines.md`:

- All app-owned strings via `AppLocalizations` (`_t`).  
- Arabic and English; unsupported → English.  
- Typed failures mapped in presentation.  
- No mixed-language UI.  
- Exceptions: user/external names, phones, ids when intentionally shown.

---

## 17. Accessibility

- Semantic labels for offer status, countdown, Accept/Reject.  
- RTL/LTR from Locale.  
- Large text (1.6) must not overflow critical actions.  
- Processing state announced.  
- Touch targets usable; disabled Accept still explainable via status text.

---

## 18. Security

- Default-deny transitions (ADR-022).  
- Fake offers blocked in Release/Production (ADR-027).  
- Idempotency keys on accept (and reject when networked).  
- No client-side “force accept” against 409/410.  
- Do not log offer payloads with sensitive customer data.  
- Do not weaken availability eligibility default-deny.

---

## 19. Logging

Use `LoggerService`:

- Log machine codes / correlation ids / offerId hashes if needed.  
- Do **not** log full addresses, phone numbers, or payment fields.  
- Error logs: typed failure codes, not stack traces to UI.

---

## 20. Error Handling

Sealed `DeliveryFailure` examples (illustrative):

| Failure | UI intent |
|---------|-----------|
| `DeliveryUnauthenticated` | Sign in again |
| `DeliveryOfflineAcceptDenied` | Connect to accept |
| `DeliveryNotAvailable` | Must be available |
| `DeliveryOfferExpired` | Offer ended |
| `DeliveryOfferTaken` | Taken by another |
| `DeliveryConflict` | Stale / revision |
| `DeliveryPersistenceFailure` | Could not save locally |
| `DeliveryUnknownFailure` | Safe generic |

Map exclusively in presentation mappers → `AppLocalizations`.

---

## 21. Concurrency

- Single-flight accept per offer (controller busy flag + repo idempotency).  
- Server 409 → `taken_by_other`; clear optimistic state.  
- Duplicate watch events for same `offerId` ignored.  
- Real multi-driver load tests deferred to Staging (roadmap); Fake can simulate 409.

---

## 22. Restart Strategy

| Local state | On cold start after auth |
|-------------|---------------------------|
| Accepted assignment persisted | Restore assignment; availability should reflect busy if still authoritative — reconcile via availability restore + assignment presence |
| Offer only (not accepted) | **Do not** resurrect as guaranteed still-valid; wait for server/fake re-issue (avoid zombie accepts) |
| Processing mid-accept | Treat as unknown; re-query authority / show safe recovery |

---

## 23. Testing Strategy

See [PHASE_2_5_DELIVERY_REQUEST_TEST_PLAN.md](./PHASE_2_5_DELIVERY_REQUEST_TEST_PLAN.md).

Mandatory: domain SM, accept/reject/expire, idempotency, offline accept deny, one-active-offer, availability busy binding, persistence restore, AR/EN widget tests, CI analyze+test.

---

## 24. Implementation Plan (after architecture approval)

| Increment | Content |
|-----------|---------|
| 1 | Domain entities, failures, transition policy + unit tests |
| 2 | Repository contracts + Fake offer source (ADR-027) |
| 3 | Accept/Reject/Expire use cases + idempotency |
| 4 | Local assignment persistence (ADR-028) + restore |
| 5 | Controller + availability busy binding (ADR-025) |
| 6 | Full-screen UI + l10n + a11y widget tests |
| 7 | Integration tests + CI green + docs status → Implementation Complete |

Suggested branch: `feature/phase-2.5-delivery-request-lifecycle` (or roadmap `feature/delivery-request-flow`).

---

## 25. Acceptance Criteria

1. Authenticated, confirmed-available driver can see at most one offer full-screen.  
2. Accept online succeeds → assignment persisted → availability busy with assignment id.  
3. Accept offline always fails safely.  
4. Reject / expire / taken clear offer without assignment.  
5. Duplicate accept is idempotent / non-corrupting.  
6. 409/410 class outcomes map to safe localized UI.  
7. Fake offers impossible in Release/Production.  
8. No availability eligibility invention.  
9. AR and EN UI without mixed app-owned copy.  
10. Tests per test plan; `flutter analyze` 0; full suite green; no regression on auth/profile/availability.

---

## 26. Open follow-ups (non-blocking for architecture review)

- Exact offer countdown UX copy.  
- Optional reject-reason enum.  
- Future HTTP/WebSocket transport choice.  
- Authoritative availability eligibility adapter (parallel track).  
- Whether `/orders` becomes history in a later phase.

---

*Implementation Complete for PHASE 2.5 scope. Deferred: production remote adapter, map/journey UI, push notifications, earnings field (product).*
