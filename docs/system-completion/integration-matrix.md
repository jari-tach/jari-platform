# Integration Matrix — Flutter → Backend

> **Audit date:** 2026-08-02  
> **Contracts paths:** `lib/core/backend_configuration/driver_api_paths.dart` (contracts-v0.2.0)  
> **DI spine:** `lib/shared/services/app_service_registry.dart`  
> **DB (client):** Drift (`DriverDatabase`) for assignments + local command ledger; SharedPreferences for local availability (fake mode)

```text
UI / Page
  → Controller (Riverpod Notifier)
    → UseCase (domain)
      → Repository (interface + Fake|Local|Remote)
        → Remote Data Source (HTTP SaeqApiClient)
          → Backend API (/v1/...)
            → Backend DB (server-owned — not in this repo)
```

---

## Auth

| Layer | Type / file |
|-------|-------------|
| UI | `login_screen.dart`, `otp_verification_screen.dart`, Settings logout |
| Controller | `AuthController` |
| UseCase | Repository methods (no separate use-case types) |
| Repo | `RemoteAuthenticationRepository` / `FakeAuthenticationRepository` |
| API | `POST /v1/auth/otp/request`, `.../otp/verify`, `.../token/refresh`, `.../logout` |
| Backend / DB | Auth challenges, tokens, driver identity (server) |

---

## Profile / compliance

| Layer | Type / file |
|-------|-------------|
| UI | `profile_screen.dart`, `profile_edit_screen.dart` |
| Controller | `ProfileController` |
| Repo | `RemoteDriverProfileRepository` / `FakeDriverProfileRepository` |
| API | `GET/PATCH /v1/drivers/me`, `GET /v1/drivers/me/compliance` |
| Backend / DB | Driver profile + compliance aggregates |

---

## Availability

| Layer | Type / file |
|-------|-------------|
| UI | `DriverAvailabilityCard` on Home |
| Controller | `AvailabilityController` |
| UseCase | `RequestAvailabilityChange`, connectivity handlers, logout force-unavailable |
| Repo | `RemoteDriverAvailabilityRepository` / `LocalDriverAvailabilityRepository` |
| Remote | `HttpDriverAvailabilityRemoteDataSource` |
| API | `GET/PUT /v1/drivers/me/availability` |
| Backend / DB | Driver availability row (wire statuses: `available` \| `busy` \| `offline` \| `suspended`) |

---

## Offers

| Layer | Type / file |
|-------|-------------|
| UI | `IncomingDeliveryOfferPage`, home offer banner |
| Controller | `DeliveryController` |
| UseCase | `GetDeliveryOffers`, `AcceptDeliveryOffer`, `RejectDeliveryOffer`, `AcceptDeliveryOfferAndBindBusy` |
| Repo | `RemoteDeliveryOfferRepository` |
| Remote | `HttpDeliveryRemoteDataSource` / `FakeDeliveryRemoteDataSource` |
| API | `GET /v1/offers`, `GET /v1/offers/{id}`, `POST .../accept`, `POST .../reject` |
| Backend / DB | Offer aggregate + assignment on accept |
| Realtime | `RealtimeCoordinator` → `GET /v1/events/stream` + poll `GET /v1/events` → offer resync |

---

## Delivery lifecycle

| Layer | Type / file |
|-------|-------------|
| UI | `ActiveDeliveryPage`, `DeliveryVerifyPage`, `DeliveryIssuePage` |
| Controller | `DeliveryController` |
| UseCase | `ConfirmPickupRemote`, `ReportAutomaticArrivalRemote`, `ConfirmDeliveryRemote`, `CancelDeliveryRemote`, `ReportDeliveryIssueRemote`, `GetActiveDelivery`, `AdvanceDeliveryWorkflow`, `ReplayPendingDeliveryCommands` |
| Repo | `RemoteDeliveryLifecycleRepository` / Fake lifecycle; `LocalDeliveryAssignmentRepository` (Drift); `DriftDeliveryCommandRepository` |
| Remote | `HttpDeliveryLifecycleRemote` |
| API | active delivery, pickup-confirmation, arrival, delivery-confirmation, cancel, issues, customer-contact |
| Backend / DB | Delivery aggregate + idempotency_records |
| Client DB | Drift assignment snapshot + local command ledger |

---

## Batches

| Layer | Type / file |
|-------|-------------|
| UI | `batch_*_screen.dart` via `BatchController` |
| Controller (product UI) | `BatchController` + **FakeBatchService** |
| UseCase (DI, underused by batch UI) | `GetActiveBatch` |
| Repo / Remote | Lifecycle remote `getActiveBatch` / `getBatch` |
| API | `GET /v1/batches/active`, `GET /v1/batches/{id}` (accept/reject batch paths exist in older handoff docs; Flutter Fake UI does not call them) |
| Gap | Batch journey not integrated with remote accept/reject/stop lifecycle |

---

## Customer contact

| Layer | Type / file |
|-------|-------------|
| UI | Active delivery contact block |
| UseCase | `GetCustomerContact` |
| Cache | `CustomerContactMemoryCache` (cleared on logout/completion) |
| API | `GET /v1/deliveries/{id}/customer-contact` |

---

## Location / navigation / arrival

| Layer | Type / file |
|-------|-------------|
| UI | Active delivery (arrival automatic); map preview / location screens |
| Domain | Geofence policy, location probe, accuracy |
| Gateway | `DeviceLocationGateway` / `FakeLocationGateway`; `UrlLauncherExternalNavigationGateway` / Fake |
| API | Arrival evidence on delivery arrival POST only — no standalone location telemetry API in DriverApiPaths |
| Gap | Active-delivery Maps CTA is clipboard, not launcher |

---

## Earnings / History / Notifications / Vehicle / Docs / Home metrics

| Area | Flutter stack | API | Backend |
|------|---------------|-----|---------|
| Earnings | Fake repo + screens | **none** | **none** in Driver API paths |
| History | Fake repo + screens | **none** | **none** |
| Notifications inbox | Fake repo + screens | **none** (SSE is events/offers, not this inbox) | **none** |
| Vehicle | Fake repo | **none** | deferred |
| Documents | Fake repo | **none** | deferred |
| Home metrics | `FakeHomeSummary` | **none** | deferred |

---

## Support / Safety

| Area | Stack | API |
|------|-------|-----|
| Support | `FakeSupportRepository` / unavailable UI | none |
| Safety | Static localized screen | none |

---

## Remaining gaps (bullets — not new GitHub issues unless noted)

- **Issue #32 still OPEN:** merge wire mapping (`offline` ↔ domain `unavailable`) + remote eligibility; close after Device QA without SQL force.
- **P0 after #32 mapping:** `RemoteDriverAvailabilityRepository` rejects any `unavailable → available` as `DriverAccountSuspended` — must narrow to true suspended (e.g. wire `suspended` / reason), else go-available remains blocked.
- HEAD eligibility reader deny-safe (`DriverProfileMissing`) until WIP lands — remote drivers cannot request available without debug confirmer / WIP.
- Active delivery **Navigate** is clipboard-only; product Maps handoff incomplete vs STEP 4 external navigation gateway.
- **Batch screens** still Fake; remote `GetActiveBatch` not driving UI; no remote batch accept/reject from Fake controller.
- **Earnings / history / notifications / vehicle / documents / home metrics** have no remote adapters or Backend Driver API surfaces in `DriverApiPaths`.
- Production Fake policy: Fake remotes forbidden; missing remotes degrade to null/empty — vehicle/docs/earnings/history/notifications unavailable in production by design until STEP 7+ contracts.
- Support / safety: no remote contact channel.
- Issue #32 GitHub not linked to a merged PR yet (WIP on `fix/availability-offline-wire-mapping`).
- Related merged delivery unblocks: PR #31, #33, #35 (I-key charset, accept status map, revision-scoped keys) — journey past accept/pickup no longer blocked by those defects.
