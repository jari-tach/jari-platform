# Button Action Audit — Critical Controls

> **Audit date:** 2026-08-02  
> **Method:** Code reading only (no Device QA)  
> **Related PRs:** [#31](https://github.com/jari-tach/jari-platform/pull/31) (Idempotency-Key charset), [#33](https://github.com/jari-tach/jari-platform/pull/33) (accept → local `DeliveryStatus`), [#35](https://github.com/jari-tach/jari-platform/pull/35) (revision-scoped command ids)

Guards common across delivery mutations:

- `_commandInFlight` / `state.isProcessing` → early return; UI disables via `processing ? null : …`
- Deterministic `localCommandId(...)` → `Idempotency-Key` (PR #31 charset; PR #35 adds `serverRevision` scope for lifecycle)
- Ledger replay reuses stored `commandId`

---

## 1. OTP submit

| | |
|--|--|
| **UI** | `otp_verification_screen.dart` → `_verify` |
| **Controller** | `AuthController.verifyOtp` |
| **Remote** | `RemoteAuthenticationRepository.verifyOtp` → `HttpAuthRemoteDataSource` (`POST /v1/auth/otp/verify`) |
| **Success** | Session applied; `AuthControllerState.authenticated`; router sends authenticated users to `/home` |
| **Fail** | `AuthError` mapped; returns to `otpRequested` with error (or expired); blocking UI for network/rate-limit/storage |
| **Offline** | Surface as network-class auth errors (`NetworkUnavailableAuthError` / timeout / server unavailable) |
| **Idempotency-Key** | Yes — `IdempotencyKeyFactory.next()` on verify (UUID-style, contract-safe). Request OTP: no I-key |
| **Double-tap** | `_isBusy` guard; UI skips when `isBusy` or code incomplete |

Also: stable `device.deviceId` UUID (PR #30) on verify body.

---

## 2. Availability toggle

| | |
|--|--|
| **UI** | `DriverAvailabilityCard` → `requestAvailable` / `requestUnavailable` |
| **Controller** | `AvailabilityController` |
| **Use case** | `RequestAvailabilityChange` |
| **Remote** | `RemoteDriverAvailabilityRepository` → `PUT /v1/drivers/me/availability` |
| **Success** | Server wire → domain status emitted; UI shows available/unavailable |
| **Fail** | Failures retained on last stable (`ActiveAssignmentConflict`, sync conflict, suspended, etc.) |
| **Offline** | Controller blocks go-available when `state.isOffline`; ADR-017; unavailable may still be intended offline in local path. Remote eligibility WIP requires online |
| **Idempotency-Key** | Yes — new factory key per PUT |
| **Double-tap** | `_commandInFlight`; processing view disables toggle |

**Issue #32:** HEAD maps backend `offline` → connectivity `offline` (blocks go-available). WIP maps to `unavailable` + remote eligibility. **Still blocked if** `RemoteDriverAvailabilityRepository` treats all `unavailable→available` as suspended.

---

## 3. Offer accept

| | |
|--|--|
| **UI** | `delivery_offer_card.dart` / offer page |
| **Controller** | `DeliveryController.acceptCurrentOffer` |
| **Use case** | `AcceptDeliveryOfferAndBindBusy` / `AcceptDeliveryOffer` |
| **Remote** | `POST /v1/offers/{id}/accept` body `{aggregateVersion}` |
| **Success** | Assignment persisted; busy bind; active delivery path (**PR #33** maps canonical `pickupAwaitingManualConfirmation` → local status so Active Delivery / Confirm pickup appear) |
| **Fail** | Typed delivery failures; bind failure may preserve assignment |
| **Offline** | Preconditions (`connectivityOnline`, availability); accept policy ADR-024; UI `canAccept` false when offline/processing |
| **Idempotency-Key** | Yes — `localCommandId(driver, offerId, accept)` (**PR #31**). Offer accept does **not** need revision scope (offer id is the target); lifecycle uses PR #35 scope |
| **Double-tap** | `_commandInFlight` + `canAccept` |

---

## 4. Offer reject

| | |
|--|--|
| **UI** | Offer card reject |
| **Controller** | `DeliveryController.rejectCurrentOffer` |
| **Use case** | `RejectDeliveryOffer` |
| **Remote** | `POST /v1/offers/{id}/reject` |
| **Success** | Clears active offer list |
| **Fail** | Failure state with offer retained |
| **Offline** | Preconditions pass `connectivityOnline` into use case |
| **Idempotency-Key** | Yes — `localCommandId(..., reject)`; remote may fallback to `offerId` |
| **Double-tap** | `_commandInFlight` + `canReject` |

---

## 5. Confirm pickup

| | |
|--|--|
| **UI** | `active_delivery_page.dart` primary action → `advanceWorkflow(confirmPickup)` |
| **Controller** | Remote branch when `ConfirmPickupRemote` wired |
| **Use case** | `ConfirmPickupRemote` |
| **Remote** | `POST .../pickup-confirmation` |
| **Success** | Ack advances local workflow (pickup → en route) |
| **Fail** | Failure message on active page; processing cleared |
| **Offline** | Network classification; pending ledger / retry path for commands |
| **Idempotency-Key** | Yes — `localCommandId` + **`scope: serverRevision` (PR #35)** |
| **Double-tap** | processing disables button; `_commandInFlight` |

Depends on PR #33 for assignment to exist after accept.

---

## 6. Navigate (Maps)

| | |
|--|--|
| **UI** | `SaeqContactActionsRow` on `active_delivery_page.dart` |
| **Action** | Builds Google Maps search URL from pickup/dropoff **label**, **copies to clipboard**, snackbar |
| **Remote** | None |
| **Success** | Clipboard + snackbar only |
| **Fail / Offline** | N/A (local clipboard) |
| **Idempotency-Key** | N/A |
| **Double-tap** | No in-flight guard (harmless re-copy) |

**Gap:** Does **not** call `UrlLauncherExternalNavigationGateway` (that path exists on map-preview / location feature). Journey “Navigate” is **placeholder**.

---

## 7. Record arrival

| | |
|--|--|
| **UI** | **No manual button** (comment on active page: automatic geofence only) |
| **Controller** | Location stream → geofence → `ReportAutomaticArrivalRemote` |
| **Remote** | `POST .../arrival` with evidence payload |
| **Success** | Stage → arrived; unlocks verify/confirm path |
| **Fail** | Failure retained; may retry via pending sync |
| **Offline** | Command ledger / pending sync |
| **Idempotency-Key** | Yes — revision-scoped (**PR #35**) |
| **Double-tap** | Stream/subscription cancellation; command in-flight |

Related: PR #34 stationary geofence on device stream.

---

## 8. Confirm delivery

| | |
|--|--|
| **UI** | `delivery_verify_page.dart` (remote ignores trial code) |
| **Controller** | verify / confirm path |
| **Use case** | `ConfirmDeliveryRemote` (remote) or `VerifyDeliveryCode` (fake) |
| **Remote** | `POST .../delivery-confirmation` |
| **Success** | Summary stage; busy release on complete summary |
| **Fail** | Error on verify page |
| **Offline** | Ledger / failure classification |
| **Idempotency-Key** | Yes — revision-scoped (**PR #35**) |
| **Double-tap** | `isProcessing` disables actions |

---

## 9. Cancel

| | |
|--|--|
| **UI** | Verify / issue pages → `cancelActiveDelivery` |
| **Use case** | `CancelDeliveryRemote` or Fake local cancel record |
| **Remote** | `POST .../cancel` |
| **Success** | Clears assignment / stops arrival watch |
| **Fail** | Failure state |
| **Offline** | Fake: local record only; remote: network errors |
| **Idempotency-Key** | Yes — revision-scoped (**PR #35**) |
| **Double-tap** | processing / `_commandInFlight` |

---

## 10. Report issue

| | |
|--|--|
| **UI** | `delivery_issue_page.dart` → `reportIssueRemote(code:)` |
| **Use case** | `ReportDeliveryIssueRemote` or Fake workflow advance |
| **Remote** | `POST .../issues` |
| **Success** | Issue stage / ack |
| **Fail** | Failure messaging |
| **Offline** | Same family as other lifecycle commands |
| **Idempotency-Key** | Yes — revision-scoped (**PR #35**) |
| **Double-tap** | processing disables submit |

---

## 11. Logout

| | |
|--|--|
| **UI** | `settings_screen.dart` destructive confirm |
| **Sequence** | `AvailabilityController.prepareForLogout` → `AuthController.signOut` |
| **Remote** | Best-effort `POST /v1/auth/logout` with I-key; local clear always proceeds |
| **Success** | Unauthenticated; contact memory + realtime closed |
| **Fail** | Secure storage failure can restore previous session UI; availability prep failure does not block auth sign-out |
| **Offline** | Logout remote catch swallowed; local session cleared |
| **Idempotency-Key** | Yes on logout remote |
| **Double-tap** | `signingOut` / already unauthenticated early return; dialog confirm |

---

## PR cross-reference (delivery keys)

| PR | What it fixed for buttons |
|----|---------------------------|
| **#31** | Accept/reject/pickup/arrival/confirm/cancel/issue keys no longer contain `:` → Backend stops `VALIDATION_ERROR` on I-key |
| **#33** | Accept success actually yields Active Delivery + Confirm pickup (status mapping) |
| **#35** | Lifecycle retries after QA reset / recycled delivery UUID avoid `IDEMPOTENCY_CONFLICT` by scoping key with `serverRevision` |
