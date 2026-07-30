# STEP 2D — Item 21 · Figma ⇄ Flutter Node Mapping

> **Baseline:** `6164994ca262535c85bdeafdee822e32ad877da2` (PR #16 Hotfix merge commit)
> **Figma file:** `MNJldEpkMxVjIavCPaPBFh` — SAEQ Driver Design System / UX
> **Primary reference (mandated):** `150:427`
> **Rule:** node names below are read from Figma metadata or from the `150:427`
> “مرجع عقد Figma للمهندس / Changed Nodes” list inside that frame. **No node ID
> and no node name is invented.** Where a name could not be read from Figma in
> this pass, the source is stated explicitly.

## 1. Status vocabulary

| Code | Meaning |
|------|---------|
| `MATCH` | Flutter implements the node’s structure and behaviour, with test evidence |
| `PARTIAL` | Implemented, but part of the node’s behaviour is intentionally deferred |
| `GAP` | Flutter surface exists, no approved node pinned in this pass |
| `FIGMA-ONLY` | Node is a QA/handoff board, not a screen to implement 1:1 |

`Light/Dark`, `AR/EN` and `Responsive` describe **what the node itself
specifies**, and the Flutter evidence that the same axis is covered.

---

## 2. Mandated primary reference

| Node ID | Figma name | Flutter screen / component | Route | Light/Dark | AR/EN | Responsive | Status | Missing behaviour | Test evidence |
|---------|-----------|----------------------------|-------|-----------|-------|------------|--------|-------------------|---------------|
| `150:427` | P27 — Full Visual QA + Mandatory Journey Handoff | Journey contract implemented across `BatchJourneyStage` (`lib/features/batch/batch_view_data.dart`) and `BatchFeature` (`lib/features/batch/batch_feature.dart`) | `/batch/:batchId/*` | Board (Light) | AR board | Board 1900×1864 | `FIGMA-ONLY` (contract) → journey `MATCH` | Real Geofence + GPS accuracy/debounce/background handling (frame item 3) is **deferred to STEP 4**; batch uses a fake location event | `test/features/batch/batch_controller_test.dart` → `exact journey sequence for one stop`, `fake automatic arrival via location controller only`, `no driver action can register the arrival` |

**The three mandatory journey stages required by `150:427`** (`الاستلام من
المتجر` manual → `الوصول إلى العميل` automatic → `تسليم الطلب` manual) map 1:1 to
`BatchJourneyStage.pickupConfirmedManually`,
`BatchJourneyStage.arrivedAutomaticallyByLocation` and
`BatchJourneyStage.deliveredConfirmedManually`.

---

## 3. Mandated P27 node set

| Node ID | Figma name | Flutter screen / component | Route | Light/Dark | AR/EN | Responsive | Status | Missing behaviour | Test evidence |
|---------|-----------|----------------------------|-------|-----------|-------|------------|--------|-------------------|---------------|
| `39:35` | Operational/Timeline Final | `BatchJourneyTimeline` (`lib/features/batch/batch_ui_helpers.dart:480`) | `/batch/:batchId/stop/:sequence` | Both (semantic tokens) | Both | 390 → 320 | `MATCH` | — | `test/features/batch/batch_journey_screens_test.dart` → `dark + narrow 320 + textScale 1.3 without overflow` |
| `138:2714` | Final/Batch/Pickup Confirmed Manual | `BatchManualPickupScreen` (`lib/features/batch/batch_manual_pickup_screen.dart`) | `/batch/:batchId/confirm-pickup` | Both | Both | 390 → 320 | `MATCH` | — | `batch_journey_screens_test.dart` → `Figma 138:2714 manual pickup confirmation structure` |
| `119:406` | Batch/Customer Contact | `BatchCustomerContactCard` (`lib/features/batch/batch_ui_helpers.dart:634`) | `/batch/:batchId/stop/:sequence` | Both | Both | 358 wide card | `MATCH` | — | `batch_journey_screens_test.dart` → `semantics expose contact and automatic arrival` |
| `119:366` | Visibility=Locked | Same card in `BatchCustomerContactVisibility.locked` (masked phone, disabled call) | `/batch/:batchId/stop/:sequence` | Both | AR sample | 358 | `MATCH` | — | `batch_journey_screens_test.dart` → `contact locked before the manual pickup`; `batch_controller_test.dart` → `contact locked before manual pickup` |
| `119:377` | Visibility=Revealed | Same card in `…visibility.revealed` (full phone, address, notes, call + WhatsApp) | `/batch/:batchId/stop/:sequence` | Both | AR sample | 358 | `MATCH` | Call / WhatsApp are **fake attempt counters**, no platform intent | `batch_journey_screens_test.dart` → `contact revealed immediately after the manual pickup`; `batch_controller_test.dart` → `fake call and WhatsApp actions count attempts only` |
| `119:397` | Visibility=Closed | Same card in `…visibility.closed` (PII hidden again) | `/batch/:batchId/stop/:sequence` | Both | AR sample | 358 | `MATCH` | — | `batch_journey_screens_test.dart` → `Figma 125:508 contact closed after delivery`; `batch_controller_test.dart` → `contact closed after delivered or cancelled` |
| `125:370` | Final/Batch/Contact Locked Before Pickup | `BatchStopScreen` locked state | `/batch/:batchId/stop/:sequence` | Light | AR | 390×844 | `MATCH` | — | `batch_journey_screens_test.dart` → `contact locked before the manual pickup` |
| `125:402` | Final/Batch/Arrived Automatically + Contact | `BatchStopScreen` arrived state + `BatchArrivalStatus` | `/batch/:batchId/stop/:sequence` | Light | AR | 390×844 | `MATCH` | Arrival is produced by a **fake** location event (STEP 4 owns real GPS) | `batch_journey_screens_test.dart` → `Figma 125:402 arrived automatically reveals current contact` |
| `125:462` | Button Primary/Manual Delivery Confirmation (child of `125:402`) | `SaeqDeliveryActionButton` wired to `confirmDeliveryManually` | `/batch/:batchId/stop/:sequence` | Both | Both | 358×56 (≥48dp) | `MATCH` | — | `batch_controller_test.dart` → `manual delivery refuses auto-complete before arrival`, `revealed contact does not arm manual delivery` |
| `125:464` | Final/Batch/Customer Unavailable + Phone | `BatchStopScreen` customer-unavailable state | `/batch/:batchId/stop/:sequence` | Light | AR | 390×844 | `MATCH` | — | `batch_journey_screens_test.dart` → `customer unavailable retains current contact only` |
| `125:508` | Final/Batch/Contact Closed After Delivery | `BatchStopScreen` delivered state | `/batch/:batchId/stop/:sequence` | Light | AR | 390×844 | `MATCH` | — | `batch_journey_screens_test.dart` → `Figma 125:508 contact closed after delivery` |
| `115:835` | Status/Automatic GPS Arrival | `BatchArrivalStatus` (`batch_ui_helpers.dart:597`) — read-only, never a button | `/batch/:batchId/stop/:sequence` | Both | Both | 326×48 | `MATCH` | Real geofence deferred (STEP 4) | `batch_controller_test.dart` → `no driver action can register the arrival` |
| `115:890` | Status/Automatic GPS Arrival | Same component, arrived variant | `/batch/:batchId/stop/:sequence` | Both | Both | 326×48 | `MATCH` | Same | `batch_journey_screens_test.dart` → `semantics expose contact and automatic arrival` |
| `115:1000` | Status/Automatic GPS Arrival | Same component, en-route variant | `/batch/:batchId/stop/:sequence` | Both | Both | 326×48 | `MATCH` | Same | `batch_journey_screens_test.dart` → `en-route stop: contact revealed, delivery still locked` |
| `42:1041` | Final/Delivery/Dark | `ActiveDeliveryPage` in dark theme | `/delivery/active` | **Dark** | AR | 390×844 | `PARTIAL` | Dark parity is covered by shared semantic tokens and design-system dark tests, not by a per-screen dark golden for `/delivery/active` | `test/shared/widgets/saeq_design_system_sprint1_completion_test.dart` → `RTL Arabic + dark + large text smoke`, `dark theme extension exposes dark primary token` |
| `106:482` | Final/Location/Arabic Dark | `LocationScreen` available state, dark + AR | `/location` | **Dark** | AR | 390×844 (+320 / 1.3 asserted) | `MATCH` | Fake location fix only; no OS permission dialog | `test/features/location/location_screen_test.dart` → `P27 106:482 Arabic Dark Available and narrow 1.3 is safe` |
| `110:381` | Final/Documents/Arabic Dark | `DocumentsListScreen` dark + AR | `/profile/documents` | **Dark** | AR | 390×844 | `PARTIAL` | No document picker / camera / upload API (metadata-only fixtures) | `test/features/profile/documents/documents_screens_test.dart` |
| `110:443` | Final/A11y/Narrow Documents | `DocumentsListScreen` at 320 dp | `/profile/documents` | Light | AR | **320×720** | `PARTIAL` | Same upload gap as `110:381` | `test/features/profile/documents/documents_screens_test.dart` |
| `115:1307` | Final/Batch/Arabic Dark | `BatchRouteScreen` / batch surfaces, dark + AR (incl. `Batch Multi Stop Map`) | `/batch/:batchId/route` | **Dark** | AR | 390×844 | `MATCH` | Map is CustomPaint — no Map SDK | `test/features/batch/batch_screens_test.dart` → `dark theme and narrow 320px without overflow` |
| `115:1360` | Final/Batch/A11y Narrow | Batch order rows / CTAs at 320 dp | `/batch/:batchId/route` · `/offers/batch/:batchId` | Light | AR | **320×720** | `MATCH` | — | `batch_journey_screens_test.dart` → `dark + narrow 320 + textScale 1.3 without overflow` |

**Coverage of the mandated list:** all 19 mandated P27 node IDs plus `150:427`
are present in the two tables above — `unmapped mandated Figma nodes = 0`.

---

## 4. Additional P27 nodes already carried in code comments

Source for these names/IDs: the `150:427` Changed-Nodes list and the merged
STEP 2B / 2C PRs, quoted in Dart doc comments (file:line given).

| Node ID | Flutter surface | Route | Status | Test evidence |
|---------|-----------------|-------|--------|---------------|
| `115:412` · `115:461` · `115:518` · `115:534` | `BatchOfferScreen` (4-order / 3-order / loading / expired) — `batch_offer_screen.dart:16` | `/offers/batch/:batchId` | `MATCH` | `batch_screens_test.dart` → `P27 115:412 …`, `P27 115:461 …`, `P27 115:518 …`, `P27 115:534 …` |
| `115:370` · `115:379` · `115:399` · `115:383` | `BatchOrderRow` · `BatchMetricChip` · `BatchProgress` · `BatchMultiStopMap` — `batch_ui_helpers.dart:72/176/240/289` | batch routes | `MATCH` | `batch_screens_test.dart` → `masked order id never shows full id`, `BatchOfferViewData progress fraction` |
| `115:581` · `115:637` · `115:693` | `BatchPickupScreen` waiting / ready / verification — `batch_pickup_screen.dart:15` | `/batch/:batchId/pickup` · `/batch/:batchId/verify` | `MATCH` | `batch_controller_test.dart` → `all-required-ready + all-verified gate before manual pickup` |
| `115:737` · `115:1078` | `BatchRouteScreen` overview / restored — `batch_route_screen.dart:17` | `/batch/:batchId/route` | `MATCH` | `batch_controller_test.dart` → `restored snapshot flag` |
| `115:786` · `115:837` · `115:955` | `BatchCurrentStopViewData` — `batch_view_data.dart:302` | `/batch/:batchId/stop/:sequence` | `MATCH` | `batch_journey_screens_test.dart` |
| `115:1002` · `115:1034` | `BatchIssueScreen` — `batch_issue_screen.dart:17` | `/batch/:batchId/issue/:orderId` | `MATCH` | `batch_journey_screens_test.dart` → `Report a problem opens issue with selectable cancel reason` |
| `115:1142` · `115:1196` | `BatchSummaryScreen` — `batch_summary_screen.dart:16` | `/batch/:batchId/summary` | `MATCH` | `batch_controller_test.dart` → `earnings breakdown and return home` |
| `115:1435` | Per-order lifecycle handoff — `batch_view_data.dart:9` | batch routes | `MATCH` | `batch_controller_test.dart` → `merchant cancel on one order continues batch` |
| `106:115` · `106:148` · `106:161` · `106:177` · `106:204` · `106:216` · `106:246` · `106:452` | `LocationScreen` states | `/location` | `MATCH` | `location_screen_test.dart` → one `P27 106:*` test per node |
| `106:276` · `106:288` · `106:304` · `106:433` | `MapPreviewScreen` states | `/map/preview` | `MATCH` | `map_preview_screen_test.dart` → one `P27 106:*` test per node |
| `40:4` | `WelcomeScreen` — `welcome_screen.dart:12` | `/` | `MATCH` | `test/features/auth/presentation/auth_batch2_flow_test.dart` |
| `40:15` … `40:55` · `40:293` · `48:1989` | `LoginScreen` — `login_screen.dart:15` | `/login` | `MATCH` | `login_screen_test.dart` · `login_arabic_localization_test.dart` |
| `40:72` … `48:2024` | `OtpVerificationScreen` — `otp_verification_screen.dart:17` | `/login/otp` | `MATCH` | `test/features/auth/otp_flow_test.dart` |
| `39:2` · `39:6` · `39:13` · `41:160` · `41:211` · `41:273` · `41:308` | `DriverAvailabilityCard` + Home states — `saeq_semantic_colors.dart:88` and `docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md` | `/home` | `MATCH` | `home_availability_batch3_flow_test.dart` · `driver_availability_card_test.dart` |
| `42:872` · `42:883` · `42:892` · `42:916` · `42:925` · `42:946` | Single-order journey frames (listed in `150:427`) | `/delivery/*` | `PARTIAL` | `active_delivery_completion_navigation_test.dart` · `delivery_controller_test.dart` — journey covered, per-node visual parity not asserted |
| `23:71` | 00 — Cover and Decisions (page) | — | `FIGMA-ONLY` | Product rules only (no screen) |

---

## 5. Unmapped production screens

Screens that render in the app with **no approved Figma node pinned in this
pass** (`GAP`). None of them is a STEP 2D code change; they are registered in
the gap register of
[`localization_accessibility_audit.md`](./localization_accessibility_audit.md).

| Flutter screen | Route | Why GAP |
|----------------|-------|---------|
| `SplashScreen` | `/splash` | No Final node pinned in 2A–2C PRs |
| `OnboardingScreen` | `/onboarding` | No Final node pinned |
| `SessionExpiredScreen` | `/session-expired` | No Final node pinned |
| `ShellPlaceholderScreen` | `/coming-soon` | Flutter-only placeholder, no design target |
| `VehicleOverviewScreen` · `VehicleEditScreen` | `/profile/vehicle`, `/profile/vehicle/edit` | STEP 2A PR #13 shipped without node IDs |
| `DocumentUploadScreen` · `DocumentDetailScreen` | `/profile/documents/upload`, `/profile/documents/:id` | Only the list surface has dark/narrow samples (`110:381`, `110:443`) |
| `DeliveriesHistoryScreen` + detail · `EarningsScreen` + detail · `NotificationsScreen` + detail · `SettingsScreen` · `SupportScreen` · `SupportSafetyScreen` · `ProfileScreen` · `ProfileEditScreen` | shell + focus routes | `docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md` carries `DRV-*` design targets by name only, without pinned Final node IDs |

**Counts for this pass**

| Metric | Value |
|--------|-------|
| Mandated nodes required by Item 21 | 20 (`150:427` + 19 P27) |
| Mandated nodes mapped | **20** |
| Unmapped mandated Figma nodes | **0** |
| Additional nodes mapped from code/PR references | 46 node IDs |
| Production screens with a pinned node | 16 |
| Production screens without a pinned node (`GAP`) | 18 |
| Invented node IDs or names | **0** |

**Owner follow-up (not STEP 2D code):** pin Final node IDs for Vehicle /
Documents upload / shell list screens and the remaining Auth system frames, so
that `unmapped production screens` can reach 0 in a later documentation pass.
