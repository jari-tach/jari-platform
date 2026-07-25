# Saeq Driver

Saeq Driver is the Flutter foundation for the Saeq multi-app ecosystem, including customer, merchant, driver, and admin experiences.

## Current foundation

This phase establishes a scalable and modular app structure with:

- Arabic RTL-first localization support
- A shared professional design system
- Go Router-based navigation
- Riverpod provider setup
- Core services and configuration placeholders for future API and storage integration
- A welcome shell for the driver app without business features

## Main project structure

- `lib/core/` for shared app foundation and infrastructure
- `lib/features/` for feature-specific modules
- `lib/shared/` for reusable widgets and services

## Toolchain

Authoritative Flutter version is pinned in `.flutter-version`.

| Item | Value |
|------|--------|
| Flutter | **exactly** `3.44.7` (stable) — see `.flutter-version` |
| Bundled Dart | `3.12.2` (satisfies `sdk: ^3.12.2` in `pubspec.yaml`) |
| CI | `.github/workflows/flutter-ci.yml` installs `flutter-version: '3.44.7'` and verifies both Flutter and Dart versions |

Use the same Flutter version locally and in CI. Do not lower the Dart SDK constraint to accommodate an older Flutter toolchain.
