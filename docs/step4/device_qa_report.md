# STEP 4A — Device QA Report

> **Status:** COMPLETE WITH OWNER-APPROVED DEVICE TEST DEFERRAL
> **Device:** HONOR VKP-NX9
> **Branch:** `feature/step-4-real-gps-permissions-maps-geofence`
> **Baseline:** `62d0ed1467b77f1b0c72b26283db96038aab9fc7`
> **Date:** 2026-07-30
> **STEP 5 Backend:** NOT STARTED

## Device results

- **HONOR location permission:** PASS
- **GNSS timeout classification:** PASS
- **Fresh/stale/weak accuracy handling:** PASS
- **External Google Maps navigation:** PASS
- **No manual arrival button:** PASS
- **Automated geofence policy tests:** PASS
- **Live geofence automatic arrival on HONOR:** DEFERRED BY OWNER TO STEP 4B
- **False arrival observed:** 0
- **Runtime errors:** 0

## Live geofence deferral

Stable mock-location dwell could not be produced on the HONOR device. The
device rejected or cleared Android `LocationManager` test providers before a
stable sequence could be consumed by the application position stream.
Physical-walk validation is therefore deferred by explicit owner decision.

This is an approved test deferral, not a device-test pass. STEP 4B must begin
with live geofence device validation using either:

1. a physical walk through the configured geofence; or
2. a stable mock-location provider accepted by the device and fused location
   stack.

## Observed behavior

- The Android when-in-use location permission dialog was displayed and
  foreground precise location was granted.
- A GNSS timeout with an old last-known position produced the Arabic stale
  state (`الموقع المحفوظ قديم`), not an internet/offline error.
- A fresh accurate device fix produced the available-location state.
- The observed ±110 m sample was classified Low Accuracy and did not expose
  delivery confirmation or trigger automatic arrival.
- External navigation opened Google Maps with the expected coordinates.
- The en-route delivery screen exposed no manual arrival action.

## Scope boundaries

- **Backend:** NOT STARTED
- **Embedded Map SDK:** DEFERRED
- **Background location:** DEFERRED
- **Live HONOR geofence:** DEFERRED — NOT A MERGE BLOCKER

## Decision

**STEP 4A: COMPLETE WITH OWNER-APPROVED DEVICE TEST DEFERRAL**

This report does not claim that live geofence device validation passed, that
full device geofence validation passed, or that background location is
complete.
