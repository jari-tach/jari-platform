# Driver Backend Endpoint Matrix

> **Status:** STEP 5A Documentation Handoff — draft matrix
> **Date:** 2026-07-31
> **Canonical paths:** owned later by `jari-tach/saeq-contracts`
> **Related:** [driver_api_contract_handoff.md](./driver_api_contract_handoff.md)

This matrix lists Driver-needed capabilities. Path names below are **handoff
proposals**, not the final OpenAPI.

Legend:

- **I** = requires `Idempotency-Key`
- **R** = requires `X-Request-Id`
- **Auth** = Bearer access token required

---

## Endpoint matrix

| Capability | Proposed method + path | Auth | I | R | Primary success | Key errors |
|------------|------------------------|------|---|---|-----------------|------------|
| Request OTP | `POST /v1/driver/auth/otp/request` | No | No | Yes | OTP challenged | `VALIDATION_ERROR`, `RATE_LIMITED` |
| Verify OTP | `POST /v1/driver/auth/otp/verify` | No | Yes | Yes | Tokens + driver session | `UNAUTHORIZED`, `VALIDATION_ERROR`, `RATE_LIMITED` |
| Refresh token | `POST /v1/driver/auth/token/refresh` | Refresh | Yes | Yes | New tokens | `UNAUTHORIZED`, `IDEMPOTENCY_CONFLICT` |
| Logout | `POST /v1/driver/auth/logout` | Yes | Yes | Yes | Revoked | `UNAUTHORIZED` |
| Get profile | `GET /v1/driver/profile` | Yes | No | Yes | Profile | `UNAUTHORIZED`, `FORBIDDEN` |
| Update profile | `PATCH /v1/driver/profile` | Yes | Yes | Yes | Updated profile | `VALIDATION_ERROR`, `FORBIDDEN` |
| Compliance status | `GET /v1/driver/compliance` | Yes | No | Yes | Compliance snapshot | `UNAUTHORIZED`, `FORBIDDEN` |
| Get availability | `GET /v1/driver/availability` | Yes | No | Yes | Authoritative status | `UNAUTHORIZED` |
| Update availability | `PUT /v1/driver/availability` | Yes | Yes | Yes | Authoritative status | `FORBIDDEN`, `ACTIVE_ASSIGNMENT_CONFLICT`, `VALIDATION_ERROR` |
| List offers | `GET /v1/driver/offers` | Yes | No | Yes | Offer list / empty | `UNAUTHORIZED` |
| Offer detail | `GET /v1/driver/offers/{offerId}` | Yes | No | Yes | Offer + revision | `RESOURCE_NOT_FOUND`, `FORBIDDEN` |
| Accept offer | `POST /v1/driver/offers/{offerId}/accept` | Yes | Yes | Yes | Assignment + busy | `OFFER_EXPIRED`, `OFFER_ALREADY_ACCEPTED`, `ACTIVE_ASSIGNMENT_CONFLICT`, `IDEMPOTENCY_CONFLICT` |
| Reject offer | `POST /v1/driver/offers/{offerId}/reject` | Yes | Yes | Yes | Rejected | `OFFER_EXPIRED`, `RESOURCE_NOT_FOUND`, `IDEMPOTENCY_CONFLICT` |
| Active delivery | `GET /v1/driver/assignments/active` | Yes | No | Yes | Assignment or empty | `UNAUTHORIZED` |
| Confirm pickup | `POST /v1/driver/assignments/{id}/confirm-pickup` | Yes | Yes | Yes | Stage advanced | `INVALID_DELIVERY_TRANSITION`, `IDEMPOTENCY_CONFLICT` |
| Automatic arrival | `POST /v1/driver/assignments/{id}/arrive` | Yes | Yes | Yes | Arrived stage | `INVALID_DELIVERY_TRANSITION`, `VALIDATION_ERROR`, `IDEMPOTENCY_CONFLICT` |
| Confirm delivery | `POST /v1/driver/assignments/{id}/confirm-delivery` | Yes | Yes | Yes | Delivered | `INVALID_DELIVERY_TRANSITION` (locked before arrival), `IDEMPOTENCY_CONFLICT` |
| Cancel delivery | `POST /v1/driver/assignments/{id}/cancel` | Yes | Yes | Yes | Cancelled / continued | `INVALID_DELIVERY_TRANSITION`, `FORBIDDEN` |
| Report issue | `POST /v1/driver/assignments/{id}/issues` | Yes | Yes | Yes | Issue recorded | `VALIDATION_ERROR`, `RESOURCE_NOT_FOUND` |
| Current customer contact | `GET /v1/driver/assignments/{id}/customer-contact` | Yes | No | Yes | Contact or redacted | `CUSTOMER_CONTACT_NOT_AVAILABLE`, `FORBIDDEN` |
| Batch offer detail | `GET /v1/driver/batches/{batchId}` | Yes | No | Yes | Batch fixture/auth view | `RESOURCE_NOT_FOUND`, `FORBIDDEN` |
| Accept batch | `POST /v1/driver/batches/{batchId}/accept` | Yes | Yes | Yes | Batch assignment | Same family as accept offer |
| Reject batch | `POST /v1/driver/batches/{batchId}/reject` | Yes | Yes | Yes | Rejected | Same family as reject offer |

Pagination applies to list endpoints (`offers`, future history/earnings once Backend owns them). Identity fields are UUID. Timestamps are UTC. Offer/assignment responses include aggregate version / revision.

---

## Journey → endpoint ownership

| Journey stage | Client trigger | Backend command |
|---------------|----------------|-----------------|
| `offered` | Fetch / watch offers | List/detail offers |
| `accepted` | Accept | Accept offer / batch |
| `pickupAwaitingManualConfirmation` | UI after accept/verify | Assignment state |
| `pickupConfirmedManually` | Driver confirms pickup | Confirm pickup |
| `enRouteToCustomer` | After pickup | Assignment state |
| `arrivedAutomaticallyByLocation` | Geofence intent | Automatic arrival |
| `deliveryAwaitingManualConfirmation` | After arrival | Assignment state |
| `deliveredConfirmedManually` | Driver confirms delivery | Confirm delivery |

There is **no** Driver-facing “I arrived” button endpoint.

---

## Notes for OpenAPI authors

1. Replace proposed paths with the official `/v1/...` design in `saeq-contracts`.
2. Keep error codes stable; add new codes via non-breaking extension when possible.
3. Document customer-contact redaction rules on the contact schema itself.
4. Document busy as system-owned and not client-settable.
5. Do not add WebSocket/SSE operations in STEP 5 contracts.
