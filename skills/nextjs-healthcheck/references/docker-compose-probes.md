# Docker Compose Health Probes Reference

This document provides instructions for detecting and configuring zero-dependency Docker Compose health check probes for Next.js standalone containers.

---

## 1. Automated Detection & Service Matching

When health checks are initialized or updated, scan the repository root for Compose configurations:

1. **Compose Manifests**:
   - `docker-compose.yml` (Local development/standalone stack)
   - `docker-compose.prod.yml` (Production / GHCR package deployment stack)
   - `docker-compose.*.yml` or `compose.yaml` (if present)

2. **Next.js Service Identification**:
   - Inspect services for indicators such as `build: .`, `dockerfile: Dockerfile`, `ports: ["3000:3000"]`, or service names matching `nextjs-app`, `web`, or `app`.

---

## 2. Zero-Dependency Healthcheck Definition

Node.js (v18+) includes a native global `fetch` API. This allows health checks to run inside minimal, distroless, or alpine containers without requiring `curl` or `wget` installed in the production image:

```yaml
healthcheck:
  test:
    [
      "CMD-SHELL",
      'node -e "fetch(''http://127.0.0.1:'' + (process.env.PORT || 3000) + ''/api/health'').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"',
    ]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 10s
```

### Probe Parameters Explained:

- `test`: Executes inline Node.js script evaluating HTTP 200–299 (`r.ok`). Returns exit code 0 on success, exit code 1 on failure.
- `interval`: Time between consecutive health probe evaluations (30 seconds).
- `timeout`: Maximum duration allowed for the probe to respond before considering it failed (5 seconds).
- `retries`: Number of consecutive probe failures required to mark the container `unhealthy` (3 retries).
- `start_period`: Grace period post-startup during which probe failures do not count against max retries (10 seconds for Next.js bootstrap).
