# PHASE 2.6 — Complete Driver UI & Interaction Layer

> **Status:** Architecture **Accepted** — Increment 1 **Implemented** (awaiting review; no commit yet)  
> **Date:** 2026-07-26  
> **Baseline:** `7d90851` / `alpha-stable-v1.0`  
> **Constraint:** Fake-only interactive UI; preserve Clean Architecture; no production backend; no commit/push until review  
> **Related:** [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](./PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md), [ADR-020…028](./adr/), [testing/REAL_ANDROID_DEVICE_TEST_PLAN.md](./testing/REAL_ANDROID_DEVICE_TEST_PLAN.md)

---

## 1. Purpose

Deliver a **complete, interactive Driver shell** (not static mockups): navigation, buttons, dialogs/sheets, loading/empty/error states, Fake-driven flows, Arabic/RTL, and device validation — while keeping production gates (ADR-027) and Alpha offer lifecycle (`_generation`, reject cooldown, assignment suppression) intact.

**Scope expansion (approved):** this phase is broader than the older roadmap title “Active Delivery Flow”. It includes history, earnings, notifications, settings, and support under one Driver UI program, delivered in increments.

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

Driver-facing stages persist on the assignment (Fake + Drift JSON). Widgets call controller/use cases only. Do not regress offer `_generation` / watch / Fake reject cooldown. Restart restores assignment + stage; Home/Active reconcile busy binding (ADR-025).

---

## 5. Fake & persistence (summary)

| Domain | Store | Notes |
|--------|-------|-------|
| Auth / OTP | Secure storage + Fake | OTP UI in Inc 4; production gate unchanged |
| Availability | SharedPreferences | Existing + DEV-ONLY Fake confirm |
| Active assignment + stage | Drift JSON | Stage field in Inc 2 |
| Home earnings/trips placeholders | In-memory Fake seed | Inc 1 — no new Drift schema |
| History / earnings / notifications | Fake repos | Inc 3 |

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
