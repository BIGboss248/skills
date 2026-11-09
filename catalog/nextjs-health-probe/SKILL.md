---
name: nextjs-health-probe
description: >-
  Add and verify a health endpoint. Use when exposing /api/health, wiring
  container healthchecks, or debugging a deploy that never becomes healthy.
---

# Health Probe Standards

How a health endpoint and its container probe are built. This skill writes the
probe only.

## Endpoint contract

- Path: `app/api/health/route.ts` (or `src/app/...`).
- `export const dynamic = "force-dynamic"` and
  `Cache-Control: no-store, no-cache, must-revalidate`.
- `export const runtime = "nodejs"` — heap and event-loop metrics need it.
- Payload: `status`, `timestamp`, `uptimeSeconds`, `environment`, `version`,
  `checks`, `metrics`.

## Status discipline

| Status | HTTP | Meaning | Orchestrator behavior |
| :--- | :--- | :--- | :--- |
| `healthy` | 200 | Metrics normal, critical dependencies reachable | Route traffic |
| `degraded` | 200 | Serving under pressure | Keep routing, alert |
| `unhealthy` | 503 | Critical failure | Stop traffic, restart |

A `200` with `"status": "unhealthy"` is a broken probe. Orchestrators read the
status code, not the body.

## Metrics

| Signal | Healthy | Degraded | Unhealthy |
| :--- | :--- | :--- | :--- |
| Heap used / limit | < 80% | 80–90% | > 90% |
| Event-loop delay p99 | < 100 ms | 100–500 ms | > 500 ms |

Heap comes from `v8.getHeapStatistics()` or `process.memoryUsage()`; delay from
`perf_hooks.monitorEventLoopDelay`. Both are non-blocking reads.

## Dependency probes

Probe only what exists. Skip with a reason when there is no store.

| Store | Probe | Timeout |
| :--- | :--- | :--- |
| Prisma | `prisma.$queryRaw\`SELECT 1\`` | 2000 ms |
| Drizzle | `db.execute(sql\`SELECT 1\`)` | 2000 ms |
| Supabase | `from('_dummy_health').select('count', { head: true })` | 2000 ms |
| Mongoose | `connection.readyState === 1` | 2000 ms |
| `pg` / `mysql2` | `pool.query('SELECT 1')` | 2000 ms |
| `better-sqlite3` | `db.prepare('SELECT 1').get()` | synchronous |
| Redis | `redis.ping()` | 1000 ms |

Wrap every async probe in `Promise.race` with an explicit timeout. An unbounded
probe exhausts the pool during an outage. Return a high-level summary only — no
connection string, password, or stack trace.

## Container probe

Minimal and distroless images have no `curl`. Use Node's `fetch` from
[docker-compose healthcheck template](./resources/templates/docker-compose.healthcheck.template.yml):

- `interval: 30s`, `timeout: 5s`, `retries: 3`, `start_period: 10s`.
- Exit `0` on `r.ok`, non-zero otherwise.

## Definition of Done

- [ ] `force-dynamic` and the no-store header are present.
- [ ] Status code matches the reported status (`503` for `unhealthy`).
- [ ] Every async probe has a timeout.
- [ ] No secret appears in the payload.
- [ ] The container healthcheck uses Node, not `curl`/`wget`.
- [ ] The probe was exercised once: endpoint, then `docker inspect` state.
- [ ] The endpoint and container state were observed.

## Edge Cases & Pitfalls

- **Missing `force-dynamic`** — the body is cached and `timestamp` freezes.
- **Always-200** — traffic keeps flowing to a broken instance.
- **No timeout** — a slow database hangs the endpoint.
- **`curl` in the healthcheck** — fails on alpine/distroless.
- **Edge runtime** — `perf_hooks` and V8 metrics are unavailable.
- **Probe churn** — a 10-second probe must stay cheap; never write to the store
  from it.
- **Secrets in the body** — the endpoint is usually public.

## References

- [Full health contract](./references/health-contract.md)
- [No-database template](./resources/templates/route-no-db.ts.template)
- [Database template](./resources/templates/route-with-db.ts.template)
- [Compose healthcheck](./resources/templates/docker-compose.healthcheck.template.yml)
