# SAEQ — Official Business Rules

> **Version:** 1.0.0
> **Status:** Active
> **Last Updated:** 2026-07-25
> **Author:** Platform Architecture Alignment
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md), [42_PLATFORM_DOMAIN_ARCHITECTURE.md](./42_PLATFORM_DOMAIN_ARCHITECTURE.md), [adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md), [25_REQUIREMENTS_SPECIFICATION.md](./25_REQUIREMENTS_SPECIFICATION.md)
> **Authority:** This document is the **binding source of truth** for platform business rules. Older BR-* rows in Requirements that conflict with this file are **Superseded** for the conflicting clause only.

---

## 1. Purpose

توثيق قواعد الأعمال المعتمدة لمنصة SAEQ برموز ثابتة، وبيان أين يجب تطبيق كل قاعدة لاحقًا.
**لا يُنفَّذ أي منطق في هذه الوثيقة** — مرجع تصميمي فقط.

### Implementation status legend (current repository)

| Status | Meaning |
|--------|---------|
| **DocumentedOnly** | موثّق هنا؛ غير منفَّذ في الكود/DB/API |
| **PartialInDriver** | جزئي داخل `saeq_driver` فقط |
| **NotStarted** | لم يبدأ تنفيذيًا في أي منتج |

---

## 2. Platform topology (binding)

```text
Customer Mobile App
Merchant Mobile App
Driver Mobile App
Web Admin for SAEQ Platform Owners
Backend Platform
```

| Channel | Audience | Daily ops? |
|---------|----------|------------|
| Customer Mobile | End customers | Yes (shopping) |
| Merchant Mobile | Business / branch staff | Yes (store ops) |
| Driver Mobile | Branch drivers | Yes (delivery) |
| Web Admin | SAEQ platform owners & authorized platform staff only | Platform governance — **not** merchant daily ops |
| Backend | Shared | Source of truth, isolation, authorization, audit |

---

## 3. Retail / customer order rules

| Rule ID | Name | Rule | Docs | Domain | DB | Backend | API | Mobile | Web Admin | Tests | Code status |
|---------|------|------|------|--------|----|---------|-----|--------|-----------|-------|-------------|
| BR-ORDER-001 | Single business per order | كل طلب عميل يرتبط بنشاط تجاري (`business_id`) واحد فقط | This file | Order Aggregate | FK `business_id` NOT NULL | Enforce | Request/response scoped | Customer | Oversight only | Isolation | DocumentedOnly |
| BR-ORDER-002 | Single branch per order | كل طلب عميل يرتبط بفرع (`branch_id`) واحد فقط | This file | Order Aggregate | FK `branch_id` NOT NULL | Enforce | Scoped | Customer | Oversight | Isolation | DocumentedOnly |
| BR-ORDER-003 | Single-store cart | لا يجوز دمج منتجات من عدة متاجر/أنشطة في السلة نفسها | This file | Cart Aggregate | Constraint | Enforce | Cart APIs | Customer | — | Cart tests | DocumentedOnly |
| BR-ORDER-004 | Single-branch cart/order lines | لا يجوز دمج منتجات من عدة فروع في الطلب نفسه | This file | Cart/Order | Constraint | Enforce | Cart/Order APIs | Customer | — | Cart tests | DocumentedOnly |
| BR-ORDER-005 | One cart per order | كل طلب يمتلك سلة واحدة | This file | Order | 1:1 | Enforce | — | Customer | — | Unit | DocumentedOnly |
| BR-ORDER-006 | One delivery per order | كل طلب يمتلك عملية توصيل واحدة | This file | Delivery | 1:1 order | Enforce | Delivery APIs | Customer/Driver | Oversight | Delivery | DocumentedOnly |
| BR-ORDER-007 | One payment context | كل طلب يمتلك سياق دفع واحدًا؛ يُسمح بمحاولات دفع متعددة عند الفشل | This file | Payment | payment_attempts | Enforce | Payments | Customer | Finance/support | Payment | DocumentedOnly |
| BR-ORDER-008 | Price snapshot at submit | تُحفظ أسعار بنود الطلب وقت الإنشاء/التأكيد ولا تتغير بتعديل السعر لاحقًا | This file | OrderLine VO | snapshot columns | Enforce | Order APIs | Customer/Merchant | Audit | Order | DocumentedOnly |

---

## 4. Wholesale order rules

| Rule ID | Name | Rule | Affected | Code status |
|---------|------|------|----------|-------------|
| BR-WHOLESALE-001 | Single supplier per wholesale order | كل طلب جملة يرتبط بمورد (`supplier_id`) واحد فقط | Merchant App, Wholesale, Backend, DB, API, Tests | DocumentedOnly |
| BR-WHOLESALE-002 | No multi-supplier basket | لا يجوز دمج منتجات عدة موردين في طلب جملة واحد | Merchant App, Backend | DocumentedOnly |
| BR-WHOLESALE-003 | Receipt creates stock movements | استلام طلب الجملة ينشئ حركات مخزون موثقة (لا تعديل رصيد مباشر) | Inventory Engine, Backend, Audit | DocumentedOnly |
| BR-WHOLESALE-004 | Partial receipt readiness | التصميم يدعم الاستلام الجزئي مستقبلًا دون كسر النموذج | Domain SM, Inventory | DocumentedOnly (deferred execution) |

---

## 5. Branch rules

| Rule ID | Name | Rule | Code status |
|---------|------|------|-------------|
| BR-BRANCH-001 | Branch operating independence | كل فرع نطاق تشغيلي مستقل: موقع، ساعات عمل، مناطق توصيل، موظفون، صلاحيات، مستودع، مخزون، عروض منتجات، طلبات، سائقون، تقارير، إعدادات | DocumentedOnly |
| BR-BRANCH-002 | Branch belongs to business | استقلال الفرع لا يجعله كيانًا منفصلًا عن النشاط؛ يبقى تابعًا لـ `Business` عبر `business_id` | DocumentedOnly |
| BR-BRANCH-003 | Independent warehouse | كل فرع يمتلك مستودعًا مستقلًا (`warehouse_id` ضمن الفرع) | DocumentedOnly |
| BR-BRANCH-004 | Independent inventory | مخزون الفرع مستقل؛ لا مشاركة تلقائية بين الفروع | DocumentedOnly |
| BR-BRANCH-005 | Independent users & permissions | مستخدمو الفرع وصلاحياتهم ضمن `business_id` + `branch_id` scope | DocumentedOnly |
| BR-BRANCH-006 | Independent orders/drivers/reports | طلبات وسائقون وتقارير الفرع معزولة عن الفروع الأخرى | DocumentedOnly |

---

## 6. Driver rules

| Rule ID | Name | Rule | Code status |
|---------|------|------|-------------|
| BR-DRIVER-001 | Driver bound to business + branch | السائق يرتبط بـ `business_id` و`branch_id` محددين أثناء التفعيل التشغيلي | DocumentedOnly (Driver schema today lacks branch_id) |
| BR-DRIVER-002 | Branch-scoped operations | يعمل ضمن نطاق الفرع المصرح له فقط | DocumentedOnly |
| BR-DRIVER-003 | No cross-branch orders | لا يطلع على طلبات فرع آخر | DocumentedOnly |
| BR-DRIVER-004 | No cross-branch customers/inventory/reports | لا يطلع على عملاء أو مخزون أو تقارير فرع آخر | DocumentedOnly |
| BR-DRIVER-005 | Server-side enforcement | تُفرض القيود من Backend وليس بإخفاء UI فقط | DocumentedOnly |
| BR-DRIVER-006 | Branch reassignment audited | أي تغيير في ارتباط السائق بالفرع موثّق وقابل للتدقيق | DocumentedOnly |

### 6.1 Driver availability rules (PHASE 2.4 design)

> Full architecture: [PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md](./PHASE_2_4_DRIVER_AVAILABILITY_ARCHITECTURE.md).
> Code status remains **DocumentedOnly** until implementation authorization.

| Rule ID | Name | Rule | Enforcement | Test implications | Backend implications |
|---------|------|------|-------------|-------------------|----------------------|
| BR-AVAIL-001 | Authenticated session required | يجب وجود جلسة مصادقة صالحة قبل أي حالة تشغيلية | Domain eligibility + use case | T-DOM-002 | Session/token validation |
| BR-AVAIL-002 | Profile required for available | يجب وجود ملف سائق صالح قبل `available` | Eligibility | T-DOM-003 | Profile service |
| BR-AVAIL-003 | Ineligible account blocked | حساب معلّق/معطّل/غير مؤهل لا يصبح متاحًا | Eligibility | T-DOM-004/005 | Account/employment flags |
| BR-AVAIL-004 | No manual busy | لا يختار السائق `busy` يدويًا | Transition policy + UI | T-DOM-006, T-WID-008 | N/A client; server assigns busy |
| BR-AVAIL-005 | Busy from system/assignment | `busy` فقط من حدث نظام/تعيين سلطوي | Transition policy | T-DOM-007 | Assignment engine |
| BR-AVAIL-006 | Active assignment conflict | مع تعيين نشط لا يصبح متاحًا بحرية إلا وفق دورة التعيين | Policy (future 2.5) | reserved | Assignment SM |
| BR-AVAIL-007 | Local not final truth | الحالة المحلية ليست مصدر الحقيقة النهائي | Authority ADR-016 | T-DOM-010, T-REPO-002 | Authoritative API |
| BR-AVAIL-008 | No auto-publish on restore | الاستعادة لا تنشر `available` كمؤكد تلقائيًا | Restore use case | T-REPO-001 | Confirm endpoint |
| BR-AVAIL-009 | Uncertain → safe state | عند شك الاتصال/الجلسة الحالة الفعلية غير متاحة/غير متصل | Connectivity policy | T-CTL-008 | Heartbeat optional |
| BR-AVAIL-010 | Idempotent same-state | تكرار نفس الحالة ناجح بلا أثر جانبي | Transition policy | T-DOM-008 | Idempotent POST |
| BR-AVAIL-011 | Deterministic denial | الرفض يُرجع فشل مجال محدد | Failures | all denial tests | Error codes |
| BR-AVAIL-012 | No UI bypass | العرض لا يتجاوز سياسة الانتقال | Controller→use case only | architecture review | N/A |
| BR-AVAIL-013 | Release fake blocked | الهويات/التوفر الوهمي ممنوع في Release | Security + 2.3 guards | T-SEC-001 | Real auth only |
| BR-AVAIL-014 | Sovereign timestamps/ids | الحقول الزمنية والهوية غير قابلة لتعديل المستخدم | Domain command allowlist | T-DOM-013 | Server clocks |
| BR-AVAIL-015 | Server busy wins | `busy` من الخادم يغلب `available` المحلي البالي | Reconcile | T-DOM-012 | Push/revision |
| BR-AVAIL-016 | Logout clears availability | تسجيل الخروج يُبطل التوفر التشغيلي محليًا | clearOnLogout | T-REPO-007 | Best-effort notify |
| BR-AVAIL-017 | Suspension forces safe state | التعليق أثناء التشغيل يفرض حالة غير متاحة | System force | T-DOM-004 | Account events |
| BR-AVAIL-018 | No assignment in 2.4 | لا يُنفَّذ منطق تعيين الطلبات في PHASE 2.4 | Scope gate | review checklist | PHASE 2.5+ |

---

## 7. Administration & channel rules

| Rule ID | Name | Rule | Code status |
|---------|------|------|-------------|
| BR-ADMIN-001 | Merchant daily ops via Merchant Mobile | التاجر يدير نشاطه اليومي من Merchant Mobile App فقط | DocumentedOnly (apps not built) |
| BR-ADMIN-002 | Platform ops via Web Admin | إدارة SAEQ تدير المنصة من Web Admin فقط | DocumentedOnly |
| BR-ADMIN-003 | Merchant has no platform admin powers | لا يستخدم التاجر Web Admin للإدارة اليومية ولا يحصل على صلاحيات إدارة المنصة عبره | DocumentedOnly |
| BR-ADMIN-004 | Sensitive admin actions audited | كل عملية إدارية حساسة تُسجَّل في Audit Log | DocumentedOnly |
| BR-ADMIN-005 | Intervention reason required | كل تدخل إداري في بيانات التاجر أو الطلب يسجّل سبب التدخل | DocumentedOnly |
| BR-ADMIN-006 | Before/after values | تسجيل القيمة السابقة والجديدة عند تعديل البيانات الحساسة | DocumentedOnly |

---

## 8. Catalog & offer rules

| Rule ID | Name | Rule | Code status |
|---------|------|------|-------------|
| BR-CATALOG-001 | Central catalog | فهرس المنتجات مركزي على مستوى المنصة (Catalog Product) | DocumentedOnly |
| BR-CATALOG-002 | Branch-level commerce fields | السعر والمخزون والتوفر وحدود الشراء والعروض على مستوى Branch Product Offer فقط | DocumentedOnly |
| BR-CATALOG-003 | No store price on catalog product | يُمنع وضع سعر بيع الفرع أو كمية مخزونه أو توفره داخل Catalog Product | DocumentedOnly (docs corrected 2026-07-25) |

---

## 9. Payment rules

| Rule ID | Name | Rule | Code status |
|---------|------|------|-------------|
| BR-PAY-001 | Electronic payment primary | الدفع الإلكتروني هو المسار الأساسي المدعوم | DocumentedOnly |
| BR-PAY-002 | Cash optional | الدفع النقدي ميزة اختيارية | DocumentedOnly |
| BR-PAY-003 | Merchant cash toggle | يستطيع التاجر تفعيل/تعطيل النقدي وفق سياسة المنصة والباقة | DocumentedOnly |
| BR-PAY-004 | Cash scoping | يمكن تقييد النقدي حسب النشاط أو الفرع أو المدينة أو نوع الطلب | DocumentedOnly |
| BR-PAY-005 | Docs must not say cashless-only | يُمنع وصف المنصة كـ cashless-only مع وجود نقدي اختياري؛ الوثائق توحَّد على BR-PAY-001…004 | DocumentedOnly (Requirements aligned 2026-07-25) |

> **Supersession:** Older `BR-003` wording “cashless payments” in `25_REQUIREMENTS_SPECIFICATION.md` is **Superseded** by **BR-PAY-001…005**. Older `FR-PAY-001` listing cash as an equal primary method is clarified: cash is optional per merchant/branch policy.

---

## 10. Authorization & audit cross-cutting

| Rule ID | Name | Rule | Code status |
|---------|------|------|-------------|
| BR-SEC-001 | Server-side authorization | الصلاحيات الحساسة تُفرض من Backend (RBAC + Business Scope + Branch Scope) | DocumentedOnly |
| BR-SEC-002 | Audit sensitive interventions | كل تدخل إداري حساس → Audit Log (انظر Domain Architecture §Audit) | DocumentedOnly |
| BR-SEC-003 | No client-trusted tenant IDs | لا يُعتمد `business_id`/`branch_id` القادم من العميل دون تحقق خادم | DocumentedOnly |

---

## 11. Traceability note

Legacy IDs in `25_REQUIREMENTS_SPECIFICATION.md` (`BR-001`…`BR-010`) remain for historical traceability. **Conflict resolution:** when a legacy BR conflicts with a `BR-ORDER-*` / `BR-PAY-*` / etc. rule in this file, **this file wins**.
