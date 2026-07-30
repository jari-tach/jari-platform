# ADR-029: Driver Location, Permissions, Maps & Geofence

> **ADR Number:** ADR-029
> **Title:** Driver Location, Permissions, Maps & Geofence (STEP 4)
> **Status:** ✅ Accepted (owner STEP 4 authorization 2026-07-30)
> **Date:** 2026-07-30
> **Author:** STEP 4 Architecture · Principal Engineer
> **Last Updated:** 2026-07-30
> **Related:** [ADR-013](./ADR_SEPARATE_APPLICATIONS_STRATEGY.md), [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md), [ADR-021](./ADR_021_DELIVERY_REQUEST_LIFECYCLE.md), [step2d_closeout](../step2d/step2d_closeout.md)

---

## Context

STEP 2B/2C delivered Fake location, Fake map preview, and timer-based automatic
arrival. STEP 3 kept Fake/Local arrival sequences. STEP 4 must replace Fake
platform bridges with real OS location while preserving:

- Clean Architecture (UI never calls plugins / HTTP / DB directly)
- Automatic arrival only (no manual arrival button)
- No Backend / REST / WebSocket (STEP 5–6 locked)
- No secrets / map API keys in Git

ADR-013 notes Driver may need background location; there is no prior location ADR.

---

## Decision

### 1. Layering

```
Presentation (Location / Map / Active Delivery / Batch Stop)
  → Controllers (Riverpod)
    → Use policies / evaluators (pure Dart)
      → LocationGateway / ExternalNavigationGateway (ports)
        → Fake* | Device* adapters (plugins only here)
```

UI and Controllers must not import `geolocator`, `permission_handler`, or
`url_launcher` directly.

### 2. Approved dependencies (STEP 4)

| Package | Role |
|---------|------|
| `geolocator` | Foreground position stream + service/permission status |
| `permission_handler` | Explicit OS permission UX (denied / permanently denied / open settings) |
| `url_launcher` | External navigation handoff (Google Maps / Apple Maps / geo: URI) |

**Rejected for STEP 4 MVP:** in-app Map SDK (`google_maps_flutter`, Mapbox,
etc.) — requires API keys and tile contracts. Keep CustomPaint / Fake map
placeholder for in-app preview; external apps own turn-by-turn.

### 3. Permission & privacy

- Request **when-in-use / fine location** for foreground tracking and geofence.
- **Background / Always** location and Android FGS: deferred to **STEP 4B**
  within the same STEP program only if device QA proves foreground is
  insufficient; document before enabling.
- Never log raw coordinates in production analytics strings; redact in debug.
- No map/API keys in repository; use `--dart-define` only if a later ADR
  introduces an in-app Map SDK.

### 4. Accuracy, debounce, geofence (local policy)

Pure-Dart policies (unit-tested), defaults:

| Policy | Default |
|--------|---------|
| Acceptable accuracy for arrival | ≤ 50 m |
| Geofence radius (pickup / customer) | 80 m |
| Debounce | 2 consecutive accepted fixes within radius, ≥ 1.5 s apart |
| Weak accuracy UX | > 50 m and ≤ 150 m → `weakAccuracy` (no arrival) |
| Reject fix | accuracy unknown or > 150 m |
| Stream freshness | captured timestamp ≤ 30 s old for geofence evaluation |

Policies are local **intent** only (ADR-016). Backend authority for arrival
proof remains STEP 5+.

GNSS acquisition failures are not network failures. `offline` is reserved for
operations that actually require connectivity; timeout/provider failure maps
to `unavailable`, an old last-known fix maps to `stale`, and low accuracy maps
to `weakAccuracy`. On a high-accuracy timeout the Device adapter validates one
last-known fix by timestamp and accuracy, then performs at most one bounded
medium-accuracy attempt. Last-known samples are marked as fallback and cannot
trigger arrival unless they independently pass the same freshness, accuracy,
radius, and debounce policies. Continuous streams have no per-event timeout;
silence produces no state transition.

### 5. Automatic arrival wiring

- **Forbidden:** any driver-facing “I arrived” button.
- **Single delivery:** after `collected` / en-route-to-customer, arrival at
  customer is produced by geofence evaluator → workflow `arrivedCustomer`
  (then verify). Remove Fake **timer auto-sequence** of `arrivedCustomer`
  from `confirmPickup` once geofence / Fake location stream owns it.
- **Batch:** replace timer-only `FakeBatchLocationController` with a
  location-signal controller that consumes Fake **or** Device fixes against
  stop coordinates; still calls `registerAutomaticArrivalByLocation` only.
- Without coordinates on a stop/order: do not invent Backend coords; use
  Fake seed coordinates for Fake path, or keep Fake stream simulation.

### 6. Coordinates on local Fake models

Optional `latitude` / `longitude` on Fake delivery order / batch stop payloads
are **synthetic local fixtures** for geofence tests and device QA — not a
Backend contract and not a STEP 5 schema claim.

### 7. Production providers

STEP 2B returned `null` location/map services in production. STEP 4 enables
**Device adapters in production** when plugins are available; Fake remains
non-production / test default. Fail closed to clear permission/GPS UX states —
never silent success.

### 8. Out of scope (locked)

- STEP 5 Backend / REST / `saeq-backend` / `saeq-contracts`
- STEP 6 WebSocket / realtime tracking upload
- Manual arrival control
- In-app Map SDK / tile keys
- Merging Customer/Merchant/Admin apps

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Google Maps Flutter in STEP 4 | Rich in-app map | API keys in/near Git; scope creep | Rejected for MVP |
| geolocator only (no permission_handler) | Fewer deps | Weaker permanently-denied UX | Rejected |
| Background Always from day one | Continuity when app backgrounded | FGS/privacy complexity | Deferred 4B |
| Keep timer Fake forever + Device UI only | Safer | Fails STEP 4 geofence AC | Rejected |
| Manual arrival fallback | Simple | Violates product/Figma contract | Forbidden |

---

## Consequences

### Positive

- Clear ports/adapters for GPS and external nav
- Testable geofence/accuracy without device
- No secrets in Git for maps
- Aligns Fake→Real without Backend

### Negative

- In-app map remains placeholder until a future Map SDK ADR
- Foreground-only may miss arrival if app is backgrounded (4B risk)
- Delivery/batch Fake models gain optional coordinates

### Neutral

- STEP 3 Fake pickup→customer auto-sequence for `arrivedCustomer` is replaced
  by location-driven arrival (behavior change owned by STEP 4)

---

## Related Decisions

- [ADR-013](./ADR_SEPARATE_APPLICATIONS_STRATEGY.md) — Driver may need background location
- [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md) — local intent vs Backend
- [ADR-021](./ADR_021_DELIVERY_REQUEST_LIFECYCLE.md) — workflow stages
- [ADR-028](./ADR_028_DELIVERY_ASSIGNMENT_PERSISTENCE.md) — assignment durability

---

*جزء من المرجع الرسمي لمشروع SAEQ Driver. STEP 5 Backend يبقى مقفلاً حتى إغلاق STEP 4.*
