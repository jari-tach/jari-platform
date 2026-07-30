# STEP 2D — Item 20 · Route → Controller → Test Matrix

> **Baseline:** `6164994ca262535c85bdeafdee822e32ad877da2` (PR #16 Hotfix merge commit)
> **Route source of truth:** `lib/core/routes/app_router.dart` — **38 `GoRoute`
> entries** plus one redirect (`/orders` → `/deliveries`).
> **Frontend ownership:** Route · Screen · Parameters · Controller/Provider ·
> Widget/Route tests · Device validation.
> **Backend/Domain ownership (ChatGPT):** Repository boundary review · future API
> domain · Fake/Local/Remote classification · deferred contracts. This file
> records only what exists in the repository; **no backend endpoint is guessed.**

## Column semantics

| Column | Meaning |
|--------|---------|
| Authentication guard | `PROTECTED` = matched by `AppRoutes.protectedRoots`; `PUBLIC` = auth-entry route (`AppRoutes.authEntryRoutes`), redirected to `/home` when authenticated |
| Remote implementation | A class that would talk to a backend. `NONE` means no such class; `fake-backed` means the class exists but is wired to an in-memory fake |
| Device validation | STEP 2D itself is documentation-only, so **no new device run was performed**. Entries cite the device evidence of the phase that shipped the surface |
| Deferred step | The step that owns the remaining real behaviour (STEP 3 Fake/Local lifecycle · STEP 4 real GPS/maps · STEP 5 REST backend · STEP 6 realtime · STEP 7 vehicle/documents · STEP 8 driver services) |

---

## 1. Public / auth routes

| Route | Screen | Route parameters | Authentication guard | Controller/Notifier | Provider | Repository interface | Fake implementation | Local implementation | Remote implementation | Unit test | Widget test | Route test | Device validation | Deferred step |
|-------|--------|------------------|----------------------|---------------------|----------|----------------------|---------------------|----------------------|-----------------------|-----------|-------------|------------|-------------------|---------------|
| `/splash` | `SplashScreen` | none | `PUBLIC` | `AuthController` | `authControllerProvider` | `AuthenticationRepository` | `FakeAuthenticationRepository` | `AuthSessionStorage` (secure storage) | NONE | `test/features/auth/presentation/auth_controller_test.dart` | `test/widget_test.dart` → `Splash screen renders on cold start` | `test/features/auth/navigation/auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/` | `WelcomeScreen` | none | `PUBLIC` | `AppLocaleNotifier` · `AppThemeModeNotifier` | `appLocaleProvider` · `appThemeModeProvider` | n/a (preferences) | n/a | `AppPreferences` (SharedPreferences) | NONE | `test/features/settings/app_preferences_test.dart` | `test/widget_test.dart` → `Welcome screen has required elements after Splash tap` | `auth_navigation_test.dart` | PHASE 2.6 device report | — |
| `/onboarding` | `OnboardingScreen` | none | `PUBLIC` | none (local widget state) | — | n/a | n/a | n/a | NONE | — | `test/features/auth/presentation/auth_batch2_flow_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | — |
| `/login` | `LoginScreen` | none | `PUBLIC` | `AuthController` | `authControllerProvider` | `AuthenticationRepository` | `FakeAuthenticationRepository` | `AuthSessionStorage` | NONE | `auth_controller_test.dart` · `test/features/auth/domain/saudi_phone_normalizer_test.dart` | `test/features/auth/presentation/login_screen_test.dart` · `login_arabic_localization_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 (real SMS OTP) |
| `/login/otp` | `OtpVerificationScreen` | query `phone` | `PUBLIC` | `AuthController` | `authControllerProvider` | `AuthenticationRepository` | `FakeAuthenticationRepository` (+ `FakeAuthPolicy` production gate) | `AuthSessionStorage` | NONE | `test/features/auth/data/fake_otp_production_gate_test.dart` · `test/features/auth/domain/fake_auth_policy_test.dart` | `test/features/auth/otp_flow_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/session-expired` | `SessionExpiredScreen` | none | `PUBLIC` | `AuthController` | `authControllerProvider` | `AuthenticationRepository` | `FakeAuthenticationRepository` | `AuthSessionStorage` | NONE | `test/features/auth/domain/session_lifecycle_test.dart` | `test/features/auth/logout_flow_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/coming-soon` | `ShellPlaceholderScreen` | none (title injected from `l10n`) | not protected, not auth-entry → reachable in both states | none | — | n/a | n/a | n/a | NONE | — | `auth_batch2_flow_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | — |

---

## 2. Shell tabs (bottom navigation)

| Route | Screen | Route parameters | Authentication guard | Controller/Notifier | Provider | Repository interface | Fake implementation | Local implementation | Remote implementation | Unit test | Widget test | Route test | Device validation | Deferred step |
|-------|--------|------------------|----------------------|---------------------|----------|----------------------|---------------------|----------------------|-----------------------|-----------|-------------|------------|-------------------|---------------|
| `/home` | `HomeScreen` | none | `PROTECTED` | `AvailabilityController` · `DeliveryController` · `AuthController` | `availabilityControllerProvider` · `deliveryControllerProvider` · `authControllerProvider` · `isOfflineProvider` · `fakeHomeSummaryProvider` | `DriverAvailabilityRepository` · `DeliveryOfferRepository` · `DeliveryAssignmentRepository` | availability fake lives in tests; `FakeDeliveryRemoteDataSource`; `FakeHomeSummary` | `LocalDriverAvailabilityRepository` (SharedPreferences) · `LocalDeliveryAssignmentRepository` (Drift) | `RemoteDeliveryOfferRepository` — **fake-backed** | `test/features/availability/presentation/availability_controller_test.dart` · `test/features/delivery/presentation/delivery_controller_test.dart` | `test/features/driver/presentation/home_screen_phase26_test.dart` · `home_availability_batch3_flow_test.dart` · `home_arabic_localization_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 3 (offer lifecycle) · STEP 5 |
| `/deliveries` | `DeliveriesHistoryScreen` | none | `PROTECTED` | `HistoryController` | `historyControllerProvider` | `DeliveryHistoryRepository` | `FakeDeliveryHistoryRepository` | NONE | NONE | `test/features/history/history_controller_test.dart` | `test/features/history/fake_shell_data_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/earnings` | `EarningsScreen` | none | `PROTECTED` | `EarningsController` | `earningsControllerProvider` | `EarningsRepository` | `FakeEarningsRepository` | NONE | NONE | `test/features/earnings/earnings_controller_test.dart` | `fake_shell_data_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/notifications` | `NotificationsScreen` | none | `PROTECTED` | `NotificationsController` | `notificationsControllerProvider` | `NotificationsRepository` | `FakeNotificationsRepository` | NONE | NONE | `test/features/notifications/notifications_mark_read_test.dart` | `notifications_mark_read_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 6 (push) |
| `/profile` | `ProfileScreen` | none | `PROTECTED` | `ProfileController` | `profileControllerProvider` | `DriverProfileRepository` | `FakeDriverProfileRepository` (+ `FakeProfileSynthesisPolicy`) | NONE | NONE | `test/features/profile/presentation/profile_controller_test.dart` · `test/features/profile/data/fake_driver_profile_repository_test.dart` | `profile_screen_test.dart` · `profile_arabic_localization_test.dart` | `test/features/profile/presentation/profile_screen_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/orders` → `/deliveries` | redirect only | none | `PROTECTED` | — | — | — | — | — | — | — | — | `auth_navigation_test.dart` | — | — |

---

## 3. Focus routes under Profile

| Route | Screen | Route parameters | Authentication guard | Controller/Notifier | Provider | Repository interface | Fake implementation | Local implementation | Remote implementation | Unit test | Widget test | Route test | Device validation | Deferred step |
|-------|--------|------------------|----------------------|---------------------|----------|----------------------|---------------------|----------------------|-----------------------|-----------|-------------|------------|-------------------|---------------|
| `/profile/edit` | `ProfileEditScreen` | none | `PROTECTED` | `ProfileController` | `profileControllerProvider` | `DriverProfileRepository` | `FakeDriverProfileRepository` | NONE | NONE | `test/features/profile/domain/email_validator_test.dart` · `profile_controller_test.dart` | `test/features/profile/profile_edit_test.dart` · `profile_edit_screen_test.dart` | `profile_screen_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/profile/vehicle` | `VehicleOverviewScreen` | none | `PROTECTED` | `VehicleController` | `vehicleControllerProvider` | `VehicleRepository` | `FakeVehicleRepository` | NONE | NONE | `test/features/profile/vehicle/vehicle_screens_test.dart` (controller groups) | `vehicle_screens_test.dart` | `profile_screen_navigation_test.dart` | STEP 2A PR #13 | STEP 7 |
| `/profile/vehicle/edit` | `VehicleEditScreen` | none | `PROTECTED` | `VehicleController` | `vehicleControllerProvider` | `VehicleRepository` | `FakeVehicleRepository` | NONE | NONE | `vehicle_screens_test.dart` | `vehicle_screens_test.dart` | `profile_screen_navigation_test.dart` | STEP 2A PR #13 | STEP 7 |
| `/profile/documents` | `DocumentsListScreen` | none | `PROTECTED` | `DocumentsListController` | `documentsListControllerProvider` | `DocumentsRepository` | `FakeDocumentsRepository` | NONE | NONE | `test/features/profile/documents/documents_screens_test.dart` | `documents_screens_test.dart` | `profile_screen_navigation_test.dart` | STEP 2A PR #13 | STEP 7 |
| `/profile/documents/upload` | `DocumentUploadScreen` | none | `PROTECTED` | `DocumentUploadController` | `documentUploadControllerProvider` | `DocumentsRepository` | `FakeDocumentsRepository` (+ `FakeFileMetadata`) | NONE | NONE | `documents_screens_test.dart` | `documents_screens_test.dart` | `profile_screen_navigation_test.dart` | STEP 2A PR #13 | STEP 7 (picker/camera/upload API) |
| `/profile/documents/:id` | `DocumentDetailScreen` | path `id` | `PROTECTED` | `documentDetailProvider` (FutureProvider.family) | `documentDetailProvider` | `DocumentsRepository` | `FakeDocumentsRepository` | NONE | NONE | `documents_screens_test.dart` | `documents_screens_test.dart` | `profile_screen_navigation_test.dart` | STEP 2A PR #13 | STEP 7 |
| `/settings` | `SettingsScreen` | none | `PROTECTED` | `AppThemeModeNotifier` · `AppLocaleNotifier` · `AuthController` | `appThemeModeProvider` · `appLocaleProvider` · `authControllerProvider` | n/a (preferences) | n/a | `AppPreferences` (SharedPreferences) | NONE | `test/features/settings/app_preferences_test.dart` | `test/features/settings/settings_screen_test.dart` | `test/integration/fake_e2e_flow_h_settings_theme_locale_test.dart` | PHASE 2.6 device report | — |
| `/support` | `SupportScreen` | none | `PROTECTED` | `supportConfigProvider` (FutureProvider) | `supportConfigProvider` · `supportRepositoryProvider` | `SupportRepository` | `FakeSupportRepository` (`SupportConfig.unavailable`) | NONE | NONE | — | `test/features/support/support_screen_test.dart` | `profile_screen_navigation_test.dart` | PHASE 2.6 device report | STEP 8 |
| `/support/safety` | `SupportSafetyScreen` | none | `PROTECTED` | none (static content) | — | n/a | n/a | n/a | NONE | — | `support_screen_test.dart` | `profile_screen_navigation_test.dart` | PHASE 2.6 device report | STEP 8 |

---

## 4. Shell detail routes

| Route | Screen | Route parameters | Authentication guard | Controller/Notifier | Provider | Repository interface | Fake implementation | Local implementation | Remote implementation | Unit test | Widget test | Route test | Device validation | Deferred step |
|-------|--------|------------------|----------------------|---------------------|----------|----------------------|---------------------|----------------------|-----------------------|-----------|-------------|------------|-------------------|---------------|
| `/deliveries/:id` | `DeliveryHistoryDetailScreen` | path `id` | `PROTECTED` | `historyDetailProvider` | `historyDetailProvider` | `DeliveryHistoryRepository` | `FakeDeliveryHistoryRepository` | NONE | NONE | `history_controller_test.dart` | `fake_shell_data_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/earnings/:id` | `EarningsDetailScreen` | path `id` | `PROTECTED` | `earningsDetailProvider` | `earningsDetailProvider` | `EarningsRepository` | `FakeEarningsRepository` | NONE | NONE | `earnings_controller_test.dart` | `fake_shell_data_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/notifications/:id` | `NotificationDetailScreen` | path `id` | `PROTECTED` | `notificationDetailProvider` | `notificationDetailProvider` | `NotificationsRepository` | `FakeNotificationsRepository` | NONE | NONE | `notifications_mark_read_test.dart` | `notifications_mark_read_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 6 |

---

## 5. Single-order delivery (outside shell)

| Route | Screen | Route parameters | Authentication guard | Controller/Notifier | Provider | Repository interface | Fake implementation | Local implementation | Remote implementation | Unit test | Widget test | Route test | Device validation | Deferred step |
|-------|--------|------------------|----------------------|---------------------|----------|----------------------|---------------------|----------------------|-----------------------|-----------|-------------|------------|-------------------|---------------|
| `/delivery/offer` | `IncomingDeliveryOfferPage` | none | `PROTECTED` | `DeliveryController` | `deliveryControllerProvider` | `DeliveryOfferRepository` | `FakeDeliveryRemoteDataSource` · `FakeDeliverySeed` | `LocalDeliveryAssignmentRepository` (Drift) | `RemoteDeliveryOfferRepository` — **fake-backed** | `test/features/delivery/domain/usecases/get_delivery_offers_test.dart` · `accept_delivery_offer_test.dart` · `reject_delivery_offer_test.dart` | `test/features/delivery/presentation/incoming_delivery_offer_page_test.dart` · `delivery_offer_arabic_localization_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | **STEP 3** (Loading Offers defect) · STEP 5 |
| `/delivery/active` | `ActiveDeliveryPage` | none | `PROTECTED` | `DeliveryController` | `deliveryControllerProvider` | `DeliveryAssignmentRepository` | `FakeDeliveryRemoteDataSource` | `LocalDeliveryAssignmentRepository` (Drift) + `DriftDeliveryLocalDataSource` | `RemoteDeliveryOfferRepository` — fake-backed | `test/features/delivery/domain/driver_workflow_test.dart` · `test/features/delivery/application/complete_delivery_and_release_busy_test.dart` | `test/features/delivery/presentation/active_delivery_completion_navigation_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 3 · STEP 4 (real tracking) |
| `/delivery/verify` | `DeliveryVerifyPage` | none | `PROTECTED` | `DeliveryController` | `deliveryControllerProvider` | `DeliveryAssignmentRepository` | `FakeDeliveryVerificationCodes` | Drift assignment | NONE | `test/features/delivery/domain/usecases/get_active_delivery_test.dart` | `active_delivery_completion_navigation_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |
| `/delivery/issue` | `DeliveryIssuePage` | none | `PROTECTED` | `DeliveryController` | `deliveryControllerProvider` | `DeliveryAssignmentRepository` | `FakeDeliveryRemoteDataSource` | Drift assignment | NONE | `test/features/delivery/presentation/delivery_controller_completion_test.dart` | `active_delivery_completion_navigation_test.dart` | `auth_navigation_test.dart` | PHASE 2.6 device report | STEP 5 |

---

## 6. Location / map (STEP 2B)

| Route | Screen | Route parameters | Authentication guard | Controller/Notifier | Provider | Repository interface | Fake implementation | Local implementation | Remote implementation | Unit test | Widget test | Route test | Device validation | Deferred step |
|-------|--------|------------------|----------------------|---------------------|----------|----------------------|---------------------|----------------------|-----------------------|-----------|-------------|------------|-------------------|---------------|
| `/location` | `LocationScreen` | none | `PROTECTED` | `LocationController` | `locationControllerProvider` · `locationServiceProvider` | `LocationService` | `FakeLocationService` | NONE | NONE | `test/features/location/location_screen_test.dart` (controller groups) | `location_screen_test.dart` (9 P27 state tests) | `test/features/location/location_routes_test.dart` | STEP 2B PR #14 | **STEP 4** (real GPS / OS permissions / geofence) |
| `/map/preview` | `MapPreviewScreen` | none | `PROTECTED` | `MapPreviewController` | `mapPreviewControllerProvider` · `mapPreviewServiceProvider` | `MapPreviewService` | `FakeMapPreviewService` · `FakeMapPlaceholder` | NONE | NONE | `map_preview_screen_test.dart` | `map_preview_screen_test.dart` (4 P27 state tests) | `location_routes_test.dart` | STEP 2B PR #14 | **STEP 4** (Map SDK / external nav intents) |

---

## 7. Multi-order batch (STEP 2C + Hotfix PR #16)

All batch routes share `BatchController` / `batchControllerProvider` and the
in-memory `FakeBatchService` (`lib/features/batch/batch_feature.dart`). There is
no repository abstraction beyond `BatchService`, no local persistence and no
remote implementation.

| Route | Screen | Route parameters | Authentication guard | Controller/Notifier | Provider | Repository interface | Fake implementation | Local implementation | Remote implementation | Unit test | Widget test | Route test | Device validation | Deferred step |
|-------|--------|------------------|----------------------|---------------------|----------|----------------------|---------------------|----------------------|-----------------------|-----------|-------------|------------|-------------------|---------------|
| `/offers/batch/:batchId` | `BatchOfferScreen` | path `batchId` | `PROTECTED` | `BatchController` | `batchControllerProvider` · `batchFixtureEntryEnabledProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `test/features/batch/batch_controller_test.dart` | `batch_screens_test.dart` · `batch_entry_card_offers_page_test.dart` | `test/features/batch/batch_routes_test.dart` | STEP 2C PR #15 | STEP 5 · STEP 6 |
| `/batch/:batchId/pickup` | `BatchPickupScreen` | path `batchId` | `PROTECTED` | `BatchController` | `batchControllerProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `batch_controller_test.dart` → `all-required-ready + all-verified gate before manual pickup` | `batch_journey_screens_test.dart` | `batch_routes_test.dart` | STEP 2C PR #15 | STEP 5 |
| `/batch/:batchId/verify` | `BatchVerifyScreen` | path `batchId` | `PROTECTED` | `BatchController` | `batchControllerProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `batch_controller_test.dart` → `verification alone does not complete pickup or open route` | `batch_journey_screens_test.dart` | `batch_routes_test.dart` | STEP 2C PR #15 | STEP 5 |
| `/batch/:batchId/confirm-pickup` | `BatchManualPickupScreen` | path `batchId` | `PROTECTED` | `BatchController` | `batchControllerProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `batch_controller_test.dart` → `manual pickup has processing + duplicate-tap guard then route` | `batch_journey_screens_test.dart` → `Figma 138:2714 …` | `batch_routes_test.dart` | STEP 2C PR #15 | STEP 5 |
| `/batch/:batchId/route` | `BatchRouteScreen` | path `batchId` | `PROTECTED` | `BatchController` | `batchControllerProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `batch_controller_test.dart` → `offline queue on stop 2 then recovery`, `restored snapshot flag` | `batch_journey_screens_test.dart` | `batch_routes_test.dart` | STEP 2C PR #15 | STEP 4 (real map) · STEP 6 |
| `/batch/:batchId/stop/:sequence` | `BatchStopScreen` | path `batchId`, `sequence` (int) | `PROTECTED` | `BatchController` (+ `FakeBatchLocationController` for fake arrival) | `batchControllerProvider` · `fakeBatchLocationControllerProvider` · `fakeBatchArrivalDelayProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `batch_controller_test.dart` → contact + arrival + delivery groups (12 tests) | `batch_journey_screens_test.dart` → contact locked / revealed / en-route / arrived / unavailable / closed / semantics | `batch_routes_test.dart` | **Hotfix PR #16 device run (HONOR): manual pickup → route → stop → PII revealed with delivery locked → fake arrival → delivery enabled → confirm → PII hidden; crash 0 / freeze 0 / NOT CONNECTED 0** | **STEP 4** (real geofence) · STEP 5 |
| `/batch/:batchId/issue/:orderId` | `BatchIssueScreen` | path `batchId`, `orderId` | `PROTECTED` | `BatchController` | `batchControllerProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `batch_controller_test.dart` → `merchant cancel on one order continues batch` | `batch_journey_screens_test.dart` → `Report a problem opens issue with selectable cancel reason` | `batch_routes_test.dart` | STEP 2C PR #15 | STEP 5 |
| `/batch/:batchId/summary` | `BatchSummaryScreen` | path `batchId` | `PROTECTED` | `BatchController` | `batchControllerProvider` | `BatchService` | `FakeBatchService` | NONE | NONE | `batch_controller_test.dart` → `finish batch only when all resolved`, `earnings breakdown and return home` | `batch_journey_screens_test.dart` | `batch_routes_test.dart` | STEP 2C PR #15 | STEP 5 |

---

## 8. Modal surfaces (no route of their own)

| Surface | Host route | Controller | Widget test |
|---------|-----------|------------|-------------|
| `SaeqConfirmDialog` | `/offers/batch/:batchId` (reject / leave) | local widget state | `test/shared/widgets/saeq_design_kit_test.dart` → `SaeqConfirmDialog returns true on confirm` |
| `SaeqDestructiveDialog` | `/profile`, `/settings` (logout) | `authControllerProvider` + availability logout use case | `saeq_design_kit_test.dart` → `SaeqDestructiveDialog cancel returns false` · `settings_screen_test.dart` |
| `SaeqBottomSheetScaffold.show` (issue type) | `/delivery/issue` | `deliveryControllerProvider` | `test/shared/widgets/design_sprint2_inc3_widgets_test.dart` |
| Router `errorBuilder` page | unknown URI | none | `auth_navigation_test.dart` |

---

## 9. Coverage summary

| Metric | Value |
|--------|-------|
| `GoRoute` entries in `app_router.dart` | **38** |
| Redirects | 1 (`/orders` → `/deliveries`) |
| Routes with at least one widget or route test | **38 / 38** |
| Routes with a dedicated route-resolution test | 38 (`auth_navigation_test.dart`, `location_routes_test.dart`, `batch_routes_test.dart`, `profile_screen_navigation_test.dart`) |
| Routes whose data is Fake or Local only | **38 / 38** |
| Routes wired to a real backend | **0** |
| Device validation performed inside STEP 2D | **0 — NOT REQUIRED** (documentation-only step) |

**Backend/Domain handoff status:** Official handoff is recorded in
[`backend_domain_handoff.md`](./backend_domain_handoff.md) (source package
`STEP2D_Backend_Domain_Handoff.md` + draft contracts `0.1.0-draft`). Future-remote
cells remain **DRAFT CONTRACT ONLY** — Backend server **NOT STARTED**, production
**NOT CONNECTED**. No API path, verb, or production schema is approved for Flutter
wiring here.
