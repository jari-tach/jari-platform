# Rollback Plan — SAEQ Driver

> Scope: production / store incidents after a Driver release derived from PR #27 lineage.

## Stable references

| Ref | Value |
| --- | --- |
| Pre-Gate-9 docs baseline (pre-hardening commit on branch before Gate 9 close) | `38633c4` |
| Current release-hardening HEAD | `3f86900` |
| Last known Device QA functional fix set | `3f9ec5d` (journey fixes; later commits mostly closure/hardening) |

## Disable / halt new version

1. Pause Play / App Store phased rollout or halt release.
2. If server-side flags exist for Driver API features, disable risky endpoints (ownership: backend ops).
3. Communicate to Driver ops to force-update / stay on prior installed build when possible.

## Revert client binary

1. Republish previous store build (prior `versionCode`).
2. If emergency Git revert on `main` after merge: revert merge commit of PR #27 (or cherry-pick fix-forward — prefer fix-forward once live).
3. Rebuild with previous signing materials; never commit keystores.

## Certificate pinning incidents

1. If API cert rotated without pin update → clients fail TLS closed.
2. Immediate mitigation: ship hotfix with `SAEQ_TLS_PINS=old,new` (rotation guide).
3. Do **not** disable pinning in production as a permanent workaround.

## API / geofence failure

1. Confirm Backend health and Arrival contract.
2. If client-only geofence bug: hotfix on Driver branch; Device QA smoke on HONOR path.
3. Temporary ops: instruct drivers to use official support path for stuck deliveries (no Fake mode in release).

## Sessions / local data

1. Refresh tokens remain in secure storage — rollback APK should still restore sessions if token validity unchanged.
2. Avoid schema-breaking Drift migrations without a forward migration plan.
3. Clear-data is last resort (logs user out).

## Ownership

| Role | Responsibility |
| --- | --- |
| Project owner | Final rollback / republish decision |
| Release engineer | Build, sign, upload |
| Backend owner | API / pin coordination |
