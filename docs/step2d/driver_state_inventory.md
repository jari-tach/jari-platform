# STEP 2D — Item 19 · Driver State Inventory

> Baseline: `6164994ca262535c85bdeafdee822e32ad877da2`  
> Normalized owner vocabulary: **Loading, Empty, Success, Error, Offline, Processing, Permission denied, Permission permanently denied, Disabled, Expired, Cancelled, Restored, Pending sync, Completed**. Static pages use `Success`.

## State-selector finding

**No visible production state selector exists.** `LocationController.selectScenario`, `MapPreviewController.selectScenario`, and non-default `BatchController.loadOffer(scenario:)` are controller/test APIs only. The only user-surface fixture entry is `BatchOfferEntryCard`, gated by `batchFixtureEntryEnabledProvider = kDebugMode && !AppConfig.isProduction`. `main.dart` supplies no provider overrides.

`Production reachability` below means reachability with `AppConfig.isProduction`, not merely a release build. A release build can still default to `Environment.dev`; auth and delivery fakes additionally hard-block `kReleaseMode`.

## Per-screen applicable states

| Screen / route | State | How reached | Controller/Provider | Fake/Local/Production | Figma node | Widget test | Naturally reachable | Developer-only entry | Deferred? |
|---|---|---|---|---|---|---|---|---|---|
| Splash `/splash` | Loading | Cold-start timer | none | Static | GAP — no pinned node | `auth_batch2_flow_test.dart` | Yes | No | No |
| Welcome `/` | Success | Splash completes/auth redirect | `appLocaleProvider`, `appThemeModeProvider` | Local preferences | `40:4` | `widget_test.dart`; `auth_batch2_flow_test.dart` | Yes | No | No |
| Onboarding `/onboarding` | Success | Welcome Start | local widget state | Static | GAP — no pinned node | `auth_batch2_flow_test.dart` | Yes | No | No |
| Session expired `/session-expired` | Expired | Auth expiry/deep link | `authControllerProvider` | Fake + Local; no production auth adapter | GAP — no pinned node | `auth_batch2_flow_test.dart`; `logout_flow_test.dart` | Route yes; real expiry unverified | No | STEP 5 auth |
| Coming soon `/coming-soon` | Empty | Direct route only | none | Static | GAP — no pinned node | Route test only | No in-app call site | No | Yes |
| Login `/login` | Success | Public entry/redirect; idle form | `authControllerProvider` | Fake auth + Local secure session | `40:15…40:55`, `40:293`, `48:1989` | `login_screen_test.dart` | Non-production only | No | STEP 5 |
| Login `/login` | Processing | OTP request | same | Fake | same | disabled-button/request tests | Non-production only | No | STEP 5 |
| Login `/login` | Error | Invalid phone/repository failure | same | Validation + Fake | same | validation/rejected sign-in tests; blocking failure widget GAP | Yes for validation | No | Blocking-state test gap |
| Login `/login` | Expired | `SessionExpiredError` listener | same | Fake | same | Batch 2 session route test | Unverified in production | No | STEP 5 |
| OTP `/login/otp` | Success | OTP requested; awaiting code | `authControllerProvider` | Fake + Local | `40:72…48:2024` | `otp_flow_test.dart` | Non-production only | No | STEP 5 |
| OTP `/login/otp` | Processing | Verify/resend | same | Fake | same | disabled/verify tests | Non-production only | No | STEP 5 |
| OTP `/login/otp` | Error | Invalid/incomplete/rate-limited/storage/unexpected | same | Fake | same | invalid OTP; blocking-state widget GAP | Non-production only | No | STEP 5 |
| OTP `/login/otp` | Expired | Expired challenge | same | Fake | same | expired OTP/resend test | Non-production only | No | STEP 5 |
| Home `/home` | Success | Authenticated dashboard | `authControllerProvider`, `fakeHomeSummaryProvider`, delivery providers | Fake summary + Local prefs/assignment | Home nodes `39:*`, `41:*` | `home_screen_phase26_test.dart`; `home_availability_batch3_flow_test.dart` | Shell yes; summary no in production | No | Backend summary STEP 5 |
| Home `/home` | Empty | No offer and no active assignment | `deliveryControllerProvider` | Fake remote/Local Drift | same | Dedicated empty-hint test GAP | Yes | No | No |
| Home `/home` | Offline | Device network offline | `isOfflineProvider` | Local/device | same | offline-banner test | Yes | No | No |
| Availability card on Home | Loading | Controller initialize | `availabilityControllerProvider` | Local SharedPreferences | same | availability flow tests | Yes when repository available | No | No |
| Availability card on Home | Processing | Toggle available/unavailable | same | Local | same | processing disables CTA | Yes | No | No |
| Availability card on Home | Pending sync | Availability requested, awaiting authority | same | Local; debug confirmer can simulate authority | same | pending→confirmed flow | Yes as local state | Debug confirmer only | STEP 5 authority |
| Availability card on Home | Restored | Cold restore of unconfirmed availability | same | Local | same | restored warning test | Yes | No | No |
| Availability card on Home | Disabled | Busy/active assignment or ineligible | same | Local assignment link | same | Busy M4/M5/M7 tests | Yes with local assignment | No | No |
| Availability card on Home | Error | Local repository failure | same | Local | same | failure/retry test | Yes | No | No |
| Deliveries `/deliveries` | Loading | Controller load | `historyControllerProvider` | Fake; null in production | GAP — no pinned node | Controller test only | Production shows unavailable/error | No | STEP 5 |
| Deliveries `/deliveries` | Empty | Repository returns no items | same | Fake | GAP | Dedicated screen widget GAP | Test override only | No | STEP 5 |
| Deliveries `/deliveries` | Success | Fake seed loads/filter selected | same | Fake | GAP | Controller/filter tests only | No production seed | No | STEP 5 |
| Deliveries `/deliveries` | Error | Failure/null repository | same | Fake/null | GAP | Controller failure test | Yes in production | No | STEP 5 |
| Deliveries `/deliveries` | Cancelled | Cancelled filter | same | Fake | GAP | Filter tests | Non-production | No | STEP 5 |
| Delivery history detail `/deliveries/:id` | Loading / Empty / Success / Error | `historyDetailProvider` resolves/misses/fails | `historyDetailProvider` | Fake; null in production | GAP | No dedicated detail widget test | Success no in production | No | STEP 5 |
| Earnings `/earnings` | Loading / Empty / Success / Error | Controller load/result/failure | `earningsControllerProvider` | Fake; null in production | GAP | `earnings_controller_test.dart`; no full screen matrix | Error/unavailable in production | No | STEP 5 |
| Earnings detail `/earnings/:id` | Loading / Empty / Success / Error | Detail provider resolves/misses/fails | `earningsDetailProvider` | Fake | GAP | No dedicated detail widget test | No production success | No | STEP 5 |
| Notifications `/notifications` | Loading / Empty / Success / Error | Controller load/result/failure | `notificationsControllerProvider` | Fake; null in production | GAP | `notifications_mark_read_test.dart` | Error/unavailable in production | No | STEP 6 |
| Notifications `/notifications` | Processing | Mark read | same | Fake memory | GAP | mark-read tests | No production repository | No | STEP 6 |
| Notification detail `/notifications/:id` | Loading / Empty / Success / Error | Detail provider resolves/misses/fails | `notificationDetailProvider` | Fake | GAP | mark-read/detail invalidation test | No production success | No | STEP 6 |
| Profile `/profile` | Loading | Profile load | `profileControllerProvider` | Fake + Drift cache; null in production | GAP | Dedicated loading widget GAP | No production repository | No | STEP 5 |
| Profile `/profile` | Empty | No profile | same | Fake/Local | GAP | `profile_screen_test.dart` empty state | UI reachable through override | No | STEP 5 |
| Profile `/profile` | Success | Synthetic/cached profile loaded | same | Fake + Local Drift | GAP | profile screen/localization tests | No current production wiring | No | STEP 5 |
| Profile `/profile` | Error | Load failure | same | Fake/null | GAP | Dedicated error widget GAP | Production unavailable path possible | No | STEP 5 |
| Profile `/profile` | Expired | `ProfileViewStatus.sessionExpired` | same | Fake | GAP | Controller only | Unverified | No | STEP 5 |
| Profile edit `/profile/edit` | Success | Loaded form/save succeeds | `profileControllerProvider` | Fake + Local Drift | GAP | `profile_edit_*_test.dart` | No production repository | No | STEP 5 |
| Profile edit `/profile/edit` | Processing | Save in flight | same | Fake | GAP | save tests | No production repository | No | STEP 5 |
| Profile edit `/profile/edit` | Error | Validation/update failure | same | Fake | GAP | validation/error tests | Validation naturally reachable | No | STEP 5 |
| Vehicle overview `/profile/vehicle` | Loading / Empty / Success / Error / Offline | `VehicleViewStatus` from selected repository mode | `vehicleControllerProvider` | Fake; null in production | GAP | `vehicle_screens_test.dart` | Success no in production | No visible selector | STEP 7 |
| Vehicle edit `/profile/vehicle/edit` | Success / Processing / Error / Offline / Disabled | Loaded/editing; save; validation/failure; saving disables | same | Fake | GAP | `vehicle_screens_test.dart` | Validation yes; remote success no | No | STEP 7 |
| Documents list `/profile/documents` | Loading / Empty / Success / Error / Offline | `DocumentsViewStatus` from repository mode | `documentsListControllerProvider` | Fake; null in production | `110:381`, `110:443` | `documents_screens_test.dart` | Success no in production | No visible selector | STEP 7 |
| Documents list rows | Success / Error / Expired | Approved/under review/rejected/expiring/expired metadata | same | Fake metadata | same | review-status test | No production data | No | STEP 7 |
| Document upload `/profile/documents/upload` | Success / Processing / Error / Disabled | File selected/uploading/success/failure/validation; CTA disabled while invalid/busy | `documentUploadControllerProvider` | Fake metadata/in-memory | GAP | `documents_screens_test.dart` | No real picker/upload | No | STEP 7 |
| Document detail `/profile/documents/:id` | Loading / Empty / Success / Error / Expired | Detail lookup and review status | `documentDetailProvider` | Fake | GAP | approved/rejected/expired detail tests | No production data | No | STEP 7 |
| Settings `/settings` | Success | Toggle locale/theme | `appLocaleProvider`, `appThemeModeProvider` | Local SharedPreferences | GAP | `settings_screen_test.dart` | Yes | No | No |
| Settings `/settings` | Processing | Confirm sign-out | `authControllerProvider` | Fake auth + Local secure session | GAP | sign-out tests | No current production auth | No | STEP 5 |
| Support `/support` | Loading | Config provider resolves | `supportConfigProvider` | Fake; null in production | GAP | Loading test not identified | Yes briefly | No | STEP 8 |
| Support `/support` | Empty / Error | Unavailable/null/error config | same | Fake/null | GAP | unavailable contact state test | Yes in production | No | STEP 8 |
| Support `/support` | Success | FAQ/config fixture | same | Fake | GAP | FAQ/safety navigation test | No production config | No | STEP 8 |
| Safety `/support/safety` | Success | Static route content | none | Static localization | GAP | `support_screen_test.dart` | Route yes if authenticated | No | STEP 8 content governance |
| Offer `/delivery/offer` | Loading | Controller initialization/poll | `deliveryControllerProvider` | Fake remote + Local Drift | `42:872…42:946` partial | loading→empty test | Production remote absent | No | STEP 3/5 |
| Offer `/delivery/offer` | Empty | No offer/assignment | same | Fake/null | same | empty/reject-clears tests | Yes | No | No |
| Offer `/delivery/offer` | Success | Fake offer or local assignment | same | Fake offer; Local Drift assignment | same | offer-card/assignment tests | Assignment only if locally persisted | No | STEP 5 |
| Offer `/delivery/offer` | Processing | Accept/reject | same | Fake | same | duplicate-tap tests | No production authority | No | STEP 3/5 |
| Offer `/delivery/offer` | Error | Load/action failure | same | Fake/null | same | retry and inline failure tests | Unavailable/error in production | No | STEP 5 |
| Offer `/delivery/offer` | Expired | Offer countdown reaches expiry | same | Fake | `115:534` is batch-only; no pinned single node | Dedicated single-offer expiry widget GAP | No production offer | No | STEP 5 |
| Offer `/delivery/offer` | Cancelled | `cancelled`/`takenByOther` remote status | same | Fake | GAP | Dedicated page test GAP | No production remote | No | STEP 5/6 |
| Active delivery `/delivery/active` | Loading / Empty | Initialize/no assignment | `deliveryControllerProvider` | Local Drift + fake authority | `42:1041` partial | Dedicated loading/empty GAP | Empty yes | No | STEP 3 |
| Active delivery `/delivery/active` | Success | Assignment workflow stage | same | Local Drift | same | completion/navigation tests | Yes with persisted assignment | No | STEP 5 authority |
| Active delivery `/delivery/active` | Processing / Disabled | Stage command in flight; CTA disabled | same | Local | same | rapid-tap tests | Yes | No | No |
| Active delivery `/delivery/active` | Error | Stage advance fails | same | Local | same | failure-on-summary test | Yes | No | No |
| Active delivery `/delivery/active` | Offline | Connectivity provider offline | `isOfflineProvider` | Local/device | same | Dedicated active-page offline test GAP | Yes | No | No |
| Active delivery `/delivery/active` | Completed | Finish summary and navigate Home | `deliveryControllerProvider` | Local | same | completion navigation test | Yes with assignment | No | No |
| Delivery verify `/delivery/verify` | Processing / Disabled | Verification command; input/CTA disabled | `deliveryControllerProvider` | Local assignment + fake code | journey nodes partial | completion tests | Yes with assignment | No | STEP 5 |
| Delivery verify `/delivery/verify` | Error / Success | Invalid/failing code or return to active | same | Local + fake code | same | success/failure tests | Fake verification only | No | STEP 5 |
| Delivery issue `/delivery/issue` | Processing / Error / Success | Submit issue; failure or return active | `deliveryControllerProvider` | Local assignment/fake authority | journey nodes partial | completion navigation tests | Yes with assignment | No | STEP 5 |
| Location `/location` | Empty | Permission intro | `locationControllerProvider` | Fake; null in production | `106:115` | `location_screen_test.dart` | Route yes; fake service no in production | No | STEP 4 |
| Location `/location` | Permission denied | `selectScenario(permissionDenied)` | same | Fake | `106:148` | P27 test | No UI path | Controller/test only | STEP 4 |
| Location `/location` | Permission permanently denied | `selectScenario(permissionPermanentlyDenied)` | same | Fake | `106:161` | P27 test | No UI path | Controller/test only | STEP 4 |
| Location `/location` | Disabled | GPS disabled scenario | same | Fake | `106:177` | P27 test | No UI path | Controller/test only | STEP 4 |
| Location `/location` | Loading / Processing | Allow/retry probe | same | Fake | `106:204` | P27 test | Non-production Fake only | No | STEP 4 |
| Location `/location` | Success | Available/weak accuracy result | same | Fake | `106:216`, `106:246`, `106:482` | P27 locale/dark/narrow tests | No production service | Weak scenario controller-only | STEP 4 |
| Location `/location` | Offline | Offline scenario | same | Fake | `106:452` | Dedicated offline widget test GAP | No UI path | Controller/test only | STEP 4 |
| Location `/location` | Error | Service unavailable/null | same | Production null | GAP | Dedicated widget test GAP | Yes in production | No | STEP 4 |
| Map `/map/preview` | Loading | Auto-load | `mapPreviewControllerProvider` | Fake; null in production | `106:276` | P27 test | Production unavailable/error | No | STEP 4 |
| Map `/map/preview` | Success | Placeholder loaded | same | Fake | mapped location set | Success assertion partial | No production service | No | STEP 4 |
| Map `/map/preview` | Error | Error scenario/retry | same | Fake | `106:288` | P27 test | No UI selector | Controller/test only | STEP 4 |
| Map `/map/preview` | Offline | Offline scenario | same | Fake | `106:304` | P27 test | No UI selector | Controller/test only | STEP 4 |
| Map `/map/preview` | Disabled | External navigation unavailable | same | Fake always returns false | `106:433` | P27 test | No real external intent | No | STEP 4 |
| Batch offer `/offers/batch/:batchId` | Loading / Success / Processing / Expired / Error / Offline | Default load; accept/reject; selected scenario/null service | `batchControllerProvider` | Fake; null in production | `115:412`, `115:461`, `115:518`, `115:534` | `batch_screens_test.dart` | No production entry/success | Entry debug-only; non-default scenarios test-only | STEP 5/6 |
| Batch pickup `/batch/:batchId/pickup` | Success / Processing / Error | Waiting→ready→verified; confirm; verification error | same | Fake | `115:581`, `115:637`, `115:693` | journey/controller tests | No production entry | Yes | STEP 5 |
| Batch verify `/batch/:batchId/verify` | Success / Processing / Error | Verification and failure path | same | Fake | `115:693` | journey/controller tests | No production entry | Yes | STEP 5 |
| Batch manual pickup `/batch/:batchId/confirm-pickup` | Processing / Success | Manual confirmation→route | same | Fake | `138:2714` | `batch_journey_screens_test.dart` | No production entry | Yes | STEP 5 |
| Batch route `/batch/:batchId/route` | Success | Overview/active/final stop | same | Fake | `115:737`, `115:1307` | batch screen/journey tests | No production entry | Yes | STEP 4/5 |
| Batch route `/batch/:batchId/route` | Restored | `markRestoredFromSnapshot` | same | In-memory marker only | `115:1078` | Unit test | No UI caller | Controller/test only | Persistence STEP 5/6 |
| Batch route `/batch/:batchId/route` | Processing | Route action in flight | same | Fake | mapped batch set | Controller tests | No production entry | Yes | STEP 5 |
| Batch stop `/batch/:batchId/stop/:sequence` | Pending sync | `offlineQueue`/`deliveredPendingSync` | same | In-memory Fake marker | batch stop nodes | offline queue/recovery tests | No production entry | Yes | STEP 6 |
| Batch stop `/batch/:batchId/stop/:sequence` | Cancelled | Merchant-cancel issue outcome | same | Fake | `125:508`/lifecycle mapping | merchant-cancel tests | No production entry | Yes | STEP 5/6 |
| Batch stop `/batch/:batchId/stop/:sequence` | Success | En route; contact reveal; automatic arrival | `batchControllerProvider`, `fakeBatchLocationControllerProvider` | Fake | `125:370`, `125:402`, contact/arrival nodes | contact/arrival tests | No production entry | Yes | STEP 4/5 |
| Batch stop `/batch/:batchId/stop/:sequence` | Disabled | Delivery CTA before automatic arrival | same | Fake | `125:462`, `115:1000` | delivery gate tests | No production entry | Yes | STEP 4 |
| Batch stop `/batch/:batchId/stop/:sequence` | Processing / Completed | Manual delivery after arrival; order closes | same | Fake | `125:402`, `125:508` | journey/controller tests | No production entry | Yes | STEP 5/6 |
| Batch issue `/batch/:batchId/issue/:orderId` | Success / Processing / Cancelled | Select reason; submit; merchant cancel | `batchControllerProvider` | Fake | `115:1002`, `115:1034` | journey/controller tests | No production entry | Yes | STEP 5 |
| Batch summary `/batch/:batchId/summary` | Completed / Cancelled / Success | All resolved; partial/cancelled-order summary; earnings toggle/return | same | Fake | `115:1142`, `115:1196` | journey/controller tests | No production entry | Yes | STEP 5 |
| Sign-out dialogs | Success | Cancel or confirm | `authControllerProvider` | Fake + Local | GAP — no pinned node | dialog/profile/settings tests | Host naturally reachable | No | STEP 5 auth |
| Batch leave dialog | Success | Back/leave; cancel or confirm | local state + batch controller | Fake | GAP — no pinned node | shared dialog + indirect screen tests | Batch only | Yes | STEP 5 |
| Issue category sheet | Success | Helper selection | `deliveryControllerProvider` | Local/Fake | GAP — no pinned node | Shared scaffold only | No caller | No | Deferred/unwired |
| Router error page | Error | Unknown URI | none | Static | GAP — no pinned node | `auth_navigation_test.dart` | Yes via bad URI | No | No |

## Hotfix contact visibility and automatic arrival

| State | How reached | Visible data/actions | Delivery confirmation |
|---|---|---|---|
| `locked` | No current order, before manual pickup, or non-current unresolved order | Masked phone; no full address/notes; actions disabled | Disabled |
| `revealed` | Current order is picked up (`pickedUp`, `headingToCustomer`, `arrived`, or `customerUnavailable`) | Synthetic phone/address/notes; fake Call/WhatsApp counters | Still disabled until automatic arrival |
| `revealed` + `arrivedAutomaticallyByLocation` | Fake location signal `atCustomer` fires automatically | Contact remains visible | Enabled for manual confirmation |
| `closed` | Non-current order resolved by delivery/cancellation | PII hidden again | Not applicable |

`customerUnavailable` intentionally retains revealed contact until the final outcome. No driver action can register arrival. Real geofence/location behavior is deferred to STEP 4. Banner copy that can imply reveal only at arrival remains a documented copy gap.

## Complete enum/value catalogue

The following **52 enums / 280 ordered values** are present in the audited state extract:

| Enum | Ordered values |
|---|---|
| `AuthenticationStatus` | `unknown`, `authenticated`, `unauthenticated` |
| `AuthControllerStatus` | `initial`, `restoring`, `unauthenticated`, `authenticating`, `requestingOtp`, `otpRequested`, `verifyingOtp`, `authenticated`, `signingOut`, `expired`, `failure` |
| `SessionLifecycle` | `unknown`, `unauthenticated`, `authenticating`, `authenticated`, `expired`, `failed` |
| `AvailabilityStatus` | `offline`, `unavailable`, `available`, `busy` |
| `AvailabilitySource` | `localUserAction`, `system`, `server`, `restoredLocalState`, `connectivityPolicy` |
| `AvailabilityActor` | `driver`, `system`, `backend`, `connectivity` |
| `AvailabilityViewStatus` | `initial`, `loading`, `ready`, `processing`, `failure` |
| `AvailabilityRequiredAction` | `none`, `signIn`, `completeProfile`, `waitConnectivity`, `contactSupport`, `waitAssignment` |
| `DeliveryStatus` | `accepted`, `pickedUp`, `delivered`, `cancelled` |
| `DeliveryOfferStatus` | `none`, `offered`, `accepting`, `rejecting`, `accepted`, `rejected`, `expired`, `takenByOther`, `cancelled`, `failed` |
| `DriverWorkflowStage` | `assigned`, `navToPickup`, `arrivedPickup`, `waitingPickup`, `collected`, `navToCustomer`, `arrivedCustomer`, `verifying`, `delivered`, `summary`, `issueOpen` |
| `DriverWorkflowCommand` | `startTripPickup`, `arrivedPickup`, `waitAtPickup`, `confirmPickup`, `startTripCustomer`, `arrivedCustomer`, `startVerify`, `completeDelivery`, `showSummary`, `reportIssue`, `resumeAfterIssue` |
| `DeliveryViewStatus` | `initial`, `loading`, `ready`, `processing`, `failure` |
| `DeliveryProcessingAction` | `none`, `accepting`, `rejecting`, `refreshing`, `advancing`, `verifying`, `completing` |
| `LocationViewStatus` | `permissionIntro`, `permissionDenied`, `permissionPermanentlyDenied`, `gpsDisabled`, `locating`, `available`, `weakAccuracy`, `offline` |
| `LocationAccuracyLevel` | `unknown`, `high`, `weak` |
| `FakeLocationScenario` | `permissionGranted`, `permissionDenied`, `permissionPermanentlyDenied`, `gpsDisabled`, `weakAccuracy`, `offline` |
| `LocationProbeOutcome` | `available`, `weakAccuracy`, `permissionDenied`, `permissionPermanentlyDenied`, `gpsDisabled`, `offline` |
| `MapPreviewStatus` | `loading`, `loadedPlaceholder`, `error`, `offline`, `externalNavigationUnavailable` |
| `FakeMapScenario` | `seeded`, `error`, `offline` |
| `BatchOfferViewStatus` | `loading`, `threeOrders`, `fourOrders`, `acceptProcessing`, `rejectProcessing`, `expired`, `error`, `offline`, `accepted`, `rejected` |
| `BatchPickupStatus` | `waiting`, `partiallyReady`, `allReady`, `verification`, `verificationError`, `awaitingManualConfirmation`, `processing`, `pickupConfirmed` |
| `BatchRouteStatus` | `overview`, `activeStop1`, `activeStop2`, `activeStop`, `finalStop`, `offlineQueue`, `restoredAfterRestart`, `orderCancelledContinue`, `customerUnavailable`, `deliveryIssue`, `processing` |
| `BatchSummaryStatus` | `completed`, `partial`, `cancelledOrderIncluded`, `earningsBreakdown`, `returnHome` |
| `FakeBatchScenario` | `fourOrders`, `threeOrders`, `expired`, `error`, `offline` |
| `FakeBatchLocationSignal` | `idle`, `approachingCustomer`, `atCustomer` |
| `BatchOrderState` | `offered`, `preparing`, `readyForPickup`, `pickedUp`, `verified`, `headingToCustomer`, `arrived`, `delivered`, `deliveredPendingSync`, `customerUnavailable`, `cancelled`, `expired` |
| `BatchJourneyStage` | `pickupAwaitingManualConfirmation`, `pickupConfirmedManually`, `enRouteToCustomer`, `arrivedAutomaticallyByLocation`, `deliveryAwaitingManualConfirmation`, `deliveredConfirmedManually` |
| `BatchCustomerContactVisibility` | `locked`, `revealed`, `closed` |
| `BatchOrderIssueReason` | `none`, `customerUnavailable`, `merchantCancelled`, `addressUnreachable` |
| `ProfileViewStatus` | `initial`, `loading`, `success`, `empty`, `error`, `sessionExpired` |
| `AccountStatus` | `pending`, `verified`, `rejected`, `suspended` |
| `EmploymentStatus` | `active`, `inactive`, `onLeave`, `terminated` |
| `DriverProfileProvenance` | `trialSynthetic`, `unknown` |
| `VehicleApprovalStatus` | `approved`, `underReview`, `rejected` |
| `FakeVehicleMode` | `seeded`, `empty`, `error`, `offline` |
| `VehicleViewStatus` | `loading`, `loaded`, `empty`, `error`, `editing`, `saving`, `saveSuccess`, `validationError`, `offline` |
| `DocumentReviewStatus` | `approved`, `underReview`, `rejected`, `expiringSoon`, `expired` |
| `DocumentType` | `nationalId`, `driverLicense`, `vehicleRegistration`, `insurance` |
| `DocumentEligibilityImpact` | `none`, `blocksAvailability`, `blocksVehicleApproval`, `requiresRenewal` |
| `DocumentRejectionReasonCode` | `plateNumberMismatch` |
| `FakeDocumentsMode` | `seeded`, `empty`, `error`, `offline` |
| `DocumentsViewStatus` | `loading`, `loaded`, `empty`, `error`, `offline` |
| `DocumentUploadStatus` | `initial`, `fileSelected`, `validationError`, `uploading`, `uploadFailure`, `uploadSuccess` |
| `DeliveryHistoryFilter` | `all`, `delivered`, `cancelled` |
| `EarningsFilter` | `all`, `today`, `week`, `month` |
| `ConnectivityStatus` | `online`, `offline`, `unknown` |
| `SyncStatus` | `idle`, `syncing`, `error`, `completed` |
| `QueueItemStatus` | `pending`, `syncing`, `completed`, `failed` |
| `SaeqStatusTone` | `neutral`, `success`, `warning`, `danger`, `busy` |
| `P27BannerTone` | `information`, `success`, `warning`, `error` |
| `Environment` | `dev`, `staging`, `production` |

Private presentation enums `_PrimaryAction` and `_ChipTone` also exist in `driver_availability_card.dart`; they are intentionally excluded from the public/domain count. `SyncStatus` and `QueueItemStatus` are not proven as first-class route-level visuals; batch uses its own pending-sync states.
