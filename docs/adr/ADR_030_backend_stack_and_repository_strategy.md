# ADR-030: Backend Stack and Repository Strategy

> **ADR Number:** ADR-030
> **Title:** Backend Stack and Repository Strategy (STEP 5A)
> **Status:** ✅ Accepted (owner STEP 5A authorization 2026-07-31)
> **Date:** 2026-07-31
> **Author:** STEP 5A Architecture · Principal Engineer
> **Last Updated:** 2026-07-31
> **Related:** [ADR-013](./ADR_SEPARATE_APPLICATIONS_STRATEGY.md), [ADR-014](./ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md), [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md), [42_PLATFORM_DOMAIN_ARCHITECTURE.md](../42_PLATFORM_DOMAIN_ARCHITECTURE.md), [20_DEVELOPMENT_ROADMAP.md](../20_DEVELOPMENT_ROADMAP.md)

---

## Context

STEP 4A closed with foreground GPS, local geofence policy, and external
navigation. STEP 5 Backend is now authorized. Official platform docs require
independent repositories for Driver, Merchant, Customer, Web Admin, and Backend
(ADR-013 / Platform Domain Architecture §12). Starting Backend work inside
`jari-tach/jari-platform` would violate that strategy.

Stage D also needs a concrete, owner-approved technology stack, a canonical
contracts home, and a clear gate before any Flutter remote integration.

---

## Decision

### 1. Repository strategy (binding)

| Repository | Role |
|------------|------|
| `jari-tach/jari-platform` | SAEQ Driver Flutter client only |
| `jari-tach/saeq-contracts` | Canonical API contracts (OpenAPI 3.1, JSON Schemas, examples, contract validation) |
| `jari-tach/saeq-backend` | Backend Modular Monolith (NestJS, PostgreSQL, Prisma, server services) |

**Forbidden inside `jari-tach/jari-platform`:**

- Backend Server
- NestJS
- Prisma
- Database Migrations
- Docker Compose
- PostgreSQL configuration
- Server-side authentication
- Backend business logic
- `apps/` or `packages/` Backend folders as a substitute for independent repos

Separate-applications strategy remains accepted. Backend must not be merged into
the Driver repository.

### 2. Backend stack (binding)

| Concern | Choice |
|---------|--------|
| Runtime | Node.js LTS |
| Language | TypeScript |
| Framework | NestJS |
| Database | PostgreSQL |
| ORM | Prisma |
| API style | REST |
| API specification | OpenAPI 3.1 |
| Testing | Jest |
| Local development | Docker Compose |

This stack does **not** require additional owner approval before Backend
repository bootstrap. It is the accepted Stage D foundation.

### 3. Canonical contracts

`jari-tach/saeq-contracts` is the single source of truth for:

- OpenAPI 3.1 specifications
- JSON Schemas
- Request/response examples
- Contract validation tests
- Breaking-change checks

Driver documentation under `docs/step5/` may contain **handoff drafts** that
describe Driver needs. Those drafts are **not** the canonical OpenAPI contract.

### 4. Realtime (deferred)

The following remain deferred to **STEP 6** and must not start in STEP 5:

- WebSocket
- SSE
- Push Notifications
- Realtime Infrastructure
- Redis Realtime

STEP 5 Backend is REST + persistence + authoritative state. Realtime transport
is out of scope until STEP 6 is unlocked.

### 5. Flutter remote integration gate

Flutter Remote / REST adapters remain **deferred** until all of the following
are true:

1. Canonical contracts are merged in `saeq-contracts`
2. Backend is implemented against the pinned contracts version
3. Contract tests pass
4. Backend integration tests pass
5. Owner authorizes STEP 5C Driver remote integration

Until that gate, Driver keeps Fake / Local adapters. No production Base URL,
no `useMockBackend` switching logic, and no Backend authentication integration
are introduced in STEP 5A.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Backend inside `jari-platform` | One clone | Violates ADR-013 / independent-repos strategy | Rejected |
| Monorepo + Melos now | Shared tooling | Explicitly deferred until ≥2 stable apps + new ADR | Rejected |
| Microservices in STEP 5 | Scale isolation | Premature; Stage D is Modular Monolith | Rejected |
| gRPC-first API | Strong typing | Driver already planned around REST; OpenAPI ownership clearer for contracts repo | Rejected for STEP 5 |
| Start Flutter REST adapters before contracts | Faster client progress | Risks contract drift and Fake/production gate regressions | Rejected |

---

## Consequences

### Positive

- Clear ownership: contracts vs Backend vs Driver
- Stack is fixed and actionable for `saeq-backend` bootstrap
- Realtime does not contaminate STEP 5 REST foundation
- Driver stays free of server-side code and secrets

### Negative

- Cross-repo coordination overhead
- Flutter remote work waits for contracts + Backend gates

### Neutral

- Existing Dio / `ApiClient` scaffolding in Driver remains unused until STEP 5C
- STEP 4B (live geofence / background location / Map SDK) remains deferred

---

## Related Decisions

- [ADR-013](./ADR_SEPARATE_APPLICATIONS_STRATEGY.md) — separate apps and shared Backend
- [ADR-014](./ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md) — channel model and Backend authority
- [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md) — local intent never grants server eligibility
- [ADR-027](./ADR_027_FAKE_OFFER_SECURITY.md) — Fake remotes forbidden in production
- [ADR-028](./ADR_028_DELIVERY_ASSIGNMENT_PERSISTENCE.md) — local assignment durability is not Backend authority
- [ADR-029](./ADR_029_DRIVER_LOCATION_MAPS_GEOFENCE.md) — local geofence intent; Backend proof remains STEP 5+

---

*جزء من المرجع الرسمي لمشروع SAEQ. STEP 6 Realtime يبقى مقفلاً. ربط Flutter REST يبدأ فقط بعد اعتماد العقود ونجاح اختبارات الـBackend.*
