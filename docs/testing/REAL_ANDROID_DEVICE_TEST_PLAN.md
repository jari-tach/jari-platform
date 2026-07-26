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

