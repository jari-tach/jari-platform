# STEP 2D — Item 24 · Driver UI Inventory and Closeout

> **Status:** MERGED — COMPLETE
> **Baseline SHA:** `6164994ca262535c85bdeafdee822e32ad877da2` (PR #16 Hotfix merge)
> **STEP 2D Head SHA:** `b4f084aeab01bc5e90390ef6321eb2ed22bcae13`
> **STEP 2D Merge SHA:** `e2b6ec4bf15541c02de86291176545c567da60e1` (PR #17)
> **Branch (merged):** `feature/step-2d-driver-ui-inventory-closeout-v2`
> **Toolchain:** Flutter **3.44.7** / Dart **3.12.2**
> **CI Run:** `30538232963`
> **CI:** SUCCESS ×4 (Analyze · Test · Build Android · Build iOS)
> **Tests:** **803 PASS**
> **Device:** NOT REQUIRED (docs + minimal Semantics)
> **Backend handoff:** ADDED — DRAFT CONTRACTS ONLY
> **Backend server:** NOT STARTED
> **Production Backend:** NOT CONNECTED
> **STEP 2D:** CLOSED
> **STEP 3:** AUTHORIZED AFTER THIS DOCS PR MERGES

## Scope delivered

| Item | Result | Artifact |
|---|---|---|
| 18 | Every registered Driver route plus modal/router surfaces inventoried | [`driver_screen_inventory.md`](./driver_screen_inventory.md) |
| 19 | Per-screen normalized states, reachability, providers, tests, enums | [`driver_state_inventory.md`](./driver_state_inventory.md) |
| 20 | Route → controller/provider → repository → test mapping | [`route_controller_test_matrix.md`](./route_controller_test_matrix.md) |
| 21 | Figma ⇄ Flutter mapping with no invented node IDs | [`figma_flutter_mapping.md`](./figma_flutter_mapping.md) |
| 22 | Localization, fonts, Semantics, touch, RTL/LTR, 320 px, text-scale audit | [`localization_accessibility_audit.md`](./localization_accessibility_audit.md) |
| 23 | Fifteen-domain Fake/Local/Remote boundary and STEP ownership | [`fake_local_remote_boundaries.md`](./fake_local_remote_boundaries.md) |
| 24 | Quality, risk, deferred work, and merge closeout | This file |
| Handoff | Backend/Domain handoff from ChatGPT package (draft contracts only) | [`backend_domain_handoff.md`](./backend_domain_handoff.md) |

## Files added/changed (STEP 2D inventory PR #17)

### Documentation

1. `docs/step2d/driver_screen_inventory.md`
2. `docs/step2d/driver_state_inventory.md`
3. `docs/step2d/route_controller_test_matrix.md`
4. `docs/step2d/figma_flutter_mapping.md`
5. `docs/step2d/localization_accessibility_audit.md`
6. `docs/step2d/fake_local_remote_boundaries.md`
7. `docs/step2d/step2d_closeout.md`

### Minimal code delta (Semantics only)

| File | Change |
|---|---|
| `lib/core/localization/app_localizations.dart` | Add `otpDigitSemantics(index, length)` |
| `lib/shared/widgets/saeq_otp_input.dart` | Use `l10n.otpDigitSemantics` |
| `lib/features/batch/batch_ui_helpers.dart` | Use `l10n.batchSemanticsMap` |

### Final docs closeout PR (this follow-up)

| File | Change |
|---|---|
| `docs/step2d/backend_domain_handoff.md` | **ADDED** — official Backend/Domain handoff |
| `docs/step2d/step2d_closeout.md` | Corrected final SHAs / CI / status |
| `docs/step2d/fake_local_remote_boundaries.md` | Point future-remote cells to handoff (no longer open handoff gap) |

Flutter runtime files in the final docs PR: **0**.

## Inventory counts

| Metric | Result |
|---|---:|
| Registered `GoRoute` count | **38** |
| Registered routes inventoried | **38 / 38** |
| Redirect aliases | **1** (`/orders` → `/deliveries`) |
| Modal invocation surfaces | **4** |
| Router error page | **1** |
| Total screen/modal/router surfaces inventoried | **43** |
| Normalized owner state categories | **15** |
| Audited state/stage enums | **52** |
| Ordered enum values catalogued | **280** |
| Mandated Figma nodes mapped | **20 / 20** (`150:427` + 19 P27) |
| Additional known Figma node IDs mapped | **46** |
| Invented Figma node IDs | **0** |
| Route test mapping | **38 / 38** |
| Routes wired to real backend | **0 / 38** |

## Quality results

| Gate | Result |
|---|---|
| Tests | **803 PASS** |
| `flutter analyze` | PASS — No issues found |
| `flutter build apk --debug` | PASS |
| Formatting (STEP 2D Dart files) | PASS |
| `git diff --check` | PASS |
| CI run | **30538232963** |
| CI | **SUCCESS ×4** |
| Device | NOT REQUIRED |
| PR #17 | MERGED (merge commit) |
| Merge SHA | `e2b6ec4bf15541c02de86291176545c567da60e1` |

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
| Loading Offers behavior after accept | DEFERRED to STEP 3 |
| Real GPS/permissions/maps/geofence/background handling | DEFERRED to STEP 4 |
| Backend server / production OpenAPI | DRAFT handoff recorded; implementation NOT STARTED until STEP 5 |

## Deferred work

- STEP 3: Fake/local offer lifecycle stabilization and Loading Offers defect (**authorized after this docs PR merges**).
- STEP 4: real location permissions, GPS, accuracy/debounce/background behavior, geofence, map SDK, external navigation.
- STEP 5: `jari-tach/saeq-backend` + `jari-tach/saeq-contracts` REST authority.
- STEP 6: realtime offers/sync/push.
- STEP 7: vehicle/document KYC, picker/camera/upload/storage.
- STEP 8: support channels and driver services.
- Typography, fixture localization, broader semantics, responsive tests, and copy changes require separately scoped work.

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

`ApiClient` is not consumed by any feature repository. Dormant `SyncManager` HTTP is not runtime-wired.

## Backend and privacy boundaries

- Official handoff: [`backend_domain_handoff.md`](./backend_domain_handoff.md) (source: `STEP2D_Backend_Domain_Handoff.md` + draft contracts package).
- Backend server: **NOT STARTED**.
- Production Backend: **NOT CONNECTED**.
- Fake adapters denied or `null` under production policy.
- Batch contact: revealed after manual pickup; closed after deliver/cancel; delivery CTA still gated on automatic arrival.
- Call/WhatsApp actions are counters only.

## Merge decision (historical)

PR #17 merged with **merge commit only** after CI SUCCESS×4 on run `30538232963`.

STEP 2D inventory phase: **CLOSED**.
STEP 3: **AUTHORIZED AFTER THIS DOCS PR MERGES**.

## التقرير العربي الموحد

- **ما تم تنفيذه:** إغلاق STEP 2D توثيقيًا نهائيًا وإضافة Handoff Backend/Domain كمسودات عقود فقط.
- **الملفات المعدلة (هذا الإغلاق):** `backend_domain_handoff.md` · تحديث `step2d_closeout.md` · تحديث إشارات الـhandoff في حدود Fake/Local/Remote.
- **سبب التعديل:** تصحيح حالة الإغلاق بعد دمج PR #17 وربط حزمة ChatGPT الرسمية.
- **المخاطر:** فجوات Figma/320px/Fixtures موثقة؛ لا اتصال إنتاجي.
- **هل تم تعديل الكود؟** لا في PR الإغلاق التوثيقي النهائي.
- **هل تغير السلوك؟** لا.
- **أعمال مؤجلة:** STEP 3 Loading Offers وما بعده حسب الخطة.
- **الخطوة التالية:** دمج هذا الـDocs PR ثم بدء STEP 3.
