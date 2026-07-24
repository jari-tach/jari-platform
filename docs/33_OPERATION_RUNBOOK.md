# SAEQ — Operations Runbook

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [19_DEPLOYMENT_GUIDE.md](./19_DEPLOYMENT_GUIDE.md), [37_DISASTER_RECOVERY.md](./37_DISASTER_RECOVERY.md)

---

## 1. Purpose

This runbook provides step-by-step procedures for operating the SAEQ platform, handling incidents, performing backups, and restoring service. It is intended for the operations team and on-call engineers.

---

## 2. System Overview

| Component | Technology | Access Method | Monitoring |
|-----------|-----------|---------------|------------|
| Mobile Apps | Flutter | App Store / Google Play | Crashlytics, Performance |
| API Server | Node.js / Express | SSH, Kubernetes | CloudWatch, Sentry |
| Database | PostgreSQL | pgAdmin, psql | CloudWatch, pgHero |
| Cache | Redis | redis-cli | CloudWatch |
| Queue | RabbitMQ | Management UI | CloudWatch |
| Storage | AWS S3 | AWS Console | CloudWatch |
| CDN | CloudFront | AWS Console | CloudWatch |
| DNS | Route53 | AWS Console | Route53 Health Checks |

---

## 3. Incident Response

### 3.1 Incident Severity Levels

| Level | Description | Response Time | Examples |
|-------|-------------|---------------|----------|
| SEV-1 | Critical service outage | 15 minutes | API down, database unavailable |
| SEV-2 | Major feature degradation | 1 hour | Order creation failing, payment issues |
| SEV-3 | Minor feature issue | 4 hours | UI glitch, non-critical error |
| SEV-4 | Cosmetic / low priority | 24 hours | Typo, styling issue |

### 3.2 Incident Response Flow

```
1. DETECT
   ├── Automated alert (CloudWatch, Sentry, Crashlytics)
   └── User report (support ticket, social media)

2. TRIAGE (within severity response time)
   ├── Confirm incident
   ├── Determine severity
   ├── Notify stakeholders
   └── Assign owner

3. MITIGATE
   ├── Apply temporary fix (rollback, feature flag, scale up)
   ├── Document actions taken
   └── Verify service restored

4. RESOLVE
   ├── Apply permanent fix
   ├── Run tests
   ├── Deploy to production
   └── Monitor for 30 minutes

5. POST-MORTEM (within 48 hours)
   ├── Root cause analysis
   ├── Timeline of events
   ├── Action items
   └── Share with team
```

---

## 4. Common Incidents

### 4.1 API Server Down

**Severity:** SEV-1

**Symptoms:**
- All API requests return 502/503
- Health check endpoint fails
- Mobile apps show "No connection" errors

**Immediate Actions:**
1. SSH into server: `ssh deploy@api.saeq.example`
2. Check server status: `systemctl status saeq-api`
3. Check logs: `journalctl -u saeq-api -n 100 --no-pager`
4. Restart service: `systemctl restart saeq-api`
5. If restart fails, check disk space: `df -h`
6. Check memory: `free -m`
7. Check CPU: `top -bn1`
8. If OOM, increase memory: `kubectl scale deployment saeq-api --replicas=3`

**Escalation:** If not resolved in 15 minutes, escalate to DevOps lead.

### 4.2 Database Connection Issues

**Severity:** SEV-1

**Symptoms:**
- API logs show "connection refused" to database
- Slow queries timing out
- Increased error rate on data operations

**Immediate Actions:**
1. Check database status: `pg_isready -h saeq-db.example.com`
2. Check connection pool: `SELECT count(*) FROM pg_stat_activity;`
3. Check long-running queries: `SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC;`
4. Kill long-running queries: `SELECT pg_terminate_backend(pid);`
5. Check disk space: `SELECT pg_size_pretty(pg_database_size('saeq'));`
6. If disk full, extend volume in AWS console

**Escalation:** If not resolved in 10 minutes, escalate to DBA.

### 4.3 High Error Rate

**Severity:** SEV-2

**Symptoms:**
- Error rate > 1% in monitoring dashboard
- Sentry showing increased errors
- User complaints about specific features

**Immediate Actions:**
1. Check Sentry for error patterns
2. Identify affected endpoint/feature
3. Check recent deployments: `git log --oneline -10`
4. If related to recent deploy, rollback: `kubectl rollout undo deployment/saeq-api`
5. If not deploy-related, check dependencies

**Escalation:** If not resolved in 1 hour, escalate to Lead Engineer.

### 4.4 Payment Processing Failure

**Severity:** SEV-2

**Symptoms:**
- Payment gateway returning errors
- Orders stuck in "pending payment" status
- Customer complaints about failed payments

**Immediate Actions:**
1. Check payment gateway status page
2. Check payment service logs
3. Verify API keys are valid
4. Check for rate limiting from gateway
5. If gateway issue, switch to fallback provider
6. Manually process stuck payments if needed

**Escalation:** If not resolved in 30 minutes, escalate to Finance team.

### 4.5 Push Notification Failure

**Severity:** SEV-3

**Symptoms:**
- Users not receiving notifications
- FCM/APNs delivery rate dropping
- Notification queue growing

**Immediate Actions:**
1. Check FCM/APNs credentials expiry
2. Check notification service logs
3. Verify Firebase project status
4. Restart notification service
5. Check queue depth in RabbitMQ

**Escalation:** If not resolved in 2 hours, escalate to Backend Engineer.

---

## 5. Backup Procedures

### 5.1 Database Backup

| Schedule | Type | Retention | Location |
|----------|------|-----------|----------|
| Every 6 hours | Full backup | 30 days | AWS S3 (encrypted) |
| Every 15 minutes | WAL archiving | 7 days | AWS S3 |
| Daily | Automated snapshot | 14 days | AWS RDS |

**Manual Backup Command:**
```bash
pg_dump -h saeq-db.example.com -U saeq_admin -F c -b -v -f saeq_backup_$(date +%Y%m%d_%H%M%S).dump saeq
```

### 5.2 File Storage Backup

| Schedule | Type | Retention | Location |
|----------|------|-----------|----------|
| Daily | S3 bucket sync | 7 days | Cross-region S3 bucket |
| Weekly | Full S3 backup | 30 days | Glacier |

### 5.3 Configuration Backup

| Schedule | Type | Retention | Location |
|----------|------|-----------|----------|
| On change | Git repository | Indefinite | GitHub |
| Daily | Kubernetes manifests | 30 days | S3 bucket |

---

## 6. Restore Procedures

### 6.1 Database Restore

```bash
# 1. Stop application
kubectl scale deployment saeq-api --replicas=0

# 2. Drop and recreate database
dropdb saeq
createdb saeq

# 3. Restore from backup
pg_restore -h saeq-db.example.com -U saeq_admin -d saeq -v saeq_backup_20260724_120000.dump

# 4. Verify data integrity
psql -h saeq-db.example.com -U saeq_admin -d saeq -c "SELECT count(*) FROM orders;"

# 5. Start application
kubectl scale deployment saeq-api --replicas=3

# 6. Verify health
curl https://api.saeq.example/health
```

### 6.2 Full System Restore

```bash
# 1. Restore database (see above)
# 2. Restore S3 files from cross-region backup
aws s3 sync s3://saeq-backup-dr/ s3://saeq-production/

# 3. Redeploy application
kubectl rollout restart deployment/saeq-api
kubectl rollout restart deployment/saeq-worker

# 4. Verify all services
kubectl get pods
curl https://api.saeq.example/health
```

---

## 7. Monitoring & Alerts

### 7.1 Key Metrics to Monitor

| Metric | Warning Threshold | Critical Threshold | Check Interval |
|--------|------------------|-------------------|----------------|
| API response time (p95) | > 500ms | > 2s | 1 minute |
| Error rate | > 0.5% | > 1% | 1 minute |
| CPU utilization | > 70% | > 90% | 1 minute |
| Memory utilization | > 70% | > 90% | 1 minute |
| Disk usage | > 80% | > 90% | 5 minutes |
| Database connections | > 80% of max | > 95% of max | 1 minute |
| Queue depth | > 1000 | > 5000 | 1 minute |
| Crash-free rate | < 99.5% | < 99% | 5 minutes |

### 7.2 Alert Channels

| Severity | Channel | Response Time |
|----------|---------|---------------|
| SEV-1 | PagerDuty + SMS + Slack | 15 minutes |
| SEV-2 | Slack + Email | 1 hour |
| SEV-3 | Slack | 4 hours |
| SEV-4 | Email (daily digest) | 24 hours |

---

## 8. Maintenance Windows

| Type | Frequency | Duration | Window | Impact |
|------|-----------|----------|--------|--------|
| Database maintenance | Monthly | 1 hour | 02:00-04:00 AST | Read-only mode |
| API deployment | Weekly | 15 minutes | 03:00-05:00 AST | Rolling update |
| Mobile app release | Bi-weekly | 30 minutes | Business hours | App store review |
| Security patches | As needed | 1 hour | 02:00-04:00 AST | Rolling update |

---

*This runbook is a living document. Update it as new procedures are developed or existing ones change.*