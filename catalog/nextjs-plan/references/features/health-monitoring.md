# Feature Pack: Health Monitoring

Plan the `/api/health` probe, runtime metrics, and container health probes as
**Phase 3** items, then wire the container in **Phase 7**. Do not duplicate the
probe in another phase.

---

## 1. Detection (before asking)

- Route root: `app/api/health/route.ts` or `src/app/api/health/route.ts`.
- State stores: Prisma, Drizzle, Supabase, Mongoose/MongoDB, `pg`, `mysql2`,
  `better-sqlite3`, Redis.
- Orchestration: `docker-compose.yml`, `docker-compose.prod.yml`,
  `docker-compose.*.yml`; Next.js service matched by `build: .`, `dockerfile:`,
  `ports: 3000:3000`, or a service named `app`/`web`/`nextjs-app`.
- Runtime target: Node runtime (not Edge) — `perf_hooks` and V8 need it.

---

## 2. Plan items to generate

| Item | Title | Acceptance shape |
| :--- | :--- | :--- |
| 3.1 | Health endpoint | `curl -sf localhost:3000/api/health` → 200 + documented payload |
| 3.2 | Container probes | `docker inspect` shows the healthcheck; container reaches `healthy` |
| 3.3 | Endpoint contract test | unit test asserts payload shape and `Cache-Control: no-store` |
| 3.4 | Dependency probe (only if a store exists) | stopped dependency → 503 + `checks.db.status = "unhealthy"` within 2 s |
| 7.x | Compose wiring | `docker compose config` valid; `ps` shows `(healthy)` |

If no database is detected, skip 3.4 explicitly (`Skipped on purpose` + revisit
trigger) instead of shipping a fake probe.

---

## 3. Endpoint contract

- Deploy [route-no-db.ts.template](../../resources/templates/health/route-no-db.ts.template)
  or [route-with-db.ts.template](../../resources/templates/health/route-with-db.ts.template).
- `export const dynamic = "force-dynamic"` and
  `Cache-Control: no-store, no-cache, must-revalidate` are mandatory.
- Payload: `status`, `timestamp`, `uptimeSeconds`, `environment`, `version`,
  `checks` (per dependency), `metrics`.
- Run on `export const runtime = "nodejs"`.

### Status discipline

| Status | HTTP | Meaning | Orchestrator |
| :--- | :--- | :--- | :--- |
| `healthy` | 200 | metrics normal, critical dependencies reachable | route traffic |
| `degraded` | 200 | serving under pressure (heap > 80 %, lag > 100 ms) | keep routing, alert |
| `unhealthy` | 503 | critical failure (store down, heap > 90 %, lag > 500 ms) | stop traffic, restart |

A 200 with `"status": "unhealthy"` is a broken probe: orchestrators read the
status code, not the body.

### Metrics (non-blocking)

- **Heap utilization** = `used_heap_size / heap_size_limit × 100`
  from `v8.getHeapStatistics()` / `process.memoryUsage()`:
  `< 80 %` healthy, `80–90 %` degraded, `> 90 %` unhealthy.
- **Event loop delay** from `perf_hooks.monitorEventLoopDelay({ resolution: 10 })`,
  p99: `< 100 ms` healthy, `100–500 ms` degraded, `> 500 ms` unhealthy.
- **Process**: `uptimeSeconds`, ISO `timestamp`, `environment`, `version`.

### Dependency probes

| Store | Probe | Timeout |
| :--- | :--- | :--- |
| Prisma | `prisma.$queryRaw\`SELECT 1\`` | 2000 ms |
| Drizzle | `db.execute(sql\`SELECT 1\`)` | 2000 ms |
| Supabase | `from('_dummy_health').select('count', { head: true })` | 2000 ms |
| Mongoose | `connection.readyState === 1` | 2000 ms |
| `pg` / `mysql2` | `pool.query('SELECT 1')` | 2000 ms |
| `better-sqlite3` | `db.prepare('SELECT 1').get()` | sync |
| Redis | `redis.ping()` | 1000 ms |

Wrap every async probe in `Promise.race` with an explicit timeout rejection; an
unbounded probe exhausts the request pool during an outage. Log detail
server-side; return only a high-level summary (never a connection string,
password, or raw stack trace).

---

## 4. Container probe (zero-dependency)

Minimal and distroless images have no `curl`/`wget`. Use Node's native `fetch`:

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

Full snippet: [docker-compose.healthcheck.template.yml](../../resources/templates/health/docker-compose.healthcheck.template.yml).

---

## 5. Verification & evidence

```powershell
curl -i http://localhost:3000/api/health
docker compose ps
docker inspect --format "{{json .State.Health}}" <container>
```

Record: status code, payload keys, cache header, container state transition,
test count. Paste them under the Phase 3 gate, and again under the Phase 7 gate
when the container probe is wired.

---

## 6. Pitfalls

- **Missing `force-dynamic`** → cached body, frozen `timestamp`/`uptimeSeconds`.
- **No probe timeout** → a slow database hangs the endpoint until the pool dies.
- **`curl`/`wget` in the healthcheck** → fails on alpine/distroless images.
- **Always-200** → orchestrators keep routing traffic to a broken instance.
- **Secrets in the payload** → public endpoint leaks credentials.
- **Edge runtime** → `perf_hooks`/V8 metrics are unavailable.
- **Probe churn** → querying the store on every 10 s probe multiplies load; keep
  the probe cheap and cached-free, and never write to the store from it.
