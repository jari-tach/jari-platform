# PHASE 2.6 — Unified Figma ↔ Flutter Screen Mapping

> **Status:** Flutter Batch 3: **PASS — MERGED TO MAIN** · STEP 1 **AWAITING PR #12 ONLY** · STEP 2 **LOCKED**
> **Baseline:** `main` @ `5a4015e` (PR [#11](https://github.com/jari-tach/jari-platform/pull/11) Batch 3 **MERGED**; PR #10 **MERGED**)
> **Batch 2:** **PASS — MERGED TO MAIN**
> **Batch 3:** **PASS — MERGED TO MAIN**
> **Figma preparation for STEP 2:** **READY — NOT IMPLEMENTED IN FLUTTER**
> **Batch 3 branch:** `feature/phase-2.6-flutter-home-availability-parity` → **MERGED**
> **Figma file:** [SAEQ Driver — Design System & UX](https://www.figma.com/design/MNJldEpkMxVjIavCPaPBFh/SAEQ-Driver-%E2%80%94-Design-System---UX) (`MNJldEpkMxVjIavCPaPBFh`)
> **Prototype:** Page `21 — High-Fidelity Screens` (`1:4`) · Final/Home `41:160`+

**Classification codes:** `C` complete · `P` partial · `M` missing · `FO` Figma-only · `FL` Flutter-only · `NC` not connected (nav/prototype)

---

## Summary counts (owner 62-screen checklist)

| Classification | Count | Notes |
|----------------|-------|-------|
| **C** Complete (Figma Final + Flutter + nav) | **18** | Auth core, shell tabs, settings, support/safety, delivery core |
| **P** Partial | **22** | Sub-states, permissions, wallet, help, many delivery milestones |
| **M** Missing | **22** | Splash, onboarding, vehicle, documents, permission screens, etc. |
| **NC** Not connected / orphan | **3** | `/coming-soon`, vehicle/doc routes, history→active shortcut |

---

## Master mapping table

| ID | Screen (EN) | Screen (AR) | Figma frame (target) | Flutter route | Flutter file | Entry | Prev → Next | Buttons (primary) | Impl | Figma | Proto | Device |
|----|-------------|-------------|----------------------|---------------|--------------|-------|-------------|---------------------|------|-------|-------|--------|
| 001 | Splash | شاشة البداية | `DRV-SYS-001-Splash` | — | — | cold start | — → Welcome | — | M | M | M | — |
| 002 | Welcome | الترحيب | `DRV-AUTH-001-Welcome` / Final `40:4` | `/` | `welcome_screen.dart` | launch | — → Login | Start, Locale | C | C | P | P |
| 003 | Onboarding | التعريف | `DRV-AUTH-002-Onboarding` | — | — | — | Welcome → Login | Skip, Next | M | M | M | — |
| 004 | Login | تسجيل الدخول | `DRV-AUTH-003-Login` / Final Auth Phone | `/login` | `login_screen.dart` | Welcome | Welcome → OTP | Submit, Retry | C | C | P | P |
| 005 | Phone Number | رقم الجوال | (same as Login) | `/login` | same | — | — | Submit | C | C | P | P |
| 006 | OTP Verification | التحقق | `DRV-AUTH-004-OTP` / Final OTP | `/login/otp` | `otp_verification_screen.dart` | Login | OTP → Home | Verify, Resend, Back | C | C | P | P |
| 007 | Auth Error | خطأ المصادقة | `DRV-AUTH-005-Error` | `/login` | inline states | Login/OTP | retry | Retry | P | C | P | P |
| 008 | Session Expired | انتهت الجلسة | `DRV-AUTH-006-SessionExpired` | — | — | — | → Login | Re-login | M | M | M | — |
| 009 | Home / Dashboard | الرئيسية | `Final/Home/*` `41:160`+ | `/home` | `home_screen.dart` | tab 0 / auth | shell | Nav×5, Quick×3, Notif (no Home logout) | C | C | P | P |
| 010 | Driver Availability | التوفر | `Card/Availability * Final` | `/home` (card) | `driver_availability_card.dart` | Home | all states | Go available/unavailable, Retry | C | C | P | P |
| 011 | Online State | متصل | `DRV-HOME-003-Online` | `/home` | availability card | Home | — | — | P | P | P | P |
| 012 | Offline State | غير متصل | `DRV-HOME-004-Offline` | `/home` | `saeq_offline_banner.dart` | Home | — | — | P | P | P | P |
| 013 | Incoming Offer | عرض جديد | `DRV-OFFER-001-Incoming` | `/delivery/offer` | `incoming_delivery_offer_page.dart` | Home banner | → Active | Accept, Reject | C | P | P | P |
| 014 | Offer Details | تفاصيل العرض | `DRV-OFFER-002-Details` | `/delivery/offer` | same | banner | — | Accept, Reject | P | P | P | P |
| 015 | Offer Accepted | قبول العرض | `DRV-OFFER-003-Accepted` | `/delivery/active` | transition | offer | → Active | — | P | P | P | P |
| 016 | Offer Rejected | رفض العرض | `DRV-OFFER-004-Rejected` | `/home` | cooldown empty | offer | Home | — | P | P | P | P |
| 017 | Offer Expired | انتهى العرض | `DRV-OFFER-005-Expired` | `/delivery/offer` | expired UI | offer | Home | — | P | C | P | P |
| 018 | No Offers | لا عروض | `DRV-OFFER-006-Empty` | `/home` | empty banner | Home | — | Refresh | P | P | P | P |
| 019 | Active Delivery | توصيل نشط | `DRV-DELIVERY-001-Active` | `/delivery/active` | `active_delivery_page.dart` | accept/banner | stages | Primary CTA, Issue, Verify | C | P | P | P |
| 020 | Navigate to Merchant | التوجيه للمتجر | `DRV-DELIVERY-002-NavMerchant` | `/delivery/active` | stage UI | active | next stage | Navigate, Arrived | P | M | M | — |
| 021 | Arrived at Merchant | وصلت للمتجر | `DRV-DELIVERY-003-ArriveMerchant` | `/delivery/active` | stage | active | pickup | Confirm | P | M | M | — |
| 022 | Pickup Verification | تحقق الاستلام | `DRV-DELIVERY-004-PickupVerify` | `/delivery/verify` | `delivery_verify_page.dart` | active | active | Submit | P | P | P | P |
| 023 | Order Collection | استلام الطلب | `DRV-DELIVERY-005-Collect` | `/delivery/active` | stage | active | transit | Confirm | P | M | M | — |
| 024 | Pickup Issue | مشكلة استلام | `DRV-DELIVERY-006-PickupIssue` | `/delivery/issue` | `delivery_issue_page.dart` | active | active | Submit | P | P | P | P |
| 025 | Navigate to Customer | التوجيه للعميل | `DRV-DELIVERY-007-NavCustomer` | `/delivery/active` | stage | active | arrive | Navigate | P | M | M | — |
| 026 | Arrived at Customer | وصلت للعميل | `DRV-DELIVERY-008-ArriveCustomer` | `/delivery/active` | stage | active | verify | Confirm | P | M | M | — |
| 027 | Delivery Verification | تحقق التسليم | `DRV-DELIVERY-009-DeliverVerify` | `/delivery/verify` | same | active | active | Submit | P | P | P | P |
| 028 | Proof of Delivery | إثبات التسليم | `DRV-DELIVERY-010-POD` | `/delivery/verify` | same | active | summary | Confirm | P | M | M | — |
| 029 | Delivery Success | نجاح التسليم | `DRV-DELIVERY-011-Success` | `/delivery/active` | summary | active | Home | Finish | P | P | P | P |
| 030 | Delivery Failure | فشل التسليم | `DRV-DELIVERY-012-Failure` | `/delivery/active` | error on summary | active | retry | Retry | P | P | P | P |
| 031 | Customer Unavailable | العميل غير متاح | `DRV-DELIVERY-013-CustomerNA` | `/delivery/issue` | issue types | active | active | Submit | P | M | M | — |
| 032 | Order Cancelled | إلغاء الطلب | `DRV-DELIVERY-014-Cancelled` | — | — | — | Home | — | M | M | M | — |
| 033 | Delivery History | سجل التوصيل | `DRV-HIST-001-List` | `/deliveries` | `deliveries_history_screen.dart` | tab 1 | → detail | Filter, row tap | C | P | P | P |
| 034 | History Details | تفاصيل التسليم | `DRV-HIST-002-Detail` | `/deliveries/:id` | same file | list | back | — | C | P | P | P |
| 035 | Earnings | الأرباح | `DRV-EARN-001-List` | `/earnings` | `earnings_screen.dart` | tab 2 | → detail | Filter, row tap | C | P | P | P |
| 036 | Earnings Details | تفاصيل الأرباح | `DRV-EARN-002-Detail` | `/earnings/:id` | same file | list | back | — | C | P | P | P |
| 037 | Wallet / Payout | المحفظة | `DRV-EARN-003-Wallet` | — | — | — | — | — | M | M | M | — |
| 038 | Notifications List | الإشعارات | `DRV-NOTIF-001-List` | `/notifications` | `notifications_screen.dart` | tab 3 | → detail | row tap | C | P | P | P |
| 039 | Notification Details | تفاصيل الإشعار | `DRV-NOTIF-002-Detail` | `/notifications/:id` | same file | list | back | Mark read | C | P | P | P |
| 040 | Empty Notifications | لا إشعارات | `DRV-NOTIF-003-Empty` | `/notifications` | empty state | tab | — | — | C | P | P | P |
| 041 | Profile | الملف الشخصي | `DRV-PROF-001-Profile` | `/profile` | `profile_screen.dart` | tab 4 | edit/settings/support | Edit, Settings, Support | C | P | P | P |
| 042 | Edit Profile | تعديل الملف | `DRV-PROF-002-Edit` | `/profile/edit` | `profile_edit_screen.dart` | profile | profile | Save | C | P | P | P |
| 043 | Vehicle Information | المركبة | `DRV-PROF-003-Vehicle` | — | — | profile (planned) | — | — | M | M | M | — |
| 044 | Driver Documents | المستندات | `DRV-PROF-004-Documents` | — | — | profile (planned) | — | — | M | M | M | — |
| 045 | Settings | الإعدادات | `DRV-SET-001-Settings` | `/settings` | `settings_screen.dart` | profile | profile | Theme×3, Lang×2, Sign out | C | P | P | P |
| 046 | Language | اللغة | (section in Settings) | `/settings` | same | settings | — | AR, EN | C | P | P | P |
| 047 | Light Theme | الوضع الفاتح | (section in Settings) | `/settings` | same | settings | — | Light | C | P | P | P |
| 048 | Dark Theme | الوضع الداكن | (section in Settings) | `/settings` | same | settings | — | Dark | C | P | P | P |
| 049 | Support | الدعم | `DRV-SUP-001-Support` | `/support` | `support_screen.dart` | profile | safety | Safety | P | P | P | P |
| 050 | Help Center | مركز المساعدة | `DRV-SUP-002-Help` | — | — | support (planned) | — | — | M | M | M | — |
| 051 | Contact Support | اتصل بالدعم | `DRV-SUP-003-Contact` | — | — | support (planned) | — | — | M | M | M | — |
| 052 | Safety | السلامة | `DRV-SUP-004-Safety` | `/support/safety` | `support_safety_screen.dart` | support | support | Back | C | P | P | P |
| 053 | Permissions Hub | الصلاحيات | `DRV-SYS-002-Permissions` | — | — | — | — | — | M | M | M | — |
| 054 | Location Permission | موقع | `DRV-SYS-003-LocationPerm` | — | — | — | — | Allow | M | M | M | — |
| 055 | Camera Permission | الكamera | `DRV-SYS-004-CameraPerm` | — | — | — | — | Allow | M | M | M | — |
| 056 | Notification Permission | إشعارات | `DRV-SYS-005-NotifPerm` | — | — | — | — | Allow | M | M | M | — |
| 057 | Offline (global) | بدون اتصال | `DRV-STATE-001-Offline` | various | `saeq_offline_banner` | connectivity | retry | — | P | P | P | P |
| 058 | General Error | خطأ عام | `DRV-STATE-002-Error` | various | `saeq_error_state.dart` | failures | retry | Retry | P | C | P | P |
| 059 | Loading | تحميل | `DRV-STATE-003-Loading` | various | skeletons/spinner | async | — | — | P | C | P | P |
| 060 | Empty | فارغ | `DRV-STATE-004-Empty` | various | `saeq_empty_state.dart` | no data | — | Action | P | C | P | P |
| 061 | Success | نجاح | `DRV-STATE-005-Success` | various | snackbars/nav | actions | — | — | P | P | P | P |
| 062 | Coming Soon | قريبًا | `DRV-SYS-006-ComingSoon` | `/coming-soon` | `shell_placeholder_screen.dart` | **NC** | Home | Home | P | M | NC | — |

**Legend — Device column:** `P` = passed on VKP-NX9 in prior Inc 4 QA; `—` = not yet tested under UI-First program.

**Locale / theme columns (per-screen formal matrix):** **PENDING** Batch 10. Until then, Auth/Shell Inc 4 QA covers AR RTL + EN LTR + Light + Dark at area level (see report §13–14). Do not mark per-screen PASS without device evidence.

| Column | Location in table |
|--------|-------------------|
| Screen ID | `ID` |
| Arabic / English name | `Screen (AR)` / `Screen (EN)` |
| Figma Frame | `Figma frame (target)` |
| Flutter file | `Flutter file` |
| Route | `Flutter route` |
| Entry / Prev / Next | `Entry` · `Prev → Next` |
| Buttons | `Buttons (primary)` |
| Status | `Impl` · `Figma` · `Proto` · `Device` |

---

## Prototype flows (target wiring)

| Flow | Path | Figma status | Flutter status |
|------|------|--------------|----------------|
| A | Welcome → Login → OTP → Home | Partial (Final Auth frames) | C |
| B | Home → Online → Offer → Accept | Partial | P |
| C | Accepted → Merchant → Arrive → Pickup | Missing sub-frames | P (stages collapsed) |
| D | Pickup → Customer → Deliver → Success | Missing sub-frames | P |
| E | Offer → Reject / Expire / Empty | Partial | P |
| F | Home → History → Detail | Partial | C |
| G | Home → Earnings → Detail | Partial | C |
| H | Profile → Settings → Dark → EN | Partial | C (Flow H test) |
| I | Profile → Edit → Save | Partial | C |
| J | Profile → Vehicle → Documents | Missing | M |
| K | Home → Notifications → Detail | Partial | C |
| L | Settings → Support → Help → Contact | Partial | P (help/contact M) |
| M | Offline → Retry → Online | Partial | P |
| N | Permission denied → Settings → Retry | Missing | M |

---

## Figma page structure (target — owner directive)

| # | Page | Repo mirror / action |
|---|------|----------------------|
| 1 | Cover | Update `FIGMA_SOURCE_OF_TRUTH.md` |
| 2 | Design System | Page `01 — Foundations & Components` |
| 3 | Components | Page `01` component sets |
| 4 | Authentication | Page `03` §01 + Final Auth |
| 5 | Home and Availability | Page `03` §02 |
| 6 | Offers | Page `03` §03 |
| 7 | Delivery Lifecycle | Page `03` §04–07 |
| 8 | Earnings and History | Page `03` §08–09 |
| 9 | Notifications | Page `03` §10 |
| 10 | Profile | Page `03` §11–12 |
| 11 | Settings | Page `03` §13 |
| 12 | Support and Safety | Page `03` §14 |
| 13 | States | Page `03` §16 |
| 14 | Prototype Flows | Page `03` connectors A–N |
| 15 | Developer Handoff | This mapping + gap map |
| 16 | Real Device Review Notes | `PHASE_2_6_UI_FIGMA_REAL_DEVICE_REPORT.md` §21 |

---

## Next actions (authorized sequence)

1. **Merge PR #7** (inventory) after owner review. — DONE (`e41c580`)
2. **Figma Batch 2:** Complete missing frames + wire Prototype flows A–N. — Figma Present **DEFERRED BY OWNER**
3. **Flutter Batch 2 Auth parity:** **PASS** on `feature/phase-2.6-flutter-auth-parity` (VKP-NX9 validated).
4. **Device validation** after each batch — VKP-NX9 only.
5. **Update this mapping** after each batch (Impl / Figma / Proto / Device columns).
6. **Batch 3:** **PASS — MERGED TO MAIN** (PR #10 + PR #11 → `5a4015e`). STEP 1 **AWAITING PR #12 ONLY**; STEP 2 **LOCKED**.

---

## Flutter Batch 2 — Auth routes (implementation)

| Route | Screen | Impl | Device (VKP-NX9) |
|-------|--------|------|------------------|
| `/splash` | SplashScreen | C | C |
| `/` | WelcomeScreen | C | C |
| `/onboarding` | OnboardingScreen | C | C |
| `/login` | LoginScreen | C | C |
| `/login/otp` | OtpVerificationScreen | C | C |
| `/session-expired` | SessionExpiredScreen | C | C |
| `/home` | HomeScreen (post-auth) | C | C |

**Main flow:** Splash → Welcome → Onboarding → Login → OTP → Home — **PASS** on device
**Subflows A1–A8:** **PASS** on device (see `PHASE_2_6_UI_FIGMA_REAL_DEVICE_REPORT.md`)

**Figma Present:** DEFERRED BY OWNER
**Screenshot comparison:** DEFERRED BY OWNER
**NOT CONNECTED buttons (Auth):** **0** (widget suite + HONOR VKP-NX9)
**Data:** Fake/Mock only (`246810` OTP, `0512345678` phone)

---

## Flutter Batch 3 — Home + Availability

| Route / surface | File | Figma Final | Impl | Device |
|-----------------|------|-------------|------|--------|
| `/home` Available | `home_screen.dart` | `41:160` | C | **PASS** |
| `/home` Unavailable | same | `41:273` | C | **PASS** |
| `/home` Busy | same | `41:211` | C | **PASS** |
| `/home` Offline | same | `41:308` | C | **PASS** |
| Availability card | `driver_availability_card.dart` | `39:2`/`39:6`/`39:13` | C | **PASS** |
| Connectivity bridge | `availability_connectivity_bridge.dart` | — | C (level reconcile + init replay) | M2 race **PASS**; Busy preserved **PASS** (USB ADB) |

**Flow B / M1–M8:** **PASS** (widget + device). Matrix **PASS**. NOT CONNECTED=**0**. Crash=**0**. Freeze=**0**.
**Loading offers** (after Accept): **KNOWN DEFECT — Deferred STEP 3** (do **not** claim fixed).
**Flutter Batch 3:** **PASS — MERGED TO MAIN**. STEP 1: **AWAITING PR #12 ONLY**; STEP 2 **LOCKED**.
**Figma preparation for STEP 2:** **READY — NOT IMPLEMENTED IN FLUTTER**
**Init race fix:** latest connectivity snapshot replayed after `AvailabilityController.initialize`; `_connectivityEpoch` + idempotent apply
**Home fixed logout CTA:** removed (NOT CONNECTED = 0 target)
**Logout:** Settings + `prepareForLogout()`
