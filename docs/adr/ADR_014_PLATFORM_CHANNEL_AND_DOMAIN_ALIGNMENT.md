# ADR-014: Platform Channel Responsibilities and Domain Alignment

> **ADR Number:** ADR-014
> **Title:** Platform Channel Responsibilities and Domain Alignment
> **Status:** ✅ Accepted
> **Date:** 2026-07-25
> **Author:** Platform Architecture Alignment
> **Last Updated:** 2026-07-25
> **Related:** [ADR-013](./ADR_SEPARATE_APPLICATIONS_STRATEGY.md), [41_OFFICIAL_BUSINESS_RULES.md](../41_OFFICIAL_BUSINESS_RULES.md), [42_PLATFORM_DOMAIN_ARCHITECTURE.md](../42_PLATFORM_DOMAIN_ARCHITECTURE.md), [00_PROJECT_BIBLE.md](../00_PROJECT_BIBLE.md), [03_ENTERPRISE_ARCHITECTURE.md](../03_ENTERPRISE_ARCHITECTURE.md)

---

## Context

The SAEQ Architecture Review (Revised) and subsequent owner approvals established:

1. Four client products plus a shared Backend.
2. **Web Admin** remains the central console for platform owners (not Windows Desktop).
3. **Merchant Mobile App** is the channel for merchant daily operations (superseding earlier “Merchant React Web Dashboard first” guidance).
4. Binding business rules for single-business/single-branch orders, driver–branch binding, catalog vs branch offer, payments, multi-tenancy, inventory movements, and order state machines.
5. Backend style for MVP: **Modular Monolith** with gradual DDD; no Microservices/Kafka by default.
6. Repository strategy: keep separate repos; no Monorepo/Melos now.

ADR-013 correctly locked **separate applications** and preferred **Web Admin** for platform operators, but left Merchant as “Web Admin-style dashboard acceptable first; mobile optional later,” and Enterprise Architecture described Merchant as React.js web. Those Merchant-channel statements conflict with the approved daily-ops model.

---

## Decision

### A. Official platform topology

```text
Customer Mobile App
Merchant Mobile App
Driver Mobile App
Web Admin for SAEQ Platform Owners
Backend Platform
```

### B. Channel responsibilities

| Product | Responsibility |
|---------|----------------|
| **Customer Mobile** | Browse stores/branches, search, addresses, order, pay, track, notifications, ratings, history |
| **Merchant Mobile** | Daily business ops: branches, staff, products/prices, inventory, orders, drivers, delivery assignment, hours, zones/fees, payment method settings (incl. optional cash), reports, wholesale purchasing |
| **Driver Mobile** | Assigned deliveries, pickup, navigation, status, PoD / failure, offline-capable ops |
| **Web Admin** | Platform owners & authorized platform staff only: merchants, businesses, branches (platform governance), suppliers, wholesale governance, catalog approval, subscriptions, fees/commissions, settlements, support, content, reports, platform settings, admin permissions, audit, feature flags, observability |
| **Backend** | Source of truth, tenant isolation, authorization, audit, domain workflows |

### C. Explicit prohibitions

- Merchant must **not** use Web Admin for daily store management.
- Merchant must **not** receive platform-administration powers via Web Admin.
- Do **not** convert Web Admin to Windows Desktop / Flutter Windows Admin / MSIX packaging as the admin strategy.
- Do **not** start Monorepo/Melos or shared god-packages without a future ADR.

### D. Domain foundations (documentation binding)

The following are **Accepted** design mandates, detailed in `41_OFFICIAL_BUSINESS_RULES.md` and `42_PLATFORM_DOMAIN_ARCHITECTURE.md`:

- Multi-tenant hierarchy `Platform → Business → Branch → …` with `business_id` / `branch_id` (and related IDs).
- Catalog Product ≠ Branch Product Offer (no branch price/stock/availability on central catalog).
- Inventory Engine = balance + immutable movements.
- Retail & Wholesale order state machines with governed transitions.
- Modular Monolith Backend for MVP; Microservices/Kafka deferred.
- Gradual DDD in complex domains only.
- RBAC + Business Scope + Branch Scope + server-side authorization + Audit Log + Observability strategy.
- Driver Offline-First as part of Driver MVP design (implementation later).

### E. Amendment to ADR-013

ADR-013 remains Accepted for **separate applications**, **shared backend only**, **no role-merge app**, and **Web Admin for platform operators**.

**Amended:** Merchant distribution channel. Replace “Web Admin-style dashboard acceptable first; mobile optional later” with:

> **SAEQ Merchant is a Merchant Mobile App for daily operations. Web Admin is reserved for SAEQ platform owners and is not the merchant daily console.**

### F. Driver DI clarification (cross-link)

Driver dependency injection remains **ADR-010 AppServiceRegistry**. `lib/core/di/service_locator.dart` (`get_it`) is Legacy / Unused / Conflicting — candidate for later removal per `docs/LEGACY_DI_MIGRATION_PLAN.md`. No code deletion in the Documentation Phase.

---

## Consequences

### Positive

- Single official story for who uses which client.
- Prevents building a merchant-facing React dashboard as the primary ops tool.
- Keeps Web Admin aligned with existing ADR-013 Web preference.
- Gives Backend/data modeling a stable tenant and catalog/offer contract before coding shared domains.

### Negative

- Existing prose in older docs (Enterprise §4 stack, Bible phase tables, archive) must be marked Superseded where conflicting — migration cost is documentary, not runtime.
- Merchant Mobile and Backend still do not exist; expectations rise without immediate code.

### Neutral

- Does not start PHASE 2.3 or any feature development.
- Does not change Drift schemas or Dart code in this phase.

---

## Alternatives Considered

| Alternative | Decision |
|-------------|----------|
| Convert Admin to Windows Desktop | ❌ Rejected (owner decision 2026-07-25) |
| Keep Merchant primary channel as React Web Dashboard | ❌ Rejected for daily ops |
| Monorepo now | ❌ Rejected (ADR-013 stands; revisit later) |
| Microservices for MVP | ❌ Rejected |

---

## Compliance

| Check | Result |
|-------|--------|
| Web Admin for platform owners only | Required |
| Merchant Mobile for daily ops | Required |
| No Windows Admin recommendation | Required |
| Business rules documented with stable IDs | `41_OFFICIAL_BUSINESS_RULES.md` |
| Domain architecture documented | `42_PLATFORM_DOMAIN_ARCHITECTURE.md` |
