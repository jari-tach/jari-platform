# W5 / P0-04 — GitHub Environment setup (EXTERNAL — not proven in-repo)

Status: **UNPROVEN**. Do **not** record `CI PROTECTION — PASS` until an owner confirms
the checklist below in the GitHub UI for each repository.

## Environments required

| Environment | Purpose |
|---|---|
| `w5-signing-production` | Production Android / iOS / Windows signing |
| `w5-signing-test` | TEST SIGNING ONLY ephemeral proofs |

## Required reviewers / policy (must configure outside Git)

- [ ] Required reviewers enabled (minimum 1 non-author)
- [ ] Prevent self-review enabled
- [ ] Deployment branches/tags allowlist:
  - `release/**`
  - tags matching `v*`
- [ ] Secrets and variables scoped to the Environment only (not repository-wide when avoidable)
- [ ] Fork PRs cannot reach Environment secrets (GitHub default; confirm)

## Production Environment variables / secrets (examples — values never in Git)

### Android
- Secret: `ANDROID_KEYSTORE_BASE64`
- Secret: `ANDROID_KEY_PROPERTIES`
- Variable/Secret: `ANDROID_UPLOAD_CERT_SHA256` (64 hex; colon form OK)

### iOS
- Secret: `APPLE_CERT_P12_BASE64`
- Secret: `APPLE_CERT_PASSWORD`
- Secret: `APPLE_PROVISIONING_PROFILE_BASE64`
- Variable: `APPLE_TEAM_ID`
- Variable: `IOS_BUNDLE_ID`
- Variable: `IOS_PROVISIONING_PROFILE_NAME`
- Variable/Secret: `APPLE_DISTRIBUTION_CERT_SHA256`

### Admin Windows (OIDC Trusted Signing / Artifact Signing)
- Secret/Variable: `AZURE_CLIENT_ID`
- Secret/Variable: `AZURE_TENANT_ID`
- Secret/Variable: `AZURE_SUBSCRIPTION_ID`
- Variable: `WINDOWS_TRUSTED_SIGNING_ENDPOINT`
- Variable: `WINDOWS_TRUSTED_SIGNING_ACCOUNT`
- Variable: `WINDOWS_TRUSTED_SIGNING_CERT_PROFILE`
- Federated credential on the Azure app registration bound to this Environment

## Trust boundary in workflow code

Signing jobs call `tool/w5_enforce_signing_ref.sh` and refuse any ref other than
`refs/heads/release/*` or `refs/tags/v*`, including arbitrary `workflow_dispatch` refs.

## Confirmation log (fill when proven)

| Repo | Env | Reviewers | Allowlist | Confirmed by | Date |
|---|---|---|---|---|---|
| Customer | w5-signing-production | UNPROVEN | UNPROVEN | — | — |
| Merchant | w5-signing-production | UNPROVEN | UNPROVEN | — | — |
| Driver | w5-signing-production | UNPROVEN | UNPROVEN | — | — |
| Admin | w5-signing-production | UNPROVEN | UNPROVEN | — | — |
