# SAEQ — Configuration Management

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md), [37_DISASTER_RECOVERY.md](./37_DISASTER_RECOVERY.md)

---

## 1. Purpose

This document defines the configuration management strategy for the SAEQ platform, including environment variables, secrets management, feature flags, and configuration deployment.

---

## 2. Configuration Hierarchy

```
┌─────────────────────────────────────┐
│         Environment Variables       │  ← OS/Container level
├─────────────────────────────────────┤
│         Secrets Manager             │  ← Encrypted secrets
├─────────────────────────────────────┤
│         Feature Flags               │  ← Runtime toggles
├─────────────────────────────────────┤
│         App Config (pubspec)        │  ← Build-time config
├─────────────────────────────────────┤
│         Local Storage               │  ← User preferences
└─────────────────────────────────────┘
```

---

## 3. Environment Configuration

### 3.1 Environments

| Environment | Purpose | Base URL | Log Level | Cache Enabled |
|-------------|---------|----------|-----------|---------------|
| `development` | Local development | `http://localhost:3000` | DEBUG | No |
| `staging` | Pre-production testing | `https://staging-api.saeq.example` | DEBUG | Yes |
| `production` | Live production | `https://api.saeq.example` | INFO | Yes |

### 3.2 Environment Variables

| Variable | Description | Development | Staging | Production |
|----------|-------------|-------------|---------|------------|
| `APP_ENV` | Environment name | `development` | `staging` | `production` |
| `API_BASE_URL` | API server URL | `http://localhost:3000` | `https://staging-api...` | `https://api...` |
| `API_TIMEOUT` | Request timeout (ms) | `30000` | `15000` | `15000` |
| `ENABLE_LOGGING` | Enable console logging | `true` | `true` | `false` |
| `LOG_LEVEL` | Minimum log level | `debug` | `debug` | `info` |
| `ENABLE_CRASHLYTICS` | Enable crash reporting | `false` | `true` | `true` |
| `ENABLE_ANALYTICS` | Enable analytics | `false` | `true` | `true` |
| `CACHE_ENABLED` | Enable local caching | `false` | `true` | `true` |
| `CACHE_TTL_MINUTES` | Cache time-to-live | `0` | `30` | `60` |
| `MAX_RETRIES` | API retry count | `0` | `2` | `3` |
| `OTP_EXPIRY_SECONDS` | OTP code validity | `300` | `300` | `300` |
| `ORDER_TIMEOUT_MINUTES` | Order acceptance timeout | `5` | `3` | `2` |

---

## 4. Secrets Management

### 4.1 Secret Categories

| Category | Examples | Storage | Encryption |
|----------|----------|---------|------------|
| API Keys | Payment gateway, map provider, SMS provider | AWS Secrets Manager | AES-256 |
| Auth Secrets | JWT secret, encryption keys | AWS Secrets Manager | AES-256 |
| Database Credentials | DB username, password | AWS Secrets Manager | AES-256 |
| Third-party Tokens | Firebase, Sentry, analytics | AWS Secrets Manager | AES-256 |
| Mobile App Secrets | App signing keys, API keys | CI/CD secrets | AES-256 |

### 4.2 Secret Access

| Role | Access Level | Method |
|------|-------------|--------|
| CI/CD Pipeline | Read-only (scoped) | IAM role |
| Backend Service | Read-only (runtime) | IAM role + caching |
| Developer (staging) | Read-only (staging only) | AWS CLI + MFA |
| Developer (production) | No access | - |
| DevOps Lead | Full access | AWS Console + MFA |

### 4.3 Secret Rotation

| Secret | Rotation Frequency | Method |
|--------|-------------------|--------|
| JWT signing key | Every 90 days | Automated rotation |
| Database password | Every 90 days | Automated rotation |
| API keys (third-party) | Per provider policy | Manual rotation |
| SSL/TLS certificates | Every 12 months | Automated renewal |

---

## 5. Feature Flags

### 5.1 Flag Categories

| Category | Description | Examples |
|----------|-------------|----------|
| Release flags | Control feature rollout | `new-checkout-flow`, `redesigned-profile` |
| Experiment flags | A/B testing | `recommendation-algorithm-v2` |
| Operational flags | System behavior | `maintenance-mode`, `disable-payments` |
| Permission flags | Access control | `beta-features`, `early-access` |

### 5.2 Flag Definitions

| Flag | Description | Default | Environment | Owner |
|------|-------------|---------|-------------|-------|
| `new-onboarding-flow` | New driver onboarding | `false` | All | Product |
| `chat-feature` | In-app chat | `false` | All | Product |
| `ai-route-optimization` | AI route suggestions | `false` | Staging only | AI Team |
| `maintenance-mode` | Read-only mode | `false` | Production | DevOps |
| `disable-payments` | Disable payment processing | `false` | Production | DevOps |
| `beta-features` | Early access features | `false` | Production | Product |
| `new-earnings-dashboard` | Redesigned earnings | `false` | All | Product |
| `offline-mode` | Offline support | `true` | All | Engineering |

### 5.3 Flag Lifecycle

```
Proposed → Reviewed → Implemented → Released → Default On → Code Removed
   1          2            3             4           5            6
```

| Stage | Description | Duration |
|-------|-------------|----------|
| 1. Proposed | Flag is suggested and documented | 1 day |
| 2. Reviewed | Team reviews and approves | 1 week |
| 3. Implemented | Code is written behind the flag | Per sprint |
| 4. Released | Flag is turned on for some users | 2-4 weeks |
| 5. Default On | Flag is on for all users | 1 month |
| 6. Code Removed | Flag and old code are removed | Next sprint |

---

## 6. Configuration Deployment

### 6.1 Mobile App Config

```yaml
# lib/core/config/app_config.dart
class AppConfig {
  static const String appEnvironment = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const String baseApiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true);
}
```

### 6.2 Build-time Configuration

```bash
# Development build
flutter build apk --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://localhost:3000

# Staging build
flutter build apk --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging-api.saeq.example

# Production build
flutter build apk --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.saeq.example
```

### 6.3 Runtime Configuration

Configuration that can change without a build:

| Config | Storage | Update Method |
|--------|---------|---------------|
| Feature flags | Remote config (Firebase) | Firebase Console |
| App settings | SharedPreferences | User action |
| Notification preferences | SharedPreferences | User action |
| Cached API responses | Drift database | Automatic |

---

## 7. Configuration Audit

| Audit Item | Frequency | Responsible |
|------------|-----------|-------------|
| Review environment variables | Monthly | Lead Engineer |
| Audit secret access | Quarterly | Security Engineer |
| Review feature flags | Bi-weekly | Product Manager |
| Clean up stale flags | Per sprint | Lead Engineer |
| Rotate secrets | Per policy | DevOps |
| Update config documentation | Per change | Lead Engineer |

---

*This document defines the configuration management strategy. All configuration changes must follow this process.*