# SAEQ — Development Roadmap

> **Version:** 2.0.0
> **Status:** Active
> **Last Updated:** 2026-07-25
> **Author:** Platform Architecture Alignment
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md), [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](./PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md), [ADR-014](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md)

---

## 0. Authority

This file defines the **platform-level stage order**.
Driver-specific PHASE 2.x detail lives in `PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md`.

**Every stage requires explicit owner approval before execution.** This document is not an automatic start order.

Historical “Phase 0–5” checklists that claimed Auth was not started / get_it pending are **Superseded** for status tracking (see §4).

---

## 1. Official stage order

```text
Stage A — Documentation and Architecture Alignment
Stage B — PHASE 2.3 Driver Identity and Profile
Stage C — Driver Operational MVP
Stage D — Backend Modular Monolith Foundation
Stage E — Merchant Mobile MVP
Stage F — Customer Mobile MVP
Stage G — Web Admin Operational MVP
Stage H — Platform Expansion
```

| Stage | Status (2026-07-25) | Notes |
|-------|---------------------|-------|
| **A** | **Done** | Docs + ADRs + business rules alignment (`e14b322`) |
| Pre-B (Stabilization, 2.1, 2.2) | **Done** (with documented conditions) | Do not rewrite as “not started” |
| **B (PHASE 2.3)** | **Validated** (pending commit authorization) | Branch `feature/phase-2.3-driver-identity-profile` |
| **C–H** | Not started | Each needs separate approval; may span multiple repos |

---

## 2. Stage summaries

### Stage A — Documentation and Architecture Alignment
Fix channel model (Merchant Mobile + Web Admin), business rules, multi-tenant design, catalog/offer split, inventory/order SM docs, Modular Monolith, ADR-010/get_it legacy labeling. **No feature coding.**

### Stage B — PHASE 2.3 Driver Identity and Profile
Driver-only. Design identity/profile so `business_id` / `branch_id` can be added later. Keep Fake Auth production guard. Tests required. No other apps / no Monorepo.

### Stage C — Driver Operational MVP
Availability, delivery loop, offline sync for critical ops, per PHASE 2 roadmap (2.4+).

### Stage D — Backend Modular Monolith Foundation
Identity, Businesses/Branches, Catalog/Offers, Inventory movements, Retail Orders SM, Delivery, Payments, Audit — tenant isolation from day one.

### Stage E — Merchant Mobile MVP
Daily ops app (not Web Admin). Branch-scoped offers, orders, drivers, optional cash setting.

### Stage F — Customer Mobile MVP
Single-business / single-branch cart & order (BR-ORDER-*). Electronic payment primary.

### Stage G — Web Admin Operational MVP
Platform owners only: approvals, catalog governance, subscriptions, finance, support, audit, flags (as needed).

### Stage H — Platform Expansion
Wholesale depth, branch transfers, advanced observability, feature flags breadth, optional Monorepo revisit via new ADR.

---

## 3. DI note

Official Driver DI: **AppServiceRegistry (ADR-010)**.
`get_it` / `service_locator.dart`: Legacy — see `LEGACY_DI_MIGRATION_PLAN.md`.

---

## 4. Historical Phase 0–5 (Superseded for status)

The previous Version 1.0.0 content describing “Phase 0 in progress”, “Auth not started”, and “get_it + injectable pending” is **Historical / Superseded**. Keep archive copies under `docs/archive/` if needed; do not use them to decide current work.
