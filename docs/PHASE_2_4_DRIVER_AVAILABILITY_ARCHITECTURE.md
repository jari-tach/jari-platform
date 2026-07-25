# PHASE 2.4 — Driver Availability & Operational Status

> **Status:** Architecture **Accepted** — Implementation **Not Started**  
> **Date:** 2026-07-25  
> **Base:** `main` @ `123fdba` (PHASE 2.3 merged)  
> **Scope of this task:** Documentation only — no `lib/`, `test/`, packages, schema, CI, commit, or push  
> **Related:** [ADR-015…019](./adr/), [41_OFFICIAL_BUSINESS_RULES.md](./41_OFFICIAL_BUSINESS_RULES.md), [31_TRACEABILITY_MATRIX.md](./31_TRACEABILITY_MATRIX.md), [PHASE_2_4_AVAILABILITY_TEST_PLAN.md](./PHASE_2_4_AVAILABILITY_TEST_PLAN.md), [PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md](./PHASE_2_FEATURE_DEVELOPMENT_ROADMAP.md)

---

## 1. Purpose

Allow an authenticated and **eligible** driver to declare readiness to receive work while keeping operational state:

- secure and deterministic  
- conservative under connectivity loss  
- explicit and testable in transitions  
- compatible with future Backend authority  
- free of premature order-assignment logic  
- consistent with PHASE 2.3 release Fake Auth / identity guards  

**Out of scope for PHASE 2.4 implementation (later):** order offers, accept/reject, maps/GPS tracking UI, payments, inventory, Merchant/Customer/Admin apps.

---

## 2. Document map

| Deliverable | Location |
|-------------|----------|
| Architecture overview (this file) | Hub |
| Business rules BR-AVAIL-* | [41_OFFICIAL_BUSINESS_RULES.md](./41_OFFICIAL_BUSINESS_RULES.md) § Driver Availability |
| Traceability | [31_TRACEABILITY_MATRIX.md](./31_TRACEABILITY_MATRIX.md) |
| Test plan | [PHASE_2_4_AVAILABILITY_TEST_PLAN.md](./PHASE_2_4_AVAILABILITY_TEST_PLAN.md) |
| State machine ADR | [ADR-015](./adr/ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md) |
| Authority ADR | [ADR-016](./adr/ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md) |
| Offline policy ADR | [ADR-017](./adr/ADR_017_OFFLINE_AVAILABILITY_POLICY.md) |
| Busy ownership ADR | [ADR-018](./adr/ADR_018_BUSY_STATE_OWNERSHIP.md) |
| Persistence ADR | [ADR-019](./adr/ADR_019_AVAILABILITY_PERSISTENCE_RESTORATION.md) |

---

## 3. Domain model (design only)

### 3.1 Aggregate: `DriverAvailability`

Single aggregate per authenticated driver session / driverId.

| Field | Kind | Keep? | Notes |
|-------|------|-------|-------|
| `driverId` | Sovereign identity | **Yes** | Must match session; never user-editable |
| `status` | Domain status | **Yes** | See `AvailabilityStatus` |
| `source` | Value | **Yes** | Who last drove the change |
| `lastChangedAt` | Audit | **Yes** | Client or server clock; not user-editable |
| `lastConfirmedAt` | Authority | **Yes** | Last Backend confirmation; null if never confirmed |
| `pendingSync` | Local derived | **Yes** | True only for allowed queued intents (see ADR-017) |
| `revision` / `serverRevision` | Authority | **Yes** | Opaque Backend revision; null until Backend exists |
| `reason` | Optional | **Yes** | Short machine-safe code/reason, not free-form PII essay |
| `activeAssignmentId` | Reference only | **Optional / deferred** | Null throughout PHASE 2.4; reserved for 2.5+ — **no assignment logic** |
| `effectiveStatus` | Presentation/policy | **Derived** | Not persisted as sovereign; computed for UI |
| `confirmationFreshness` | Derived | **Derived** | Based on `lastConfirmedAt` + policy TTL |

**Not stored in profile:** tokens, passwords, OTP, full PII dumps.

### 3.2 Value objects / enums

**`AvailabilityStatus`**

| Value | Meaning |
|-------|---------|
| `offline` | No usable connectivity for operational confirmation / safe non-work state |
| `unavailable` | Online-capable but not accepting work (user or policy) |
| `available` | Eligible and confirmed (or pending only if policy allows — **PHASE 2.4: available requires online confirmation path**) |
| `busy` | System/assignment-owned; **never** user-selected |

**`AvailabilitySource`**

`localUserAction` | `system` | `server` | `restoredLocalState` | `connectivityPolicy`

**`AvailabilityTransition`** (event record, may be ephemeral)

`from`, `to`, `requestedBy` (`user`|`system`|`server`|`connectivity`), `requestedAt`, `reason`, `correlationId`

### 3.3 Invariants

1. `driverId` equals authenticated session driverId.  
2. User cannot request `busy`.  
3. `available` requires eligibility decision `allowed == true`.  
4. Local restored `available` is never treated as Backend-confirmed without fresh confirmation (ADR-016/019).  
5. Server `busy` / newer revision wins over stale local `available`.  
6. Logout invalidates operational availability locally.

### 3.4 Aggregate boundary

Availability is **not** part of `DriverProfile`. It depends on Auth + Profile eligibility but is a separate feature aggregate under `features/availability/`.

---

## 4. State machine (summary)

Full rules: [ADR-015](./adr/ADR_015_DRIVER_AVAILABILITY_STATE_MACHINE.md).

### 4.1 Allowed transitions (when preconditions hold)

| From | To | Actor |
|------|-----|-------|
| offline | unavailable | connectivity restore + policy |
| unavailable | available | user (if eligible + online) |
| available | unavailable | user |
| available | busy | system/server only |
| busy | available | system/server only (assignment lifecycle — **future**; stubbed deny in 2.4) |
| busy | unavailable | system/server (or forced safety) |
| unavailable / available / busy | offline | connectivity policy |
| * | unavailable | forced: logout, suspension, security deny |

### 4.2 Forbidden (always)

| Transition | Reason |
|------------|--------|
| * → busy by user | BR-AVAIL-004 / ADR-018 |
| offline → available | Must not skip safe path; no offline available queue (ADR-017) |
| busy → available by user | Assignment ownership |
| Any transition bypassing policy/use case | BR-AVAIL-012 |

### 4.3 Idempotent

Requesting the **same** status as current effective/local intent → success no-op (BR-AVAIL-010).

---

## 5. Business rules

Canonical numbered rules: **BR-AVAIL-001 … BR-AVAIL-018** (+ extensions) in [41_OFFICIAL_BUSINESS_RULES.md](./41_OFFICIAL_BUSINESS_RULES.md).

Traceability: [31_TRACEABILITY_MATRIX.md](./31_TRACEABILITY_MATRIX.md).

---

## 6. Eligibility policy

**Name:** `AvailabilityEligibilityPolicy` (pure, deterministic — same pattern as `FakeAuthPolicy` / `FakeProfileSynthesisPolicy`).

**Output (structured, not bare bool):**

```text
AvailabilityEligibilityDecision
  allowed: bool
  reasonCodes: List<String>   // empty when allowed
  effectiveStatusHint: AvailabilityStatus?
  retryable: bool
  requiredAction: enum?       // signIn | completeProfile | waitConnectivity | contactSupport | none
  policyVersion: String       // e.g. phase-2.4.eligibility.v1
```

**Inputs evaluated:**

| Input | PHASE 2.4 |
|-------|-----------|
| Authenticated session (not expired) | **Required** |
| Profile exists | **Required** for `available` |
| AccountStatus not suspended/blocked | **Required** |
| EmploymentStatus eligible (active) | **Required** |
| Active assignment | Always none in 2.4; reserved conflict for later |
| Network connectivity | **Required** to enter confirmed `available` |
| Location permission | **Deferred** — not required to toggle available in 2.4 |
| Background location | **Deferred** to delivery/maps phases |
| Release Fake Auth / production Fake policy | **Required** — Fake paths remain blocked in release |
| Backend confirmation | Soft until Backend exists: local+online mock confirmation allowed in non-release trial only |

---

## 7. Authority hierarchy

See [ADR-016](./adr/ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md).

```text
1. Backend authoritative state (when present)
2. Assignment-derived busy (future; system events)
3. Connectivity-safe effective status
4. Local persisted intent (non-sovereign)
5. Ephemeral UI loading/pending flags
```

**Conflict examples (winner):**

| Local | Server/System | Winner |
|-------|---------------|--------|
| available | busy | Server busy |
| unavailable | available | Server available (after eligibility re-check) |
| restored available, no fresh confirm | — | Effective unavailable/offline until reconcile |
| available | session expired | Forced unavailable/offline |
| available | account suspended | Forced unavailable |
| available | newer server revision unavailable | Server |

---

## 8. Offline policy (decision)

See [ADR-017](./adr/ADR_017_OFFLINE_AVAILABILITY_POLICY.md).

| Scenario | Decision |
|----------|----------|
| Lost connectivity while unavailable | Effective `offline` (or stay unavailable with offline banner); no work |
| Lost connectivity while available | **Downgrade effective status** to `offline` (safe); clear “confirmed available” presentation |
| Lost connectivity while busy | Keep **busy** as assignment-derived local view; cannot self-clear to available |
| Queue offline → available | **Forbidden** in PHASE 2.4 |
| Queue offline → unavailable | **Allowed** as local intent + pendingSync; reconcile on reconnect |
| Logout offline | **Allowed** locally; clear availability; server notify best-effort later |
| Stale confirmation TTL | Design default **5 minutes** (assumed; configurable later) |

**Amends historical roadmap AC** that said “queue availability toggle offline then sync”: **superseded** for **→ available**. Unavailable-intent queue remains acceptable.

---

## 9. Repository contract (design)

`DriverAvailabilityRepository` (domain interface):

| Operation | In | Out | Notes |
|-----------|----|-----|-------|
| `watchAvailability()` | — | `Stream<DriverAvailabilityView>` | Effective + flags |
| `getCurrentAvailability()` | — | `DriverAvailabilityView` | Snapshot |
| `requestChange(AvailabilityChangeCommand)` | target + reason | `Result` | Enforces policy |
| `restoreLocal()` | — | `DriverAvailabilityView` | Never auto-publishes authoritative available |
| `reconcile()` | optional server snapshot | `DriverAvailabilityView` | Conflict resolution |
| `clearOnLogout()` | — | void | Local invalidate |
| `applyAuthoritative(AvailabilitySnapshot)` | server DTO | view | Future Backend |

**`DriverAvailabilityView`:** domain status + `effectiveStatus` + `pendingSync` + `isConfirmed` + `eligibility` denial codes for UI — **no** datasource types.

Forbidden: UI → Drift/SharedPreferences directly; Controllers → Fake concrete class (depend on interface); new `get_it`.

Registration: **AppServiceRegistry** (ADR-010), same pattern as profile.

---

## 10. Use cases

| Use case | Keep? | Purpose |
|----------|-------|---------|
| `GetDriverAvailability` | Yes | One-shot read |
| `WatchDriverAvailability` | Yes | Stream for UI |
| `RequestAvailabilityChange` | Yes | User/system request through policy |
| `EvaluateAvailabilityEligibility` | Yes | Pure policy wrapper / shared |
| `RestoreAvailability` | Yes | App start |
| `ReconcileAvailability` | Yes | On reconnect / server push |
| `ForceUnavailableOnLogout` | Yes | Session end |
| `ApplyAuthoritativeAvailability` | Yes | Server override hook |
| `HandleConnectivityChange` | Yes | Maps NetworkMonitor → transitions |
| Thin pass-through wrappers | **No** | Avoid no-op use cases |

---

## 11. Failure taxonomy

Sealed/domain failures (ADR-009 style), count **15**:

| Failure | Retryable | UI action |
|---------|-----------|-----------|
| `AvailabilityUnauthenticated` | No | Sign in |
| `DriverProfileMissing` | Soft | Open profile / retry load |
| `DriverAccountSuspended` | No | Contact support |
| `DriverAccountInactive` | No | Contact support |
| `DriverEmploymentIneligible` | No | Contact support |
| `ActiveAssignmentConflict` | No (until 2.5) | Show busy/assignment |
| `ManualBusyTransitionDenied` | No | Explain system-controlled |
| `InvalidAvailabilityTransition` | No | Show current state |
| `AvailabilityOffline` | Yes when online | Wait / retry |
| `AvailabilityConfirmationRequired` | Yes | Reconnect / retry |
| `AvailabilityStateStale` | Yes | Reconcile |
| `AvailabilitySyncConflict` | Yes | Reconcile |
| `AvailabilityPersistenceFailure` | Yes | Retry |
| `AvailabilitySecurityPolicyDenied` | No | Safe non-available |
| `AvailabilityUnknownFailure` | Maybe | Retry / support |

No stack traces / tokens / full PII in user messages.

---

## 12. Persistence (design — no migration now)

See [ADR-019](./adr/ADR_019_AVAILABILITY_PERSISTENCE_RESTORATION.md).

**PHASE 2.4 recommendation:** non-secret snapshot in existing preferences-style storage (or a thin dedicated secure key if co-located with session). **No Drift schema migration in architecture approval.** If OfflineQueue is used for unavailable intents only, reuse existing queue tables without new columns until implementation ADR says otherwise.

**Never sovereign locally:** eligibility, busy from assignment, server revision truth.

**Logout / account switch:** clear snapshot.

**Corruption:** delete + start unavailable/offline.

---

## 13. Presentation specification

### 13.1 UI states (12)

`loading` | `offline` | `unavailable` | `becomingAvailable` | `available` | `becomingUnavailable` | `busy` | `blockedIneligible` | `syncPending` | `recoverableError` | `nonRecoverableError` | (+ optional `staleAvailableWarning` folded into syncPending/offline)

### 13.2 Controls

- Primary control: **Available / Unavailable** toggle or segmented control on **existing** `HomeScreen` (integration in implementation phase).  
- **No** busy control.  
- Status badge + text (not color-only).  
- Offline banner + pending-sync indicator.  
- Disable control while transitioning; ignore rapid re-taps.  
- RTL Arabic-first (ADR-012).  
- No map / order list / assignment UI in 2.4.

### 13.3 Arabic copy (core)

| Key concept | AR (proposed) |
|-------------|----------------|
| Offline | غير متصل |
| Unavailable | غير متاح |
| Available | متاح |
| Busy | مشغول (نظام) |
| Becoming available | جاري التفعيل… |
| Becoming unavailable | جاري الإيقاف… |
| Sync pending | بانتظار المزامنة |
| Ineligible / suspended | الحساب غير مؤهل |
| Session required | يلزم تسجيل الدخول |
| Profile required | يلزم اكتمال الملف |
| Manual busy denied | لا يمكن تعيين مشغول يدويًا |
| Offline cannot go available | يلزم الاتصال بالشبكة لتصبح متاحًا |
| Retry | إعادة المحاولة |
| Confirmed available | متاح (مؤكد) |
| Not confirmed / stale | الحالة غير مؤكدة |

Exact l10n keys deferred to implementation (use `AppLocalizations` pattern).

---

## 14. Security & privacy

- Release Fake Auth remains blocked (`kReleaseMode` hard guard from 2.3).  
- No Fake Availability in release.  
- `driverId` ownership = session.  
- Local storage tampering cannot grant Backend eligibility.  
- No `bool.fromEnvironment` availability bypass.  
- Logs: correlationId, from/to, reasonCodes, driverId hash/prefix only if needed — **no** tokens, OTP, full phone/email dumps, raw payloads.  
- Client defense-in-depth only; BR-DRIVER-005 / BR-SEC-* remain Backend-authoritative.

---

## 15. Observability (events)

Safe fields: `correlationId`, `from`, `to`, `source`, `reasonCodes`, `pendingSync`, `policyVersion`, `hasServerRevision` (bool).

Events: `availability_restore_*`, `availability_transition_*`, `availability_sync_*`, `availability_forced_unavailable`, `availability_security_denied`.

---

## 16. Proposed file structure (do not create yet)

```text
lib/features/availability/
  availability_feature.dart
  domain/
    entities/driver_availability.dart
    entities/availability_transition.dart
    entities/driver_availability_view.dart
    value_objects/availability_status.dart
    value_objects/availability_source.dart
    policies/availability_transition_policy.dart
    policies/availability_eligibility_policy.dart
    repositories/driver_availability_repository.dart
    usecases/...
    failures/availability_error.dart
  data/
    datasources/availability_local_store.dart
    datasources/availability_remote_datasource.dart  # stub/fake later
    mappers/...
    repositories/fake_or_local_driver_availability_repository.dart
  presentation/
    controllers/availability_controller.dart
    controllers/availability_controller_state.dart
    providers/availability_providers.dart
    widgets/availability_status_badge.dart
    widgets/availability_toggle.dart
```

**Allowed deps:** auth session/profile contracts, NetworkMonitor abstraction, Logger, AppServiceRegistry.  
**Forbidden:** get_it, UI→Drift, Controllers→concrete Fake, order/delivery feature imports.

---

## 17. Implementation sequence (later authorization)

1. Enums/VOs + failures  
2. Transition + eligibility policies + unit tests  
3. Repository contract  
4. Use cases  
5. Local store adapter (no migration unless approved)  
6. Repository impl + Fake remote stub  
7. Controller/state  
8. Widgets + Home integration  
9. Widget/security/regression tests  
10. Docs status → Implemented → Validated  
11. analyze/test/CI  

Each increment: review checkpoint; stop if scope creeps into 2.5.

---

## 18. Risk register (summary)

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Stale available after restart | M | H | ADR-019 restore non-authoritative |
| UI available vs Backend unavailable | M | H | Authority hierarchy; reconcile |
| Busy overridden locally | L | H | ADR-018; no user busy |
| Offline → available replay | M | H | Forbid queue (ADR-017) |
| Duplicate taps | H | M | Transition lock + idempotency |
| Account switch stale state | M | H | Clear on logout/switch |
| Local tampering | M | H | Client not final authority |
| Session expiry while available | M | H | Force safe state |
| Suspension while available | M | H | Force unavailable |
| Scope creep into assignment | M | H | BR-AVAIL-018; ADR boundary |
| Over-complex sync early | M | M | Stub remote; simple reconcile |

---

## 19. Open questions

| # | Question | Status | Resolution / note |
|---|----------|--------|-------------------|
| Q1 | Network mandatory to become available? | **Resolved** | Yes for confirmed available |
| Q2 | Location permission mandatory now? | **Deferred** | Not for 2.4 toggle |
| Q3 | Background location? | **Deferred** | Delivery/maps later |
| Q4 | Queue unavailable offline? | **Resolved** | Yes, local intent |
| Q5 | Queue available offline? | **Resolved** | No |
| Q6 | Confirmation freshness TTL? | **Assumed** | 5 minutes |
| Q7 | Logout requires online server update? | **Assumed** | Local clear required; server best-effort |
| Q8 | Logout while busy? | **Resolved** | Clear local ops state; assignment ownership is Backend/future |
| Q9 | Backend revision strategy? | **Deferred** | Opaque `serverRevision` string/int |
| Q10 | Finish assignment after suspension? | **Deferred** | Backend policy; client forces non-available UI |
| Q11 | Home page exists? | **Resolved** | Yes `HomeScreen`; integrate toggle later |
| Q12 | Availability per driver/device/session? | **Assumed** | Per driverId bound to current session; single-device MVP |

**Blocking questions for architecture approval:** none remaining hidden. Deferred items are explicitly non-blocking for design approval; implementation may refine TTL with product sign-off.

---

## 20. Definition of Done — Architecture & Design

- [x] No application/test/package/schema/CI code changes in this task  
- [x] State machine complete (ADR-015)  
- [x] BR-AVAIL numbered  
- [x] Forbidden transitions defined  
- [x] Authority hierarchy explicit (ADR-016)  
- [x] Offline behavior explicit (ADR-017)  
- [x] Busy ownership explicit (ADR-018)  
- [x] Persistence/restoration explicit (ADR-019)  
- [x] Repository + use cases defined  
- [x] Failure taxonomy defined  
- [x] UI states + AR copy defined  
- [x] Security boundaries defined  
- [x] Test matrix documented  
- [x] Traceability updated  
- [x] Implementation sequence reviewable  
- [x] Open questions classified  
- [x] Owner architecture approval  
- [ ] Implementation authorization (separate)  
- [ ] Commit/push of architecture docs (this PR task)  
- [ ] Implementation / PHASE 2.5 (not started)  

---

## 21. Review checklist

- [ ] No contradiction between ADR-017 and roadmap historical AC (document supersession acknowledged)  
- [ ] Busy never user-togglable  
- [ ] PHASE 2.3 Fake Auth release guard preserved  
- [ ] No order assignment APIs designed as in-scope work  
- [ ] AppServiceRegistry only; no get_it  
- [ ] Every BR-AVAIL maps to ≥1 test ID in test plan / matrix  
