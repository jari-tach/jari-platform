# Real Android Device Test Plan — SAEQ Driver

**Scope:** Debug build on a physical Android phone using
`FakeDeliveryRemoteDataSource` (no production backend).  
**Branch intent:** UI / device validation after pausing the Production Remote
Backend Adapter.

---

## 0. Pre-device audit (expected configuration)

| Item | Expected for debug device testing |
|------|-----------------------------------|
| `applicationId` / namespace | `com.example.saeq_driver` |
| `minSdk` / `targetSdk` | Flutter defaults (`flutter.minSdkVersion` / `flutter.targetSdkVersion`) |
| Debug INTERNET | `android/app/src/debug/AndroidManifest.xml` |
| Soft keyboard | `windowSoftInputMode="adjustResize"` |
| `AppConfig` | `AppConfig.init()` in `main()`; under `kDebugMode` forces `Environment.dev` |
| Fake remote | Active when `!AppConfig.isProduction` (ADR-027) |
| Local assignment DB | Drift via `DriverDatabase` when bootstrap succeeds |
| Auth | Trial Fake auth — phone `05XXXXXXXX` (10 digits) |
| Initial route | `/` (Welcome); login `/login`; home `/home` |
| DEV-ONLY availability | Debug eligibility + Fake-trial confirmation after go-available |

Production / release builds must **not** activate Fake remote or DEV-ONLY
eligibility / confirmation hooks.

---

## 1. Windows 10 — USB device connectivity

Prefer **USB debugging**. Do not assume wireless ADB.

### 1.1 One-time phone setup

1. Enable **Developer options** → **USB debugging**.
2. Connect the phone with a data-capable USB cable.
3. Accept the RSA fingerprint prompt on the phone.
4. Set USB mode to **File transfer (MTP)** if the device stays unauthorized.

### 1.2 SDK `adb` path (if `adb` is not on PATH)

Default Android SDK location on this machine:

```text
%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe
```

PowerShell helper for the current session:

```powershell
$env:Path += ";$env:LOCALAPPDATA\Android\sdk\platform-tools"
```

### 1.3 Exact commands (run from repo root)

```powershell
cd C:\Users\yahia\saeq_driver

flutter doctor -v
flutter devices
adb devices
flutter pub get
flutter run -d <device-id>
```

Example after `flutter devices` shows a phone:

```powershell
flutter run -d R58M123ABCD
```

Optional APK-only install path:

```powershell
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### 1.4 Connectivity troubleshooting

| Symptom | Check |
|---------|--------|
| `flutter devices` shows only Windows/Chrome/Edge | Cable, USB debugging, authorize prompt, another PC claiming ADB |
| `adb devices` → `unauthorized` | Re-plug; revoke USB debugging authorizations on phone; re-accept |
| `adb devices` → empty | Try another cable/port; install OEM USB drivers |
| `flutter run` fails on Gradle | Open Android Studio once; accept licenses; retry |

---

## 2. Device test flow (Fake offers)

### Happy path (predictable Fake offer)

1. Fresh install debug APK / `flutter run`.
2. Welcome → Sign in → enter trial phone `05` + 8 digits (e.g. `0512345678`).
3. Home loads; availability card visible.
4. Tap **Start receiving requests** (or equivalent primary available action).
5. Wait until status shows **confirmed available** (DEV-ONLY Fake-trial
   confirmation applies after local request when Fake remote is active).
6. Open the delivery offer banner (or navigate to `/delivery/offer`).
7. Confirm a Fake offer appears (auto-issue on fetch).
8. Confirm countdown ticks.
9. Accept once → assignment summary; availability becomes **busy**.
10. Force-stop / kill app → relaunch → assignment still present; busy restored.
11. (Separate session) Reject an offer → offer clears; stay available.
12. Airplane mode → attempt accept → expect offline / connectivity failure.
13. Rapid double-tap Accept → only one accept progresses (duplicate prevention).
14. Switch locale / system Arabic → RTL layout looks correct.
15. Background / foreground during countdown → UI recovers without crash.
16. Uninstall → reinstall → clean session (no leftover assignment).

---

## 3. Checklist

Copy this section into a test notes file or tick in PR review.

### Install / launch

- [ ] Fresh installation succeeds
- [ ] First launch reaches Welcome without crash
- [ ] Logcat / console shows `AppConfig: Initialized with environment: Environment.dev`
- [ ] Log shows `AppServiceRegistry: FakeDeliveryRemoteDataSource initialized`
- [ ] Log shows delivery stack summary (`remote=FakeDeliveryRemoteDataSource`, `localDb=Drift`)

### Authentication

- [ ] Invalid phone rejected with clear message
- [ ] Valid trial phone signs in
- [ ] Session reaches Home
- [ ] Sign-out returns to unauthenticated flow

### Availability

- [ ] Go available succeeds while online (DEV-ONLY Fake-trial eligibility)
- [ ] Status becomes confirmed available (not stuck pending forever)
- [ ] Go unavailable works when not busy
- [ ] Offline blocks confirmed available when NetworkMonitor reports offline

### Fake offer lifecycle

- [ ] Fake offer appears predictably after available + fetch/open offer surface
- [ ] Countdown updates every second
- [ ] Accept succeeds when online + confirmed available
- [ ] Busy availability binding after accept
- [ ] Assignment summary shows after accept
- [ ] Assignment persists after app restart
- [ ] Reject clears offer and does not create assignment
- [ ] After reject, empty state is visible before Fake re-issue (≈8s Fake cooldown)
- [ ] After Fake reject cooldown, a new offer appears without app restart
- [ ] Offline accept fails with user-visible error
- [ ] Double-tap Accept does not create duplicate assignments
- [ ] While local assignment exists, incoming offers stay suppressed

### UI / RTL (phone widths ~320 / 360 / 390 / 412 dp)

- [ ] Auth screen: no overflow; keyboard does not cover Sign In
- [ ] Home: availability + banner readable; sign-out reachable above bottom nav
- [ ] Offer full-screen: scrollable; Accept/Reject ≥ ~48dp; Arabic wraps
- [ ] Empty / loading / error states readable
- [ ] Bottom nav selected tab matches route; Arabic labels not clipped
- [ ] RTL: chevron/banner direction correct; no mirrored text clipping
- [ ] Landscape: no hard crash; primary content scrollable where practical

### Background / clean

- [ ] Background during offer → resume without crash
- [ ] Uninstall + clean reinstall starts unauthenticated with empty local DB

---

## 4. Development logs to watch (no secrets)

Safe markers (no tokens / phone / PII):

| Marker | Meaning |
|--------|---------|
| `AppConfig: Initialized with environment: …` | Env selection |
| `AppServiceRegistry: … initialized` | Service activation |
| `AppServiceRegistry delivery stack: …` | Fake remote + Drift wiring |
| `DEV-ONLY: Fake-trial availability eligibility granted…` | Debug eligibility |
| `DEV-ONLY: applying Fake-trial availability confirmation…` | Debug confirm |
| `FakeDeliveryRemote: auto-issued offer on fetch…` | Offer mint |
| `FakeDeliveryRemote: acceptOffer succeeded` | Accept remote |
| `FakeDeliveryRemote: rejectOffer succeeded` | Reject remote |
| `FakeDeliveryRemote: skip auto-issue (reject cooldown)` | Empty cooldown active |
| `FakeDeliveryRemote: auto-issued offer after reject cooldown` | Post-cooldown re-issue |
| `DeliveryAcceptBind: busy bind succeeded` | ADR-025 busy bind |

Do **not** log access tokens, raw phone numbers, or secure-storage payloads.

---

## 5. Out of scope for this plan

- Production Backend adapter
- Release/store builds as the primary test vehicle
- Wireless ADB as the default path
- Map / live journey UI
- Push notifications

---

## 6. Alpha execution log (VKP NX9)

| Field | Value |
|-------|--------|
| Device | VKP NX9 (`AP4EVB6423004646`) |
| Android | 16 / API 36 |
| Execution date | 2026-07-26 |
| Command | `flutter run -d AP4EVB6423004646` |
| Fake remote | Observed in logs |
| Drift | Observed in logs |

### Scenario results

| ID | Scenario | Result | Notes |
|----|----------|--------|-------|
| A | Fresh launch | **Pass** | Welcome RTL, SafeArea OK after clear install |
| B | Auth `0512345678` | **Pass** | Login trial mode; no OTP |
| C | Driver Home | **Pass** | Bottom nav selected index OK; RTL OK |
| D | Availability confirmed | **Pass** | After fix for Riverpod self-dependency |
| E | Offer discovery / banner | **Pass** | Banner + RTL chevron OK |
| F | Offer screen | **Pass** | Fields visible; earnings placeholder; no bottom nav |
| G | Reject | **Pass** | Re-verified 2026-07-26 after generation/cooldown fix |
| H | Accept + busy bind | **Pass** | Re-verified after cooldown re-issue (see §7) |
| I | Restart persistence | **Pass** | Busy + active assignment restored after force-stop |
| J | Offline accept | **Blocked** | Not re-run in generation/cooldown pass |
| K | Background / foreground | **Partial** | Unchanged from earlier Alpha notes |
| L | Foldable / landscape | **Not run** | Requires manual fold |

### Defects found and fixed in this Alpha

1. **P0** — DEV-ONLY confirmer called `availabilityControllerProvider` from inside itself → Riverpod `dependency != origin` crash. Fixed by returning update for self-apply.
2. **P1** — Authenticated cold start stayed on Welcome → assignment/busy not visible. Redirect Welcome→Home when authenticated.
3. **P1** — After restart, Fake re-issued offer while Drift assignment existed → wrong home banner. Suppress offers when local assignment present.
4. **P1** — Accept/Reject stayed enabled after countdown expired. Disable actions when offer expired in the card.
5. **P2** — Android logger used only `developer.log` (invisible in `flutter run`). Mirror via `debugPrint` in debug.
6. **P2** — Welcome Sign In not full-width. Full-width + 48dp min height.
7. **P1** — `accept` / `reject` / `refresh` bumped `_generation`, which cancelled/orphaned the active offer watch and could stop later Fake offer emissions. Fixed: snapshot generation only for those commands; bump only on `initialize` / dispose (session/lifecycle boundaries).
8. **P2 (Fake/debug only)** — Reject immediately auto-reissued the next Fake offer, so empty state was hard to observe. Fixed: deterministic **8s** `FakeDeliveryRemoteDataSource.rejectReissueCooldown` with watch `null` during cooldown, then wall-clock Timer re-issue (no production retry policy).

---

## 7. Generation / reject-cooldown verification (2026-07-26)

| Field | Value |
|-------|--------|
| Device | VKP NX9 (`AP4EVB6423004646`) |
| Build | `flutter build apk --debug` → `app-debug.apk` |
| Install | `adb install -r` after clear (`pm clear`) |
| Cooldown | `FakeDeliveryRemoteDataSource.rejectReissueCooldown` = **8 seconds** |
| Rationale | Long enough to observe empty UI on a real phone; short enough for Alpha loops; Fake/debug only |

### Steps executed

1. Confirmed available (DEV-ONLY Fake-trial).
2. Opened offer → **Reject**.
3. Observed empty: `لا توجد عروض متاحة` (`EMPTY_AFTER_REJECT=True`).
4. Waited cooldown (~10s including buffer) **without app restart**.
5. New Fake offer appeared (`OFFER_AFTER_COOLDOWN=True`) — watch remained alive.
6. **Accept** on the re-issued offer.
7. Home shows busy + **توصيل نشط**; no competing incoming reject/accept surface while assignment exists (final UI dump).
8. Force-stop → relaunch → busy + active assignment restored (`ASSIGNMENT_RESTORED_AFTER_RESTART=True`; `busy=True` / `active=True` on final dump).

Artifacts: `device_test_artifacts/gen_cooldown_device_report.txt`, screenshots `07_after_reject` … `12_restart_restore`.

### Automated regression coverage added

- Controller: reject clears offer; watch stays live and receives later offers; accept does not orphan watch; assignment suppresses offers; stale accept/reject ignored after re-init/dispose; duplicate accept/reject taps blocked; **reject → immediate refresh keeps watch alive**.
- Fake remote: reject → empty during cooldown; re-issue after cooldown elapses; watch emits `null` before re-issue; **rapid fetch during cooldown stays empty**.

### Race path (Reject → Refresh → Reject → cooldown → Accept → Restart)

Script: `device_test_artifacts/verify_race_fast.ps1`

| Check | Status |
|-------|--------|
| Unit: reject → immediate refresh → later offer | **Pass** |
| Unit: rapid fetch during Fake cooldown | **Pass** |
| Device race (fresh APK) | **Blocked** — VKP NX9 lockscreen (`mDreamingLockscreen=true`) |

Earlier slow UI automation (many `uiautomator dump`s) could exceed the 8s Fake Timer and look like “refresh re-issued”; the fast script avoids that. **Unlock the device** and re-run `verify_race_fast.ps1` to close the matrix (one stream / one assignment / one busy / no dup offers / no orphan).

---

## 8. PHASE 2.6 Increment 1 — device checklist

**Baseline:** `7d90851` / `alpha-stable-v1.0`

**Device:** VKP NX9 (`AP4EVB6423004646`)

**Constraint:** Fake UI only; do not regress offer generation / 8s reject cooldown / assignment suppression.

| ID | Scenario | Pass criteria |
|----|----------|---------------|
| I1-A | Bottom nav 5 tabs | Home, Deliveries, Earnings, Notifications, Profile visible; Settings **not** a root tab |
| I1-B | `/orders` compat | Opening `/orders` lands on Deliveries |
| I1-C | Home strip | Fake today earnings + trips (or acceptance placeholder) visible when signed in |
| I1-D | Offline banner | Airplane mode shows offline banner on Home; restore hides it |
| I1-E | Quick actions | Can open Deliveries / Notifications / Earnings from Home actions |
| I1-F | Offer path | Available → offer → Accept still works; banner → `/delivery/active` stub shows assignment summary |
| I1-G | Reject cooldown | Reject → empty → wait ≥8s → new offer (unchanged Alpha behavior) |
| I1-H | Sign-out confirm | Sign Out opens confirm dialog; Cancel keeps session; Confirm signs out |
| I1-I | Restart busy | Accept → force-stop → relaunch → busy + assignment still restored |

**Do not run on Inc 1:** OTP entry, stage advances past accepted, real maps/camera/payments.

---

## 9. PHASE 2.6 Increment 2 — device checklist

**Baseline:** after Inc 1 commit `271d170` (+ Inc 2 changes)

**Device:** VKP NX9 (`AP4EVB6423004646`)

| ID | Scenario | Pass criteria |
|----|----------|---------------|
| I2-A | Accept → Active stages | Primary CTA advances Assigned → … → Arrived customer |
| I2-B | Verify code | Code `1234` reaches Summary; wrong code shows error |
| I2-C | Issue + resume | Report issue at pickup or to-customer; Resume restores prior stage |
| I2-D | Finish summary | Availability → unavailable (`delivery.complete`) then assignment cleared; Home only after success |
| I2-D2 | Finish failure / retry | Failed release keeps summary on screen with error; retry succeeds; no Home on failure |
| I2-D3 | Rapid Finish | Double-tap Finish runs one completion; single Home navigation |
| I2-E | Restart mid-stage | Force-stop after Collected; relaunch restores stage + busy |
| I2-E2 | Restart on summary | Force-stop on summary; relaunch restores summary; no new offer until finish |
| I2-F | Offer regression | Reject cooldown 8s + accept still work |

**Do not run on Inc 2:** OTP, History/Earnings content, Settings language/theme (Inc 3–4).

---

## 10. PHASE 2.6 Increment 3 — device checklist

| ID | Scenario | Pass criteria |
|----|----------|---------------|
| I3-A | Deliveries tab | List + filters All/Delivered/Cancelled; open detail |
| I3-B | Earnings tab | List + filters; open detail amounts |
| I3-C | Notifications | List; open unread; Mark as read returns to list as read |
| I3-D | Active entry | From Deliveries, can open Active delivery route |
| I3-E | Production gate | Release/production must not construct Fake history/earnings/notif repos |

**Do not run on Inc 3:** OTP, Settings language/theme (Inc 4).

---

## 11. PHASE 2.6 Increment 4 — device checklist

**Baseline:** after Inc 3 commit `2aef3a0` (+ Inc 4 working tree changes)

**Device:** VKP NX9 (`AP4EVB6423004646`)

**Constraint:** Fake Alpha only; OTP trial code is in-memory Fake repo only — do **not** document or log OTP as production behavior.

| ID | Scenario | Pass criteria |
|----|----------|---------------|
| I4-A | OTP login | Sign out → Login with trial phone → OTP screen → valid Fake trial code → Home |
| I4-B | OTP resend | Resend disabled during cooldown; enabled after cooldown |
| I4-C | OTP invalid | Wrong code shows error; session not created |
| I4-D | Profile view | Sovereign fields read-only; masked phone display |
| I4-E | Profile edit | Edit fullName + email; save persists; sovereign fields unchanged |
| I4-F | Settings theme | Switch light → dark → system; survives restart |
| I4-G | Settings locale | Switch ar ↔ en when navigable; RTL/LTR updates |
| I4-H | Support unavailable | Support shows unavailable state; no invented contacts |
| I4-I | Support safety | Safety route opens; informational only |
| I4-J | Session storage | Tokens not in SharedPreferences (`AppPreferences` theme/locale only) |
| I4-K | Offer regression | Reject cooldown + accept still work after OTP re-login |

**Do not run on Inc 4:** production SMS, certificate pinning validation, real support dial/email.

### Execution log (2026-07-27 — final validation)

| Field | Value |
|-------|--------|
| Device | VKP NX9 (`AP4EVB6423004646`) |
| `adb devices` | **Empty — device not connected** |
| Debug APK | **Built** — `build/app/outputs/flutter-apk/app-debug.apk` |
| APK install | **Not performed** |
| Scenarios I4-A … I4-K | **Untested** |
| Quality Gate | analyze 0/0/1 · test 637/0/0 · build OK |

---

## 12. Design Sprint 2 — device checklist

**Baseline:** Inc 3 + Inc 4 working tree with temporary **Forest Green** `SaeqSemanticColors`

**Status:** **Implemented in working tree — awaiting device QA** (not approved, not committed). Widget/unit tests must pass in Quality Gate; device validation deferred when device unavailable.

| ID | Scenario | Pass criteria |
|----|----------|---------------|
| DS2-A | Home (light, AR) | Forest Green tokens; RTL; no overflow |
| DS2-B | Settings dark | Theme switch applies semantic colors |
| DS2-C | Settings EN | English locale when navigable |
| DS2-D | Profile + edit | Header, cards, buttons match sprint palette |
| DS2-E | Support | Unavailable + safety screens styled consistently |
| DS2-F | Deliveries / History | Filter chips + list rows use sprint widgets |
| DS2-G | Earnings | Earnings row + detail styling |
| DS2-H | Notifications | Notification row + unread styling |
| DS2-I | Login + OTP | OTP input + resend timer styling |
| DS2-J | Large text | Primary Inc 3+4 screens at ~1.3× text scale without hard overflow |

**Screenshot path (when run):** `.backup/device-qa-inc4-ds2-YYYYMMDD/` (non-committed)

### Execution log (2026-07-27 — final validation)

| Field | Value |
|-------|--------|
| Device | VKP NX9 (`AP4EVB6423004646`) |
| `adb devices` | **Empty — device not connected** |
| Debug APK | **Built** — not installed |
| Result | **Deferred — device not connected** |
| Screenshots | **None** — `.backup/device-qa-inc4-ds2-20260727/` not created |
| DS2-A … DS2-J | **Untested** |
| Quality Gate | analyze 0/0/1 · test 637/0/0 · build OK |

---

## 13. PHASE 2.6 Increment 5 — device checklist

**Baseline:** after Inc 4 merge on `main` (`dad8cb2` parent chain includes `9ad0ee9` + `fbb2ef7`)

**Scope:** Responsive / a11y validation + E2E Fake matrix (flows A–H) + docs closeout.

**Device:** VKP NX9 (`AP4EVB6423004646`) when available.

| ID | Flow | Scenario | Pass criteria |
|----|------|----------|---------------|
| I5-A | A | Sign in → available → offer → reject → reissue | Reject clears offer; cooldown respected; later offer appears |
| I5-B | B | Accept → full stage path → deliver | Stage machine completes; summary Finish returns Home |
| I5-C | C | Restart at major stages | Assignment + stage restored; busy reconciled |
| I5-D | D | Offline during active delivery | Offline UI visible; no silent accept |
| I5-E | E | History list → detail | Detail opens; sovereign Fake data only |
| I5-F | F | Earnings filter | Filter chips switch seeded periods |
| I5-G | G | Notifications mark-read | Detail mark-read persists unread state |
| I5-H | H | Profile → Settings theme/locale | Theme + locale switch; RTL/LTR updates |
| I5-I | — | Text scale ~1.3× | Inc 3+4 primary screens without hard overflow |
| I5-J | — | Narrow width 320dp | Chips scroll; nav captions ellipsis |
| I5-K | — | Offer regression | Reject cooldown + accept unchanged after Inc 5 polish |

**Widget-level E2E (Fake):** `test/integration/fake_e2e_flow_h_settings_theme_locale_test.dart` covers flow H.

### Execution log

| Field | Value |
|-------|--------|
| Device | **Pending** |
| Scenarios I5-A … I5-K | **Not run on device yet** |
| Widget E2E flow H | **PASS** (local, Increment 5 branch) |

