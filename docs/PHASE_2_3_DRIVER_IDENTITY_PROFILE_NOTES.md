# PHASE 2.3 â€” Driver Identity and Profile (Implementation Notes)

> **Status:** Validated (pending commit authorization) â€” **not Done**
> **Branch:** `feature/phase-2.3-driver-identity-profile`
> **Base:** `e14b322`

## Security controls (PHASE 2.3)

### Policy versions

| Policy | Version |
|--------|---------|
| Fake Auth | `phase-2.3.fake-auth.v1` |
| Profile synthesis | `phase-2.3.profile-synthesis.v1` |

### Decision model

`SecurityPolicyDecision`: `allowed`, `reasonCodes`, `policyVersion`.
Pure / deterministic / no side effects / no timestamps / no network.

### Fake Auth reason codes

- `releaseModeDenied`
- `productionEnvironmentDenied`
- `invalidEnvironment`
- `policyConfigurationMissing`

### Profile synthesis reason codes

- `releaseModeDenied`
- `productionEnvironmentDenied`
- `synthesisNotPermitted`
- `invalidEnvironment`
- `policyConfigurationMissing`

### Hard Release guard

- `FakeAuthenticationRepository`: first check `kReleaseMode` â†’ `StateError` (non-bypassable).
- Trial profile synthesis: `kReleaseMode` â†’ no synthesis; then policy evaluation.
- Trusted environment sources: `kReleaseMode` + `AppConfig.isProduction` (tests may inject production denial only; cannot disable Release guard).
- No Dart-define escape hatch. No client/UI/request bypass.

### Sovereign fields (authoritative)

`driverId`, `businessId`, `branchId`, `phoneNumber`, `employmentStatus`, `accountStatus`, `createdAt`

### Client-editable fields

`fullName`, `email`, `profileImageUrl`

### Non-client-updatable (until separate decision)

`vehicleType`, `vehiclePlate`

### Production synthesis

- Allowed only when policy allows (non-release, non-production).
- Production/Release cache miss â†’ `ProfileNotFoundError`.
- Trial profiles marked `DriverProfileProvenance.trialSynthetic` (domain-only, not Drift, not verified production provenance).

### Client vs Backend

Client guards are **defense-in-depth only**. Authoritative AuthZ / tenant binding remains Backend (BR-DRIVER-005, BR-SEC-*).

### Migrations

**None.** No Drift schema change for provenance or tenant columns in this phase.

## Delivered (functional)

- Domain `DriverProfile` + repositories + presentation states + `/profile` route.
- `SessionLifecycle` on auth controller.
- `AppServiceRegistry` registration (ADR-010). No new `get_it`.

## Fake Auth matrix

| Build / Environment        | Fake Auth | Trial synthesis |
| -------------------------- | --------- | --------------- |
| Debug + Development        | Allowed   | Allowed         |
| Test                       | Allowed   | Allowed         |
| Profile + Development      | Allowed   | Allowed         |
| Debug/Profile + Production | Blocked   | Blocked â†’ NotFound |
| Release + any environment  | **Always blocked** | **Always blocked** |

## Known Limitations

- No real Backend OTP/JWT.
- `businessId` / `branchId` not in Drift v1.
- Client enforcement â‰  Backend enforcement.
