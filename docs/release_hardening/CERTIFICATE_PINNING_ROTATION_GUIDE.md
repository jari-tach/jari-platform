# Certificate Pinning — Rotation Guide (SAEQ Driver)

## Scope

Pinning is enforced on the live HTTP client (`SaeqApiClient`) for **HTTPS** API hosts when:

- `--dart-define=SAEQ_ENABLE_CERT_PINNING=true`, or
- App environment is **production** and pins are present.

Pinning is **never** applied to loopback / cleartext Device QA backends (`http://127.0.0.1`, `localhost`, `10.0.2.2`).

## Pin format

SPKI-style fingerprint strings:

```text
sha256/<base64-sha256-of-certificate-DER>
```

Multiple pins (leaf + backup / intermediate rotation) comma-separated:

```text
SAEQ_TLS_PINS=sha256/AAAA...,sha256/BBBB...
```

## Extracting a pin (example)

```bash
openssl s_client -servername api.saeq.com -connect api.saeq.com:443 </dev/null 2>/dev/null \
  | openssl x509 -outform DER \
  | openssl dgst -sha256 -binary \
  | openssl base64
```

Prefix the base64 digest with `sha256/`.

Always keep **at least two** pins during rotation (current + next).

## Rotation procedure

1. Obtain the **new** certificate DER pin before cut-over.
2. Deploy app/config with `SAEQ_TLS_PINS=old,new`.
3. Roll certificates on the API.
4. After old cert expiry, ship a follow-up build with `SAEQ_TLS_PINS=new[,next]`.

## Failure behaviour

- Validation failure rejects the TLS handshake (request fails).
- Logs may mention host failure in debug only; **pin values are not logged**.
- Do not surface raw TLS errors to drivers; use existing user-safe network failure copy.

## Production release guard

Production **release** builds require non-empty pins when `CertificatePinConfig.resolve` runs with `isProductionEnvironment: true` (otherwise construction throws `StateError`).

## Tests

See `test/core/network/certificate_pinning_test.dart`.
