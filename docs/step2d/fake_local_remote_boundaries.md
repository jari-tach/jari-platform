# STEP 2D — Item 23 · Fake / Local / Remote Boundaries

> Baseline: `6164994ca262535c85bdeafdee822e32ad877da2`
> Official Backend/Domain handoff: [`backend_domain_handoff.md`](./backend_domain_handoff.md)
> (source package `STEP2D_Backend_Domain_Handoff.md` + draft contracts `0.1.0-draft`).
> Future-remote cells below mean **DRAFT CONTRACT ONLY** — Backend server **NOT STARTED**, production **NOT CONNECTED**. No live endpoint, HTTP verb, or schema is approved for Flutter wiring.

## Fifteen-domain boundary matrix

| Domain | Current adapter | Fake | Local | Future remote | Current data source | Production reachability | PII | Deferred step | Required future contract | NOT CONNECTED |
|---|---|---|---|---|---|---|---|---|---|---|
| Authentication | `AuthenticationRepository` via `AppServiceRegistry` | `FakeAuthenticationRepository` + `FakeAuthPolicy` | `AuthSessionStorage` over secure storage | **DRAFT CONTRACT ONLY** | In-memory OTP challenge; secure local session | Fake constructor blocked by `kReleaseMode` and production policy; registry exposes `null` | Yes: entered phone, derived driver ID, synthetic token | STEP 5 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Driver profile | `DriverProfileRepository` | `FakeDriverProfileRepository` | Hybrid fake/local Drift `DriverProfiles` cache | **DRAFT CONTRACT ONLY** | Drift + memory; synthetic profile on miss | Current release wiring has no auth repository; profile adapter becomes `null` | Yes: name, phone, email, image URL, plate/type, IDs | STEP 5 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Availability | `DriverAvailabilityRepository` | No fake repository; debug authoritative confirmer only | `LocalDriverAvailabilityRepository` + SharedPreferences data source | **DRAFT CONTRACT ONLY** | SharedPreferences | Local adapter is release-capable, but current registry needs auth; debug confirmer gated | Yes: driver ID, assignment ID, status/reasons/timestamps | STEP 5 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Offers | `DeliveryOfferRepository`; `DeliveryRemoteDataSource`; misleadingly named `RemoteDeliveryOfferRepository` | `FakeDeliveryRemoteDataSource`, `FakeDeliverySeed` | None before acceptance | **DRAFT CONTRACT ONLY** | Deterministic in-memory fixture | Fake remote blocked in release and production; repository becomes `null` | Operational driver/merchant/pickup/dropoff labels; current values synthetic | STEP 3 then STEP 5/6 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Single delivery | `DeliveryAssignmentRepository` + offer repository | Fake remote generates accepted assignment | `LocalDeliveryAssignmentRepository` + Drift data source/database | **DRAFT CONTRACT ONLY** | Drift assignment snapshot + fake in-memory authority | Drift can initialize, but no auth/acceptance authority makes normal production flow unreachable | Driver ID and persisted pickup/dropoff/merchant labels; current labels synthetic | STEP 3/4/5 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Batch delivery | `BatchService` | `FakeBatchService`; `FakeBatchLocationController` | None; pending-sync/restart markers are in memory only | **DRAFT CONTRACT ONLY** | In-memory fixture | Service is production-gated; user entry additionally requires debug and non-production | Synthetic order/batch IDs, names, phones, addresses | STEP 4/5/6 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Customer contact | No repository abstraction; `BatchCustomerContactViewData` controlled by `BatchController` | UI/localization fixture; fake action counters | None | **DRAFT CONTRACT ONLY** | In-memory state + localized synthetic contact values | Same as batch; no call/WhatsApp platform intent | Yes conceptually; all current names/phones/addresses are synthetic | STEP 5 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Location / map | `LocationService` + `MapPreviewService` | `FakeLocationService`, `FakeMapPreviewService`, fake map painter | None | **DRAFT CONTRACT ONLY** | Normalized in-memory points/scenarios | Providers return `null` in production; no GPS plugin, permission bridge, map SDK, tiles, or external-nav handoff | Location is sensitive; current values are synthetic, not device coordinates | STEP 4 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Vehicle | `VehicleRepository` | `FakeVehicleRepository` | None; edits mutate memory | **DRAFT CONTRACT ONLY** | In-memory fixture | Fake available only outside production policy | Yes: make/model/year/color/type and plate; seeded plate synthetic | STEP 7 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Documents | `DocumentsRepository` | `FakeDocumentsRepository`, `FakeFileMetadata` | None; uploads append in memory | **DRAFT CONTRACT ONLY** | In-memory metadata fixture | Fake available only outside production policy | Sensitive KYC document metadata; masked/synthetic values only | STEP 7 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| History | `DeliveryHistoryRepository` | `FakeDeliveryHistoryRepository` | None | **DRAFT CONTRACT ONLY** | In-memory fixture | Repository `null` in production | Operational location/earnings data would be PII; current records synthetic | STEP 5 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Earnings | `EarningsRepository` | `FakeEarningsRepository` | None | **DRAFT CONTRACT ONLY** | In-memory fixture | Repository `null` in production | Driver financial/work data; current values synthetic | STEP 5 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Notifications | `NotificationsRepository` | `FakeNotificationsRepository` | None; read state mutates memory | **DRAFT CONTRACT ONLY** | In-memory generic key/timestamp fixture | Repository `null` in production; no push adapter | Current generic fixtures contain no personal data; future messages may | STEP 6 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Support | `SupportRepository` / `supportConfigProvider` | `FakeSupportRepository` returns unavailable/no contact data | None | **DRAFT CONTRACT ONLY** | Null/unavailable fixture | Production repository is `null`; UI intentionally shows unavailable | No driver/customer PII; potential platform contact fields are null | STEP 8 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |
| Safety | No adapter; static `SupportSafetyScreen` localization | None | Compiled localized copy only | **DRAFT CONTRACT ONLY** | `AppLocalizations` | Static content is release-capable, subject to authenticated routing | No PII | STEP 8 | **DRAFT CONTRACT ONLY** | **YES — NOT CONNECTED** |

## Contact visibility gate

`BatchState.currentContactVisibility` enforces:

1. Values are `locked`, `revealed`, and `closed`.
2. No current order → `locked`.
3. Only `pickedUp`, `headingToCustomer`, `arrived`, and `customerUnavailable` qualify as the active customer.
4. A non-current resolved order → `closed`; a non-current unresolved order → `locked`.
5. Current-customer contact becomes `revealed` immediately after manual pickup (`isPickedUp`), not after arrival.
6. `customerUnavailable` remains revealed until the final outcome.
7. Phone, address, and notes render only while revealed.
8. Delivery confirmation remains disabled until `arrivedAutomaticallyByLocation`.
9. After delivery/cancellation, contact becomes `closed` and PII is hidden.
10. Call and WhatsApp actions only increment fake counters; no platform intent is launched.

## ApiClient and HTTP boundary

- `ApiClient` is constructed by `AppServiceRegistry`, but **no feature repository imports or consumes it**.
- `SyncManager.processQueue()` is the only dormant core path capable of calling `ApiClient.post`, `put`, or `delete` with dynamic queue paths.
- Nothing under `lib` constructs `SyncManager`; its network listener is commented/TODO. This path is not runtime-wired.
- `TokenRefreshManager` contains only a commented HTTP example.
- Consequently, **all 15 domains are NOT CONNECTED to real HTTP**.

Drift is actively used only by `FakeDriverProfileRepository` (`DriverProfiles`) and `LocalDeliveryAssignmentRepository` (`DeliveryAssignments`). `OfflineQueue`/`SyncManager` reference Drift but are not in the current runtime graph. The legacy `DeliveryOrders` table is not consumed by a feature repository.

## Environment and failure behavior

- A release build is not automatically production. `AppConfig.init()` reads `SAEQ_ENV`; release without it defaults to `Environment.dev`.
- Auth and delivery remote fakes have hard release guards. Most other fakes check `AppConfig.isProduction` only.
- Missing production adapters degrade to `null`, error, empty, or unavailable UI. No real remote placeholder throws `UnimplementedError`/`UnsupportedError`.
- Fake safety guards may throw if directly used in a prohibited environment; `AppServiceRegistry._safeInit` catches constructor failures and stores `null`.

## Step boundary

| Step | Ownership boundary | Explicitly not claimed by STEP 2D |
|---|---|---|
| STEP 2D | Inventory, mapping, audit, minimal Semantics corrections, closeout | No backend, GPS, realtime, fixture redesign, architecture redesign |
| STEP 3 | Fake/local offer lifecycle stabilization, including known Loading Offers defect | Authorized after STEP 2D final docs PR merges |
| STEP 4 | Real GPS, OS permissions, accuracy/debounce/background handling, geofence, maps/external navigation | Current location/arrival/map behavior remains Fake |
| STEP 5 | REST/backend domain adapters (`saeq-backend` + `saeq-contracts`) | Draft handoff recorded; server NOT STARTED; no live endpoints approved |
| STEP 6 | Realtime offers/sync/push/notification channels | Transport NOT SELECTED; no WebSocket/push wired |
| STEP 7 | Vehicle/documents/KYC picker, camera, upload/storage | Current edits/uploads are in-memory metadata |
| STEP 8 | Driver support/services and governed safety content | Current support config is unavailable/static |

Known Loading Offers behavior and the contact-banner copy inconsistency remain deferred. Availability/Busy authority is local/debug-simulated and is not represented as server-connected.
