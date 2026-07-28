# Localization Guidelines — SAEQ Driver

**Phase:** 2.4.1 — Application Localization Foundation  
**Architecture:** Custom `AppLocalizations` (not ARB / `gen_l10n` in this phase)

## Supported languages

| Language | Locale codes | UI direction |
|----------|--------------|--------------|
| Arabic   | `ar`, `ar_SA` | RTL (Locale-driven) |
| English  | `en`, `en_US` | LTR (Locale-driven) |

## Fallback language

- Selection uses `locale.languageCode`.
- Arabic copy when `languageCode == 'ar'`.
- All other language codes (including unsupported) fall back to **English**.
- Prefer the shared `_t(english, arabic)` helper in `AppLocalizations` — do not repeat language checks in every getter.

## Default locale

Runtime default is Arabic via `appLocaleProvider` → `Locale('ar')` (see `lib/core/providers/app_providers.dart`).

This default **pre-existed** PHASE 2.4.1 (present at base commit `05d1285`). This phase did not introduce or change it.

## Runtime locale switching

`MaterialApp.router` watches `appLocaleProvider`. Changing that provider rebuilds the app with the new `locale`. Do not hard-code `Directionality` around production widgets; Flutter applies RTL/LTR from the locale.

**Implemented:** Settings includes a language switcher (Arabic / English) wired through `AppLocaleNotifier` and persisted via `AppPreferences` (`app_locale_language_code_v1`). Theme mode is switched the same way via `AppThemeModeNotifier`.

## Mandatory rules

1. **No hard-coded user-visible application text** in presentation widgets. All labels, hints, errors, buttons, tooltips, snackbars, dialogs, banners, chips, app bars, navigation labels, empty/loading/error states, and semantic labels must come from `AppLocalizations`.
2. **Typed failures stay English (or code) in domain.** Presentation mappers (`*_failure_messages`, screen `_messageFor` / `_mapError`) map typed failures to localized safe strings. Never show raw exceptions, repository names, DB terms, stack traces, or security-policy internals.
3. **Semantic labels are localized** the same way as visible text.
4. **No `BuildContext` / l10n in domain, application, repository, or controller layers.**
5. **No mixed-language UI** for application-owned copy:
   - Arabic locale → Arabic-only app-owned text
   - English locale → English-only app-owned text

## Allowed exceptions (not translated)

Document these when they appear in UI:

| Exception | Example | Reason |
|-----------|---------|--------|
| User-provided names | `profile.fullName` | External / user data |
| Phone numbers | masked session phone, profile phone | User / identity data |
| Email addresses | profile email | User data |
| IDs when intentionally shown | business/branch IDs | Operational identifiers |
| Brand display name | `appName`: English `Saeq Driver`, Arabic `سائق` | Locale-appropriate brand short name (`AppConstants.appName` = `سائق`) |
| Avatar initial from `AppConstants.appName` (`سائق`) | first character only | Brand glyph, not a sentence |
| Phone format hint | `05XXXXXXXX` | Shared Saudi mobile format pattern (not a sentence) |
| External / framework strings | Material date pickers, OS dialogs | Not application-owned |

**Open product decision:** Arabic welcome greeting currently says `سائق صَعِق` while the short brand constant is `سائق`. Align after an explicit brand decision; do not invent alternate spellings.

## Quality gate (every feature)

Every current and future feature must satisfy, in order:

1. Business Logic  
2. Localization  
3. Accessibility  
4. Testing  

Localization is not optional polish.

## Accessibility expectations

- Localized semantic labels for status, actions, failures, and progress.
- Status not conveyed by color alone (text/chip labels required).
- Errors understandable without technical jargon.
- Large text and narrow widths must not overflow for localized strings.
- RTL reading order remains logical without manual `Directionality` wrappers.

## Testing requirements

- Unit tests: Arabic getters, English getters, unsupported → English, no empty strings for representative keys.
- Widget tests per feature: Arabic UI, English regression, no mixed app-owned language, RTL/LTR, large-text safety.
- Availability Arabic suite must not regress.
- Prefer explicit `locale:` in widget tests (`Locale('en')` / `Locale('ar')`) so CI is independent of host locale.

## Hard-coded copy review checklist

**Manual review remains mandatory** for every presentation change. Automated coverage is intentionally limited.

`test/core/localization/hardcoded_copy_audit_test.dart` is a **limited regression guard** only: it asserts that a small set of *retired* hard-coded literals (removed in PHASE 2.4.1) do not return, and that this checklist document still exists. It is **not** a complete hard-coded-string detector and must not be treated as proof that no hard-coded UI copy exists.

Before merging presentation changes, review `lib/**/presentation/**` and shell/router for:

- [ ] New `Text('...')` / `TextSpan` with literal copy
- [ ] `labelText` / `hintText` / `helperText` / `errorText` / `tooltip` literals
- [ ] SnackBar / dialog / bottom-sheet / banner / chip / AppBar title literals
- [ ] Semantics `label` / `button` name literals
- [ ] Bottom navigation / route placeholder literals

Do **not** flag: test descriptions, keys, route path constants, enum names, internal logs, domain failure messages (mapped in presentation), external/user values.

## Deferred (not permanently rejected)

- Migration to ARB / `flutter gen-l10n` — out of scope for PHASE 2.4.1; requires a separate decision later.
- In-app language-switcher UI — implemented in Settings (PHASE 2.6 Increment 4).
