# SAEQ — Disaster Recovery Plan

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [33_OPERATION_RUNBOOK.md](./33_OPERATION_RUNBOOK.md), [32_RISK_REGISTER.md](./32_RISK_REGISTER.md)

---

## 1. Purpose

This document defines the disaster recovery (DR) strategy for the SAEQ platform, including recovery objectives, backup strategies, failover procedures, and recovery scenarios.

---

## 2. Recovery Objectives

| Metric | Target | Definition |
|--------|--------|------------|
| **RTO** (Recovery Time Objective) | ≤ 4 hours | Maximum time to restore service after disaster |
| **RPO** (Recovery Point Objective) | ≤ 15 minutes | Maximum data loss acceptable (in time) |
| **RTO (Critical)** | ≤ 1 hour | Recovery time for payment/order services |
| **RPO (Critical)** | ≤ 1 minute | Maximum data loss for payment/order data |

---

## 3. Disaster Scenarios

| ID | Scenario | Impact | RTO | RPO | Priority |
|----|----------|--------|-----|-----|----------|
| DR-001 | Single server failure | Partial outage | 15 min | 0 | Critical |
| DR-002 | Database corruption | Full outage | 2 hours | 15 min | Critical |
| DR-003 | AWS region failure | Full outage | 4 hours | 15 min | Critical |
| DR-004 | Data center disaster | Full outage | 4 hours | 15 min | Critical |
| DR-005 | Ransomware attack | Full outage | 4 hours | 15 min | Critical |
| DR-006 | Accidental data deletion | Partial data loss | 2 hours | 15 min | High |
| DR-007 | Network outage | Connectivity loss | 1 hour | 0 | High |
| DR-008 | Third-party service failure | Feature outage | 2 hours | 0 | Medium |

---

## 4. Backup Strategy

### 4.1 Database Backups

| Type | Frequency | Retention | Storage | Encryption |
|------|-----------|-----------|---------|------------|
| Full backup | Every 6 hours | 30 days | S3 (cross-region) | AES-256 |
| WAL archiving | Every 15 minutes | 7 days | S3 (same region) | AES-256 |
| Automated snapshot | Daily | 14 days | AWS RDS | AWS managed |
| Logical backup | Weekly | 90 days | S3 (cross-region) | AES-256 |

### 4.2 File Storage Backups

| Type | Frequency | Retention | Storage | Encryption |
|------|-----------|-----------|---------|------------|
| S3 cross-region replication | Real-time | Same as source | S3 (DR region) | AES-256 |
| S3 Glacier backup | Weekly | 1 year | Glacier | AES-256 |

### 4.3 Configuration Backups

| Type | Frequency | Retention | Storage |
|------|-----------|-----------|---------|
| Git repository | On commit | Indefinite | GitHub |
| Kubernetes manifests | Daily | 30 days | S3 |
| Environment variables | On change | 90 days | AWS Secrets Manager |
| SSL certificates | On issue | Until expiry | AWS Certificate Manager |

---

## 5. Failover Strategy

### 5.1 Multi-Region Architecture

```
Primary Region (me-south-1)          DR Region (eu-central-1)
     │                                      │
     ├── API Servers (active)               ├── API Servers (standby)
     ├── Database (primary) ──replication──>├── Database (read replica)
     ├── Cache (primary)                    ├── Cache (standby)
     ├── Queue (primary)                    ├── Queue (standby)
     └── S3 (primary) ──replication──────> └── S3 (DR)
```

### 5.2 Failover Triggers

| Condition | Action | Timeframe |
|-----------|--------|-----------|
| API health check fails > 5 minutes | Failover to DR region | 15 minutes |
| Database unreachable > 2 minutes | Promote read replica to primary | 10 minutes |
| AWS region health dashboard shows degradation | Manual failover decision | 30 minutes |
| RTO approaching threshold | Automatic failover | Immediate |

### 5.3 Failover Procedure

```bash
# 1. Verify DR region readiness
kubectl get pods --context=dr-cluster

# 2. Promote database read replica to primary
aws rds promote-read-replica --db-instance-identifier saeq-dr

# 3. Update DNS to point to DR region
aws route53 change-resource-record-sets --hosted-zone-id ZONEID --change-batch file://dns-failover.json

# 4. Scale up DR API servers
kubectl scale deployment saeq-api --replicas=5 --context=dr-cluster

# 5. Verify health
curl https://api.saeq.example/health

# 6. Notify stakeholders
# 7. Monitor for 1 hour
```

---

## 6. Recovery Procedures

### 6.1 Database Corruption Recovery

```bash
# 1. Stop application
kubectl scale deployment saeq-api --replicas=0

# 2. Identify last good backup
aws s3 ls s3://saeq-backups/database/

# 3. Restore from backup
pg_restore -h saeq-db.example.com -U saeq_admin -d saeq -v saeq_backup_latest.dump

# 4. Apply WAL logs for point-in-time recovery
pg_archivecleanup /var/lib/postgresql/wal_archive latest_wal.log

# 5. Verify data integrity
psql -h saeq-db.example.com -U saeq_admin -d saeq -c "SELECT count(*) FROM orders;"

# 6. Start application
kubectl scale deployment saeq-api --replicas=3

# 7. Verify health
```

### 6.2 Full Region Failover

```bash
# 1. Activate DR plan
# 2. Promote DR database to primary
aws rds promote-read-replica --db-instance-identifier saeq-dr

# 3. Update Route53 DNS
aws route53 change-resource-record-sets \
  --hosted-zone-id ZONEID \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.saeq.example",
        "Type": "A",
        "SetIdentifier": "dr",
        "Failover": "PRIMARY",
        "AliasTarget": {
          "HostedZoneId": "DR_ZONE_ID",
          "DNSName": "dr-load-balancer.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }]
  }'

# 4. Scale DR services
kubectl scale deployment saeq-api --replicas=5 --context=dr-cluster
kubectl scale deployment saeq-worker --replicas=3 --context=dr-cluster

# 5. Verify all services
curl https://api.saeq.example/health
curl https://api.saeq.example/orders?limit=1

# 6. Monitor for 4 hours
# 7. Plan failback to primary region
```

### 6.3 Accidental Data Deletion Recovery

```bash
# 1. Identify deleted data and timestamp
# 2. Restore specific table from backup
pg_restore -h saeq-db.example.com -U saeq_admin -d saeq \
  --table=orders \
  --data-only \
  --disable-triggers \
  saeq_backup_before_deletion.dump

# 3. Verify restored data
SELECT count(*) FROM orders WHERE created_at > '2026-07-24';

# 4. Re-enable triggers
ALTER TABLE orders ENABLE TRIGGER ALL;
```

---

## 7. DR Testing

| Test Type | Frequency | Scope | Success Criteria |
|-----------|-----------|-------|-----------------|
| Backup restoration | Monthly | Restore database from backup | Data integrity verified |
| Failover drill | Quarterly | Full failover to DR region | RTO ≤ 4 hours, RPO ≤ 15 min |
| Tabletop exercise | Quarterly | Walk through DR scenarios | All team members understand roles |
| Full DR test | Annually | Complete disaster simulation | All recovery objectives met |

---

## 8. DR Team

| Role | Name | Responsibility | Backup |
|------|------|---------------|--------|
| DR Lead | TBD | Overall coordination | DevOps Lead |
| Database Admin | TBD | Database recovery | Backend Lead |
| DevOps Engineer | TBD | Infrastructure recovery | Backend Engineer |
| Security Engineer | TBD | Security assessment | Lead Engineer |
| Communications Lead | TBD | Stakeholder updates | Product Manager |

---

## 9. Post-Recovery

After any disaster recovery event, the following must be completed within 48 hours:

1. **Root Cause Analysis** — Document what caused the disaster
2. **Timeline** — Record all events with timestamps
3. **Action Items** — Identify improvements to prevent recurrence
4. **DR Plan Update** — Update this document with lessons learned
5. **Team Review** — Share findings with the entire team

---

*This disaster recovery plan is tested quarterly. All changes require DR lead approval.*