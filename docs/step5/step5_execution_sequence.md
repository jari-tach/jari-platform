# STEP 5 — Execution Sequence

> **Status:** Binding sequence after STEP 5A documentation merge
> **Date:** 2026-07-31
> **Baseline:** `8bb129a83e489d348de7469a1b32243c62245199`
> **Related:** [ADR-030](../adr/ADR_030_backend_stack_and_repository_strategy.md)

---

## STEP 5A — Documentation handoff (this PR)

Repository: `jari-tach/jari-platform`
Scope: `docs/**` only

Deliverables:

1. ADR-030 Backend stack + repository strategy
2. Backend domain scope
3. Driver API contract handoff draft (not canonical OpenAPI)
4. Endpoint matrix
5. Remote repository integration plan
6. This execution sequence

Then: CI green → Merge Commit → stop Flutter runtime work.

---

## Ordered work after STEP 5A merge

1. Create the private repository `jari-tach/saeq-contracts`.
2. Build official OpenAPI 3.1 from the Driver handoff draft.
3. Add JSON Schemas and examples.
4. Add validation tests.
5. Add breaking-change checks.
6. Open and merge the contracts PR (Merge Commit).
7. Pin the first contracts release / version.
8. Create the private repository `jari-tach/saeq-backend`.
9. Bootstrap NestJS + PostgreSQL + Prisma + Docker Compose.
10. Implement Backend against the pinned contracts version.
11. Run Unit, Integration, and Contract tests.
12. Merge Backend with Merge Commit only.
13. **Stop before modifying Flutter.**
14. Wait for owner authorization to open **STEP 5C** Driver remote integration.

---

## Parallel locks

| Item | Status |
|------|--------|
| STEP 4B live geofence / background / Map SDK | DEFERRED |
| STEP 6 Realtime (WebSocket / SSE / Push / Redis Realtime) | LOCKED |
| Flutter REST adapters before contracts + Backend gates | FORBIDDEN |
| Backend code inside `jari-platform` | FORBIDDEN |

---

## Merge policy (all STEP 5 repos)

- No Squash
- No Rebase-as-merge substitute when Merge Commit is required
- No Force Push
- No direct push to `main`
- No merge before CI success
- Merge method: **Merge Commit only**
