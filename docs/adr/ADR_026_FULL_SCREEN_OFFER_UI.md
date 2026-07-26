# ADR-026: Full-Screen Offer UI

> **ADR Number:** ADR-026  
> **Title:** Full-Screen Offer UI  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** [PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md](../PHASE_2_5_DELIVERY_REQUEST_LIFECYCLE_ARCHITECTURE.md), [localization/localization-guidelines.md](../localization/localization-guidelines.md)

---

## Context

Drivers deciding on work need an interruption-safe, accessible surface. A small bottom sheet or toast is easy to miss while driving-related attention is split, and conflicts with large-text / RTL requirements.

---

## Decision

1. Incoming offers use a **full-screen** presentation as the primary UX.  
2. Not a design-system redesign: reuse existing theme/buttons/typography.  
3. Must support Locale-driven RTL/LTR, localized copy, semantic labels, and large text.  
4. Accept/Reject are primary actions; processing disables duplicate submits.  
5. `/orders` placeholder is not the offer surface in PHASE 2.5.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Modal bottom sheet only | Less navigation | Weak attention / a11y | Rejected as primary |
| Home inline card only | Familiar | Easy to miss; cramped | Rejected as primary |

Secondary non-blocking cues may exist later; primary decision UI remains full-screen.

---

## Consequences

### Positive
- Clear decision focus; better a11y surface  

### Negative
- Navigation stack discipline required  

---

## Related Decisions

- [ADR-023](./ADR_023_ONE_ACTIVE_OFFER_POLICY.md)  
