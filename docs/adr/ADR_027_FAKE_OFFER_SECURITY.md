# ADR-027: Fake Offer Security

> **ADR Number:** ADR-027  
> **Title:** Fake Offer Security  
> **Status:** ✅ Accepted  
> **Date:** 2026-07-26  
> **Author:** PHASE 2.5 Architecture  
> **Last Updated:** 2026-07-26  
> **Related:** Fake Auth / Profile policies (PHASE 2.2/2.3), [ADR-016](./ADR_016_LOCAL_INTENT_VS_BACKEND_AUTHORITY.md)

---

## Context

Roadmap allows simulated delivery offers for PHASE 2.5 without a real Backend. Fake Auth and Fake Profile already enforce Release/Production denials. Offer simulation is higher risk if it can create real-looking assignments in production builds.

---

## Decision

1. Any `FakeDeliveryOfferRepository` / simulator **must not be constructible or usable in `kReleaseMode`**.  
2. Additional deny when production environment flag is true (same spirit as `FakeAuthPolicy` / `FakeProfileSynthesisPolicy`).  
3. Registry uses `_safeInit`: failure → null repository → controller fail-closed (no offers), never crash loop.  
4. Fake may simulate 409/410/latency for tests.  
5. Fake must not bypass availability eligibility default-deny in production paths.  
6. Test-only fakes under `test/` are allowed without shipping in `lib/` app registry.

---

## Alternatives considered

| Alternative | Pros | Cons | Decision |
|-------------|------|------|----------|
| Always-on simulator | Easy demos | Production leakage | Rejected |
| Compile-time flavor only | Strong | Still need runtime guards | Insufficient alone |

---

## Consequences

### Positive
- Consistent security story with Auth/Profile  
- Safe local development  

### Negative
- Demo builds must be non-release  

---

## Related Decisions

- [ADR-020](./ADR_020_DELIVERY_OFFER_VS_ASSIGNMENT.md)  
- [ADR-024](./ADR_024_OFFLINE_ACCEPT_POLICY.md)  
