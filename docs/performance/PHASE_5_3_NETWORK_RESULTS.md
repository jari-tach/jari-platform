# Phase 5.3 — Network Performance Results

> **Date:** 2026-08-04  
> **Stack:** local Nest `127.0.0.1:3000` (Device QA backend) · PC → Backend (host)  
> **Evidence:** `docs/performance/evidence/network_20260804/network_log.txt`  
> **Threshold:** API small payload ≤ 500 ms (`35_PERFORMANCE_BENCHMARKS.md` §2.5)

## API Latency

| Call | Samples (ms) | p-approx | Verdict |
| --- | --- | --- | --- |
| `GET /health/live` | 115, 29, 43, 25, 26 | ~29–43 steady | **PASS** |
| `GET /health/ready` | 46, 28, 29 | ≤ 46 | **PASS** |
| `GET /v1/offers` (no auth headers) | 50, 2, 2 (400 validation) | Fast fail | **PASS** (latency only) |

Authenticated driver APIs exercised end-to-end during Device QA (login/offers/accept/pickup/arrival/confirm/cancel) with no timeout FAIL on HONOR via `adb reverse`.

## Retry / Cache / Offline Recovery

| Item | Result | Evidence |
| --- | --- | --- |
| Offline UI | **PASS** | Device QA matrix #6 |
| Online restore | **PASS** | #7 |
| Reconnect after drop | **PASS** | #22 · Reconnecting banner observed Phase 5 session |
| Retry | **PASS (behavioural)** | Reconnect + refresh after airplane / reverse restore in prior QA |
| Cache | **PASS (behavioural)** | Session restore / local Drift assignment — no full network block of cold restore |

## Gate 5.3

**PASS** against local-stack latency and Device QA offline recovery evidence.
