# Release secrets & signing handoff (SAEQ Driver)

> **App:** SAEQ Driver / فزعة only  
> **Application ID / Bundle ID:** `com.saeq.driver`  
> **Rule:** Never commit keystores, certificates, provisioning profiles, or passwords.

## Android release signing

1. Create an upload keystore **locally** (example):

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Copy `android/key.properties.example` → `android/key.properties` and fill values:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=app/upload-keystore.jks
```

3. `android/key.properties` and `*.jks` are gitignored.

4. Release builds use the `release` signingConfig **only when** `key.properties` exists.  
   There is **no** fallback to the debug keystore.

5. CI currently builds **debug** APK (`flutter build apk --debug`) and does not need production secrets.

6. Owner checklist before store upload:
   - Provide production upload keystore out-of-band (password manager / secure vault).
   - Confirm Play App Signing enrollment if applicable.
   - Build: `flutter build appbundle --release` with `key.properties` present.

## iOS release signing

- Bundle ID: `com.saeq.driver`
- Configure signing in Xcode / CI with Apple Developer certificates & profiles.
- **Do not** commit `.p12`, `.mobileprovision`, or AuthKeys to this repository.
- Prefer App Store Connect API keys stored in CI secrets only.

## Dart defines for production API TLS

```text
--dart-define=SAEQ_BACKEND_MODE=remote
--dart-define=SAEQ_API_BASE_URL=https://api.saeq.com
--dart-define=SAEQ_ENABLE_CERT_PINNING=true
--dart-define=SAEQ_TLS_PINS=sha256/<pin1>,sha256/<pin2>
```

See `CERTIFICATE_PINNING_ROTATION_GUIDE.md`.

## Remaining owner actions (conditional close)

| Item | Owner action |
| --- | --- |
| Production Android upload keystore | Deliver securely; keep out of Git |
| Production TLS pins | Extract from live cert chain; supply via CI secrets / defines |
| iOS distribution cert + profile | Configure in Apple Developer + CI |
| Store listing / Play / ASC metadata | Gate 10 |
