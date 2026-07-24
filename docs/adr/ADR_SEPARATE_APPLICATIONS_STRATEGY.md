# ADR-013: Separate Applications Strategy for the SAEQ Platform

> **ADR Number:** ADR-013
> **Title:** Separate Applications Strategy (Driver / Customer / Merchant / Admin)
> **Status:** ✅ Accepted
> **Date:** 2026-07-24
> **Author:** Senior Flutter Software Engineer / Lead Software Architect
> **Last Updated:** 2026-07-24
> **Related:** [00_PROJECT_BIBLE.md](../00_PROJECT_BIBLE.md), [01_BUSINESS_VISION.md](../01_BUSINESS_VISION.md), [02_SYSTEM_ARCHITECTURE.md](../02_SYSTEM_ARCHITECTURE.md), [03_ENTERPRISE_ARCHITECTURE.md](../03_ENTERPRISE_ARCHITECTURE.md), [36_RELEASE_MANAGEMENT.md](../36_RELEASE_MANAGEMENT.md), [27_ARCHITECTURAL_DECISIONS.md](../27_ARCHITECTURAL_DECISIONS.md)

---

## Context

The SAEQ platform (فزعة/جاري/منفعة) serves four distinct stakeholder types: delivery drivers, end customers, merchants (restaurants/stores), and platform operators (admin). `docs/03_ENTERPRISE_ARCHITECTURE.md` already describes these as "four stakeholder types through dedicated applications", and `docs/01_BUSINESS_VISION.md` already lists them as four separate applications (Jari, Fazaa Driver, Manafa Merchant, SAEQ Admin Dashboard).

However, the project documentation did not yet contain an **explicit, binding architectural decision** ruling out an alternative approach that is common in early-stage delivery platforms: building **one single Flutter codebase** where the user selects their role (Driver / Customer / Merchant) after login, and the UI/features/routing branch internally based on that role. This ADR formally closes that ambiguity.

The current repository (`saeq_driver`) is the **first application** built for this platform, covering the Driver role only. Before any additional application (Customer, Merchant, Admin) is started, the platform-wide strategy for how these applications relate to each other — as separate deployable products vs. a single merged app — must be decided and recorded.

### Forces at play

- **Store distribution:** Drivers, customers, and merchants have fundamentally different app-store listings, ratings, screenshots, and marketing needs. A merged app with role selection produces a confusing store presence for all audiences.
- **Permissions footprint:** Drivers require background location, foreground services, and battery-optimization exemptions. Customers and merchants do not need most of these. Bundling them into one app forces every user to grant permissions irrelevant to their role.
- **Release cadence:** Driver-side bug fixes (e.g., GPS/offline sync issues) should not force a re-release/re-review of the customer-facing app, and vice versa.
- **Team scaling:** As the platform grows, different teams will likely own different apps. Independent codebases reduce merge conflicts and cross-team coupling.
- **Security/RBAC:** Role boundaries enforced only in the UI (a shared app that hides/shows screens per role) are weaker than role boundaries enforced by shipping only the relevant code per app, backed by server-side RBAC.
- **Counter-force (cost):** Separate codebases mean duplicated boilerplate, multiple CI/CD pipelines, and the risk of divergent conventions across apps if not managed carefully.

---

## Decision

**The SAEQ platform is composed of independent, separately-distributed applications — one per role — sharing only backend infrastructure. Merging multiple roles into a single Flutter codebase with post-login role selection is explicitly prohibited.**

### The four applications

| # | Application (generic) | Brand name | Role | Distribution |
|---|---|---|---|---|
| 1 | **SAEQ Driver** | فزعة (Fazaa Driver) | Delivery drivers | Independent Android/iOS app |
| 2 | **SAEQ Customer** | جاري (Jari) | End consumers | Independent Android/iOS app |
| 3 | **SAEQ Merchant** | منفعة (Manafa Merchant) | Restaurants/stores | Independent app (Web Admin-style dashboard acceptable first; mobile app optional later) |
| 4 | **SAEQ Admin** | SAEQ Admin Dashboard | Platform operators | Independent application; **Web Admin preferred for phase 1** |

### Boundaries of each application

Each application:

- Has its **own project/repository** (not a shared monorepo at this stage — see "Reuse Strategy" below).
- Has its **own package name / bundle ID** (Android `applicationId`, iOS `bundleIdentifier`).
- Has its **own app name, icon, splash screen, and visual identity**.
- Has its **own Firebase project/configuration** where needed (push notifications, analytics, crash reporting).
- Has its **own signing keys and independent version numbers** (per `36_RELEASE_MANAGEMENT.md` versioning rules, applied independently per app).
- Has its **own listing on Google Play and the Apple App Store** (or, for Admin, its own web deployment).
- Has its **own Build/Test/Release cycle** (independent CI/CD pipeline, independent release cadence — a Driver hotfix never requires releasing Customer/Merchant/Admin).
- Requests **only the OS permissions its own role requires** (e.g., only SAEQ Driver requests background location).
- Owns **only the routing, features, and dependencies relevant to its role**. There is no shared "god router" or "god feature set" spanning roles.

### Explicitly prohibited

- Merging Driver, Customer, Merchant, and Admin roles into one Flutter application that lets the user pick a role after login.
- Any in-app logic that allows switching between roles at runtime.
- A single package name / bundle ID serving multiple roles.

### Shared backend components (not duplicated per app)

All four applications connect to a **common backend platform**:

- Shared Backend / Shared API Gateway
- Shared Authentication and Authorization (identity provider)
- Shared Central Database
- Shared Notification Service
- Shared Maps and Tracking Services
- Shared Payment Services
- Shared Observability and Audit Logs

**Role isolation is enforced server-side via Role-Based Access Control (RBAC) at the API Gateway / Authorization layer — not merely hidden in the client UI.** Each app authenticates against the same identity provider but only receives tokens/scopes valid for its own role; the backend must reject any request outside that role's granted scope regardless of which client sent it.

---

## Consequences

### Positive

- Clear, uncluttered app-store presence per audience (drivers, customers, merchants each see a purpose-built app).
- Minimal permissions requested per app — better user trust and easier OS permission review/compliance.
- Independent release cadence: a Driver-only fix ships without touching Customer/Merchant/Admin binaries.
- Smaller, more focused codebases — each app only carries the dependencies and features it actually needs (no dead code paths for other roles).
- Stronger security posture: role capabilities are constrained architecturally (separate binaries) and enforced again server-side (RBAC), a genuine defense-in-depth.
- Independent scaling of engineering teams — a Driver team and a Customer team can work without touching each other's repositories.
- Matches the platform's own pre-existing documentation (`03_ENTERPRISE_ARCHITECTURE.md`), which already assumed dedicated apps per stakeholder type.

### Negative

- Higher up-front project-scaffolding cost: each new app repeats initial setup (project structure, CI/CD, theming boilerplate, localization scaffolding) until shared packages are extracted.
- Risk of divergent conventions across apps if engineering standards (naming, architecture, linting) are not actively kept in sync via shared documentation (mitigated by the existing `00_PROJECT_BIBLE.md`, `06_CODING_STANDARDS.md`, etc. applying platform-wide).
- Some short-term code duplication (e.g., theming, base networking client, error handling) until real, proven shared usage across ≥2 apps justifies extraction into shared packages.
- Requires provisioning multiple sets of store listings, signing keys, and (where used) Firebase projects — more moving parts to manage operationally.

### Neutral

- Does not change the backend architecture; the shared backend components listed above remain a single platform regardless of how many client apps consume them.
- Does not affect the internal Clean Architecture / Feature-First structure already adopted inside each individual app (per `04_CLEAN_ARCHITECTURE.md`) — that decision applies unchanged within `SAEQ Driver` and will apply unchanged within future apps.

---

## Alternatives Considered

| Alternative | Description | Pros | Cons | Decision |
|---|---|---|---|---|
| **Single Flutter app with post-login role selection** | One codebase; after authentication, the user's role determines which screens/features are shown. | Single codebase to maintain initially; single store listing to manage. | Confusing store presence for all audiences; forces irrelevant permissions on every user; couples unrelated release cycles; weak role isolation (UI-only); becomes a "god app" as roles grow; contradicts existing `03_ENTERPRISE_ARCHITECTURE.md` assumptions. | ❌ Rejected |
| **Monorepo with multiple app targets from day one** | One repository containing all four Flutter apps plus shared packages, structured as a monorepo (e.g., via Melos). | Immediate code sharing; single place to manage cross-cutting changes. | Premature abstraction before any second app exists; large migration cost for the current `saeq_driver` repository; violates the explicit instruction to avoid extracting shared packages during PROJECT STABILIZATION. | ❌ Rejected (for now — may be revisited once ≥2 apps exist and shared usage is proven) |
| **Fully independent applications, shared backend only** (chosen) | Each role gets its own project, package ID, identity, signing, store listing, and release cycle. All apps talk to one shared backend platform with server-side RBAC. | Clean audience-specific distribution; minimal permissions per app; independent release cadence; strong role isolation via backend RBAC; matches existing documentation. | Some short-term duplication of boilerplate; more repositories/pipelines to operate. | ✅ **Accepted** |

---

## Reuse Strategy (Deferred)

No shared package is extracted at this time. `saeq_driver` (SAEQ Driver) continues to own all of its current code exactly as-is; **no files are moved or refactored as part of this decision.**

When future applications (SAEQ Customer, SAEQ Merchant, SAEQ Admin) are started, candidate shared packages **may** be extracted **only after**:

1. At least **two** applications have a real, proven need for the same component (not a hypothetical future need).
2. The contract of that component (its public API) has stabilized in at least one app first.

Candidate future shared packages (names only, not created now):

- `saeq_design_system` — shared theming, typography (Tajawal), color tokens, common widgets.
- `saeq_core` — shared error handling primitives (`AppException`/`AppFailure` patterns), logging contracts.
- `saeq_networking` — shared Dio client setup, interceptors, retry/backoff conventions.
- `saeq_localization` — shared Arabic-first RTL localization scaffolding and translation-key conventions.
- `saeq_models` — shared DTOs/entities that are genuinely identical across apps (e.g., a canonical `Address` or `Money` value object), where safe to share without leaking role-specific concerns.

**A single "god package" containing all cross-app logic is explicitly prohibited.** Any future extraction must remain narrowly scoped per package (one clear responsibility per shared package, mirroring the Single Responsibility principle already mandated in `00_PROJECT_BIBLE.md` §8).

---

## Independent Release Strategy

Each application follows the versioning and branching rules already defined in `36_RELEASE_MANAGEMENT.md` (Semantic Versioning, Git Flow branch model, independent CI/CD) **applied independently, per application repository**:

- Each app has its own `MAJOR.MINOR.PATCH` version sequence — versions are **not** synchronized across apps (SAEQ Driver `1.4.0` and SAEQ Customer `1.4.0` releasing at the same time would be coincidental, not required).
- Each app has its own branching model (`main`/`develop`/`feature/*`/`release/*`/`hotfix/*`) in its own repository.
- Each app has its own CI/CD pipeline, its own quality gates, and its own store submission process.
- A hotfix in one app never blocks, delays, or requires a release of another app.

---

## Impact on the Current Project (SAEQ Driver)

The current repository (`saeq_driver`) **is and remains scoped to the Driver role only**. As a direct consequence of this decision, effective immediately and for the remainder of **PROJECT STABILIZATION**:

- ❌ No customer-facing screens are added to this repository.
- ❌ No merchant-facing screens are added to this repository.
- ❌ No admin-facing screens are added to this repository.
- ❌ No "select your role" / "choose account type" screen or logic is added.
- ❌ No runtime role-switching logic is added.
- ✅ This repository retains **only** Driver-relevant code: authentication, onboarding, orders (driver-facing), driver status/location, delivery, profile, and driver-specific AI services, exactly as already scoped in `02_SYSTEM_ARCHITECTURE.md` §2.2 and `03_ENTERPRISE_ARCHITECTURE.md` §2.
- ✅ No code, files, dependencies, or package name were modified in this repository as part of recording this decision — this ADR is a documentation-only change.
- ✅ Shared-backend integration points (API Gateway, Auth, Central DB, Notifications, Maps/Tracking, Payments, Observability) remain exactly as already designed; this ADR does not alter how `SAEQ Driver` talks to the shared backend, only confirms that no other role's client-side code lives in this repository.

---

## Related Decisions

- [ADR-002: Clean Architecture with Feature-First Structure](../27_ARCHITECTURAL_DECISIONS.md#adr-002-clean-architecture-with-feature-first-structure) — remains the internal structure standard for every individual app, including future ones.
- [ADR-010: Service Registry Pattern (not get_it)](../27_ARCHITECTURAL_DECISIONS.md#adr-010-service-registry-pattern-not-get_it) — applies independently within each app.
- [00_PROJECT_BIBLE.md](../00_PROJECT_BIBLE.md) §1.1 "التطبيقات الأربعة" — pre-existing enumeration of the four applications, now formally backed by this ADR.
- [03_ENTERPRISE_ARCHITECTURE.md](../03_ENTERPRISE_ARCHITECTURE.md) §1 "Multi Vendor Architecture" — pre-existing shared-infrastructure diagram, now formally paired with this explicit independence decision.

---

## References

- `docs/00_PROJECT_BIBLE.md` — §1.1 (four applications), §6 (architectural decisions log)
- `docs/01_BUSINESS_VISION.md` — §1.1 (four platforms table)
- `docs/02_SYSTEM_ARCHITECTURE.md` — internal architecture applicable per-app
- `docs/03_ENTERPRISE_ARCHITECTURE.md` — §1 Multi Vendor Architecture, §2–5 per-app architecture sections
- `docs/36_RELEASE_MANAGEMENT.md` — versioning/branching rules, now applied independently per app
- `docs/27_ARCHITECTURAL_DECISIONS.md` — ADR log (ADR-001 through ADR-012), extended by this ADR-013

---

*This document is part of the official SAEQ platform reference. See [00_PROJECT_BIBLE.md](../00_PROJECT_BIBLE.md) for the complete overview.*
