# SAEQ — Monitoring & Observability

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [33_OPERATION_RUNBOOK.md](./33_OPERATION_RUNBOOK.md), [16_LOGGING_GUIDE.md](./16_LOGGING_GUIDE.md)

---

## 1. Purpose

This document defines the monitoring and observability strategy for the SAEQ platform, including KPIs, logging, metrics, tracing, and alerting.

---

## 2. Key Performance Indicators (KPIs)

### 2.1 Business KPIs

| KPI | Description | Target | Measurement | Frequency |
|-----|-------------|--------|-------------|-----------|
| Daily Active Drivers | Number of unique drivers active per day | > 500 | Analytics | Daily |
| Daily Active Customers | Number of unique customers ordering per day | > 2,000 | Analytics | Daily |
| Orders Per Day | Total orders completed per day | > 5,000 | Database | Daily |
| Average Delivery Time | Time from order to delivery | < 30 min | Database | Daily |
| Driver Acceptance Rate | % of orders accepted by drivers | > 85% | Database | Daily |
| Customer Satisfaction | Average rating from customers | > 4.5 | Database | Daily |
| Driver Retention Rate | % of drivers active after 30 days | > 80% | Analytics | Monthly |
| Customer Retention Rate | % of customers ordering again within 30 days | > 60% | Analytics | Monthly |
| Revenue Per Driver | Average daily revenue per driver | > 200 SAR | Database | Daily |
| Order Completion Rate | % of orders completed successfully | > 95% | Database | Daily |

### 2.2 Technical KPIs

| KPI | Description | Target | Measurement | Frequency |
|-----|-------------|--------|-------------|-----------|
| API Uptime | API server availability | 99.9% | Uptime monitoring | Real-time |
| API Response Time (p95) | 95th percentile response time | < 500ms | APM | Real-time |
| API Error Rate | % of failed requests | < 0.1% | APM | Real-time |
| App Crash-Free Rate | % of sessions without crash | > 99.5% | Crashlytics | Real-time |
| App Startup Time | Cold start time | < 2s | Performance monitoring | Per session |
| Database Query Time (p95) | 95th percentile query time | < 100ms | Database monitoring | Real-time |
| Cache Hit Rate | Redis cache hit ratio | > 90% | Cache monitoring | Real-time |
| Queue Processing Time | Average message processing time | < 1s | Queue monitoring | Real-time |

---

## 3. Logging Strategy

### 3.1 Log Levels

| Level | Usage | Color | Retention |
|-------|-------|-------|-----------|
| DEBUG | Development debugging, verbose | Gray | 1 day |
| INFO | Normal operation, key events | Green | 7 days |
| WARNING | Non-critical issues, retries | Yellow | 30 days |
| ERROR | Critical issues, exceptions | Red | 90 days |
| FATAL | App-crashing issues | Red (bold) | 90 days |

### 3.2 Structured Log Format

```json
{
  "timestamp": "2026-07-24T10:30:00.123Z",
  "level": "INFO",
  "service": "saeq-api",
  "environment": "production",
  "trace_id": "abc123def456",
  "span_id": "ghi789",
  "message": "Order created successfully",
  "data": {
    "order_id": "uuid",
    "customer_id": "uuid",
    "amount": 45.00
  },
  "error": null,
  "stack_trace": null
}
```

### 3.3 Log Sources

| Source | Tool | Retention | Access |
|--------|------|-----------|--------|
| Mobile App (Driver) | Crashlytics + Custom Logger | 90 days | Firebase Console |
| Mobile App (Customer) | Crashlytics + Custom Logger | 90 days | Firebase Console |
| API Server | CloudWatch Logs | 90 days | AWS Console |
| Database | PostgreSQL logs | 30 days | AWS Console |
| Queue | RabbitMQ logs | 30 days | Management UI |
| CDN | CloudFront logs | 30 days | AWS Console |

---

## 4. Metrics

### 4.1 Application Metrics (Mobile)

| Metric | Collection | Visualization | Alert |
|--------|-----------|---------------|-------|
| Screen load time | Firebase Performance | Firebase Console | > 2s |
| API call duration | Firebase Performance | Firebase Console | > 5s |
| Crash rate | Crashlytics | Firebase Console | > 0.5% |
| ANR rate (Android) | Crashlytics | Firebase Console | > 0.1% |
| Memory usage | DevTools / Xcode | Custom dashboard | > 200MB |
| Battery impact | Device stats | Custom dashboard | > 5%/hour |

### 4.2 Server Metrics (API)

| Metric | Collection | Visualization | Alert |
|--------|-----------|---------------|-------|
| Request count | CloudWatch | Grafana | - |
| Response time | CloudWatch | Grafana | > 500ms (p95) |
| Error rate | CloudWatch | Grafana | > 1% |
| CPU utilization | CloudWatch | Grafana | > 80% |
| Memory utilization | CloudWatch | Grafana | > 80% |
| Disk I/O | CloudWatch | Grafana | > 1000 IOPS |
| Network traffic | CloudWatch | Grafana | - |

### 4.3 Database Metrics

| Metric | Collection | Visualization | Alert |
|--------|-----------|---------------|-------|
| Connection count | CloudWatch + pgHero | Grafana | > 80% of max |
| Query performance | pgHero + slow query log | Grafana | > 100ms |
| Disk usage | CloudWatch | Grafana | > 80% |
| Replication lag | CloudWatch | Grafana | > 5s |
| Deadlocks | PostgreSQL logs | Grafana | > 0 |

### 4.4 Business Metrics

| Metric | Collection | Visualization | Alert |
|--------|-----------|---------------|-------|
| Orders per minute | Custom metric | Grafana | < 10 (low activity) |
| Active drivers | Custom metric | Grafana | < 50 |
| Payment success rate | Custom metric | Grafana | < 95% |
| Driver acceptance rate | Custom metric | Grafana | < 70% |

---

## 5. Distributed Tracing

### 5.1 Trace Context

Every request is assigned a `trace_id` that propagates through all services:

```
Mobile App → API Gateway → Auth Service → Orders Service → Payment Service → Database
   |             |              |               |                 |              |
   +--- trace_id: abc123 ------+---------------+-----------------+--------------+
```

### 5.2 Traced Operations

| Operation | Service | Span Tags |
|-----------|---------|-----------|
| HTTP Request | API Gateway | method, path, status_code |
| Authentication | Auth Service | user_id, auth_method |
| Order Creation | Orders Service | order_id, customer_id |
| Payment Processing | Payment Service | payment_id, amount |
| Database Query | Database | query_type, table |
| External API Call | Integration | service_name, endpoint |

---

## 6. Alerting

### 6.1 Alert Rules

| Rule | Metric | Condition | Duration | Severity | Channel |
|------|--------|-----------|----------|----------|---------|
| High API Error Rate | error_rate | > 1% | 5 minutes | SEV-1 | PagerDuty + Slack |
| API Down | uptime | = 0 | 1 minute | SEV-1 | PagerDuty + SMS |
| High Response Time | p95_response_time | > 2s | 5 minutes | SEV-2 | Slack |
| Database Connection Saturation | db_connections | > 90% | 5 minutes | SEV-1 | PagerDuty + Slack |
| High CPU | cpu_utilization | > 90% | 10 minutes | SEV-2 | Slack |
| Disk Full | disk_usage | > 90% | 5 minutes | SEV-1 | PagerDuty + Slack |
| High Crash Rate | crash_free_rate | < 99% | 1 hour | SEV-2 | Slack |
| Low Driver Availability | active_drivers | < 20 | 15 minutes | SEV-3 | Slack |
| Payment Failure Spike | payment_failure_rate | > 5% | 5 minutes | SEV-1 | PagerDuty + SMS |

### 6.2 Alert Routing

| Time | Channel | Responder |
|------|---------|-----------|
| Business hours (8AM-6PM) | Slack | On-call engineer |
| After hours (6PM-8AM) | PagerDuty + SMS | On-call engineer |
| Weekends | PagerDuty + SMS | On-call engineer |
| Holidays | PagerDuty + SMS | On-call engineer + backup |

---

## 7. Dashboards

### 7.1 Executive Dashboard

- Daily active users (drivers + customers)
- Orders per day (chart)
- Revenue (daily, weekly, monthly)
- Average delivery time
- Customer satisfaction score
- Driver acceptance rate

### 7.2 Operations Dashboard

- API response time (p50, p95, p99)
- Error rate by endpoint
- Active server instances
- Database connection pool
- Queue depth
- Cache hit rate
- Recent deployments

### 7.3 Mobile App Dashboard

- Crash-free rate
- Most common crash types
- App startup time
- Screen load times
- API call failures
- OS version distribution
- Device model distribution

---

*This document defines the monitoring and observability strategy. All metrics and alerts should be reviewed and updated quarterly.*