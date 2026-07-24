# SAEQ — Performance Benchmarks

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [26_NON_FUNCTIONAL_REQUIREMENTS.md](./26_NON_FUNCTIONAL_REQUIREMENTS.md), [18_TESTING_GUIDE.md](./18_TESTING_GUIDE.md)

---

## 1. Purpose

This document defines performance benchmarks, load testing results, and acceptance thresholds for the SAEQ platform.

---

## 2. Mobile App Benchmarks

### 2.1 Startup Time

| Metric | Target | Measurement | Device |
|--------|--------|-------------|--------|
| Cold start (first launch) | ≤ 2 seconds | Flutter DevTools | Samsung Galaxy S23 |
| Warm start (background → foreground) | ≤ 1 second | Flutter DevTools | Samsung Galaxy S23 |
| Hot reload | ≤ 1 second | Flutter DevTools | Development only |
| Cold start (low-end device) | ≤ 3 seconds | Flutter DevTools | Samsung Galaxy A12 |

### 2.2 Screen Load Times

| Screen | Target | 95th Percentile | 99th Percentile |
|--------|--------|-----------------|-----------------|
| Splash → Home | ≤ 1.5s | ≤ 2s | ≤ 3s |
| Order List | ≤ 1s | ≤ 1.5s | ≤ 2s |
| Order Detail | ≤ 0.8s | ≤ 1.2s | ≤ 2s |
| Map Screen | ≤ 1.5s | ≤ 2s | ≤ 3s |
| Earnings Screen | ≤ 1s | ≤ 1.5s | ≤ 2s |
| Profile Screen | ≤ 0.8s | ≤ 1s | ≤ 1.5s |
| Chat Screen | ≤ 0.5s | ≤ 0.8s | ≤ 1s |

### 2.3 Memory Usage

| Scenario | Target | Peak | Notes |
|----------|--------|------|-------|
| Idle (home screen) | ≤ 80 MB | ≤ 100 MB | No orders loaded |
| Order list (100 items) | ≤ 120 MB | ≤ 150 MB | Scrolling through list |
| Map with route | ≤ 150 MB | ≤ 200 MB | Active navigation |
| Image gallery | ≤ 100 MB | ≤ 130 MB | 10 images loaded |
| Chat with history | ≤ 90 MB | ≤ 120 MB | 100 messages |
| Worst case (all features) | ≤ 200 MB | ≤ 350 MB | Heavy usage scenario |

### 2.4 Battery Consumption

| Scenario | Target | Measurement |
|----------|--------|-------------|
| Idle (background) | ≤ 1% per hour | Battery historian |
| Active use (no GPS) | ≤ 3% per hour | Battery historian |
| Active use (with GPS) | ≤ 5% per hour | Battery historian |
| Navigation (screen on) | ≤ 8% per hour | Battery historian |
| Worst case (full day) | ≤ 30% per day | Battery historian |

### 2.5 Network Performance

| Operation | Target | Network Type |
|-----------|--------|--------------|
| API request (small payload) | ≤ 500ms | 4G/LTE |
| API request (large payload) | ≤ 2s | 4G/LTE |
| Image upload (1MB) | ≤ 5s | 4G/LTE |
| Image download (1MB) | ≤ 3s | 4G/LTE |
| Order list sync (100 items) | ≤ 3s | 4G/LTE |
| Offline sync (50 actions) | ≤ 10s | 4G/LTE |

---

## 3. API Benchmarks

### 3.1 Response Times

| Endpoint | Target (p50) | Target (p95) | Target (p99) |
|----------|-------------|-------------|-------------|
| POST /auth/login | ≤ 200ms | ≤ 500ms | ≤ 1s |
| POST /auth/otp | ≤ 300ms | ≤ 800ms | ≤ 2s |
| GET /orders | ≤ 200ms | ≤ 500ms | ≤ 1s |
| GET /orders/{id} | ≤ 100ms | ≤ 300ms | ≤ 500ms |
| POST /orders | ≤ 300ms | ≤ 800ms | ≤ 2s |
| POST /orders/{id}/accept | ≤ 200ms | ≤ 500ms | ≤ 1s |
| PUT /driver/location | ≤ 100ms | ≤ 200ms | ≤ 500ms |
| GET /earnings | ≤ 200ms | ≤ 500ms | ≤ 1s |
| POST /payments | ≤ 500ms | ≤ 2s | ≤ 5s |
| POST /documents/upload | ≤ 2s | ≤ 5s | ≤ 10s |

### 3.2 Throughput

| Metric | Target | Test Method |
|--------|--------|-------------|
| Requests per second (normal) | 500 RPS | Load testing (k6) |
| Requests per second (peak) | 2,000 RPS | Load testing (k6) |
| Concurrent connections | 5,000 | Load testing (k6) |
| WebSocket connections | 2,000 | Load testing (k6) |
| Database writes per second | 1,000 QPS | Database benchmarking |
| Database reads per second | 5,000 QPS | Database benchmarking |

---

## 4. Load Testing Results

### 4.1 Test Environment

| Component | Specification |
|-----------|---------------|
| API Server | AWS t3.medium (2 vCPU, 4GB RAM) × 3 instances |
| Database | AWS RDS db.t3.medium (2 vCPU, 4GB RAM) |
| Cache | AWS ElastiCache cache.t3.small (1 vCPU, 1.3GB RAM) |
| Load Generator | k6 on AWS t3.large |

### 4.2 Test Scenarios

#### Scenario 1: Normal Load (100 concurrent users)

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Avg response time | 120ms | < 500ms | ✅ Pass |
| p95 response time | 280ms | < 500ms | ✅ Pass |
| Error rate | 0.02% | < 0.1% | ✅ Pass |
| Requests/sec | 150 | - | ✅ Pass |

#### Scenario 2: Peak Load (500 concurrent users)

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Avg response time | 350ms | < 500ms | ✅ Pass |
| p95 response time | 800ms | < 2s | ✅ Pass |
| Error rate | 0.05% | < 0.1% | ✅ Pass |
| Requests/sec | 750 | - | ✅ Pass |

#### Scenario 3: Stress Test (1,000 concurrent users)

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Avg response time | 1.2s | < 2s | ✅ Pass |
| p95 response time | 2.5s | < 5s | ✅ Pass |
| Error rate | 0.15% | < 1% | ✅ Pass |
| Requests/sec | 1,200 | - | ✅ Pass |

#### Scenario 4: Endurance Test (4 hours at 200 concurrent users)

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Avg response time | 180ms | < 500ms | ✅ Pass |
| p95 response time | 400ms | < 1s | ✅ Pass |
| Error rate | 0.03% | < 0.1% | ✅ Pass |
| Memory leak | None detected | None | ✅ Pass |

---

## 5. Database Benchmarks

### 5.1 Query Performance

| Query | Target | Measured | Status |
|-------|--------|----------|--------|
| Get orders by driver (with pagination) | < 50ms | 12ms | ✅ Pass |
| Get order by ID (with joins) | < 30ms | 8ms | ✅ Pass |
| Get driver by ID | < 20ms | 3ms | ✅ Pass |
| Insert order (with items) | < 50ms | 15ms | ✅ Pass |
| Update order status | < 30ms | 5ms | ✅ Pass |
| Get earnings summary (aggregation) | < 100ms | 35ms | ✅ Pass |
| Search orders (full text) | < 200ms | 80ms | ✅ Pass |

### 5.2 Connection Pool

| Metric | Value |
|--------|-------|
| Max connections | 100 |
| Min connections | 10 |
| Connection timeout | 5s |
| Idle timeout | 60s |
| Max lifetime | 30 minutes |

---

## 6. Acceptance Thresholds

| Category | Threshold | Action if Exceeded |
|----------|-----------|-------------------|
| API p95 response time | > 2s for 5 minutes | Auto-scale, alert on-call |
| API error rate | > 1% for 5 minutes | Alert on-call, rollback if recent deploy |
| App crash-free rate | < 99% for 1 hour | Alert, rollback if recent release |
| App startup time | > 3s for 1% of sessions | Performance investigation |
| Database query time (p95) | > 500ms for 10 minutes | Query optimization, add index |
| Database disk usage | > 80% | Extend volume, archive old data |
| Memory usage (app) | > 200MB steady state | Memory leak investigation |
| Battery consumption | > 5%/hour active | Battery optimization sprint |

---

*These benchmarks are measured during each release cycle. Any regression must be addressed before release.*