# Driver API Contract Handoff

STATUS:
DRIVER HANDOFF DRAFT

NOT CANONICAL OPENAPI

The canonical API contract will live in:
jari-tach/saeq-contracts

---

> **Date:** 2026-07-31
> **Baseline:** `8bb129a83e489d348de7469a1b32243c62245199`
> **Audience:** Contracts + Backend teams
> **Driver repo:** `jari-tach/jari-platform`
> **Related:** [ADR-030](../adr/ADR_030_backend_stack_and_repository_strategy.md), [step5_backend_domain_scope.md](./step5_backend_domain_scope.md)

هذه الوثيقة ليست عقد OpenAPI الرسمي، بل مسودة تسليم توضح احتياجات تطبيق
السائق لفريق العقود والـBackend.

---

## Global conventions (required in canonical contracts)

| Concern | Driver requirement |
|---------|--------------------|
| Identifiers | UUID for offers, assignments, orders, drivers, requests |
| Timestamps | UTC ISO-8601 |
| Pagination | Cursor or page/limit with stable ordering; include `hasMore` / next cursor |
| Aggregate versioning | Explicit revision / version field on offer and assignment resources |
| Request tracing | Client sends `X-Request-Id`; every response/error echoes `requestId` |
| Idempotency | Mutating commands accept `Idempotency-Key` |
| Auth | Bearer access token; refresh token rotation policy documented in OpenAPI |
| Errors | Typed envelope (see below) — never opaque HTML |

### Error envelope (every failure)

```json
{
  "code": "OFFER_EXPIRED",
  "message": "Human-readable explanation",
  "requestId": "uuid-or-trace-id",
  "retryable": false,
  "details": {}
}
```

### Baseline error codes

- `UNAUTHORIZED`
- `FORBIDDEN`
- `VALIDATION_ERROR`
- `RESOURCE_NOT_FOUND`
- `OFFER_EXPIRED`
- `OFFER_ALREADY_ACCEPTED`
- `ACTIVE_ASSIGNMENT_CONFLICT`
- `INVALID_DELIVERY_TRANSITION`
- `IDEMPOTENCY_CONFLICT`
- `CUSTOMER_CONTACT_NOT_AVAILABLE`
- `RATE_LIMITED`
- `INTERNAL_ERROR`

### Mutating commands that require `Idempotency-Key` + `X-Request-Id`

- Accept Offer
- Reject Offer
- Confirm Pickup
- Automatic Arrival
- Confirm Delivery
- Cancel Delivery
- Report Issue
- Update Availability

---

## Domain coverage required by Driver

### 1. Authentication and OTP

- Request OTP for driver phone / channel
- Verify OTP and issue access + refresh tokens
- Map driver identity (`driverId`) into session claims
- Typed failures for invalid/expired OTP and rate limits

### 2. Token refresh and logout

- Refresh access token with rotation rules
- Logout / revoke refresh token
- Unauthorized when session is invalid

### 3. Driver profile

- Read authenticated driver profile
- Update allowed profile fields
- No client-supplied tenant elevation

### 4. Driver compliance status

- Expose compliance / eligibility flags Backend owns
- Driver UI may display, never invent compliance

### 5. Driver availability

- Get authoritative availability
- Update availability when online and eligible
- Backend owns `busy` (ADR-018); client cannot toggle busy
- Offline accept remains forbidden (ADR-024)

### 6. Offers listing and details

- Fetch current offer(s) for authenticated driver
- Offer detail includes pickup/dropoff labels, distance/ETA estimates, expiry, revision
- Coordinates for geofence may be provided when Backend authorizes them
- One active offer policy remains Backend-enforced (ADR-023)

### 7. Offer acceptance and rejection

- Accept creates authoritative assignment + busy binding (ADR-025)
- Reject clears offer without assignment
- Fail closed on expiry / already accepted / active assignment conflict

### 8. Active delivery

- Read active assignment for restart restoration
- Local Drift copy is continuity only (ADR-028)

### 9. Pickup confirmation

- Manual confirm pickup only
- Transition into en-route / customer-contact-revealed for current stop

### 10. Automatic arrival

- Client may submit location-based arrival intent after geofence policy
- Backend validates transition; no manual arrival endpoint for drivers
- Invalid transition if delivery confirmation is attempted before arrival

### 11. Delivery confirmation

- Manual confirm delivery after automatic arrival
- Remains locked until `arrivedAutomaticallyByLocation` (or Backend equivalent)

### 12. Cancellation

- Driver/system cancel paths with typed reasons
- Clears or advances assignment per Backend policy

### 13. Issue reporting

- Report issue against current assignment / stop
- Does not invent alternative arrival controls

### 14. Batch assignments

- Multi-order batch accept/reject
- Stop sequence, current stop, and journey stage alignment with Driver UI
- Same pickup / automatic arrival / manual delivery rules per stop

### 15. Current customer contact

- Contact payload available only when Backend disclosure allows it
- Current customer only after pickup confirmation
- Next customer always hidden
- Closed after deliver/cancel
- Other drivers never receive contact

---

## Mandatory journey alignment

```text
offered
→ accepted
→ pickupAwaitingManualConfirmation
→ pickupConfirmedManually
→ enRouteToCustomer
→ arrivedAutomaticallyByLocation
→ deliveryAwaitingManualConfirmation
→ deliveredConfirmedManually
```

Rules:

- Pickup confirmation is manual.
- Arrival is automatic by location.
- No manual arrival button.
- Delivery confirmation is manual.
- Delivery remains locked until automatic arrival.

---

## Customer data protection (Backend-owned)

| Condition | Required Backend behavior |
|-----------|---------------------------|
| Before pickup confirmation | Omit / redact customer contact |
| After pickup confirmation | Return current-customer contact for assigned driver only |
| Next customer | Never include contact until current |
| After delivery or cancel | Close contact |
| Different driver | `FORBIDDEN` or empty authorized view |

Flutter must treat disclosure as Backend truth, not a local guess.

---

## Non-goals of this draft

- Final OpenAPI paths/schemas (owned by `saeq-contracts`)
- NestJS implementation
- WebSocket / SSE / Push (STEP 6)
- Flutter Remote adapter code (STEP 5C)

---

## Handoff checklist for contracts repo

- [ ] Convert this draft into OpenAPI 3.1 paths and components
- [ ] Add JSON Schemas + examples for success and each typed error
- [ ] Document `Idempotency-Key` and `X-Request-Id` globally
- [ ] Add validation + breaking-change checks
- [ ] Pin first contracts release for `saeq-backend`
