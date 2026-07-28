# PHASE 2.6 — Complete Driver UI & Interaction Layer

> **Status:** Architecture **Accepted** — Increment 1 committed (`271d170`); Increment 2 committed (`6338ec4`); Design Sprint 1 committed (`faf7d0f`); Increment 3 committed as Fake Alpha (`2aef3a0`); **Increment 4 + Design Sprint 2 — `APPROVED` · `DEVICE_QA_PASSED` · COMMIT `FINAL` · CODE `LOCKED` · HONOR VKP-NX9 (`AP4EVB6423004646`)**
>
> **Date:** 2026-07-27
> **Baseline:** `2aef3a0` (Increment 3 Fake Alpha)
> **Inc 4 + DS2:** COMMIT `FINAL` · DOCUMENTATION `SYNCED` · PUSH `PENDING` · MERGE `NOT STARTED` · INCREMENT 5 `NOT STARTED`
> **Constraint:** Fake-only interactive UI; preserve Clean Architecture; no production backend
> **Inc 4 + DS2 report:** [PHASE_2_6_INCREMENT_4_DESIGN_SPRINT_2_REPORT.md](./PHASE_2_6_INCREMENT_4_DESIGN_SPRINT_2_REPORT.md)
> **Related:** [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](./PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md), [ADR-020…028](./adr/), [testing/REAL_ANDROID_DEVICE_TEST_PLAN.md](./testing/REAL_ANDROID_DEVICE_TEST_PLAN.md)

---

## 1. Purpose

Deliver a **complete, interactive Driver shell** (not static mockups): navigation, buttons, dialogs/sheets, loading/empty/error states, Fake-driven flows, Arabic/RTL, and device validation — while keeping production gates (ADR-027) and Alpha offer lifecycle (`_generation`, reject cooldown, assignment suppression) intact.

**Scope expansion (approved):** this phase is broader than the older roadmap title "Active Delivery Flow". It includes history, earnings, notifications, settings, and support under one Driver UI program, delivered in increments.

---

## 2. Increments

| Increment | Goal |
|-----------|------|
| **1** | Shared design kit + 5-tab shell + Home completion + offer polish + `/delivery/active` stub + sign-out confirm (OTP deferred) |
| **2** | Active delivery stage machine + verify/issue sheets + Drift stage persistence |
| **3** | History / earnings / notifications list+detail+filter |
| **4** | Profile extended + settings + support + OTP UI |
| **5** | Responsive / a11y / E2E Fake matrix + docs closeout |

---

## 3. Route map (locked)

**Bottom nav (5):** `/home` · `/deliveries` · `/earnings` · `/notifications` · `/profile`

**Under Profile (no bottom nav):** `/settings`, `/support`, `/support/safety`, `/profile/vehicle`, `/profile/documents`

**Focus (no bottom nav):** `/delivery/offer`, `/delivery/active`, `/delivery/verify`, `/delivery/issue`, detail routes

**Compat:** `/orders` redirects to `/deliveries`.

---

## 4. Delivery workflow (Increment 2)

Driver-facing stages persist on the assignment JSON (`workflowStage`,
`resumeAfterIssueStage`; legacy JSON defaults to `assigned`). Widgets call
controller/use cases only. Do not regress offer `_generation` / watch / Fake
reject cooldown. Restart restores assignment + stage; Home/Active reconcile
busy binding (ADR-025).

### Completion / release (minimum fixes)

1. **Ordering:** apply authoritative availability → `unavailable`
   (`delivery.complete`) **before** clearing the active assignment. The summary
   row remains persisted until availability succeeds.
2. **Idempotency:** a second complete when the assignment is already absent and
   availability is already post-completion returns success (no user-facing error).
3. **Navigation:** Active summary "Finish" and Issue submit navigate only after
   confirmed controller success.
4. **Failure re-sync:** `completeDeliverySummary` re-reads the active assignment
   after a failed completion so memory matches repository truth.
5. **`isActive`:** includes `delivered` as offer-blocking / active-slot ownership
   through the summary phase (`blocksNewOffers` alias). Not limited to physical
   transport.

Increment 3 History/Earnings/Notifications is **committed** as Fake Alpha
(`2aef3a0`). It is **not** linked to live Inc2 completions.

### Increment 3 — Fake Alpha boundaries (committed `2aef3a0`)

| Surface | Truth |
|---------|--------|
| **History** | **Fake Alpha** seeded data only. **Not** derived from real completed assignments / Inc2 workflow. |
| **Earnings** | **Fake Alpha** seeded periods only. **Not** settlement-grade. `double` amounts are display seeds; production money must later use **integer minor units** or an approved decimal type. |
| **Notifications** | **Local Fake Alpha** in-memory list. **Push notifications are not implemented.** |
| **Approval** | Increment 3 **committed** as Fake Alpha. Design Sprint 2 visual refresh of these screens is in the working tree only (see §9). |

Do **not** treat Fake History or Earnings as production or accounting data.

---

## 5. Fake & persistence (summary)

| Domain | Store | Notes |
|--------|-------|-------|
| Auth / OTP | Secure storage + Fake | OTP UI in Inc 4 (working tree); Fake Alpha only; production gate unchanged |
| App preferences | SharedPreferences | Theme + locale only via `AppPreferences`; never tokens |
| Availability | SharedPreferences | Existing + DEV-ONLY Fake confirm |
| Active assignment + stage | Drift JSON | Stage field in Inc 2 |
| Home earnings/trips placeholders | In-memory Fake seed | Inc 1 — no new Drift schema |
| History / earnings / notifications | Fake repos (Inc 3, Fake Alpha only) | Not linked to live completions; no push |
| Support contacts | Fake `SupportConfig` | `unavailable` by default; no invented contacts |

---

## 6. Increment 1 acceptance

- Shared buttons/chips/empty/error/loading/dialog/sheet/offline banner exist under `lib/shared/widgets/`; offer empty/error migrate to shared.
- Shell shows 5 destinations; Settings not a root tab.
- Home shows Fake earnings/trips strip, quick actions, offline banner, notification entry; availability + offer/assignment banners unchanged in behavior.
- Assignment banner / Continue open `/delivery/active` stub (summary only).
- Sign-out requires confirmation dialog.
- `dart format` (scoped) → `flutter analyze` → `flutter test` → `flutter build apk --debug` → `git diff --check`; device plan updated.
- **No** OTP UI in Inc 1; **no** stage machine; **no** production backend; **no** commit until review.

---

## 7. Non-goals (whole phase)

- Customer / Merchant / Admin apps or shared-package extraction
- Production remote delivery adapter
- Real camera / payments / auto-dial
- Weakening ADR-015…028 or Fake release gates

---

## 8. Increment 4 — implementation status (working tree, **NOT approved**)

Increment 4 delivers Profile extended, Settings, Support, and OTP UI behind
existing domain contracts. **Owner status (2026-07-28):** `APPROVED` ·
`DEVICE_QA_PASSED` on HONOR VKP-NX9 (`AP4EVB6423004646`).

| Surface | Status | Notes |
|---------|--------|-------|
| **OTP UI** | Fake Alpha only | Login → `requestOtp` → OTP screen → `verifyOtp`; resend timer; no production SMS/API |
| **Profile edit** | Fake Alpha | Editable: **fullName**, **email** only; sovereign fields immutable |
| **Settings** | Fake Alpha | Theme (light/dark/system) + locale (ar/en) via `AppPreferences` / SharedPreferences |
| **Support** | Fake Alpha | `SupportConfig.unavailable` by default — no invented phone/email/URL |

**Status board:** CODE `LOCKED` · DOCUMENTATION `SYNCED` · COMMIT `FINAL` ·
PUSH `PENDING` · MERGE `NOT STARTED` · INCREMENT 5 `NOT STARTED`.

### Approval commit package (mandatory — one commit)

When Increment 4 + Design Sprint 2 is authorized, **exactly one** Conventional
Commit on `feature/phase-2.6-increment-4-design-sprint-2` (or an equivalent
approved feature branch) **must** include **all** of the following in the
**same** commit. Splitting docs from code is forbidden for this closeout.

| Must include | Path / note |
|--------------|-------------|
| Inc 4 + DS2 implementation | Auth OTP, Profile edit, Settings, Support, shared widgets, providers, routes, l10n, tests |
| Device / localization plan updates | `docs/testing/REAL_ANDROID_DEVICE_TEST_PLAN.md`, `docs/localization/localization-guidelines.md` |
| This plan (status + report link in header) | `docs/PHASE_2_6_COMPLETE_DRIVER_UI_PLAN.md` |
| Official Inc 4 + DS2 report | `docs/PHASE_2_6_INCREMENT_4_DESIGN_SPRINT_2_REPORT.md` |

**Must not include** in that commit (unless separately authorized): `.backup/**`,
unrelated `docs/design/STEP*` design-first artifacts, secrets, build outputs.

Safety branch `safety/inc4-design-sprint2-a9007e0` (`a9007e0`) is a **code
snapshot only** — it does **not** contain the official report or the plan header
report link. It is **not** a substitute for the approval commit above.

### Real vs Fake backend

| Contract | Fake Alpha (Inc 4) | Production |
|----------|-------------------|------------|
| `requestOtp` | In-memory challenge; format validation only | Remote auth API (future) |
| `verifyOtp` | Deterministic trial code in Fake repo memory | Remote verify (future) |
| `refreshSession` | Returns current session when valid; `null` when expired | Remote refresh (future) |
| `signIn` | Legacy trial path preserved for tests/back-compat | Deprecated in favour of OTP flow |

**No production auth API is claimed complete.** Contracts are preserved so a
future remote implementation can swap behind `AuthenticationRepository` without
touching controllers or UI.

### OTP security (Fake Alpha)

- **No plaintext OTP persistence** — challenge lives in `FakeAuthenticationRepository` memory only (`_pendingPhone`, expiry, resend cooldown).
- **Trial code is Fake-repo memory only** — used for Alpha device QA; **never logged**, never written to SharedPreferences or secure storage.
- **Tokens / sessions** — persisted via `AuthSessionStorage` (secure abstraction); not in `AppPreferences`.
- **Resend cooldown** — 30 s; OTP expiry 5 min (Fake constants).

### Certificate pinning

Production gate only — **NOT implemented**. `CertificatePinning` in
`lib/core/security/security_interceptors.dart` has placeholder hashes and a
TODO. Fake Alpha does not exercise pinning. Production remote auth must not ship
without an approved pinning ADR and implementation.

### Profile editable fields

| Editable (Inc 4 UI) | Immutable (sovereign) |
|---------------------|----------------------|
| `fullName` | `driverId`, `businessId`, `branchId` |
| `email` | `phoneNumber`, `employmentStatus`, `accountStatus`, `createdAt` |

`ProfileEditScreen` exposes fullName + email only. Sovereign fields display
read-only on Profile. `profileImageUrl` remains in the domain model but has no
Inc 4 UI surface (deferred).

### Settings — `AppPreferences`

- **SharedPreferences keys:** `app_theme_mode_v1`, `app_locale_language_code_v1`.
- **Stores:** theme mode + locale language code only.
- **Never stores:** auth tokens, sessions, OTP, or secrets.
- **Logout wiring:** Settings and Home call `AvailabilityController.prepareForLogout()` before `AuthController.signOut()`; secure-clear failures surface `SecureStorageFailureError` without falsely claiming unauthenticated when tokens may remain.

### Support — unavailable by default

- `SupportConfig.unavailable` is the Fake default (`phone`, `email`, `helpUrl` all null).
- Support screen shows an explicit unavailable state — **no invented contacts**.
- Safety sub-route exists; content is informational only (no auto-dial).

---

## 9. Design Sprint 2 — visual refresh (working tree, **implemented — awaiting device QA**)

Design Sprint 2 applies a **temporary Forest Green** palette via
`SaeqSemanticColors` (`lib/core/theme/saeq_semantic_colors.dart`). This is a
candidate palette, not a final brand lock.

| Scope | Status |
|-------|--------|
| Inc 3 screens (History, Earnings, Notifications) | **Implemented** — `SaeqSemanticColors` + shared Saeq widgets |
| Inc 4 screens (Login, OTP, Profile, Profile edit, Settings, Support) | **Implemented** — `SaeqSemanticColors` + shared Saeq widgets |
| Shared widgets (filter chips, earnings row, notification row, OTP input, profile header, settings rows) | Updated |

**Status:** code complete in working tree; **NOT approved** and **NOT committed**.
Widget/unit tests must pass in Quality Gate; **device QA deferred** (see §10).
Design Sprint 2 must **not** be marked complete until runtime validation on a
physical device (or documented exception).

### Increment 4 auth helpers (working tree)

| Helper | Location | Behavior |
|--------|----------|----------|
| **Saudi phone normalizer** | `lib/features/auth/domain/saudi_phone_normalizer.dart` | Accepts `05XXXXXXXX`, `+9665…`, `9665…`, `009665…`; returns local `05XXXXXXXX` or `null` |
| **Refresh dedup** | `AuthController.refreshSession`, `FakeAuthenticationRepository.refreshSession` | Concurrent calls share one in-flight `Future`; second caller awaits the same result |
| **Logout prepare** | `HomeScreen`, `SettingsScreen` | Both call `AvailabilityController.prepareForLogout()` before `AuthController.signOut()` |

---

## 10. Device QA (Increment 4 + Design Sprint 2)

| Field | Value |
|-------|--------|
| Target device | VKP NX9 (`AP4EVB6423004646`) |
| Execution date | 2026-07-27 (final validation pass) |
| `adb devices` | **Empty — device not connected** |
| Result | **Deferred — device not connected** |
| Debug APK | **Built** — `build/app/outputs/flutter-apk/app-debug.apk` (2026-07-27 validation) |
| APK install | **Not performed** (no connected device) |
| Screenshots | None — `.backup/device-qa-inc4-ds2-20260727/` not created (device unavailable) |

**Quality Gate (2026-07-27):** `dart format` (52 dart files) · `flutter analyze` (0 errors, 0 warnings, 1 info) · `flutter test` (637 passed, 0 failed, 0 skipped) · `flutter build apk --debug` (success) · `git diff --check` (clean).

**Untested on device:** OTP login path, Settings theme/locale switch, Profile
edit save, Support unavailable state, Design Sprint 2 visual pass on Inc 3+4
screens, RTL/dark/large-text combinations on new surfaces.

Re-run per [testing/REAL_ANDROID_DEVICE_TEST_PLAN.md §11–12](./testing/REAL_ANDROID_DEVICE_TEST_PLAN.md)
when device is available.

---

## 11. Deferred items

| Item | Phase / note |
|------|----------------|
| Production auth API + SMS OTP | Post–Fake Alpha; behind `AuthenticationRepository` |
| Certificate pinning | Production gate; ADR + implementation required |
| `profileImageUrl` edit UI | Inc 4 deferred; domain field exists |
| Support real contacts | Backend `SupportConfig` when available |
| History linked to real completions | Post–Fake Alpha |
| Earnings settlement-grade amounts | Integer minor units or approved decimal type |
| Push notifications | Not implemented |
| Design Sprint 2 device validation | Blocked until runtime pass |
| Increment 4 commit + approval | Awaiting review — **must** ship report + plan header link in the **same** commit (§8 Approval commit package) |
| Increment 5 (responsive / a11y / E2E matrix) | After Inc 4 closeout |
