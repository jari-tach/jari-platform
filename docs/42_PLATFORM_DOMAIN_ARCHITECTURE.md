# SAEQ — Platform Domain Architecture

> **Version:** 1.0.0
> **Status:** Active
> **Last Updated:** 2026-07-25
> **Author:** Platform Architecture Alignment
> **Related:** [41_OFFICIAL_BUSINESS_RULES.md](./41_OFFICIAL_BUSINESS_RULES.md), [adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md), [10_PRODUCT_CATALOG_ARCHITECTURE.md](./10_PRODUCT_CATALOG_ARCHITECTURE.md), [29_DATA_DICTIONARY.md](./29_DATA_DICTIONARY.md)
> **Scope:** Documentation / future Backend & apps. **No schema or code changes in this phase.**

---

## 1. Multi-Tenant SaaS hierarchy

```text
Platform
└── Business
    └── Branch
        ├── Users
        ├── Warehouse
        ├── Inventory
        ├── Branch Product Offers
        ├── Drivers
        ├── Orders
        ├── Delivery Operations
        └── Reports
```

### 1.1 Reference identifiers (expected usage — not implemented in Drift yet)

| ID | When required | Tables (future) | Domain | API | Authorization | Audit |
|----|---------------|-----------------|--------|-----|---------------|-------|
| `business_id` | Almost all merchant-scoped records | businesses, branches, offers, orders, inventory, drivers, users | Aggregates scoped to Business | Path/body + server override from token | Business Scope | Actor + target business |
| `branch_id` | Branch-scoped ops | warehouses, inventory, offers, retail orders, drivers, reports | Branch Aggregate children | Same | Branch Scope | Target branch |
| `warehouse_id` | Stock balances & movements | warehouses, inventory_balances, stock_movements | Inventory | Stock APIs | Warehouse/Branch roles | Movement audit |
| `supplier_id` | Wholesale & catalog supplier links | suppliers, wholesale_orders | Wholesale Aggregate | Wholesale APIs | Supplier/Wholesale admin | Supplier changes |
| `driver_id` | Delivery assignment & driver profile | drivers, delivery_jobs | Delivery | Driver APIs | Driver + branch scope | Reassignment |
| `customer_id` | Retail checkout & history | customers, retail_orders | Order | Customer APIs | Customer self / support scoped | Support interventions |
| `order_id` | Order lifecycle & payments | retail_orders, wholesale_orders, payments, deliveries | Order/Delivery | All order APIs | Role + tenant scope | Status changes |

### 1.2 Isolation rules (Backend-owned)

Backend **must**:

1. Isolate every Business tenant’s data.
2. Isolate every Branch within a Business per role scope.
3. Validate user Business Scope and Branch Scope on every sensitive request.
4. Validate driver branch binding before exposing offers/orders.
5. **Never** trust client-supplied `business_id` / `branch_id` without matching the authenticated principal’s grants.
6. Reject attempts to escalate by rewriting tenant IDs.
7. Log unauthorized access attempts (Security Events).

UI hiding is complementary only (`BR-SEC-001`).

---

## 2. Catalog Product vs Branch Product Offer

```text
Catalog Product
        ↓
Branch Product Offer
        ├── Price
        ├── Availability
        ├── Inventory (link / balance)
        ├── Purchase Limit
        ├── Promotion
        └── Branch Settings
```

### 2.1 Catalog Product (platform-level)

Allowed fields (conceptual): Arabic name, English name, barcode, brand, category, unit, weight, size/dimensions, images, attributes/specs, data source, review status, approval status, deduplication/merge metadata.

**Forbidden on Catalog Product:** branch selling price, branch stock qty, branch availability, branch promotions, branch purchase limits.

### 2.2 Branch Product Offer (branch-level)

Required links: `catalog_product_id`, `business_id`, `branch_id`.

Commerce fields: sell price, compare-at / pre-discount price, availability, publish status, max order qty, sell settings, promotions, inventory relationship.

> Supersedes any prior catalog doc that placed store `price` / `isAvailable` on the central product. See updated `10_PRODUCT_CATALOG_ARCHITECTURE.md`.

---

## 3. Inventory Engine

Design principle:

```text
Inventory Balance
+
Immutable Stock Movement History
```

**Direct balance edits without a stock movement are forbidden.**

### 3.1 Movement types

| Code | Description | MVP | Notes |
|------|-------------|-----|-------|
| `OpeningBalance` | رصيد افتتاحي | Yes (design) | |
| `PurchaseReceipt` | استلام شراء عام | Later | |
| `WholesaleReceipt` | استلام جملة | Yes (design) | Links BR-WHOLESALE-003 |
| `SaleReservation` | حجز عند قبول/تأكيد الطلب | Yes | |
| `ReservationRelease` | تحرير الحجز | Yes | |
| `SaleDeduction` | خصم عند اكتمال البيع/التسليم حسب السياسة | Yes | |
| `CustomerReturn` | مرتجع عميل | Later | |
| `SupplierReturn` | مرتجع لمورد | Later | |
| `Damage` | تالف | Later | |
| `AdjustmentIncrease` | تسوية زيادة | Yes (admin/warehouse) | Audited |
| `AdjustmentDecrease` | تسوية نقص | Yes | Audited |
| `StockCount` | جرد | Later | |
| `BranchTransferOut` | تحويل خارج | Deferred execution | Design must allow |
| `BranchTransferIn` | تحويل داخل | Deferred execution | Design must allow |

### 3.2 Movement record fields

`business_id`, `branch_id`, `warehouse_id`, product or offer id, movement type, quantity, balance_before, balance_after, reason, reference (order/count/transfer id), actor (user or system service), executed_at, correlation_id, idempotency_key (when needed).

---

## 4. Order state machines (documentation only — not coded)

### 4.1 Retail order happy path

```text
Draft → PendingPayment → Submitted → Accepted → Preparing → Ready
→ DriverAssigned → PickedUp → Delivered
```

Exception / terminal-ish states: `Rejected`, `Cancelled`, `PaymentFailed`, `DeliveryFailed`, `RefundRequested`, `PartiallyRefunded`, `Refunded`.

### 4.2 Wholesale order happy path

```text
Draft → Submitted → SupplierConfirmed → Processing → Shipped
→ PartiallyReceived → Received → Closed
```

Exceptions: `Rejected`, `Cancelled`, `PartiallyFulfilled`, `Returned`, `PartiallyRefunded`, `Refunded`.

### 4.3 Transition documentation template

For each transition, Backend design must define:

| Field | Content |
|-------|---------|
| From / To | Previous and next status |
| Authorized roles | Platform / Business / Branch / Driver / System |
| Preconditions | Payment, stock, assignment, etc. |
| Inventory effect | Reserve / release / deduct / none |
| Payment effect | Capture / fail / refund / none |
| Notifications | Who is notified |
| Audit | Required fields |
| Reversible? | Yes/No + conditions |
| Idempotent? | Yes/No + key strategy |

Free-form `status` string updates from any client **without** a transition service are **not allowed** in future implementations.

---

## 5. Backend: Modular Monolith (MVP)

**Decision:** One deployable Backend with clear internal modules. Microservices and Kafka / distributed messaging are **deferred** until measurable operational need.

### Modules

```text
IdentityAndAccess
Businesses
Branches
Customers
Merchants
Drivers
Catalog
BranchOffers
Inventory
RetailOrders
Delivery
Wholesale
Suppliers
Payments
Subscriptions
Notifications
Reports
Audit
Administration
```

### Module rules

- Clear ownership per module.
- No arbitrary cross-module table access; use application services / published contracts.
- Internal Domain Events allowed inside the monolith.
- No Kafka requirement for MVP.

---

## 6. Gradual DDD

Apply DDD patterns where rules are complex:

Retail Orders, Wholesale Orders, Inventory, Delivery, Payments, Product Catalog, Subscriptions.

| Pattern | Use when |
|---------|----------|
| Entity | Identity + lifecycle |
| Value Object | Immutable descriptive values (money, address, price snapshot) |
| Aggregate | Consistency boundary (Order, InventoryBalance+policy, BranchOffer) |
| Repository | Persist aggregates |
| Domain Service | Cross-entity rules inside domain |
| Application Service / Use Case | Orchestrate one user intention |
| Domain Event | Decouple side effects inside monolith |
| Policy | Authorization / pricing / cash-enabled rules |

Do **not** rewrite the Driver app or invent empty abstractions without real rules.

---

## 7. Authorization model

```text
RBAC
+ Business Scope
+ Branch Scope
+ Permission Policies
+ Server-Side Authorization
```

### Platform roles

Platform Owner, Super Admin, Operations Admin, Finance Admin, Support Admin, Catalog Admin, Wholesale Admin, Security Auditor.

### Business roles

Business Owner, Branch Manager, Warehouse Manager, Cashier, Order Operator, Driver.

Example grant:

```text
Role: BranchManager
Business Scope: business_123
Branch Scope: branch_456
```

Role alone is insufficient without scope.

---

## 8. Audit Log

Required fields (conceptual): Actor User ID, Actor Role, Business ID, Branch ID, Action, Resource Type, Resource ID, Previous Values, New Values, Reason, Timestamp, IP Address, Session ID, Correlation ID, Result, Failure Reason.

Sensitive actions requiring audit (non-exhaustive): merchant/branch approve or suspend; subscription change; commission change; permission change; admin order status intervention; central catalog product edit; financial settlement; refund; feature flag toggle.

---

## 9. Observability

Unified strategy: Structured Logging, Crash Reporting, Error Tracking, Metrics, Tracing, Health Checks, Correlation IDs, Security Events, Audit Events.

| Stream | Purpose |
|--------|---------|
| Operational Logs | Runtime diagnostics |
| Security Logs | Authz failures, abuse |
| Audit Logs | Sensitive business mutations |
| Business Events | Domain facts for workflows/analytics |

**Never log:** passwords, OTP codes, access/refresh tokens, full card data, unnecessary full PII.

Web Admin / ops tooling may show service health, error rates, failed payments, sync issues, stuck orders, API performance, crashes by app version — without secrets.

---

## 10. Feature Flags (deferred execution)

Managed later from Web Admin by environment, city, business, branch, plan, app version, percentage rollout.

Examples: Wholesale Marketplace, Cash Payment, Coupons, Loyalty, Wallet, Driver Tracking, Experimental Features.

Not a blocker for Driver MVP.

---

## 11. Offline-First (Driver MVP — design)

Priority offline operations: persist active order; confirm arrival at branch; confirm pickup; update trip status; proof of delivery; delivery failure; PoD media when used.

Requirements: Local Queue, Retry Policy, Idempotency, Operation Ordering, Conflict Resolution, Sync Status UI, Failed Operation History, Network Recovery, Duplicate Prevention (especially PoD).

Existing Driver code (`OfflineQueue`, `SyncManager`, `NetworkMonitor`) is structural; **wiring is out of scope for Documentation Phase**.

Customer MVP: browsing cache + local cart only. Web Admin: server as source of truth.

---

## 12. Repository strategy (current)

- No Monorepo, no Melos now.
- Independent repos: Driver (this), Merchant (future), Customer (future), Web Admin (future), Backend (future).
- Revisit Monorepo only after ≥2 stable apps, measurable duplication, clear shared-package benefit, **new ADR**, and a migration plan.

Do not create `apps/` or `packages/` folders in this repository during documentation alignment.
