# STEP 3 — Item 26 · Loading Offers Root Cause

> **Status:** ROOT CAUSE IDENTIFIED — failing regression test added  
> **Baseline SHA:** `cad0488e40fdec36aed5af3f0e048b4bf75ecc82`  
> **Fix layer:** Controller / provider wiring only (no Widget workaround)

## Symptom

After Accept Offer, `IncomingDeliveryOfferPage` keeps showing
`DeliveryOfferLoadingState` (“Loading offers” / “جارٍ تحميل العروض”).

## Evidence chain

1. Offer page shows loading when status is `initial` or `loading`
   (`incoming_delivery_offer_page.dart`).
2. Production accept preconditions use `ref.watch(availabilityControllerProvider)`
   (`delivery_providers.dart` → `_readAcceptPreconditions`).
3. Accept success then refreshes availability via
   `AvailabilityController.initialize()` (`_refreshAvailability`).
4. Availability state change rebuilds `DeliveryController`.
5. `DeliveryController.build()` always returns
   `DeliveryControllerState.initial()` and only schedules `initialize()` once
   (`_initializeStarted`).
6. Status remains `initial` → Loading Offers permanently.

## Ruled-out / lower likelihood

| Hypothesis | Verdict |
|---|---|
| Controller stays `loading` from accept processing | Lower — accept sets `ready` before refresh |
| Offer remains Active after Accept | Lower — accept path clears offers when assignment exists |
| Route waits for missing state | UI already handles `ready` + assignment |
| Fake offer stream re-issues offer | Would show offer card, not Loading |
| Assignment persistence delay | Accept tests persist before ready |
| Restore reopens Offer instead of Active Delivery | Separate restore path; not the sticky Loading path |

## Failing test (red before fix)

`test/features/delivery/presentation/delivery_controller_loading_offers_regression_test.dart`

Asserts after accept + availability refresh:

- status ≠ `initial` / `loading`
- status == `ready`
- `hasActiveAssignment == true`
- accepted offer no longer present

## Allowed fix targets

- `lib/features/delivery/presentation/controllers/delivery_controller.dart`
- `lib/features/delivery/presentation/providers/delivery_providers.dart`

Forbidden: Widget-only workaround; GPS; Backend; WebSocket.
