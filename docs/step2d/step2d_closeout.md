# STEP 2D — Item 24 · Driver UI Inventory and Closeout

> Status: **OPEN — pending commit and CI**  
> Baseline SHA: `6164994ca262535c85bdeafdee822e32ad877da2` (PR #16 Hotfix merge)  
> Branch: `feature/step-2d-driver-ui-inventory-closeout-v2`  
> Head SHA: **pending commit** (filled after push)  
> Toolchain: Flutter **3.44.7** / Dart **3.12.2**  
> Device: **NOT REQUIRED** — documentation plus minimal accessibility Semantics fixes  
> Merge recommendation: **MERGE AFTER CI SUCCESS×4** (owner authorized auto-merge for this phase; merge-commit only)  
> STEP 3: **LOCKED until merge verified**

## Scope delivered

| Item | Result | Artifact |
|---|---|---|
| 18 | Every registered Driver route plus modal/router surfaces inventoried with owner columns | [`driver_screen_inventory.md`](./driver_screen_inventory.md) |
| 19 | Per-screen normalized states, reachability, providers, tests, and full enum catalogue | [`driver_state_inventory.md`](./driver_state_inventory.md) |
| 20 | Route → controller/provider → repository → test mapping | [`route_controller_test_matrix.md`](./route_controller_test_matrix.md) |
| 21 | Figma ⇄ Flutter mapping with no invented node IDs | [`figma_flutter_mapping.md`](./figma_flutter_mapping.md) |
| 22 | Localization, fonts, mixed-language, Semantics, touch, RTL/LTR, 320 px, and text-scale audit | [`localization_accessibility_audit.md`](./localization_accessibility_audit.md) |
| 23 | Fifteen-domain Fake/Local/Remote boundary and STEP 2D–8 ownership | [`fake_local_remote_boundaries.md`](./fake_local_remote_boundaries.md) |
| 24 | Quality, risk, deferred work, and merge closeout | This file |

## Files added/changed

### STEP 2D documentation set

1. `docs/step2d/driver_screen_inventory.md`
2. `docs/step2d/driver_state_inventory.md`
3. `docs/step2d/route_controller_test_matrix.md`
4. `docs/step2d/figma_flutter_mapping.md`
5. `docs/step2d/localization_accessibility_audit.md`
6. `docs/step2d/fake_local_remote_boundaries.md`
7. `docs/step2d/step2d_closeout.md`

### Minimal code delta already in this branch

| File | Approved change |
|---|---|
| `lib/core/localization/app_localizations.dart` | Add localized `otpDigitSemantics(index, length)` |
| `lib/shared/widgets/saeq_otp_input.dart` | Use `l10n.otpDigitSemantics` |
| `lib/features/batch/batch_ui_helpers.dart` | Use existing `l10n.batchSemanticsMap` |

No other Dart/code file belongs to STEP 2D.

## Inventory counts

| Metric | Result |
|---|---:|
| Registered `GoRoute` count | **38** |
| Registered routes inventoried | **38 / 38** |
| Redirect aliases | **1** (`/orders` → `/deliveries`, not a `GoRoute`) |
| Modal invocation surfaces | **4** |
| Router error page | **1** |
| Total screen/modal/router surfaces inventoried | **43** |
| Normalized owner state categories | **15** |
| Audited state/stage enums | **52** |
| Ordered enum values catalogued | **280** |
| Mandated Figma nodes mapped | **20 / 20** (`150:427` + 19 P27 nodes) |
| Additional known Figma node IDs mapped | **46** |
| Total mapped node IDs in the pass | **66** |
| Invented Figma node IDs | **0** |
| Route test mapping | **38 / 38 routes** |
| Modal/router test mappings | **5 / 5 surfaces**, with issue sheet tested only at shared-scaffold level |
| Routes wired to real backend | **0 / 38** |

The mapping source reports 16 production screens with pinned nodes and 18 without pinned nodes. Missing nodes remain `GAP — no pinned node`; no ID was inferred from a name.

## Quality results

| Gate | Result |
|---|---|
| Tests before STEP 2D | **803 passed** |
| Tests after STEP 2D delta | **803 passed** (`TEST_EXIT=0`) |
| `flutter analyze` | **PASS — No issues found** (`ANALYZE_EXIT=0`) |
| `flutter build apk --debug` | **PASS** (pre-commit gate) |
| Formatting (STEP 2D Dart files only) | **PASS** (`FORMAT_CHECK_EXIT=0`) |
| `git diff --check` (lib + docs/step2d) | **PASS** |
| Whole-tree `dart format` observation | Pre-existing drift on five protected files; they must not be reformatted or committed |
| Protected files | `api_client.dart`, `app_exception.dart`, `login_arabic_localization_test.dart`, `delivery_controller_test.dart`, `design_sprint2_inc4_widgets_test.dart` |
| Device validation | **NOT REQUIRED** |
| CI | **pending push** |
| Commit SHA | **pending commit** |

No claim is made that a whole-tree format run is clean. The protected drift predates this step and is outside scope.

## Known gaps

| Gap | Status / owner |
|---|---|
| Production screens without pinned Final Figma nodes | GAP; later Figma handoff |
| Dedicated widget matrices for history, earnings, notification lists/details, some auth blocking states, and delivery verify/issue | GAP; test expansion |
| 320 px / text scale 1.3 not tested on every route | GAP; per-feature responsive coverage |
| English/Roboto locale switch | GAP; Tajawal currently applies to both locales |
| Visible English history/delivery/document fixture values in Arabic UI | GAP; fixture redesign intentionally not included |
| Filter chips and onboarding text buttons likely below 48 dp | GAP; accessibility stabilization |
| Some tappable rows/contact actions lack explicit Semantics roles | GAP; accessibility follow-up |
| Contact banner copy can imply reveal at arrival although Hotfix reveals after pickup | DEFERRED product-copy decision |
| Loading Offers behavior after accept | DEFERRED to STEP 3; not fixed |
| Real GPS/permissions/maps/geofence/background handling | DEFERRED to STEP 4 |
| Backend contracts | **PENDING HANDOFF**; no handoff file exists |

## Deferred work

- STEP 3: Fake/local offer lifecycle stabilization and Loading Offers defect.
- STEP 4: real location permissions, GPS, accuracy/debounce/background behavior, geofence, map SDK, and external navigation.
- STEP 5: backend adapters/authority for auth, profile, availability, delivery, batch, history, and earnings.
- STEP 6: realtime offers, queue sync, and push notifications.
- STEP 7: vehicle/document KYC, picker/camera/upload/storage.
- STEP 8: support channels and driver services.
- Typography, fixture localization, broader semantics, responsive tests, and copy changes require separately scoped stabilization work.

## NOT CONNECTED list

All fifteen audited domains are **NOT CONNECTED** to production HTTP:

1. Authentication
2. Driver profile
3. Availability
4. Offers
5. Single delivery
6. Batch delivery
7. Customer contact
8. Location/map
9. Vehicle
10. Documents
11. History
12. Earnings
13. Notifications
14. Support
15. Safety

`ApiClient` is not consumed by any feature repository. The dormant core `SyncManager` HTTP path is not instantiated in the runtime graph. No backend endpoint, method, event, or schema was invented.

## Backend and privacy boundaries

- Fake adapters are denied or become `null` under production policy; missing production adapters render unavailable/error/empty states.
- Auth and delivery remote fakes additionally have hard release guards.
- Driver profile and accepted single-delivery snapshots use Drift locally; availability and locale/theme use local preferences; auth session uses secure storage.
- Batch contact data is synthetic. It is revealed after manual pickup, remains visible through automatic arrival/customer-unavailable handling, and is hidden after resolution.
- Delivery confirmation is enabled only after fake automatic arrival; real geofence ownership is STEP 4.
- Call/WhatsApp actions are counters only and launch no platform intent.

## Merge decision

Current recommendation: **MERGE AFTER CI SUCCESS×4**. The owner authorized auto-merge for this phase after those four checks succeed. Until the commit exists and merge is verified:

- Head SHA remains **pending commit**.
- CI remains **TBD**.
- STEP 3 remains **LOCKED**.

## التقرير العربي الموحد

- **ما تم تنفيذه:** إكمال وثائق جرد STEP 2D للشاشات والحالات والربط مع Figma وحدود Fake/Local/Remote وتدقيق الترجمة وإمكانية الوصول والإغلاق.
- **الملفات المعدلة:** ملفات التوثيق السبعة تحت `docs/step2d/`، مع توثيق فرق الكود الأدنى الموجود مسبقًا في ثلاثة ملفات فقط.
- **سبب التعديل:** إغلاق متطلبات المالك للبنود 18–24 بأدلة صريحة ومن دون اختراع عقد Figma أو Backend.
- **المخاطر:** فجوات Figma واختبارات 320px وبعض أهداف اللمس وبيانات Fake الإنجليزية وخط Roboto غير المستخدم ما زالت موثقة.
- **هل تم تعديل الكود؟** ليس ضمن مهمة كتابة هذه الوثائق؛ فرق STEP 2D المسجل مسبقًا يقتصر على إصلاحي Semantics ومفتاح ترجمة واحد.
- **هل تغير السلوك؟** التغيير السلوكي الوحيد في فرق STEP 2D هو جعل تسميتي Semantics ثنائيتي اللغة؛ لا تغيير في منطق الأعمال.
- **أعمال مؤجلة:** Backend وGPS وRealtime وLoading Offers وإعادة تصميم Fixtures والطباعة والفجوات الأخرى أعلاه.
- **الخطوة التالية المقترحة:** إنشاء commit، تشغيل CI، ثم الدمج تلقائيًا فقط بعد `SUCCESS×4` والتحقق من الدمج؛ يبقى STEP 3 مقفلًا حتى ذلك.
