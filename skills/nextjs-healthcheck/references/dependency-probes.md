# Database & Dependency Health Probe Matrix

This guide details automated database discovery rules and health probe strategies for Next.js App Router applications.

---

## Detection Checklist (`package.json` & Project Files)

| Dependency / ORM | Indicators in Project | Health Probe Strategy |
| :--- | :--- | :--- |
| **Prisma** | `@prisma/client`, `prisma` in `package.json`, `prisma/schema.prisma` | `await prisma.$queryRaw\`SELECT 1\`` with a 2-second timeout. |
| **Drizzle ORM** | `drizzle-orm` in `package.json`, `drizzle.config.ts` | `await db.execute(sql\`SELECT 1\`)` with a 2-second timeout. |
| **Supabase** | `@supabase/supabase-js`, `@supabase/ssr` | `await supabase.from('_dummy_health').select('count', { count: 'exact', head: true })` or ping auth endpoint. |
| **Mongoose / MongoDB** | `mongoose`, `mongodb` in `package.json` | Check `mongoose.connection.readyState === 1` or ping admin db. |
| **PostgreSQL (`pg`)** | `pg`, `postgres` in `package.json` | `await pool.query('SELECT 1')` with a 2-second timeout. |
| **MySQL (`mysql2`)** | `mysql2` in `package.json` | `await pool.query('SELECT 1')` with a 2-second timeout. |
| **SQLite (`better-sqlite3`)** | `better-sqlite3` in `package.json` | Synchronously run `db.prepare('SELECT 1').get()`. |
| **Redis (`ioredis` / `redis`)** | `ioredis`, `redis` in `package.json` | `await redis.ping()` with a 1-second timeout. |
| **No Database Detected** | None of the above dependencies present | **Omit all database checks completely.** Provide pure runtime & system metrics. |

---

## Core Runtime Metrics Thresholds

### 1. V8 Heap Saturation
$$\text{Heap Utilization (\%)} = \left(\frac{\text{used\_heap\_size}}{\text{heap\_size\_limit}}\right) \times 100$$
- `< 80%`: `healthy`
- `80% - 90%`: `degraded` (memory pressure)
- `> 90%`: `unhealthy` (imminent OOM kill)

### 2. Event Loop Lag (`perf_hooks.monitorEventLoopDelay`)
- $p99 < 100\text{ms}$: `healthy`
- $100\text{ms} \le p99 \le 500\text{ms}$: `degraded`
- $p99 > 500\text{ms}$: `unhealthy` (event loop frozen)

