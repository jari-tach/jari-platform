# SAEQ — Release Management

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md), [20_DEVELOPMENT_ROADMAP.md](./20_DEVELOPMENT_ROADMAP.md)

---

## 1. Purpose

This document defines the release management strategy for the SAEQ platform, including versioning, branching, release cycles, deployment procedures, and rollback plans.

> ⚠️ **Scope note (ADR-013 — Separate Applications Strategy):** The SAEQ platform ships as four independent applications (SAEQ Driver, SAEQ Customer, SAEQ Merchant, SAEQ Admin), each with its own repository, package name, and store listing. The versioning, branching, release-cycle, and rollback rules below apply **independently, per application repository** — version numbers, branches, and release schedules are not synchronized across applications. A hotfix released for one application never requires releasing another. See [ADR_SEPARATE_APPLICATIONS_STRATEGY.md](./adr/ADR_SEPARATE_APPLICATIONS_STRATEGY.md) for the full decision record. During PROJECT STABILIZATION, this document governs the `saeq_driver` (SAEQ Driver) repository only.

---

## 2. Versioning Strategy

### 2.1 Semantic Versioning

We follow **Semantic Versioning 2.0.0**: `MAJOR.MINOR.PATCH`

| Component | MAJOR | MINOR | PATCH |
|-----------|-------|-------|-------|
| **Mobile App** | Breaking UI/UX changes | New features | Bug fixes |
| **API** | Breaking API changes | New endpoints | Bug fixes |
| **Database** | Schema changes (breaking) | Schema changes (additive) | Index/optimization |

**Examples:**
- `1.0.0` — Initial release
- `1.1.0` — New feature (e.g., chat)
- `1.1.1` — Bug fix
- `2.0.0` — Breaking change (e.g., API v2)

### 2.2 Build Numbers

| Platform | Format | Example |
|----------|--------|---------|
| Android | versionCode (integer) | 10 |
| iOS | buildNumber (string) | 1.0.0.10 |
| API | Docker image tag | v1.0.0-build.10 |

---

## 3. Branching Strategy

### 3.1 Branch Naming

| Branch | Pattern | Purpose |
|--------|---------|---------|
| `main` | `main` | Production-ready code |
| `develop` | `develop` | Integration branch for features |
| `feature/*` | `feature/feature-name` | New features |
| `bugfix/*` | `bugfix/bug-description` | Bug fixes |
| `release/*` | `release/vX.Y.Z` | Release preparation |
| `hotfix/*` | `hotfix/issue-description` | Urgent production fixes |

### 3.2 Git Flow

```
main ──────●────────────●────────────●────────────●
            \          / \          / \          /
develop      ●──●──●──●   ●──●──●──●   ●──●──●──●
                 \  /         \  /
feature/*         ●●           ●●
```

### 3.3 Branch Lifecycle

| Branch | Created From | Merged Into | Deleted After |
|--------|-------------|-------------|---------------|
| `feature/*` | `develop` | `develop` | ✅ Yes |
| `bugfix/*` | `develop` | `develop` | ✅ Yes |
| `release/*` | `develop` | `main` + `develop` | ✅ Yes |
| `hotfix/*` | `main` | `main` + `develop` | ✅ Yes |

---

## 4. Release Cycles

### 4.1 Mobile App Releases

| Type | Frequency | Process | Timeline |
|------|-----------|---------|----------|
| Major | Quarterly | Full regression, beta testing | 4 weeks |
| Minor | Monthly | Feature testing, staged rollout | 2 weeks |
| Patch | As needed | Targeted fix, expedited review | 2-3 days |
| Hotfix | Emergency | Critical fix, immediate review | Hours |

### 4.2 API Releases

| Type | Frequency | Process | Timeline |
|------|-----------|---------|----------|
| Major | Quarterly | Full regression, canary deployment | 2 weeks |
| Minor | Bi-weekly | Automated tests, rolling update | 3 days |
| Patch | As needed | Targeted fix, rolling update | 1 day |
| Hotfix | Emergency | Immediate fix, direct deploy | Hours |

---

## 5. Release Process

### 5.1 Mobile App Release Checklist

```
□ All feature branches merged to develop
□ Code freeze on develop branch
□ Create release branch: release/vX.Y.Z
□ Run full test suite (unit + widget + integration)
□ Run static analysis (flutter analyze)
□ Update version in pubspec.yaml
□ Update CHANGELOG.md
□ Create release candidate build
□ Submit to QA for testing
□ QA sign-off
□ Create App Store / Google Play listing
□ Submit for review
□ Monitor review status
□ Approve release (Google Play) / Wait for review (App Store)
□ Tag release in Git: vX.Y.Z
□ Merge release branch to main
□ Merge release branch back to develop
□ Post-release monitoring (24 hours)
```

### 5.2 API Release Checklist

```
□ All feature branches merged to develop
□ Run full test suite
□ Run static analysis
□ Update API version in config
□ Update CHANGELOG.md
□ Build Docker image: docker build -t saeq-api:vX.Y.Z
□ Push to registry: docker push saeq-api:vX.Y.Z
□ Deploy to staging
□ Run smoke tests on staging
□ Deploy to production (rolling update)
□ Monitor for 30 minutes
□ Tag release in Git: api-vX.Y.Z
□ Post-release monitoring (24 hours)
```

---

## 6. Deployment Strategies

### 6.1 Mobile App

| Platform | Strategy | Rollout % | Monitoring Period |
|----------|----------|-----------|-------------------|
| Android (Google Play) | Staged rollout | 1% → 10% → 50% → 100% | 24 hours per stage |
| iOS (App Store) | Phased release | 1% → 100% over 7 days | 7 days total |

### 6.2 API

| Environment | Strategy | Description |
|-------------|----------|-------------|
| Staging | Full deploy | Deploy to staging cluster |
| Production | Rolling update | Update 1 pod at a time |
| Production (major) | Canary | 10% traffic → 50% → 100% |

---

## 7. Rollback Plan

### 7.1 Mobile App Rollback

| Platform | Rollback Method | Time |
|----------|----------------|------|
| Android | Revert to previous version in Google Play Console | 2-4 hours |
| iOS | Reject current build, re-submit previous version | 24-48 hours |
| **Mitigation** | Use feature flags to disable problematic features | Immediate |

### 7.2 API Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/saeq-api

# Rollback to specific version
kubectl rollout undo deployment/saeq-api --to-revision=3

# Verify rollback
kubectl rollout status deployment/saeq-api
```

---

## 8. Release Communication

| Audience | Channel | Timing | Content |
|----------|---------|--------|---------|
| Internal team | Slack | 24 hours before | Release notes, testing results |
| Stakeholders | Email | 2 hours before | Summary of changes, expected impact |
| Drivers | In-app notification | On release | New features, bug fixes |
| Customers | In-app notification | On release | New features, improvements |
| Public | Social media | After release | Major features, promotions |

---

*This document defines the release management strategy. All releases must follow this process.*