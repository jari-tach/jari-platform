# Screen Wiring Audit — SAEQ Driver (Flutter)

> **Audit date:** 2026-08-02  
> **Scope:** Code reading under `lib/features/**` (no Device QA)  
> **Backend mode:** `BackendConfiguration` selects Fake vs Remote at bootstrap (`AppServiceRegistry`)  
> **Branch note:** Working tree audited on `fix/availability-offline-wire-mapping` (Issue #32 WIP). HEAD/`main` still has the pre-#32 wire mapping unless this branch merges.

Legend for **Adapter** column:

| Mark | Meaning |
|------|---------|
| **Remote** | HTTP adapter wired when `BackendConfiguration.isRemote` |
| **Fake** | In-memory / fixture adapter (non-production / fake mode) |
| **Local** | Drift / SharedPreferences only |
| **Partial** | Remote seams exist but UI or domain path incomplete |
| **Placeholder** | Shell / empty / clipboard / static UI |

---

## Domain adapter summary

| Domain | Adapter (remote mode) | Adapter (fake mode) | Notes |
|--------|----------------------|---------------------|-------|
| Auth | **Remote** | **Fake** | `RemoteAuthenticationRepository` → `HttpAuthRemoteDataSource` |
| Profile | **Remote** | **Fake** | `RemoteDriverProfileRepository` → `HttpDriverProfileRemoteDataSource` |
| Availability | **Remote** (Issue #32 fixed on branch) | **Local** (SharedPreferences) | Wire offline→unavailable; Backend decides suspend |
| Offers | **Remote** | **Fake** | `HttpDeliveryRemoteDataSource` / `FakeDeliveryRemoteDataSource` |
| Delivery lifecycle | **Remote** | **Fake** | Pickup / arrival / confirm / cancel / issue via `HttpDeliveryLifecycleRemote` |
| Batches | **Partial** Remote GET | **Fake** UI stack | `GetActiveBatch` + lifecycle remote exist; batch screens use `FakeBatchService` |
| Earnings | **Fake** | **Fake** | No remote repository |
| History | **Fake** | **Fake** | No remote repository |
| Notifications | **Fake** | **Fake** | No remote / push adapter; realtime SSE is offers/events, not this inbox |
| Vehicle | **Fake** | **Fake** | `FakeVehicleRepository` |
| Documents | **Fake** | **Fake** | `FakeDocumentsRepository` |
| Home metrics | **Fake** / hidden in prod | **Fake** | `FakeHomeSummary` seed |
| Navigation (active delivery Maps) | **Remote UX** | **Remote UX** | Opens Maps via `url_launcher`; clipboard fallback only |
| Location / geofence | **Device** (+ Fake gateway) | **Fake** | STEP 4A device gateway; arrival is automatic only |
| Realtime | **Remote** (SSE + poll) | none | Remote-only `RealtimeCoordinator` |

---

## Issue #32 fix status

**GitHub:** [Issue #32](https://github.com/jari-tach/jari-platform/issues/32) — **OPEN**  
**Title:** Backend wire `offline` mapped to connectivity-offline, blocking offline→available

| Item | Status |
|------|--------|
| Wire: Backend `offline` → domain `unavailable` | **Implemented in working tree** (`driver_availability_wire.dart`); **not on HEAD/`main`** |
| Wire: domain `unavailable` → PUT `offline` | Same WIP branch |
| Eligibility for remote: session + online → allow *request* | **Implemented in working tree** (`availability_eligibility_reader.dart`); HEAD remains deny-safe (`DriverProfileMissing`) |
| Merge / close issue | **Not done** |
| Follow-on risk after mapping | **P0:** `RemoteDriverAvailabilityRepository` still rejects `_current == unavailable` → `available` as `DriverAccountSuspended` (lines ~64–68). After #32 mapping, seed `offline` becomes `unavailable` and this gate would still block go-available unless fixed |

---

## Inventory: Page → Controller → UseCase → Repository → Remote

### Auth

| Page / Screen | Controller | UseCase / repo call | Repository | Remote |
|---------------|------------|---------------------|------------|--------|
| `login_screen.dart` | `AuthController` | `requestOtp` | `AuthenticationRepository` | `HttpAuthRemoteDataSource` / Fake |
| `otp_verification_screen.dart` | `AuthController` | `verifyOtp` | same | OTP verify + `Idempotency-Key` |
| `splash_screen.dart` / `session_expired_screen.dart` | `AuthController` | restore / refresh | same | refresh token remote |
| Settings logout | `AuthController.signOut` (+ `AvailabilityController.prepareForLogout`) | `signOut` | same | `POST /v1/auth/logout` |

Paths: `lib/features/auth/presentation/**`, `lib/features/auth/data/repositories/remote_authentication_repository.dart`, `lib/features/auth/data/remote/http_auth_remote_data_source.dart`

### Profile

| Page | Controller | UseCase | Repository | Remote |
|------|------------|---------|------------|--------|
| `profile_screen.dart` | `ProfileController` | `getCurrentProfile` / `getCompliance` | `DriverProfileRepository` | `HttpDriverProfileRemoteDataSource` |
| `profile_edit_screen.dart` | `ProfileController.updateProfile` | `updateCurrentProfile` | same | PATCH + Idempotency-Key |

### Availability

| Page / Widget | Controller | UseCase | Repository | Remote |
|---------------|------------|---------|------------|--------|
| Home `DriverAvailabilityCard` | `AvailabilityController` | `RequestAvailabilityChange` | `RemoteDriverAvailabilityRepository` / Local | `HttpDriverAvailabilityRemoteDataSource` |

Eligibility: `readAvailabilityEligibility` (remote WIP vs deny-safe HEAD).

### Offers

| Page | Controller | UseCase | Repository | Remote |
|------|------------|---------|------------|--------|
| `incoming_delivery_offer_page.dart` + home banner | `DeliveryController` | `GetDeliveryOffers`, `AcceptDeliveryOffer` (+ bind busy), `RejectDeliveryOffer` | `RemoteDeliveryOfferRepository` | `HttpDeliveryRemoteDataSource` / Fake |
| Realtime binder | `RealtimeController` | resync offers on events | coordinator → events remote | `HttpDriverEventsRemote` SSE/poll |

### Delivery lifecycle

| Page | Controller | UseCase | Repository | Remote |
|------|------------|---------|------------|--------|
| `active_delivery_page.dart` | `DeliveryController.advanceWorkflow` | `ConfirmPickupRemote`, local advance, geofence → `ReportAutomaticArrivalRemote` | `RemoteDeliveryLifecycleRepository` / Fake lifecycle + Drift assignment | `HttpDeliveryLifecycleRemote` |
| `delivery_verify_page.dart` | `confirmDelivery` / cancel | `ConfirmDeliveryRemote` / `CancelDeliveryRemote` | same | same |
| `delivery_issue_page.dart` | `reportIssueRemote` / cancel | `ReportDeliveryIssueRemote` / cancel | same | same |

Local ledger: `DriftDeliveryCommandRepository` + `ReplayPendingDeliveryCommands` (not Backend).

### Batches

| Page | Controller | UseCase | Repository | Remote |
|------|------------|---------|------------|--------|
| `batch_*_screen.dart` (offer/pickup/stop/…) | `BatchController` | in-feature Fake service methods | **FakeBatchService** | Lifecycle has `getActiveBatch` / `getBatch` but **UI not wired** |

### Earnings / History / Notifications

| Page | Controller | Repository | Remote |
|------|------------|------------|--------|
| `earnings_screen.dart` (+ detail) | earnings notifier | `FakeEarningsRepository` | **none** |
| `deliveries_history_screen.dart` (+ detail) | history notifier | `FakeDeliveryHistoryRepository` | **none** |
| `notifications_screen.dart` (+ detail) | notifications notifier | `FakeNotificationsRepository` | **none** |

### Vehicle / Documents

| Page | Controller / provider | Repository | Remote |
|------|----------------------|------------|--------|
| `vehicle_overview_screen.dart` / `vehicle_edit_screen.dart` | vehicle feature providers | `FakeVehicleRepository` | **none** |
| `documents_list_screen.dart` / `document_upload_screen.dart` | documents feature providers | `FakeDocumentsRepository` | **none** |

### Home metrics

| Page | Data | Remote |
|------|------|--------|
| `home_screen.dart` `_HomeSummaryStrip` | `fakeHomeSummaryProvider` → `FakeHomeSummary.seed` | **none** (null in production) |

### Navigation / Location

| Page | Controller | Gateway | Notes |
|------|------------|---------|-------|
| Active delivery Maps button | `SaeqContactActionsRow` | Clipboard only | Placeholder for journey nav |
| `map_preview_screen.dart` | `MapPreviewController` | Fake map + optional `UrlLauncherExternalNavigationGateway` | External open on map-preview path; not active-delivery CTA |
| `location_screen.dart` | location providers | Device / Fake location | STEP 4A |

### Support / Settings / Shell

| Page | Wiring |
|------|--------|
| `support_screen.dart` | `FakeSupportRepository` / unavailable |
| `support_safety_screen.dart` | Static l10n |
| `settings_screen.dart` | Locale + logout |
| `comingSoon` route | `ShellPlaceholderScreen` |

---

## Key files (wiring spine)

- DI: `lib/shared/services/app_service_registry.dart`
- Paths: `lib/core/backend_configuration/driver_api_paths.dart`
- Delivery providers: `lib/features/delivery/presentation/providers/delivery_providers.dart`
- Availability wire: `lib/features/availability/data/models/driver_availability_wire.dart`
- Eligibility: `lib/features/availability/presentation/providers/availability_eligibility_reader.dart`
