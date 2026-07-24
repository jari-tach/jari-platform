# SAEQ — Non-Functional Requirements

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [25_REQUIREMENTS_SPECIFICATION.md](./25_REQUIREMENTS_SPECIFICATION.md)

---

## 1. Purpose

This document defines the **quality attributes** of the SAEQ platform. It does **not** describe features or functionality. Instead, it specifies measurable quality targets that the system must meet.

---

## 2. Performance

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-PERF-001 | App cold start time | ≤ 2 seconds | Flutter DevTools timeline |
| NFR-PERF-002 | App warm start time | ≤ 1 second | Flutter DevTools timeline |
| NFR-PERF-003 | Screen transition time | ≤ 300 ms | Navigation observer |
| NFR-PERF-004 | API response time (p95) | ≤ 500 ms | Server-side monitoring |
| NFR-PERF-005 | API response time (p99) | ≤ 2 seconds | Server-side monitoring |
| NFR-PERF-006 | UI frame rate | 60 FPS (smooth) | Flutter DevTools |
| NFR-PERF-007 | Order list load time (100 items) | ≤ 1 second | Performance test |
| NFR-PERF-008 | Map rendering time | ≤ 500 ms | Map SDK metrics |
| NFR-PERF-009 | Image upload time (5MB) | ≤ 10 seconds | Network test |
| NFR-PERF-010 | Search response time | ≤ 300 ms | Performance test |

---

## 3. Memory & Storage

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-MEM-001 | App memory usage (steady state) | ≤ 200 MB | Android Profiler / Xcode Instruments |
| NFR-MEM-002 | App memory usage (peak) | ≤ 350 MB | Android Profiler / Xcode Instruments |
| NFR-MEM-003 | Local database size | ≤ 100 MB | SQLite file size check |
| NFR-MEM-004 | Image cache size | ≤ 50 MB | Cache directory size |
| NFR-MEM-005 | Log file size (per session) | ≤ 5 MB | Log rotation check |
| NFR-MEM-006 | Offline queue size | ≤ 20 MB | Queue directory size |

---

## 4. CPU & Battery

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-CPU-001 | CPU usage (idle) | ≤ 5% | Android Profiler / Xcode Instruments |
| NFR-CPU-002 | CPU usage (active use) | ≤ 30% | Android Profiler / Xcode Instruments |
| NFR-CPU-003 | Battery consumption (active) | ≤ 5% per hour | Battery historian |
| NFR-CPU-004 | Battery consumption (background) | ≤ 1% per hour | Battery historian |
| NFR-CPU-005 | Location tracking battery impact | ≤ 3% per hour | Battery historian |

---

## 5. Availability & Reliability

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-AVAIL-001 | System uptime (API) | 99.9% (8.76 hours/year downtime) | Uptime monitoring |
| NFR-AVAIL-002 | System uptime (critical periods) | 99.99% | Uptime monitoring |
| NFR-AVAIL-003 | API error rate | ≤ 0.1% of requests | Error monitoring |
| NFR-AVAIL-004 | Crash-free session rate | ≥ 99.5% | Crashlytics |
| NFR-AVAIL-005 | Order processing success rate | ≥ 99% | Business monitoring |
| NFR-AVAIL-006 | Payment processing success rate | ≥ 99.5% | Payment gateway |
| NFR-AVAIL-007 | Notification delivery rate | ≥ 98% within 30 seconds | Push notification analytics |

---

## 6. Scalability

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-SCAL-001 | Maximum concurrent users | 10,000 | Load testing |
| NFR-SCAL-002 | Maximum concurrent drivers | 2,000 | Load testing |
| NFR-SCAL-003 | Maximum orders per day | 50,000 | Load testing |
| NFR-SCAL-004 | Maximum orders per second (peak) | 100 | Load testing |
| NFR-SCAL-005 | Maximum concurrent WebSocket connections | 5,000 | Load testing |
| NFR-SCAL-006 | Database read throughput | 5,000 QPS | Database benchmarking |
| NFR-SCAL-007 | Database write throughput | 1,000 QPS | Database benchmarking |
| NFR-SCAL-008 | Auto-scaling trigger threshold | 70% CPU utilization | Cloud monitoring |

---

## 7. Security

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-SEC-001 | Authentication token encryption | AES-256 | Security audit |
| NFR-SEC-002 | Data in transit encryption | TLS 1.3 | Network security scan |
| NFR-SEC-003 | Data at rest encryption | AES-256 | Security audit |
| NFR-SEC-004 | Password hashing algorithm | bcrypt (cost 12) | Code review |
| NFR-SEC-005 | Session timeout (inactive) | 15 minutes | Functional test |
| NFR-SEC-006 | Maximum login attempts before lockout | 5 attempts | Functional test |
| NFR-SEC-007 | API rate limiting | 100 requests/minute per user | Load testing |
| NFR-SEC-008 | OWASP Top 10 compliance | Zero critical findings | Security scan |
| NFR-SEC-009 | Vulnerability scan frequency | Weekly | Automated scanning |
| NFR-SEC-010 | Penetration testing frequency | Quarterly | Third-party audit |

---

## 8. Localization & Internationalization

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-L10N-001 | Supported languages | Arabic (primary), English | Code review |
| NFR-L10N-002 | RTL layout support | Full RTL for Arabic | Visual inspection |
| NFR-L10N-003 | Date/time format | Arabic (Hijri/Gregorian), English | Functional test |
| NFR-L10N-004 | Number formatting | Arabic (Hindi) and Western digits | Functional test |
| NFR-L10N-005 | Currency formatting | SAR with proper placement | Functional test |
| NFR-L10N-006 | Address format | Saudi address format (building, street, district, city) | Functional test |
| NFR-L10N-007 | Translation coverage | 100% of UI strings | L10n audit |

---

## 9. Accessibility

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-ACC-001 | Screen reader support | Full TalkBack/VoiceOver support | Accessibility scanner |
| NFR-ACC-002 | Minimum touch target size | 48x48 dp | UI audit |
| NFR-ACC-003 | Color contrast ratio (normal text) | ≥ 4.5:1 | Contrast checker |
| NFR-ACC-004 | Color contrast ratio (large text) | ≥ 3:1 | Contrast checker |
| NFR-ACC-005 | Text scaling support | Up to 200% font size | Functional test |
| NFR-ACC-006 | Focus indicators | Visible on all interactive elements | UI audit |

---

## 10. Maintainability

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-MAINT-001 | Code coverage (unit tests) | ≥ 80% | Coverage report |
| NFR-MAINT-002 | Code coverage (widget tests) | ≥ 60% | Coverage report |
| NFR-MAINT-003 | Static analysis warnings | Zero | Dart analyzer |
| NFR-MAINT-004 | Cyclomatic complexity per method | ≤ 10 | Lint rules |
| NFR-MAINT-005 | Maximum method lines | ≤ 50 lines | Lint rules |
| NFR-MAINT-006 | Maximum file lines | ≤ 400 lines | Lint rules |
| NFR-MAINT-007 | Documentation coverage | 100% of public APIs | dartdoc |
| NFR-MAINT-008 | Dependency update frequency | Monthly | `flutter pub outdated` |

---

## 11. Recovery & Backup

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-REC-001 | Recovery Time Objective (RTO) | ≤ 4 hours | Disaster recovery drill |
| NFR-REC-002 | Recovery Point Objective (RPO) | ≤ 15 minutes | Backup verification |
| NFR-REC-003 | Database backup frequency | Every 6 hours | Backup logs |
| NFR-REC-004 | Database backup retention | 30 days | Backup policy audit |
| NFR-REC-005 | Log backup retention | 90 days | Log policy audit |
| NFR-REC-006 | File backup retention | 7 days | Backup policy audit |

---

## 12. Network & Connectivity

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-NET-001 | Minimum supported network speed | 256 Kbps | Network test |
| NFR-NET-002 | Offline operation duration | Up to 4 hours | Functional test |
| NFR-NET-003 | Data synchronization delay (after reconnect) | ≤ 30 seconds | Functional test |
| NFR-NET-004 | WebSocket reconnection time | ≤ 5 seconds | Functional test |
| NFR-NET-005 | API request retry mechanism | 3 retries with exponential backoff | Code review |
| NFR-NET-006 | Image compression for upload | Max 1 MB per image | Functional test |

---

## 13. Compliance

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-COMP-001 | SDAIA (Saudi Data & AI Authority) compliance | Full compliance | Compliance audit |
| NFR-COMP-002 | ZATCA (Tax & Customs Authority) compliance | Full compliance | Compliance audit |
| NFR-COMP-003 | PCI DSS compliance (payment data) | Level 1 | Security audit |
| NFR-COMP-004 | GDPR compliance (user data) | Full compliance | Compliance audit |
| NFR-COMP-005 | App Store / Google Play guidelines | Full compliance | Store review |
| NFR-COMP-006 | Saudi labor law compliance | Full compliance | Legal review |

---

## 14. Monitoring & Observability

| ID | Requirement | Target | Measurement Method |
|----|-------------|--------|-------------------|
| NFR-MON-001 | Crash reporting coverage | 100% of sessions | Crashlytics |
| NFR-MON-002 | Error log retention | 90 days | Log storage |
| NFR-MON-003 | Performance monitoring | All key screens | Firebase Performance |
| NFR-MON-004 | API monitoring | All endpoints | Server monitoring |
| NFR-MON-005 | Alert response time (critical) | ≤ 15 minutes | On-call policy |
| NFR-MON-006 | Alert response time (high) | ≤ 1 hour | On-call policy |

---

*This document defines the quality attributes of the SAEQ platform. All changes require stakeholder approval.*