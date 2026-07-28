# PHASE 2.6 — Driver Screen Inventory & Navigation Audit

> **Date:** 2026-07-28
> **Branch baseline:** `main` @ `9bbdcd6` (PR #6 merged)
> **Strategy:** UI-First · Real Device First · Fake/Mock data only
> **E2E matrix:** **PAUSED** after PR #6 (Flows A–G deferred)

---

## 1. Execution pivot (owner directive)

| Priority order | Focus |
|----------------|--------|
| 1 | All screens exist and are reachable via in-app navigation |
| 2 | Fake/Mock data wired; no new production backend |
| 3 | Real Android device walkthrough after each screen group |
| 4 | Owner visual approval |
| 5 | Backend integration (later) |
| 6 | Full E2E test matrix (later) |

**PR sequence (small batches):**

| PR | Scope |
|----|--------|
| **1** | This inventory + navigation audit (docs only) |
| **2** | Auth + Home + Availability |
| **3** | Offers + Delivery lifecycle |
| **4** | Earnings + Notifications + Profile |
| **5** | Settings + Support + shared states |
| **6** | Responsive + RTL/LTR + theme fixes |
| **7** | Real device visual corrections |

---

## 2. State legend

| State | Meaning in this audit |
|-------|------------------------|
| **Default** | Primary happy-path content visible |
| **Loading** | Skeleton / spinner / disabled CTA while in flight |
| **Empty** | No data to show (intentional empty state UI) |
| **Error** | Typed or generic failure with retry/message |
| **Success** | Post-action confirmation (snackbar, navigation, updated UI) |
| **Offline** | Offline banner or blocked action when connectivity false |

**Coverage codes:** `✅` implemented · `⚠️` partial · `❌` missing · `—` not applicable

---

## 3. Route map vs implementation

### 3.1 Public / auth

| Route | Screen | File | In-app entry | Data | Default | Loading | Empty | Error | Success | Offline |
|-------|--------|------|--------------|------|---------|---------|-------|-------|---------|---------|
| `/` | Welcome / First Launch | `welcome_screen.dart` | App cold start | — | ✅ | — | — | — | ✅ locale toggle | — |
| `/login` | Phone login | `login_screen.dart` | Welcome → Start | Fake Auth | ✅ | ✅ OTP request | — | ✅ validation + auth errors | ✅ → OTP | — |
| `/login/otp` | OTP verification | `otp_verification_screen.dart` | Login success | Fake OTP | ✅ | ✅ verify/resend | — | ✅ invalid/expired/incomplete | ✅ → Home | — |
| `/coming-soon` | Explore architecture placeholder | `shell_placeholder_screen.dart` | **No UI link** (route exists) | — | ⚠️ placeholder | — | ✅ | — | — | — |

### 3.2 Shell (bottom nav)

| Route | Screen | File | Tab / entry | Data | Default | Loading | Empty | Error | Success | Offline |
|-------|--------|------|-------------|------|---------|---------|-------|-------|---------|---------|
| `/home` | Home / Dashboard | `home_screen.dart` | Tab 0 · post-auth redirect | Fake summary + live availability/offer banners | ✅ | ✅ availability loading | ✅ no-offer hint | ✅ availability failure | ✅ availability confirmed | ✅ banner + offline card |
| `/deliveries` | History list | `deliveries_history_screen.dart` | Tab 1 · Home quick action | Fake History | ✅ | ✅ | ✅ | ✅ | ✅ → detail | — |
| `/deliveries/:id` | History detail | same file | List tap | Fake History | ✅ | ✅ | ✅ | ✅ | — | — |
| `/earnings` | Earnings list | `earnings_screen.dart` | Tab 2 · Home quick action | Fake Earnings | ✅ | ✅ | ✅ | ✅ | ✅ → detail | — |
| `/earnings/:id` | Earnings detail | same file | List tap | Fake Earnings | ✅ | ✅ | ✅ | ✅ | — | — |
| `/notifications` | Notifications list | `notifications_screen.dart` | Tab 3 · Home icon | Fake Notifications | ✅ | ✅ | ✅ | ✅ | ✅ mark-read | — |
| `/notifications/:id` | Notification detail | same file | List tap | Fake Notifications | ✅ | ✅ | ✅ | ✅ | ✅ mark-read | — |
| `/profile` | Profile view | `profile_screen.dart` | Tab 4 | Fake Profile | ✅ | ✅ | ✅ | ✅ | — | — |
| `/profile/edit` | Profile edit | `profile_edit_screen.dart` | Profile → Edit | Fake Profile | ✅ | ✅ save | — | ✅ validation + save fail | ✅ snackbar | — |

### 3.3 Profile subtree (no bottom nav)

| Route | Screen | File | Entry | Data | Default | Loading | Empty | Error | Success | Offline |
|-------|--------|------|-------|------|---------|---------|-------|-------|---------|---------|
| `/settings` | Settings | `settings_screen.dart` | Profile → Settings | `AppPreferences` | ✅ | — | — | ⚠️ persist throw | ✅ theme/locale | — |
| `/support` | Support | `support_screen.dart` | Profile → Support | Fake `SupportConfig` | ⚠️ unavailable default | ✅ | ✅ unavailable | ✅ | — | — |
| `/support/safety` | Safety info | `support_safety_screen.dart` | Support → Safety | Static | ✅ | — | — | — | — | — |

### 3.4 Delivery focus (no bottom nav)

| Route | Screen | File | Entry | Data | Default | Loading | Empty | Error | Success | Offline |
|-------|--------|------|-------|------|---------|---------|-------|-------|---------|---------|
| `/delivery/offer` | Incoming offer | `incoming_delivery_offer_page.dart` | Home banner / offer flow | Fake Delivery remote | ✅ | ✅ | ✅ expired/empty | ✅ | ✅ accept → active | ⚠️ accept blocked |
| `/delivery/active` | Active delivery | `active_delivery_page.dart` | Banner / accept / history shortcut | Drift + Fake | ✅ | ✅ | ✅ no assignment | ✅ stage errors | ✅ Finish → Home | ⚠️ |
| `/delivery/verify` | Verify sheet page | `delivery_verify_page.dart` | Active → Verify | Workflow | ✅ | ✅ | — | ✅ | ✅ → active | — |
| `/delivery/issue` | Issue report | `delivery_issue_page.dart` | Active → Issue | Workflow | ✅ | ✅ | — | ✅ | ✅ → active | — |

### 3.5 Plan routes **not implemented**

| Planned route | Plan reference | Status |
|---------------|----------------|--------|
| `/profile/vehicle` | `PHASE_2_6_COMPLETE_DRIVER_UI_PLAN.md` §3 | ❌ No route, no screen, no nav |
| `/profile/documents` | Same | ❌ No route, no screen, no nav |

### 3.6 Compat / system

| Route | Behavior |
|-------|----------|
| `/orders` | Redirects to `/deliveries` ✅ |
| Unknown URI | `errorBuilder` → localized page not found ✅ |

---

## 4. Navigation audit

### 4.1 Reachable from authenticated happy path

```
Welcome → Login → OTP → Home
Home ⇄ [Deliveries | Earnings | Notifications | Profile] (bottom nav)
Home → Notifications (app bar)
Home → Deliveries / Earnings / Notifications (quick actions)
Home → Offer banner → /delivery/offer OR /delivery/active
Profile → Edit | Settings | Support
Support → Safety
Lists → Detail routes (/deliveries/:id, etc.)
Active → Verify | Issue | Home (Finish)
```

### 4.2 Routes without in-app discoverability

| Route | Issue |
|-------|--------|
| `/coming-soon` | Registered; **no button** on current Welcome (Figma First Launch only) |
| `/delivery/offer` | Only via offer banner when offer exists |
| `/delivery/active` | Banner, accept, or **History dev shortcut** (`deliveries_history_screen` button) |
| `/delivery/verify` | Only from Active when stage allows |
| `/delivery/issue` | Only from Active when stage allows |

### 4.3 Tap / action gaps

| Location | Control | Status | Notes |
|----------|---------|--------|-------|
| Welcome | Locale toggle | ✅ | No Explore Architecture entry |
| Home | Availability card | ✅ | Full PHASE 2.4 flow |
| Home | Offer banner | ✅ | Offer vs active routing |
| Home | Sign out | ❌ removed (Batch 3) | Logout only in Settings/Profile |
| History list | → Active delivery button | ⚠️ | Dev/QA shortcut; not user-facing product path |
| Profile | Vehicle / Documents | ❌ | Planned routes missing |
| Support | Call / email when unavailable | ✅ | Correctly disabled |
| Settings | Sign out | ✅ | Confirm + `prepareForLogout` |

### 4.4 Screen completeness summary

| Area | Complete | Partial | Missing |
|------|----------|---------|---------|
| Authentication | Login, OTP, Welcome | — | — |
| Home / Availability | Home + availability card | Offline on delivery surfaces | — |
| Offers / Delivery | Offer, Active, Verify, Issue | Offline edge cases | — |
| History / Earnings / Notifications | List + detail + filters | Fake only (by design) | — |
| Profile | View + edit | `profileImageUrl` edit UI deferred | Vehicle, Documents screens |
| Settings / Support | Settings, Support unavailable, Safety | Support real contacts | — |
| Theme / Locale | App-wide via Settings + Welcome toggle | — | — |
| Placeholder | `/coming-soon` orphan route | — | — |

---

## 5. Fake data boundaries (UI-First)

| Domain | UI source | Production |
|--------|-----------|------------|
| Auth / OTP | `FakeAuthenticationRepository` | Not wired |
| Availability | Fake + local persistence | Partial real local |
| Delivery offer/active | Fake remote + Drift assignment | Not production remote |
| History / Earnings / Notifications | Fake in-memory repos | Not linked to completions |
| Profile | Fake profile repo | Sovereign fields read-only |
| Support | `SupportConfig.unavailable` | No invented contacts |
| Home summary strip | `fakeHomeSummaryProvider` | Placeholder metrics |

---

## 6. Device validation backlog (UI-First)

After each implementation PR, run on **HONOR VKP-NX9** (`AP4EVB6423004646`):

- Tap every primary CTA on affected screens
- AR + EN, RTL + LTR, Light + Dark
- Capture screenshots to `.backup/device-qa-*` (not committed)
- Log visual/functional issues before next PR
- **Batch 3 M2:** Unavailable cold-start race **PASS** on VKP-NX9 (USB ADB) — Offline cleared → Unavailable without restart; Busy path **BLOCKED** (Accept stuck on Loading offers); Batch 3 not fully closed (see `PHASE_2_6_UI_FIGMA_REAL_DEVICE_REPORT.md`)

Checklist reference: `docs/testing/REAL_ANDROID_DEVICE_TEST_PLAN.md` §8–13.

---

## 7. Deferred (explicit pause)

| Item | Status |
|------|--------|
| E2E Fake flows A–G | **PAUSED** after PR #6 |
| Additional `test/integration/*` beyond Flow H | **PAUSED** |
| Semantics sweep | PR 6 in new sequence |
| Production backend / SMS OTP | Post UI approval |
| `/profile/vehicle`, `/profile/documents` | **Missing** — target PR 4 or 5 |

---

## 8. PR #6 status (merged — scope closed)

| Field | Value |
|-------|--------|
| PR | [#6](https://github.com/jari-tach/jari-platform/pull/6) — **MERGED** |
| Merge commit on `main` | `9bbdcd6` |
| Scope | Fake E2E harness + Flow H + §13 — **closed** |

---

## 9. Phase 2.6 completion criteria (UI-First)

Phase 2.6 is **not** complete until:

1. All approved screens exist (including vehicle/documents if still in scope).
2. All screens reachable via real in-app navigation.
3. Primary buttons work with Fake data.
4. App runs on real Android device without critical visual defects.
5. Owner approves UI experience.
6. No critical open device QA blockers.

---

## 10. Next authorized step

**PR 1 (this document):** `feature/phase-2.6-ui-first-screen-inventory` → PR [#7](https://github.com/jari-tach/jari-platform/pull/7).

**Extended UI-First docs (same program):**
- `docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md` — 62-screen master table
- `docs/PHASE_2_6_UI_FIGMA_REAL_DEVICE_REPORT.md` — comprehensive tracking report

**Do not start PR 2 (Figma + Flutter implementation)** until inventory PR is merged and authorized.
