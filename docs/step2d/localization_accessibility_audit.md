# STEP 2D — Item 22 · Localization and Accessibility Audit

> Baseline: `6164994ca262535c85bdeafdee822e32ad877da2`  
> Scope: audit plus two minimal critical-path Semantics fixes. Fixture redesign, typography redesign, and layout refactors are not STEP 2D work.

## Localization mechanism

| Concern | Verified implementation |
|---|---|
| Translation mechanism | Hand-written `AppLocalizations`; private `_t(String english, String arabic)` returns Arabic when `locale.languageCode == 'ar'`, otherwise English. No ARB/gen-l10n files. |
| Public localized API | **695 members**: 656 public `String get` getters + 39 public parameterized methods. |
| Locale provider | `appLocaleProvider` (`NotifierProvider<AppLocaleNotifier, Locale>`). |
| Default and supported locales | Arabic default; notifier normalizes to `ar` or `en`. |
| Persistence | `AppPreferences` → SharedPreferences key `app_locale_language_code_v1`. |
| Direction | Flutter derives RTL/LTR from the locale passed to `MaterialApp.router`; no manual root `Directionality` override. |
| Literal widgets | No literal `Text('…')` application copy was found in `lib/`; this does **not** mean fixture data is localized. |
| Existing audit guard | `hardcoded_copy_audit_test.dart` is a limited three-file substring regression guard, not a repository-wide detector. |

Nine public getters bypass `_t`: four aliases (`navOrders`, `ordersScreenTitle`, `welcomeTitle`, `welcomeSubtitle`), and five locale-neutral literals/aliases (`deliveryVerifyCodeHint`, `phoneNumberHint`, `homeFakeSummaryHint`, and two masked phone formats). `batchCustomerPhoneNumber` returns synthetic digits and is locale-neutral.

## Font audit

| Finding | Status |
|---|---|
| `AppTheme.fontFamily = 'Tajawal'` | Applied to **both Arabic and English**. |
| `GoogleFonts.tajawal(...)` | Applied unconditionally throughout the text theme and key control styles. |
| `AppTheme.fontFamilyFallback = 'Roboto'` | Declared but unused. |
| Locale-driven font switching | **Absent.** |
| Bundled font assets | None; Tajawal is supplied through `google_fonts`. |

This is a documented **GAP: English/Roboto switching is not implemented**. STEP 2D does not change typography because that would exceed the approved minimal Semantics scope. Runtime font availability on a first offline cold launch also remains a risk because no font asset is bundled.

## Mixed-language audit and STEP 2D fixes

| Surface | Before STEP 2D | STEP 2D result |
|---|---|---|
| OTP digit cells, `saeq_otp_input.dart` | English-only Semantics: `Digit X of Y` | **FIXED** with new localized `otpDigitSemantics(index, length)` |
| Batch map preview, `batch_ui_helpers.dart` | English-only Semantics: `Batch stops preview` despite an existing key | **FIXED** by using `l10n.batchSemanticsMap` |

After this PR, **mixed-language Semantics defects on the audited critical path = 0**. This claim is limited to the two identified Semantics defects; it does not claim fixture text is clean.

### Remaining visible English fixture data in Arabic UI

| Source | Visible examples | Surface | Status |
|---|---|---|---|
| `fake_delivery_history_repository.dart` | `Merchant Alpha`, `Pickup Downtown`, `Dropoff North` and equivalent Beta/Gamma/Delta rows | Deliveries list/detail | GAP — fixture redesign deferred |
| `fake_delivery_seed.dart` | `Merchant <token>`, `Pickup <token>`, `Dropoff <token>` | Delivery offer card | GAP — fixture redesign deferred |
| `documents_feature.dart` fake upload metadata | `trial-document.pdf`, `1.2 MB`, `application/pdf` | Document upload | GAP — metadata localization/product decision deferred |

Earnings and notifications fakes already use neutral keys that screens map through `l10n`; history and delivery seeds do not. Replacing these fixtures would change behavioral test data and is intentionally not included in the STEP 2D Semantics-only code delta.

Arabic-only `AppConstants.appName` and `appTagline` also exist outside `AppLocalizations`; whether they render on an English surface remains unverified and is kept in the gap register.

## Accessibility semantics

Shared widgets with explicit semantics include OTP input, status chips, resend timer, profile header, offline banner, loading skeleton, filter chips, error state, delivery timeline, and delivery action button. Feature-level semantics cover the batch journey/contact/map components, location/map placeholders, offers, availability, login, and OTP flows.

| Surface | Finding |
|---|---|
| Standard SAEQ text buttons | Underlying Material button exposes the localized text; high-value delivery/availability actions add explicit semantics. |
| `SaeqIconButton` | Uses localized tooltip and `Icon.semanticLabel`. |
| Profile/settings/notification tappable rows | Visible text is exposed, but some rows do not declare `button: true`. GAP. |
| Contact card | Card summary is localized. Call/WhatsApp buttons lack explicit Semantics wrappers; locked indicator is visual-only. GAP. |
| Splash gesture | `GestureDetector` has no explicit Semantics role. GAP. |
| Focus traversal | Implicit widget-tree order; no `FocusTraversalGroup` or `autofocus`. Vehicle edit has six fields without explicit next-field traversal. GAP. |

## Touch-target audit

| Target | Evidence | Result |
|---|---|---|
| OTP cells | `48 × 52` dp | PASS |
| SAEQ primary/secondary/outline/destructive/success buttons | `minimumSize` height uses `AppTheme.minTouchTarget = 48` | PASS |
| Delivery action button | 56 dp | PASS |
| Icon buttons/resend timer | 48 dp | PASS |
| Profile navigation rows | 56 dp minimum | PASS |
| Settings rows | 48 dp minimum | PASS |
| Batch Call/WhatsApp and issue options | 48 dp minimum | PASS |
| `SaeqFilterChip` | Derived height about **34 dp** at scale 1.0; no minimum-height constraint | **GAP (<48)** |
| Onboarding locale/theme `TextButton`s | Material default minimum height about **36 dp**; no local 48 dp constraint | **GAP (<48)** |

The two sub-48 findings are derived from declared padding/font metrics and Material defaults, not measured in a widget test. No `visualDensity`, `MaterialTapTargetSize`, or tap-target override was found that would raise them to 48 dp.

## Responsive evidence

| Axis | Proven evidence | Honest limit |
|---|---|---|
| 320 px | Shared design buttons; Documents list; Location; Map preview; Batch screens/journey; Availability card | No 320 test for login, OTP, home as a whole, profile, profile edit, vehicle, upload, single-delivery verify/issue/active, settings, support, notifications, earnings, or history. |
| Text scale 1.3 | Documents at 320×800; Location/Map at 320×640; Batch at 320×800; profile header | Coverage is smoke/no-overflow for the exercised state only. |
| Larger scale | Login/Profile/Availability at 1.6; delivery offer actions at 1.6; shared primary button at 1.6 | Does not substitute for every screen at 320 px. |
| Dark + RTL | Shared design-system smoke; Location Arabic dark at 320/1.3; Documents Arabic dark; Batch dark/narrow | Several pages rely only on inherited semantic theme tokens. |

Most content screens are scrollable. Fixed-column risk remains on Delivery Verify, Delivery Issue, Welcome, Onboarding, Splash, Session Expired, Shell Placeholder, and blocking-failure branches of Login/OTP. Delivery Issue is the highest overflow risk because it combines four list tiles, copy, errors, and actions without scrolling.

## Gap register

| ID | Gap | Evidence / risk | Deferred owner |
|---|---|---|---|
| L10N-01 | Tajawal used for English; Roboto declared but unused | No locale-driven font switch | Future design-system/typography decision |
| L10N-02 | Fake history seed is English in Arabic UI | Merchant/pickup/dropoff fixture strings rendered verbatim | Fixture redesign |
| L10N-03 | Fake delivery seed is English in Arabic UI | Merchant/pickup/dropoff labels rendered verbatim | STEP 3/5 fixture/backend model |
| L10N-04 | Upload metadata is English/technical in Arabic UI | Filename, MB label, MIME type | STEP 7 |
| L10N-05 | Arabic-only `AppConstants` English-path usage unverified | Call-site trace not completed | Localization follow-up |
| A11Y-01 | Filter chips likely ~34 dp | Below 48 dp | Design-system stabilization follow-up |
| A11Y-02 | Onboarding text buttons likely ~36 dp | Below 48 dp | Auth UI stabilization follow-up |
| A11Y-03 | Some tappable rows lack button role | Screen reader role not explicit | Accessibility follow-up |
| A11Y-04 | Contact actions/locked marker lack explicit semantics | Text may be exposed, action/state role incomplete | Batch accessibility follow-up |
| A11Y-05 | Implicit focus order and weak keyboard handling | Delivery Verify/Issue and multi-field Vehicle Edit risks | Form accessibility follow-up |
| RESP-01 | 320/1.3 coverage is incomplete | Screen list above | Per-feature test expansion |
| RESP-02 | Fixed-column pages can overflow | Highest risk: Delivery Issue | Stabilization bug-fix phase |
| COPY-01 | Contact banner may imply reveal at arrival, while Hotfix reveals after pickup | Product copy inconsistency | Product copy decision |

## Audit conclusion

- New localized members in STEP 2D: **1** (`otpDigitSemantics`).
- Critical-path Semantics defects found/fixed: **2 / 2**.
- Remaining critical-path mixed-language Semantics defects from this audit: **0**.
- Remaining English fixtures visible in Arabic UI: **documented gaps, not zero**.
- Code changes were limited to the three approved localization/Semantics files; no fixture, typography, layout, or behavior redesign was performed.
