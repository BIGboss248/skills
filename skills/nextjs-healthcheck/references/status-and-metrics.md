# Architectural Principles & Runtime Metrics Reference

This document details the architectural status code discipline, severity classifications, and non-blocking runtime metrics measured by the Next.js health check endpoint.

---

## 1. Status Code & Severity Matrix

A robust health check distinguishes between **Liveness** (process is running), **Readiness** (process is ready to serve traffic), and **Saturation** (system is degraded/stressed).

| Status          | HTTP Code                 | Meaning                                                                                                              | Orchestrator Action (Docker Compose / Reverse Proxy / LB)          |
| :-------------- | :------------------------ | :------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------- |
| **`healthy`**   | `200 OK`                  | All system metrics within normal bounds; all critical dependencies reachable.                                        | Route traffic normally.                                            |
| **`degraded`**  | `200 OK`                  | App is serving requests, but under elevated resource pressure (e.g. heap utilization >80% or event loop lag >100ms). | Continue routing traffic; trigger observability warning alert.     |
| **`unhealthy`** | `503 Service Unavailable` | Critical failure (database unreachable, heap saturation >90%, event loop lockup >500ms).                             | **Stop routing traffic** and trigger container restart / rollover. |

> [!IMPORTANT]
> **HTTP 503 on Critical Failure:** Orchestrators, reverse proxies, and cloud load balancers inspect the HTTP status code. If a critical dependency or metric is failing, the endpoint **must return 503** so the instance is identified as unhealthy and removed from active traffic routing.

---

## 2. Core Metrics & Thresholds

Every health check endpoint collects non-blocking, zero-overhead Node.js runtime metrics:

### 1. V8 Heap Saturation & Memory Utilization

- **Source**: `v8.getHeapStatistics()` and `process.memoryUsage()`.
- **Metrics Collected**: `used_heap_size`, `total_heap_size`, `heap_size_limit`, `rss`.
- **Formula**:
  $$\text{Heap Utilization (\%)} = \left(\frac{\text{used\_heap\_size}}{\text{heap\_size\_limit}}\right) \times 100$$
- **Thresholds**:
  - `< 80%`: `healthy`
  - `80% - 90%`: `degraded` (memory pressure detected)
  - `> 90%`: `unhealthy` (imminent Out-Of-Memory / OOM kill)

### 2. Event Loop Delay (CPU Starvation & Blocking Tasks)

- **Source**: `perf_hooks.monitorEventLoopDelay({ resolution: 10 })`.
- **Metrics Collected**: Mean lag, 99th percentile lag ($p99$).
- **Thresholds**:
  - $p99 < 100\text{ms}$: `healthy`
  - $100\text{ms} \le p99 \le 500\text{ms}$: `degraded` (elevated CPU load)
  - $p99 > 500\text{ms}$: `unhealthy` (event loop stalled or frozen)

### 3. Process Uptime & System Metadata

- **Source**: `process.uptime()`, `process.env`.
- **Metrics Collected**:
  - `uptimeSeconds`: `Math.floor(process.uptime())`
  - `timestamp`: Current ISO 8601 string (`new Date().toISOString()`)
  - `environment`: `process.env.NODE_ENV || "development"`
  - `version`: `process.env.npm_package_version || "1.0.0"`
