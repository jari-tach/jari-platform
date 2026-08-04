# Operational Handoff Checklist — SAEQ Driver

> Do **not** put secrets in Git or in this file. Status as of Gate 10 / HEAD `3f86900`.

| Item | Status | Notes |
| --- | --- | --- |
| Android production upload keystore | **OWNER ACTION REQUIRED** | Deliver via vault; wire `android/key.properties` locally/CI secrets |
| Android keystore passwords / alias | **OWNER ACTION REQUIRED** | Out-of-band only |
| iOS distribution certificate | **OWNER ACTION REQUIRED** | Apple Developer |
| iOS Provisioning Profile (App Store) | **OWNER ACTION REQUIRED** | Bundle ID `com.saeq.driver` |
| Apple / Play console accounts | **OWNER ACTION REQUIRED** | Owner-controlled |
| Production API base URL | **AVAILABLE** (process) | Via `--dart-define=SAEQ_API_BASE_URL` |
| Production `SAEQ_TLS_PINS` | **OWNER ACTION REQUIRED** | See Gate 9 rotation guide |
| Pin rotation ownership | **OWNER ACTION REQUIRED** | Name an owner before first store ship |
| Crash reporting enablement | **OWNER ACTION REQUIRED** | Still disabled in `AppConfig` |
| Monitoring / alerting ownership | **OWNER ACTION REQUIRED** | Backend + client ops |
| Release version / build | **AVAILABLE** | `1.0.0+1` (`versionName`/`versionCode`) |
| Secret retention policy | **OWNER ACTION REQUIRED** | Document vault + rotation cadence |
| Rollback decision authority | **OWNER ACTION REQUIRED** | Name release commander |
| Final publish approval | **OWNER ACTION REQUIRED** | Project owner only |

Reference: `docs/release_hardening/RELEASE_SECRETS_AND_SIGNING_HANDOFF.md`
