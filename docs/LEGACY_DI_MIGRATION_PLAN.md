# Legacy DI Migration Plan — `service_locator.dart` / get_it

> **Version:** 1.0.0
> **Status:** Active (plan only — no code deletion yet)
> **Last Updated:** 2026-07-25
> **Related:** [ADR-010](./27_ARCHITECTURAL_DECISIONS.md#adr-010-service-registry-pattern-not-get_it), [ADR-014](./adr/ADR_014_PLATFORM_CHANNEL_AND_DOMAIN_ALIGNMENT.md), `lib/core/di/service_locator.dart`, `lib/shared/services/app_service_registry.dart`

---

## 1. Classification of `lib/core/di/service_locator.dart`

| Attribute | Value |
|-----------|-------|
| Status | **Legacy** |
| Runtime use in app entry | **Unused** (`main.dart` uses `AppServiceRegistry`) |
| Conflict | **Conflicts with ADR-010** |
| Disposition | **Candidate for later removal** |
| Action in Documentation Phase | Document only — **do not delete** |

`get_it` as an architecture choice is **Deprecated / Superseded** by ADR-010. Mentions of get_it as the official DI approach in active docs must be corrected or marked superseded.

---

## 2. Safe removal checklist (future phase — requires explicit approval)

Before deleting `service_locator.dart` or removing `get_it` from `pubspec.yaml`:

1. Ripgrep for `service_locator`, `initDependencies`, `get_it`, `GetIt`, `sl.`, `getIt`.
2. Confirm zero imports from `lib/` and `test/` (except intentional historical comments).
3. Run `flutter analyze`.
4. Run `flutter test`.
5. Verify Bootstrap path: only `AppServiceRegistry.init()` from `main.dart`.
6. Verify no debug/tools scripts depend on get_it.
7. Obtain explicit approval to delete the file and optionally drop the dependency.
8. Commit on a dedicated cleanup branch (not during feature work).

---

## 3. Dual-registration ban

Do not register the same services in both `AppServiceRegistry` and `service_locator`. New work must use **AppServiceRegistry only**.
