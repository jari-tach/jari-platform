# STEP 4 — Implementation Progress

> **Status:** STEP 4A COMPLETE WITH OWNER-APPROVED DEVICE TEST DEFERRAL
> **Baseline:** `62d0ed1467b77f1b0c72b26283db96038aab9fc7`
> **Branch:** `feature/step-4-real-gps-permissions-maps-geofence`
> **ADR:** [ADR-029](../adr/ADR_029_DRIVER_LOCATION_MAPS_GEOFENCE.md)
> **STEP 5 Backend:** LOCKED

## Done in this increment

- ADR-029 accepted under owner STEP 4 authorization
- Pure-Dart geofence / accuracy / debounce policies + unit tests
- `LocationGateway` + Fake / Device adapters (`geolocator`, `permission_handler`)
- External navigation port + `url_launcher` adapter (no Map SDK / no API keys)
- Android / iOS foreground location permission declarations
- Single-delivery: `confirmPickup` → en-route; customer arrival via geofence
- Batch: `FakeBatchLocationController` geofence-driven (delay = sample interval)
- Optional lat/lng on Fake `DeliveryOrder` seed
- Regression: `step4_geofence_arrival_test.dart` + updated STEP 3 lifecycle wait

## STEP 4A — GPS timeout correction

### Root cause

The first Device QA run mapped GNSS acquisition timeout and other location
provider failures to `LocationProbeOutcome.offline`. That classification was
incorrect: obtaining a GPS/GNSS fix does not require internet connectivity,
and the resulting UI guidance incorrectly blamed connectivity.

### Corrected classification

- `offline` is reserved for operations that genuinely depend on the network.
- GNSS timeout with no usable sample → `unavailable`.
- Old last-known sample → `stale`.
- Fresh sample with accuracy above the arrival threshold (including the
  observed **±110 m**) → `weakAccuracy`.
- Permission and disabled-location-service outcomes remain distinct.
- Platform exceptions use a validated fallback or `unavailable`; never
  `offline`.

### Fallback and stream policy

1. Request one high-accuracy current fix (25 s bound).
2. On timeout, inspect `getLastKnownPosition` timestamp and accuracy and mark
   it internally as `lastKnown`.
3. A fresh last-known sample may restore/display state, but it reaches
   geofence evaluation only under the same freshness and accuracy rules.
4. If no fresh last-known sample exists, make exactly one medium-accuracy
   attempt (20 s bound); no retry loop and no Widget timer.
5. The position stream has no per-event `timeLimit`; silence is neither
   arrival nor offline. Stream errors stop the active subscription without a
   lifecycle transition.
6. Delivery/batch subscriptions are cancelled on arrival completion,
   controller disposal, completion/reset, or stream error.

The **±110 m** Device QA sample was shown as Low Accuracy and was not used to
trigger geofence arrival, expose delivery confirmation, or move the workflow
to automatic-arrival state.

### Regression coverage

- Fresh/stale/low-accuracy last-known timeout paths
- Exactly one medium retry after stale/no fallback
- Low accuracy cannot auto-arrive
- Fresh accurate dwell does auto-arrive
- Stream remains alive through silence (no `timeLimit`)
- Stream cleanup after arrival/dispose
- Arabic/English GNSS failure copy does not blame internet/network

## Local Quality Gate (post-correction)

- `dart format` / `git diff --check`: clean
- `flutter analyze`: no issues
- `flutter test`: **841 passed**
- `flutter build apk --debug --dart-define=SAEQ_DEVICE_LOCATION_QA=true`: success

## HONOR Device QA (VKP-NX9)

| Check | Result | Evidence |
|-------|--------|----------|
| OS permission dialog (when-in-use + accurate) | PASS | System permission controller shown; granted foreground |
| GNSS timeout / stale classification | PASS | UI showed `الموقع المحفوظ قديم` — no internet blame |
| Accurate fix display | PASS | After valid fused fix: `الموقع متاح` |
| External navigation | PASS | Opened `com.google.android.apps.maps` at `24.713600, 46.675300` |
| No manual arrival button while en-route | PASS | Active delivery stayed at `إلى العميل` with Home CTA only |
| Live geofence auto-arrival on device | DEFERRED BY OWNER TO STEP 4B | Stable mock-location dwell could not be produced; physical-walk validation is deferred |

## Remaining before close

- PR + CI ×4 + merge commit
- STEP 4B must begin with live geofence device validation
- Stop before STEP 5 and await owner authorization

## Deferred (STEP 4B / later ADR)

- Background / Always location + Android FGS
- In-app Map SDK
