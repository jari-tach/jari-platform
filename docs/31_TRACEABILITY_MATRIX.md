# SAEQ — Traceability Matrix

> **Version:** 2.0.0
> **Status:** Active
> **Last Updated:** 2026-07-25
> **Author:** Platform Architecture Alignment
> **Related:** [41_OFFICIAL_BUSINESS_RULES.md](./41_OFFICIAL_BUSINESS_RULES.md), [42_PLATFORM_DOMAIN_ARCHITECTURE.md](./42_PLATFORM_DOMAIN_ARCHITECTURE.md), [25_REQUIREMENTS_SPECIFICATION.md](./25_REQUIREMENTS_SPECIFICATION.md), [ADR-014](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md), [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md)

---

## 1. Purpose

This matrix links **official platform business rules** (`BR-ORDER-*`, `BR-WHOLESALE-*`, …) to domain modules, data/API impacts, applications, security, tests, and planned stages.

**Authority:** When this file conflicts with older legacy BR-001…BR-010 rows for payment/cart/tenant semantics, **`41_OFFICIAL_BUSINESS_RULES.md` wins**.

### Status legend

| Status | Meaning |
|--------|---------|
| DocumentedOnly | Spec only; not in code/DB/API yet |
| PartiallyImplemented | Partial (e.g. Driver Fake Auth) |
| Implemented | Delivered in a product |
| NotStarted | Planned, not started |
| Deferred | Explicitly postponed |
| Historical | Superseded mapping kept for history |

### Planned Stage legend

Stage A (docs) · B (PHASE 2.3) · C (Driver MVP) · D (Backend) · E (Merchant) · F (Customer) · G (Web Admin) · H (Expansion)

---

## 2. Official Business Rules Traceability

| Rule ID | Rule Name | Business Requirement | Domain Module | Database Impact | API Impact | Application Impact | Security/Authorization Impact | Required Tests | Current Implementation Status | Planned Stage |
|---------|-----------|----------------------|---------------|-----------------|------------|---------------------|-------------------------------|----------------|-------------------------------|---------------|
| BR-ORDER-001 | Single business per order | طلب عميل ← `business_id` واحد | RetailOrders | `orders.business_id` NOT NULL + FK | Create/update order scoped | Customer Mobile | Reject cross-business ids | Isolation: cannot create multi-business order | DocumentedOnly | D, F |
| BR-ORDER-002 | Single branch per order | طلب عميل ← `branch_id` واحد | RetailOrders, Branches | `orders.branch_id` NOT NULL + FK | Order APIs branch-scoped | Customer, Merchant | Branch Scope on read/write | Isolation: single branch constraint | DocumentedOnly | D, F |
| BR-ORDER-003 | Single-store cart | لا دمج متاجر في سلة واحدة | RetailOrders | Cart owned by one business | Cart APIs | Customer Mobile | Server validates cart business | Cart isolation tests | DocumentedOnly | D, F |
| BR-ORDER-004 | Single-branch cart/lines | لا دمج فروع في طلب/سلة | RetailOrders, Branches | Line items same `branch_id` | Cart/Order APIs | Customer Mobile | Branch Scope | Multi-branch cart rejected | DocumentedOnly | D, F |
| BR-ORDER-005 | One cart per order | سلة واحدة لكل طلب | RetailOrders | 1:1 cart–order | — | Customer Mobile | — | Unit: cart cardinality | DocumentedOnly | D, F |
| BR-ORDER-006 | One delivery per order | توصيل واحد لكل طلب | Delivery | 1:1 delivery–order | Delivery APIs | Customer, Driver | Driver branch scope | Delivery 1:1 tests | DocumentedOnly | C, D |
| BR-ORDER-007 | One payment context | سياق دفع واحد + محاولات فاشلة | Payments | `payment` + `payment_attempts` | Payments API | Customer, Web Admin (support) | No client-forged payment context | Payment attempt / idempotency | DocumentedOnly | D, F |
| BR-ORDER-008 | Price snapshot at submit | تثبيت السعر وقت التأكيد | RetailOrders, BranchOffers | Order line snapshot columns | Order submit payload stores snapshot | Customer, Merchant | Tamper-check amounts server-side | Snapshot immutability after submit | DocumentedOnly | D, F |
| BR-WHOLESALE-001 | Single supplier per wholesale order | طلب جملة ← مورد واحد | Wholesale, Suppliers | `wholesale_orders.supplier_id` | Wholesale APIs | Merchant Mobile | Wholesale/Merchant scopes | Multi-supplier order rejected | DocumentedOnly | D, E |
| BR-WHOLESALE-002 | No multi-supplier basket | لا دمج موردين في طلب جملة | Wholesale | Constraint on lines | Cart/order wholesale | Merchant Mobile | Server enforce | Basket isolation | DocumentedOnly | D, E |
| BR-WHOLESALE-003 | Receipt → stock movements | استلام جملة = حركات مخزون | Inventory, Wholesale | Immutable stock_movements | Receipt APIs | Merchant, Warehouse roles | Actor + reason on movement | Movement created; no silent balance edit | DocumentedOnly | D, E |
| BR-WHOLESALE-004 | Partial receipt readiness | استلام جزئي دون كسر النموذج | Wholesale, Inventory | Partial qty / PartiallyReceived | Receipt APIs | Merchant | Audited partials | Partial receipt SM tests | DocumentedOnly | H (design now; exec Deferred) |
| BR-BRANCH-001 | Branch operating independence | فرع = نطاق تشغيلي مستقل | Branches | Branch settings tables | Branch APIs | Merchant Mobile | Branch Scope | Branch settings isolation | DocumentedOnly | D, E |
| BR-BRANCH-002 | Branch belongs to business | الفرع تابع لـ Business | Businesses, Branches | `branch.business_id` | — | Merchant, Web Admin | Cannot orphan branch | FK integrity tests | DocumentedOnly | D, E |
| BR-BRANCH-003 | Independent warehouse | مستودع مستقل لكل فرع | Inventory, Branches | `warehouse.branch_id` | Warehouse APIs | Merchant | Warehouse/Branch roles | Warehouse cross-branch deny | DocumentedOnly | D, E |
| BR-BRANCH-004 | Independent inventory | مخزون غير مشترك تلقائيًا | Inventory | Balances per warehouse/branch | Stock APIs | Merchant | Tenant + branch isolation | Stock leak tests | DocumentedOnly | D, E |
| BR-BRANCH-005 | Independent users & permissions | مستخدمون/صلاحيات ضمن نطاق الفرع | IdentityAndAccess, Branches | Role grants + scopes | AuthZ APIs | Merchant Mobile | Business + Branch Scope | Cross-branch staff deny | DocumentedOnly | D, E |
| BR-BRANCH-006 | Independent orders/drivers/reports | طلبات/سائقون/تقارير معزولة | RetailOrders, Drivers, Reports | Scoped queries | List/report APIs | Merchant, Driver | Enforce scopes on every list | Report/order leak tests | DocumentedOnly | D, E, C |
| BR-DRIVER-001 | Driver bound to business + branch | سائق ↔ business + branch | Drivers | `drivers.business_id`, `branch_id` | Driver profile/assign | Driver, Merchant | Reassignment audited | Driver scope on tokens | DocumentedOnly | B (model readiness), C, D |
| BR-DRIVER-002 | Branch-scoped operations | عمليات ضمن الفرع المصرح | Drivers, Delivery | — | Driver delivery APIs | Driver Mobile | Server-side branch filter | Cannot fetch other branch jobs | DocumentedOnly | C, D |
| BR-DRIVER-003 | No cross-branch orders | لا طلبات فرع آخر | Delivery, RetailOrders | — | Offers/orders APIs | Driver Mobile | AuthZ deny | Isolation suite | DocumentedOnly | C, D |
| BR-DRIVER-004 | No cross-branch customers/inventory/reports | لا عملاء/مخزون/تقارير فرع آخر | Drivers, Inventory, Reports | — | Deny endpoints | Driver Mobile | AuthZ deny | Negative authz tests | DocumentedOnly | C, D |
| BR-DRIVER-005 | Server-side enforcement | ليس UI-only | Authorization | — | All driver APIs | Driver Mobile | RBAC + Branch Scope | UI hide ≠ sufficient (API tests) | DocumentedOnly | D, C |
| BR-DRIVER-006 | Branch reassignment audited | تغيير ارتباط الفرع موثّق | Drivers, Audit | Audit + driver history | Admin/Merchant assign APIs | Merchant, Web Admin | Audit required | Audit fields present | DocumentedOnly | D, E, G |
| BR-ADMIN-001 | Merchant daily ops via Merchant Mobile | التاجر لا يعتمد Web Admin يوميًا | Merchants, Administration | — | Merchant APIs only for ops | Merchant Mobile | No platform admin role for merchants | Channel policy review | DocumentedOnly | E |
| BR-ADMIN-002 | Platform ops via Web Admin | إدارة المنصة من Web Admin | Administration | Admin tables | Admin APIs | Web Admin | Platform roles only | Admin authz tests | DocumentedOnly | G |
| BR-ADMIN-003 | Merchant has no platform powers | لا صلاحيات منصة للتاجر | Authorization | Role catalog | Token scopes | Merchant, Web Admin | Deny platform permissions | Privilege escalation tests | DocumentedOnly | D, E, G |
| BR-ADMIN-004 | Sensitive admin actions audited | تدخل حساس → Audit Log | Audit, Administration | audit_logs | Admin mutation APIs | Web Admin | Mandatory audit middleware | Audit completeness | DocumentedOnly | D, G |
| BR-ADMIN-005 | Intervention reason required | سبب إلزامي للتدخل | Audit | reason NOT NULL on sensitive | Admin APIs | Web Admin | Reject empty reason | Validation tests | DocumentedOnly | D, G |
| BR-ADMIN-006 | Before/after values | previous/new values | Audit | JSON before/after | Admin APIs | Web Admin | Tamper-evident log | Audit payload tests | DocumentedOnly | D, G |
| BR-CATALOG-001 | Central catalog | فهرس مركزي للمنصة | Catalog | catalog_products | Catalog APIs | Web Admin, Merchant (link) | Catalog Admin roles | Catalog CRUD authz | DocumentedOnly | D, G |
| BR-CATALOG-002 | Branch-level commerce fields | سعر/مخزون/توفر على Offer | BranchOffers, Inventory | branch_product_offers | Offer APIs | Merchant, Customer | Branch Scope on offers | Offer vs catalog field tests | DocumentedOnly | D, E, F |
| BR-CATALOG-003 | No store price on catalog product | ممنوع سعر/مخزون الفرع على المركزي | Catalog | No price/stock cols on catalog | Catalog write APIs reject | Web Admin, Merchant | Schema + API validation | Reject catalog price write | DocumentedOnly | D, G |
| BR-PAY-001 | Electronic payment primary | الدفع الإلكتروني أساسي | Payments | payment methods config | Payments API | Customer, Merchant settings | PCI / gateway | Electronic path happy-path | DocumentedOnly | D, F |
| BR-PAY-002 | Cash optional | النقدي اختياري | Payments | cash_enabled flags | Settings + checkout | Merchant, Customer | Policy + plan gates | Cash disabled → reject cash | DocumentedOnly | D, E, F |
| BR-PAY-003 | Merchant cash toggle | تفعيل/تعطيل نقدي للتاجر | Payments, Merchants | business/branch payment settings | Merchant settings API | Merchant Mobile | Business/Branch Scope | Toggle audited | DocumentedOnly | D, E |
| BR-PAY-004 | Cash scoping | تقييد نقدي بنشاط/فرع/مدينة/نوع طلب | Payments | policy tables | Checkout validation | Customer, Merchant | Server policy engine | Matrix of scope rules | DocumentedOnly | D, H |
| BR-PAY-005 | Docs not cashless-only | توحيد الوثائق: إلكتروني + نقدي اختياري | Payments (policy) | — | — | Docs / all apps | — | Doc consistency review | PartiallyImplemented (docs aligned Stage A) | A (done), keep |
| BR-SEC-001 | Server-side authorization | RBAC + scopes على الخادم | Authorization | grants/policies | All sensitive APIs | All apps | Core AuthZ | Authz suite | DocumentedOnly | D |
| BR-SEC-002 | Audit sensitive interventions | Audit للعمليات الحساسة | Audit | audit_logs | Admin/finance APIs | Web Admin | Audit + Security logs | Audit required actions list | DocumentedOnly | D, G |
| BR-SEC-003 | No client-trusted tenant IDs | لا ثقة بـ business_id/branch_id من العميل دون تحقق | Authorization | — | Gateway/API | All apps | Derive scope from token | Forged tenant id rejected | DocumentedOnly | D |

**Count of official Rule IDs in §2:** 40 (ORDER 8 + WHOLESALE 4 + BRANCH 6 + DRIVER 6 + ADMIN 6 + CATALOG 3 + PAY 5 + SEC 3).

---

## 3. Payment policy (single source)

| Topic | Official rule | Legacy mapping |
|-------|---------------|----------------|
| Primary path | **BR-PAY-001** electronic | Old “cashless only” wording → **Historical / Superseded** |
| Optional cash | **BR-PAY-002…004** merchant/branch/platform policy | Old FR-PAY-001 “card, wallet, cash” as equal primaries → clarified in `25_REQUIREMENTS_SPECIFICATION.md` |
| Requirements link | `25_REQUIREMENTS_SPECIFICATION.md` BR-003 + FR-PAY-001 (updated) | Must not reintroduce cashless-only |
| Domain | Payments + Merchant/Branch settings | |
| Tests | TC-PAY-ELEC-001 (electronic), TC-PAY-CASH-001 (cash when enabled), TC-PAY-CASH-002 (cash rejected when disabled) | Planned Stage D/F — DocumentedOnly |

**Do not maintain two conflicting payment policies.**

---

## 4. Critical order / branch / driver / inventory links

| Concern | Rule IDs | Domains |
|---------|----------|---------|
| Single business order | BR-ORDER-001 | RetailOrders |
| Single branch order | BR-ORDER-002 | RetailOrders, Branches |
| No multi-store cart | BR-ORDER-003 | RetailOrders |
| No multi-branch cart | BR-ORDER-004 | RetailOrders, Branches |
| Price snapshot | BR-ORDER-008 | RetailOrders, BranchOffers |
| Single supplier wholesale | BR-WHOLESALE-001, BR-WHOLESALE-002 | Wholesale |
| Driver–branch binding | BR-DRIVER-001…006 | Drivers, Delivery, Authorization, Audit |
| Independent warehouse/inventory | BR-BRANCH-003, BR-BRANCH-004, BR-WHOLESALE-003 | Branches, Inventory |

---

## 5. Legacy BR-001…BR-010 matrix (Historical mapping)

> **Status:** Historical for **payment/cart/tenant** semantics. Kept so older FR/TC IDs remain findable. Prefer §2 for platform rules.

| Legacy BR | FR examples | Notes |
|-----------|-------------|-------|
| BR-001 | FR-AUTH-* | Still useful for auth tracing; Driver Fake Auth = PartiallyImplemented |
| BR-002 | FR-ORD-* | Must be read **with** BR-ORDER-001…008 (single business/branch) |
| BR-003 | FR-PAY-* | **Superseded wording** → use BR-PAY-001…005 (electronic primary, cash optional) |
| BR-004…BR-010 | compliance, offline, reports, tracking, documents | Still valid as legacy product BRs; align tests when Backend exists |

### Legacy FR ↔ Test index (preserved)

| TC ID | Description | FR Link | Notes |
|-------|-------------|---------|-------|
| TC-AUTH-001…006 | Auth flows / RBAC | FR-AUTH-* | Driver: Fake Auth foundation only (Stage 2.2) |
| TC-ORD-001…008 | Order flows | FR-ORD-* | Must later assert BR-ORDER-* constraints |
| TC-PAY-001…006 | Payments / earnings | FR-PAY-* | Update acceptance to BR-PAY-* (not cashless-only) |
| TC-TRK-*, TC-OFF-*, TC-DOC-*, TC-RPT-*, TC-COM-*, TC-L10N-*, TC-COMP-* | As in v1 matrix | — | Historical index; re-validate at implementation |

---

## 6. Application / channel impact summary

| Application | Rules most relevant | Status |
|-------------|---------------------|--------|
| Customer Mobile | BR-ORDER-*, BR-PAY-*, BR-CATALOG-002 | NotStarted (app absent) |
| Merchant Mobile | BR-BRANCH-*, BR-WHOLESALE-*, BR-ADMIN-001, BR-PAY-003, BR-CATALOG-002 | NotStarted |
| Driver Mobile | BR-DRIVER-*, BR-ORDER-006, offline | PartiallyImplemented (Auth foundation only) |
| Web Admin | BR-ADMIN-002…006, BR-CATALOG-001/003, BR-SEC-*, BR-PAY policy oversight | NotStarted |
| Backend | All rules — source of enforcement | NotStarted (Modular Monolith planned Stage D) |

---

## 7. Coverage summary (official rules)

| Rule group | Count | DocumentedOnly | PartiallyImplemented | Deferred exec |
|------------|-------|----------------|----------------------|---------------|
| BR-ORDER-* | 8 | 8 | 0 | 0 |
| BR-WHOLESALE-* | 4 | 3 | 0 | 1 (partial receipt exec) |
| BR-BRANCH-* | 6 | 6 | 0 | 0 |
| BR-DRIVER-* | 6 | 6 | 0 | 0 |
| BR-ADMIN-* | 6 | 6 | 0 | 0 |
| BR-CATALOG-* | 3 | 3 | 0 | 0 |
| BR-PAY-* | 5 | 4 | 1 (BR-PAY-005 docs) | 0 |
| BR-SEC-* | 3 | 3 | 0 | 0 |
| **Total** | **40** | **39** | **1** | **1** |

Implementation coverage of official rules in code: **~0% product logic** (documentation Stage A complete for tracing).

---

## 8. PHASE status note

| Item | Status |
|------|--------|
| Stage A Documentation Alignment | Finalization in progress → pending owner approval |
| PHASE 2.1 / 2.2 | Done (see phase reports) |
| PHASE 2.3 | **NotStarted** — requires explicit start command |

---

*Gaps between §2 rules and runnable tests/APIs are expected until Stages D–G. Do not mark official rules Implemented without evidence.*
