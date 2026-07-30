# STEP 3 — Item 25 · Baseline

> **Branch:** `feature/step-3-local-offer-lifecycle-stabilization`  
> **Baseline SHA (origin/main):** `cad0488e40fdec36aed5af3f0e048b4bf75ecc82`  
> **Recorded:** 2026-07-30  
> **Flutter:** 3.44.7  
> **Dart:** 3.12.2  
> **Test count (last known on main):** 803 PASS  
> **Test files present:** 105 `*_test.dart`  
> **Code modified before this baseline:** none

## Approved gate from STEP 2D

- STEP 2D final docs PR [#18](https://github.com/jari-tach/jari-platform/pull/18): MERGED
- Merge SHA: `cad0488e40fdec36aed5af3f0e048b4bf75ecc82`
- CI: SUCCESS ×4
- Backend server: NOT STARTED
- Production Backend: NOT CONNECTED

## Existing Loading Offers reproduction

| Field | Value |
|---|---|
| Symptom | After Accept Offer, UI remains on “Loading offers” / “جارٍ تحميل العروض” |
| Route | `/delivery/offer` → `IncomingDeliveryOfferPage` |
| Widget | `DeliveryOfferLoadingState` when `status` is `initial` or `loading` |
| Localization key | `deliveryLoadingTitle` |
| Device path | Login → Availability → Offer → Accept → stuck Loading Offers |
| Prior docs | Known gap deferred from STEP 2D closeout |

## Current DeliveryController states

| Type | Values |
|---|---|
| `DeliveryViewStatus` | `initial`, `loading`, `ready`, `processing`, `failure` |
| `DeliveryProcessingAction` | `none`, `accepting`, `rejecting`, `refreshing`, `advancing`, `verifying`, `completing` |
| Domain `DeliveryStatus` | `accepted`, `pickedUp`, `delivered`, `cancelled` |
| Domain `DriverWorkflowStage` | `assigned` → `navToPickup` → `arrivedPickup` → `waitingPickup` → `collected` → `navToCustomer` → `arrivedCustomer` → `verifying` → `delivered` → `summary` (+ `issueOpen`) |

Source:

- `lib/features/delivery/presentation/state/delivery_controller_state.dart`
- `lib/features/delivery/presentation/controllers/delivery_controller.dart`

## Current repositories

| Contract | Implementation | Role |
|---|---|---|
| `DeliveryOfferRepository` | `RemoteDeliveryOfferRepository` → Fake remote | Offers watch / accept / reject |
| `DeliveryAssignmentRepository` | `LocalDeliveryAssignmentRepository` | Persist accepted assignment |
| `DeliveryRemoteDataSource` | `FakeDeliveryRemoteDataSource` | Fake authority |
| `DeliveryLocalDataSource` | `DriftDeliveryLocalDataSource` | Drift persistence |

## Current Drift tables (delivery-related)

| Table | Role |
|---|---|
| `DeliveryAssignments` | Active accepted assignment snapshot (ADR-028); unique `driverId` |
| `DeliveryOrders` | Legacy scaffold; not used by PHASE 2.5 accept path |
| `OfflineQueue` | Present; SyncManager not runtime-wired for delivery accept |
| `DriverProfiles` | Profile cache (out of STEP 3 primary scope) |

Source: `lib/features/driver/data/datasources/local/driver_database.dart`

## Current restore behavior

On `DeliveryController.initialize()`:

1. Load active assignment via `GetActiveDelivery` (Drift).
2. Load offers; if assignment exists, force `offers = []`.
3. Reconcile Busy via `AcceptDeliveryOfferAndBindBusy.bindBusyForAssignment`.
4. Emit `DeliveryControllerState.ready(activeAssignment: …)`.

Covered by existing test: `restart restores assignment and reconciles busy` in
`test/features/delivery/presentation/delivery_controller_busy_binding_test.dart`.

## Suspected Loading Offers root cause (for Item 26)

Production wiring in `delivery_providers.dart`:

1. `_readAcceptPreconditions` uses `ref.watch(availabilityControllerProvider)`.
2. After accept success, controller calls `_availabilityRefreshReader` →
   `AvailabilityController.initialize()`.
3. Availability state change rebuilds `DeliveryController`.
4. `DeliveryController.build()` always returns `DeliveryControllerState.initial()`.
5. `_initializeStarted` is already `true`, so `initialize()` is not re-scheduled.
6. UI stays on `initial` → Loading Offers permanently.

Existing accept tests stub preconditions/`availabilityRefresh` and do **not**
reproduce this production pair.

## Explicit non-goals before Item 26 failing test

- No widget workaround.
- No GPS / geofence / Backend / WebSocket.
- No STEP 4 / STEP 5 / STEP 6 work.
- No code fix until a failing test proves the defect.
