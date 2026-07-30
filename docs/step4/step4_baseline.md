# STEP 4 — Baseline Inventory

> **Status:** AUTHORIZED — IN PROGRESS
> **Baseline main SHA:** `62d0ed1467b77f1b0c72b26283db96038aab9fc7`
> **Branch:** `feature/step-4-real-gps-permissions-maps-geofence`
> **Worktree:** `C:\Users\yahia\saeq_driver-step4`
> **Flutter / Dart:** 3.44.7 / 3.12.2
> **Date:** 2026-07-30
> **ADR:** [ADR-029](../adr/ADR_029_DRIVER_LOCATION_MAPS_GEOFENCE.md)
> **STEP 5 Backend:** LOCKED until STEP 4 close

---

## Goal

Replace Fake platform location/map bridges with real OS GPS, permissions,
accuracy/debounce, local geofence-driven automatic arrival, and external
navigation — without Backend, WebSocket, or a manual arrival button.

---

## Baseline (at STEP 3 merge)

| Area | State |
|------|-------|
| `LocationService` | Fake only; `null` in production |
| Map preview | Fake CustomPaint; external nav always unavailable |
| Batch arrival | `FakeBatchLocationController` timer (~4s) |
| Single-delivery arrival | Controller Fake sequence after `confirmPickup` |
| `pubspec` GPS/maps | None (`geolocator` / maps / `url_launcher` absent) |
| Android Manifest | No location permissions |
| iOS Info.plist | No `NSLocation*` usage strings |
| Order/stop coordinates | Labels only — no lat/lng |
| Location ADR | None (until ADR-029) |

---

## In scope

1. ADR-029 + this baseline / closeout docs
2. Pure-Dart geo policies (distance, accuracy, debounce, geofence)
3. Location / permission / external-nav ports + Fake & Device adapters
4. OS permissions (Android + iOS strings)
5. Wire automatic arrival (single + batch) to location signal
6. External navigation via `url_launcher`
7. Tests + HONOR device QA + PR merge commit

## Out of scope (locked)

- STEP 5 Backend / REST / contracts repos
- STEP 6 realtime / WebSocket
- In-app Map SDK + API keys
- Manual arrival button
- Background Always / FGS unless STEP 4B explicitly opened

---

## Dependency gate (ADR-029)

Approved for this branch: `geolocator`, `permission_handler`, `url_launcher`.

---

## التقرير العربي (افتتاح)

- **ما تم تنفيذه حتى الآن:** Worktree + Baseline + ADR-029.
- **الملفات:** `docs/step4/step4_baseline.md`, `docs/adr/ADR_029_…`, فهرس ADR.
- **الخطوة التالية:** سياسات Pure Dart ثم محوّلات Device وربط الوصول التلقائي.
