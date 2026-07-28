# PHASE 2.6 — UI Figma + Real Device Report

> **Program:** UI-First · Figma Interactive Prototype · Real Device Validation  
> **Repository:** jari-tach/jari-platform  
> **Status:** Flutter Auth Batch 2 — **PASS** (device-validated on HONOR VKP-NX9)  
> **Last updated:** 2026-07-28  
> **Main baseline:** `a00a328` (PR #8 merged)

---

## 1. Executive Summary

Flutter Authentication UI parity implemented on `feature/phase-2.6-flutter-auth-parity`, Fake/Mock data only, debug APK installed and exercised on **HONOR VKP-NX9**.

- **PR #7** inventory merged (`e41c580`).
- **PR #8** mapping/report baseline merged (`a00a328`) — owner one-time exception for cancelled iOS on docs-only PR.
- **Figma Present / screenshot comparison:** **DEFERRED BY OWNER** (does not block Flutter).
- Splash, Welcome, Onboarding, Login, OTP, Session Expired + error/loading/resend states wired.
- **NOT CONNECTED = 0** in Auth scope (device + widget suite).
- Real Android APK validation on HONOR VKP-NX9: **PASS** (Main Flow + A1–A8).

---

## 2. Figma references

| Field | Value |
|-------|--------|
| **Figma file** | [SAEQ Driver — Design System & UX](https://www.figma.com/design/MNJldEpkMxVjIavCPaPBFh/SAEQ-Driver-%E2%80%94-Design-System---UX) |
| **File key** | `MNJldEpkMxVjIavCPaPBFh` |
| **Figma Present** | **DEFERRED BY OWNER** |
| **Screenshot comparison** | **DEFERRED BY OWNER** |
| **Approved Figma version** | PENDING owner stamp |

---

## 3. Engineering references

| Field | Value |
|-------|--------|
| **PR #7 merge** | `e41c580` |
| **PR #8 merge** | `a00a328` |
| **Auth branch** | `feature/phase-2.6-flutter-auth-parity` |
| **Mapping** | `docs/PHASE_2_6_UI_FIGMA_FLUTTER_MAPPING.md` |
| **This report** | `docs/PHASE_2_6_UI_FIGMA_REAL_DEVICE_REPORT.md` |
| **QA artifacts (local only)** | `.backup/device-qa-ui-first-20260728/` |

---

## 4. APK / build

| Field | Value |
|-------|--------|
| **APK name** | `app-debug.apk` |
| **APK path** | `build/app/outputs/flutter-apk/app-debug.apk` |
| **Build type** | debug |
| **Approximate size** | ~162.5 MB (170431349 bytes) |
| **Build time (local)** | 2026-07-28 18:57 |
| **Commit SHA at build** | uncommitted Batch 2 tree on top of `a00a328` (APK rebuilt from working tree) |
| **Install result** | `adb install -r` **Success** on `AP4EVB6423004646` |
| **Package** | `com.example.saeq_driver` `1.0.0` (versionCode 1) |

---

## 5. Android device

| Field | Value |
|-------|--------|
| **Manufacturer** | HONOR |
| **Model** | VKP-NX9 |
| **Serial** | `AP4EVB6423004646` |
| **Android version** | 16 |
| **Resolution** | 1264×2728 |
| **Device language** | `ar-SA` |
| **App version** | 1.0.0 |
| **Test date** | 2026-07-28 |
| **Real device APK test** | **PASS** |

---

## 6. Deferred items (owner)

| Item | Status |
|------|--------|
| Figma Present on phone | **DEFERRED BY OWNER** |
| Figma vs device screenshot comparison | **DEFERRED BY OWNER** |
| iOS physical device test | **DEFERRED** — no physical iPhone currently available |

---

## 7. Flutter Auth Batch 2 — screens

| Screen | Route | Flutter status | Device |
|--------|-------|----------------|--------|
| Splash | `/splash` | Implemented | Captured (`17_splash_fresh.png`) |
| Welcome | `/` | Updated | PASS AR/EN + theme |
| Onboarding | `/onboarding` | Implemented | PASS Continue / Skip |
| Login | `/login` | Updated | PASS validation + send |
| OTP | `/login/otp` | Updated | PASS invalid / valid / resend timer |
| Session Expired | `/session-expired` | Implemented | PASS → Login |
| Home | `/home` | Existing | PASS after Fake OTP `246810` |

---

## 8. Buttons (Auth scope)

| Status | Count |
|--------|-------|
| CONNECTED | All Auth CTAs listed in directive (Start, Continue, Skip, Back, Send Code, Verify, Change Phone, Resend, Retry, Login Again, Locale, Theme, Confirm/demo Session) |
| INTENTIONALLY DISABLED | Primary CTAs while loading; Resend while cooldown timer active |
| NOT CONNECTED | **0** |

---

## 9. Flows (device)

| Flow | Widget tests | Device APK |
|------|--------------|------------|
| Main Splash→Welcome→Onboarding→Login→OTP→Home | PASS | **PASS** |
| A1 Skip → Login | PASS | **PASS** |
| A2 Validation → correct phone → Send | PASS | **PASS** |
| A3 Change Phone → Login → OTP | PASS | **PASS** |
| A4 Resend timer / UI present | Covered | **PASS** (timer state captured; 30s cooldown) |
| A5 Invalid OTP → error | PASS | **PASS** |
| A6 Session Expired → Login | PASS | **PASS** |
| A7 AR↔EN | PASS | **PASS** |
| A8 Light↔Dark | PASS | **PASS** |

Fake OTP: `246810` · Fake phone example: `0512345678`

---

## 10. Screenshots (local, not committed)

Directory: `.backup/device-qa-ui-first-20260728/`

| File | Coverage |
|------|----------|
| `03_welcome_ar_light.png` | Arabic + light |
| `04_welcome_en.png` | English |
| `05_welcome_theme.png` | Theme toggle |
| `06_onboarding.png` | Onboarding |
| `07_login.png` / `08_login_validation_error.png` | Login + validation |
| `09_otp.png` / `11_invalid_otp.png` / `16_otp_resend_timer_state.png` | OTP states |
| `10_change_phone_login.png` | A3 |
| `12_home.png` | Home after auth |
| `13_session_expired.png` / `14_session_to_login.png` | A6 |
| `15_a1_skip_login.png` | A1 |

---

## 11. Problems found / fixed

| Issue | Resolution |
|-------|------------|
| Cold start expected `/` Welcome; Splash-first broke `widget_test` | Updated tests for `/splash` |
| Device QA PowerShell script parse/encoding failures | Rewrote robust script; fixed int cast on tap coordinates |
| OTP→Home missed in first automated pass (EditText after invalid) | Retested with clear + Fake OTP; Home confirmed |

**Remaining issues:** none blocking Auth Batch 2. Pixel-perfect Figma screenshot comparison remains **DEFERRED BY OWNER**.

---

## 12. Quality Gate (pre-commit)

| Check | Result |
|-------|--------|
| `dart format` (scoped) | clean |
| `git diff --check` | clean |
| `flutter analyze` | No issues found |
| `flutter test` | PASS (full suite) |

---

## 13. Batch tracker

| Batch | Status |
|-------|--------|
| 1 Inventory (PR #7) | Merged |
| 1b Mapping/Report (PR #8) | Merged `a00a328` |
| 2 Flutter Auth parity | **PASS** (awaiting owner PR review; do not merge without approval) |
| 3+ | NOT AUTHORIZED |

---

## 14. Final decision

**Flutter Batch 2: PASS**

Evidence: widget suite + debug APK on HONOR VKP-NX9 (Main + A1–A8), NOT CONNECTED = 0.

*iOS Real Device Test: DEFERRED — no physical iPhone currently available*
