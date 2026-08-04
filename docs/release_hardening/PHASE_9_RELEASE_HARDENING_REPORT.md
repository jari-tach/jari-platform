# Phase 9 — Release Hardening Report

> **Status:** **CLOSED — CONDITIONAL PASS**  
> **Date:** 2026-08-04  
> **Plan:** `PHASE_9_RELEASE_HARDENING_PLAN.md`  
> **Branch:** `feature/step-4b-a-honor-live-geofence-validation`  
> **HEAD before:** `38633c4`  
> **Working tree:** Gate 9 remediations uncommitted (await «اعتمد الـ commit»)  
> **Constraints:** no PR #27 merge · no Gate 10 · no Merchant · no secrets in Git

## Baseline

| Item | Value |
| --- | --- |
| Origin sync at start | Yes @ `38633c4` |
| CI at start | GREEN — [30874151118](https://github.com/jari-tach/jari-platform/actions/runs/30874151118) |
| Local out-of-scope (unchanged, untracked) | evidence / design / plans / parse tools / generated CRLF noise |

## Identifiers

| Platform | Before | After |
| --- | --- | --- |
| Android `applicationId` / `namespace` | `com.example.saeq_driver` | **`com.saeq.driver`** |
| Android `MainActivity` package | `com.example.saeq_driver` | **`com.saeq.driver`** |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.saeqDriver` | **`com.saeq.driver`** |
| iOS tests | `com.example.saeqDriver.RunnerTests` | **`com.saeq.driver.RunnerTests`** |

No `com.example` remaining under `android/`, `ios/`, or `lib/`.

## Release signing

| Control | Status |
| --- | --- |
| Debug signing fallback removed from `release` | **Done** |
| `android/key.properties` + `*.jks` gitignored | **Done** (also in `android/.gitignore`) |
| Example file | `android/key.properties.example` |
| Local verify keystore (gitignored) | Used for release APK only; **not** production upload key |
| Handoff doc | `RELEASE_SECRETS_AND_SIGNING_HANDOFF.md` |

**Owner remaining:** deliver production upload keystore / iOS distribution certs out-of-band.

## Certificate pinning (`SaeqApiClient`)

| Control | Status |
| --- | --- |
| Policy + host scoping | `CertificatePinConfig` |
| DER pin validator | `CertificatePinValidator` |
| Dio `IOHttpClientAdapter` wiring | `applyCertificatePinning` |
| Loopback / HTTP Device QA skipped | **Yes** |
| Production release requires pins | **Yes** (`StateError` if empty) |
| Pin values not logged | **Yes** |
| Rotation guide | `CERTIFICATE_PINNING_ROTATION_GUIDE.md` |
| Tests | `test/core/network/certificate_pinning_test.dart` |

**Owner remaining:** supply live `SAEQ_TLS_PINS` for store builds.

## Security debt closed this gate

| Item | Action |
| --- | --- |
| Legacy `LoggingInterceptor` | Registered **only in `kDebugMode`**; Authorization redacted when present |
| Saeq HTTP debug logs | Emitted only in `kDebugMode` |
| Console logger | Default `warning+` in profile/release; no JSON metadata outside debug |
| Fake in profile/release | Reconfirmed via existing `BackendConfiguration` tests (suite green) |
| Android cleartext | Main NSC `cleartextTrafficPermitted=false`; debug allows loopback only |
| Permissions | Unchanged — foreground location only |
| Secure storage | Refresh tokens remain on `SecureAuthTokenStore` / flutter_secure_storage |

## Dependencies (selective, no mass upgrade)

| Package | Note | Severity |
| --- | --- | --- |
| `dio` 5.10→5.11 | Patch available, not blocking | Low |
| `flutter_secure_storage` major 10 | Major; defer | Accepted Risk |
| `get_it` major 9 | Major; defer | Accepted Risk |
| `js` discontinued (transitive) | Not direct path | Low |
| Known CVE blocking production path | **None identified requiring upgrade this gate** | — |

No Critical/High CVE remediation required for the live Driver path in this review.

## Verification

| Check | Result |
| --- | --- |
| `flutter analyze` | **No issues found** (after clean) |
| `flutter test` | **+1116 All tests passed** |
| Pinning + logging tests | Included |
| Fake guard tests | Covered in suite |
| `flutter build apk --debug` | **PASS** (`com.saeq.driver`) |
| `flutter build apk --release` | **PASS** with local gitignored keystore (66.7MB) |
| iOS build | Via CI after commit/push (not locally on Windows) |
| Secrets in Git | **None** (`key.properties` / `upload-keystore.jks` ignored) |

CI on Gate 9 commit: **pending** until owner orders commit + push.

## Release blockers inventory update

| ID | Item | Gate 9 outcome |
| --- | --- | --- |
| R1 | Replace `com.example` | **CLOSED** |
| R2 | Release signing ≠ debug | **CLOSED (structure)** — production secrets owner handoff |
| R3 | Certificate pinning on live client | **CLOSED (mechanism)** — production pins owner handoff |

## Behavior / production code

- **Production code changed:** Yes (IDs, signing gradle, NSC, pinning, logging gates).  
- **Driver journey behavior:** Unchanged functionally; TLS may fail closed in production release without valid pins (intentional).  
- **Dev/Device QA (`http://127.0.0.1`):** Pinning off; debug cleartext loopback allowed.

## Decision

**CLOSED as CONDITIONAL PASS**

Structure for production is complete. Remaining items are operational secret delivery (upload keystore, iOS signing materials, live TLS pins) — allowed under Gate 9 conditional rules.

## Not done

- Commit / push  
- Merge PR #27  
- Gate 10  
- Merchant  
- Committing any keystore or real pins
