# PHASE 2.6 — UI Figma + Real Device Report

> **Program:** UI-First · Figma Interactive Prototype · Real Device Validation  
> **Repository:** jari-tach/jari-platform  
> **Status:** **IN PROGRESS** — Batch 1 closed · Batch 2 Figma in progress  
> **Last updated:** 2026-07-28  
> **Main baseline:** `e41c580` (PR #7 merged)

---

## 1. Executive Summary

SAEQ Driver Phase 2.6 is pivoting to **UI-First delivery**: complete Figma interactive prototype, implement all screens in Flutter with Fake/Mock data, validate on a **real Android device**, and produce owner-approvable UI before backend expansion.

**Current baseline (post PR #7 merge @ `e41c580`):**

- **18** screens/surfaces are **complete** (auth core, 5-tab shell, settings, delivery core, profile edit).
- **22** are **partial** (sub-states, delivery milestones, support unavailable, theme/locale sections).
- **22** are **missing** (splash, onboarding, vehicle, documents, permissions, wallet, help/contact, many delivery sub-screens).
- **E2E test matrix A–G** is **paused**; **Flow H** widget test exists and passes.
- **PR #7** (screen inventory) **merged** — merge commit `e41c580`.
- **Baseline docs PR** (mapping + this report) on `feature/phase-2.6-ui-figma-baseline-docs` — **PENDING** review.

**Priority order:** All screens → full navigation → real device → design approval → backend → full tests.

---

## 2. Figma references

| Field | Value |
|-------|--------|
| **Figma file** | [SAEQ Driver — Design System & UX](https://www.figma.com/design/MNJldEpkMxVjIavCPaPBFh/SAEQ-Driver-%E2%80%94-Design-System---UX) |
| **File key** | `MNJldEpkMxVjIavCPaPBFh` |
| **Prototype** | Page `03 — High-Fidelity Screens & Prototype` — **partial wiring** |
| **Final Auth frames** | Nodes `40:4` … `48:2024` (implemented in Flutter Inc 4) |
| **Repo SoT doc** | `docs/design/FIGMA_SOURCE_OF_TRUTH.md` |
| **Spec inventory** | `docs/design/STEP6_SCREEN_INVENTORY.md` |
| **Approved Figma version** | **PENDING** owner stamp after prototype completion |

---

## 3. Engineering references

| Field | Value |
|-------|--------|
| **Branch (inventory PR)** | merged → `main` |
| **PR #7 merge commit** | `e41c580` |
| **Inventory commit** | `dda398c` |
| **Main baseline** | `e41c580` (PR #7 + PR #6) |
| **Baseline docs branch** | `feature/phase-2.6-ui-figma-baseline-docs` |
| **Screen inventory** | `docs/PHASE_2_6_SCREEN_INVENTORY.md` |
| **Unified mapping** | `docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md` |
| **Plan** | `docs/PHASE_2_6_COMPLETE_DRIVER_UI_PLAN.md` |

---

## 4. APK / build (pending UI-First acceptance build)

| Field | Value |
|-------|--------|
| **APK name** | **PENDING** |
| **Build type** | **PENDING** (`debug` for batch QA; `release` for final acceptance) |
| **Build command** | `flutter build apk --debug` |
| **Commit SHA at build** | **PENDING** |

---

## 5. Android device (reference)

| Field | Value |
|-------|--------|
| **Manufacturer** | HONOR |
| **Model** | VKP-NX9 |
| **Serial** | `AP4EVB6423004646` |
| **Android version** | **PENDING** capture in next device session |
| **Resolution** | 1264×2728 px (design reference) |
| **Device language** | **PENDING** |
| **Orientation tested** | Portrait (primary); landscape **PENDING** |
| **App version at test** | **PENDING** |
| **Commit SHA at test** | **PENDING** |

---

## 6. Screen inventory (summary)

Full route/state matrix: `docs/PHASE_2_6_SCREEN_INVENTORY.md`  
62-screen owner checklist mapping: `docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md`

| Category | Count |
|----------|-------|
| Complete | 18 |
| Partial | 22 |
| Missing | 22 |
| Not connected | 3 |

---

## 7. Figma-to-Flutter mapping

See **`docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md`** (master table with Figma frame IDs, routes, entry points, button actions, implementation/Figma/prototype/device columns).

---

## 8. Navigation map

```
/  Welcome ──→ /login ──→ /login/otp ──→ /home
                                              ├── bottom nav ──→ /deliveries | /earnings | /notifications | /profile
                                              ├── /notifications (app bar)
                                              ├── quick actions → tabs
                                              └── offer banner → /delivery/offer | /delivery/active

/profile ──→ /profile/edit | /settings | /support ──→ /support/safety

/delivery/offer ──accept──→ /delivery/active ──→ /delivery/verify | /delivery/issue ──→ /home (finish)

/deliveries/:id   /earnings/:id   /notifications/:id  (list → detail)

/coming-soon  (orphan — no Welcome link)
/profile/vehicle   /profile/documents  (planned — not implemented)
```

---

## 9. Prototype flows (Figma target)

| ID | Flow | Status |
|----|------|--------|
| A | Welcome → Login → OTP → Home | Flutter ✅ · Figma partial · Proto partial |
| B | Home → Online → Offer → Accept | Partial |
| C | Accept → Merchant → Pickup | Missing Figma sub-frames |
| D | Pickup → Customer → Deliver → Success | Partial |
| E | Reject / Expire / No offer | Partial |
| F | History → Detail | Complete Flutter |
| G | Earnings → Detail | Complete Flutter |
| H | Profile → Settings → Dark → EN | Complete Flutter · Flow H test ✅ |
| I | Profile → Edit → Save | Complete Flutter |
| J | Vehicle → Documents | **Missing** |
| K | Notifications → Detail | Complete Flutter |
| L | Support → Help → Contact | Help/Contact **missing** |
| M | Offline → Retry | Partial |
| N | Permission denied → Settings | **Missing** |

---

## 10. Button inventory (starter — expand per batch)

| Button ID | AR | EN | Screen | Figma frame | Flutter file | Route | Expected action | Flutter | Figma proto | Device | Result |
|-----------|----|----|--------|-------------|--------------|-------|-----------------|---------|-------------|--------|--------|
| BTN-AUTH-001 | ابدأ | Start | Welcome | DRV-AUTH-001 | `welcome_screen.dart` | `/` | → Login | ✅ | P | P | PASS |
| BTN-AUTH-002 | — | Locale toggle | Welcome | DRV-AUTH-001 | same | `/` | Toggle AR/EN | ✅ | P | P | PASS |
| BTN-AUTH-003 | إرسال رمز التحقق | Send code | Login | DRV-AUTH-003 | `login_screen.dart` | `/login` | → OTP | ✅ | P | P | PASS |
| BTN-AUTH-004 | تحقق | Verify | OTP | DRV-AUTH-004 | `otp_verification_screen.dart` | `/login/otp` | → Home | ✅ | P | P | PASS |
| BTN-HOME-001 | — | Notifications | Home | DRV-HOME-001 | `home_screen.dart` | `/home` | → Notifications | ✅ | P | P | PASS |
| BTN-HOME-002 | تسجيل الخروج | Sign out | Home | DRV-HOME-001 | same | `/home` | Dialog → logout | ✅ | P | P | PASS |
| BTN-HOME-003 | — | Go available | Home | DRV-HOME-002 | `driver_availability_card.dart` | `/home` | Toggle availability | ✅ | P | P | PASS |
| BTN-OFFER-001 | قبول | Accept | Offer | DRV-OFFER-001 | `incoming_delivery_offer_page.dart` | `/delivery/offer` | → Active | ✅ | P | P | PASS |
| BTN-OFFER-002 | رفض | Reject | Offer | DRV-OFFER-001 | same | `/delivery/offer` | → Home cooldown | ✅ | P | P | PASS |
| BTN-PROF-001 | تعديل | Edit | Profile | DRV-PROF-001 | `profile_screen.dart` | `/profile` | → Edit | ✅ | P | P | PASS |
| BTN-PROF-002 | الإعدادات | Settings | Profile | DRV-PROF-001 | same | `/profile` | → Settings | ✅ | P | P | PASS |
| BTN-SET-001 | داكن | Dark | Settings | DRV-SET-001 | `settings_screen.dart` | `/settings` | Theme dark | ✅ | P | P | PASS |
| BTN-SET-002 | English | English | Settings | DRV-SET-001 | same | `/settings` | Locale EN | ✅ | P | P | PASS |
| BTN-SUP-001 | — | Safety | Support | DRV-SUP-001 | `support_screen.dart` | `/support` | → Safety | ✅ | P | P | PASS |
| BTN-VEH-001 | — | Vehicle | Profile | DRV-PROF-003 | — | — | → Vehicle | ❌ | ❌ | — | NOT CONNECTED |
| BTN-DOC-001 | — | Documents | Profile | DRV-PROF-004 | — | — | → Documents | ❌ | ❌ | — | NOT CONNECTED |

**Rule:** Any new button must be added to this table before batch close.

---

## 11. Route inventory

| Route | Registered | Reachable in-app | Notes |
|-------|------------|------------------|-------|
| `/` | ✅ | ✅ | Welcome |
| `/login` | ✅ | ✅ | |
| `/login/otp` | ✅ | ✅ | |
| `/home` | ✅ | ✅ | |
| `/deliveries` | ✅ | ✅ | |
| `/deliveries/:id` | ✅ | ✅ | |
| `/earnings` | ✅ | ✅ | |
| `/earnings/:id` | ✅ | ✅ | |
| `/notifications` | ✅ | ✅ | |
| `/notifications/:id` | ✅ | ✅ | |
| `/profile` | ✅ | ✅ | |
| `/profile/edit` | ✅ | ✅ | |
| `/profile/vehicle` | ❌ | ❌ | Planned |
| `/profile/documents` | ❌ | ❌ | Planned |
| `/settings` | ✅ | ✅ | |
| `/support` | ✅ | ✅ | |
| `/support/safety` | ✅ | ✅ | |
| `/delivery/offer` | ✅ | ⚠️ | Banner only |
| `/delivery/active` | ✅ | ⚠️ | Banner / accept / QA shortcut |
| `/delivery/verify` | ✅ | ⚠️ | From active stage |
| `/delivery/issue` | ✅ | ⚠️ | From active stage |
| `/coming-soon` | ✅ | ❌ | Orphan |

---

## 12. UI states inventory

| State | Shared widget | Used in | Figma | Flutter | Device |
|-------|---------------|---------|-------|---------|--------|
| Loading | `SaeqLoadingSkeleton`, button spinners | Profile, lists, delivery | C | P | P |
| Empty | `SaeqEmptyState` | History, earnings, notifications, support | C | C | P |
| Error | `SaeqErrorState`, inline auth errors | Lists, profile, login | C | C | P |
| Offline | `SaeqOfflineBanner` | Home | P | P | P |
| Success | Snackbars, navigation | Edit profile, OTP, delivery finish | P | P | P |
| Disabled | Buttons | Loading states | P | P | P |

---

## 13. Light / Dark results

| Area | Light | Dark | Notes |
|------|-------|------|-------|
| Auth | P | P | Final `#0D4F3C` CTA both modes |
| Shell tabs | P | P | DS2 semantic colors |
| Settings | P | P | Theme switch works |
| Delivery | P | P | **PENDING** full device matrix |
| **Overall** | **PENDING** formal sign-off | **PENDING** | Batch 10 |

---

## 14. Arabic / English results

| Area | AR RTL | EN LTR | Notes |
|------|--------|--------|-------|
| Auth | P | P | Inc 4 device QA passed |
| Shell | P | P | |
| Profile/Settings | P | P | Flow H covers Settings EN |
| **Overall** | **PENDING** formal sign-off | **PENDING** | Batch 10 |

---

## 15. RTL / LTR results

**PENDING** — formal device matrix in Batch 10. Widget tests cover smoke for Home/Welcome.

---

## 16. Responsive results

**PENDING** — Batch 10. Design spec: 390×844 primary, 320dp narrow, 1.3× text scale (`STEP6_RESPONSIVE_ACCESSIBILITY_REVIEW.md`).

---

## 17. Real device results

| Batch | Device | Date | Scenarios | Result | Artifacts |
|-------|--------|------|-----------|--------|-----------|
| Inc 4 QA | VKP-NX9 | 2026-07-28 | I4 + DS2 | **PASSED** (owner) | `.backup/device-qa-vkp-*` |
| UI-First Batch 1 | — | — | Inventory only | N/A | — |
| UI-First Batch 2+ | **PENDING** | — | Per mapping flows | — | `.backup/device-qa-ui-first-*` |

---

## 18. Screenshots

**PENDING** — captured per batch under `.backup/device-qa-ui-first-YYYYMMDD/` (not committed).

---

## 19. Videos

**PENDING** — primary flows A, B, D, H after Figma prototype + Flutter parity.

---

## 20. Bugs found

| ID | Severity | Screen | Description | Status |
|----|----------|--------|-------------|--------|
| — | — | — | No new bugs filed in Batch 1 docs | — |

Prior known visual deltas (Inc 4 Final Visual QA): loading CTA spinner-only, some EN title 24px vs Figma 22px, CTA weight w600 vs Bold.

---

## 21. Bugs fixed

| ID | Fix | Commit |
|----|-----|--------|
| CI-001 | Unused imports in fake E2E harness | `41b2abd` |

---

## 22. Remaining issues

1. **22 missing screens** per owner 62-screen checklist (see mapping).
2. **Figma prototype flows A–N** not fully wired.
3. **Vehicle / Documents** routes and screens missing.
4. **Permission screens** missing.
5. **Help / Contact support** missing.
6. **`/coming-soon`** orphan route.
7. **E2E flows A–G** paused (by directive).
8. **Figma Batch 2** Auth + Onboarding + Flow A — **IN PROGRESS**.

---

## 23. Approval status

| Gate | Status |
|------|--------|
| All screens in Figma | ❌ |
| All screens in Flutter | ❌ |
| All buttons connected | ❌ |
| All routes work | ⚠️ partial |
| Real device validated | ⚠️ partial (Inc 4 only) |
| Analyze / Test / CI | ✅ on current branches |
| Owner UI approval | ❌ **PENDING** |
| Phase 2.6 UI complete | ❌ **IN PROGRESS** |

---

## 24. Batch execution tracker

| Batch | Scope | Figma | Flutter | Device | PR | Status |
|-------|-------|-------|---------|--------|-----|--------|
| 1 | Inventory + audit | — | — | — | [#7](https://github.com/jari-tach/jari-platform/pull/7) | **Merged** `e41c580` |
| 1b | Mapping + report baseline | — | — | — | **PENDING** | Docs PR open |
| 2 | Auth + Onboarding (Figma) | **IN PROGRESS** | **NOT AUTHORIZED** | **PENDING** | — | Figma only |
| 3 | Home + Availability | Pending | Pending | Pending | — | Not started |
| 4 | Offers + states | Pending | Pending | Pending | — | Not started |
| 5 | Delivery lifecycle | Pending | Pending | Pending | — | Not started |
| 6 | History + Earnings + Notifications | Pending | Pending | Pending | — | Not started |
| 7 | Profile + Vehicle + Documents | Pending | Pending | Pending | — | Not started |
| 8 | Settings + Support + Safety | Pending | Pending | Pending | — | Not started |
| 9 | Shared states + permissions | Pending | Pending | Pending | — | Not started |
| 10 | RTL/LTR + themes + responsive | Pending | Pending | Pending | — | Not started |
| 11 | Real device fixes | — | Pending | Pending | — | Not started |
| 12 | Final UI acceptance APK | — | Pending | Pending | — | Not started |

---

## 25. Final acceptance criteria (owner — 20 points)

| # | Criterion | Met |
|---|-----------|-----|
| 1 | All screens in Figma | ❌ |
| 2 | All screens in Flutter | ❌ |
| 3 | All buttons linked | ❌ |
| 4 | All routes work | ⚠️ |
| 5 | No orphan screens | ❌ |
| 6 | No silent buttons | ❌ |
| 7 | Flows end-to-end | ⚠️ |
| 8 | Real Android device | ⚠️ |
| 9 | No critical overflow | ⚠️ |
| 10 | No clipped text | ⚠️ |
| 11 | AR + EN | ⚠️ |
| 12 | RTL + LTR | ⚠️ |
| 13 | Light + Dark | ⚠️ |
| 14 | Loading/Empty/Error/Offline | ⚠️ |
| 15 | Analyze pass | ✅ |
| 16 | Tests pass | ✅ (662) |
| 17 | Android build pass | ✅ (CI) |
| 18 | CI green | ✅ (PR #6, #7) |
| 19 | Report complete | ⚠️ (this doc — living) |
| 20 | Owner approval | ❌ |

---

## 26. Related documents

- `docs/PHASE_2_6_SCREEN_INVENTORY.md`
- `docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md`
- `docs/PHASE_2_6_COMPLETE_DRIVER_UI_PLAN.md`
- `docs/design/FIGMA_SOURCE_OF_TRUTH.md`
- `docs/design/STEP6_SCREEN_INVENTORY.md`
- `docs/design/STEP6_DESIGN_TO_CODE_GAP_MAP.md`
- `docs/testing/REAL_ANDROID_DEVICE_TEST_PLAN.md`

---

*This report is updated after each batch. Do not mark Phase 2.6 UI complete until §25 all ✅ and owner sign-off.*
