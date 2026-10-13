# Database & Dependency Probes Reference

This document outlines the automatic detection rules, timeout strategies, and implementation patterns for database and dependency health probes in Next.js App Router applications.

---

## 1. Dependency Detection Matrix

Before configuring health checks, inspect `package.json` and project files to identify configured state stores:

| Dependency / ORM                | Detection Indicator                                                  | Probe Strategy                                                                                               | Strict Timeout |
| :------------------------------ | :------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------- | :------------- |
| **Prisma**                      | `@prisma/client`, `prisma` in `package.json`, `prisma/schema.prisma` | `await prisma.$queryRaw\`SELECT 1\``                                                                         | 2000ms         |
| **Drizzle ORM**                 | `drizzle-orm` in `package.json`, `drizzle.config.ts`                 | `await db.execute(sql\`SELECT 1\`)`                                                                          | 2000ms         |
| **Supabase**                    | `@supabase/supabase-js`, `@supabase/ssr` in `package.json`           | `await supabase.from('_dummy_health').select('count', { count: 'exact', head: true })` or ping auth endpoint | 2000ms         |
| **Mongoose / MongoDB**          | `mongoose`, `mongodb` in `package.json`                              | Check `mongoose.connection.readyState === 1`                                                                 | 2000ms         |
| **PostgreSQL (`pg`)**           | `pg`, `postgres` in `package.json`                                   | `await pool.query('SELECT 1')`                                                                               | 2000ms         |
| **MySQL (`mysql2`)**            | `mysql2` in `package.json`                                           | `await pool.query('SELECT 1')`                                                                               | 2000ms         |
| **SQLite (`better-sqlite3`)**   | `better-sqlite3` in `package.json`                                   | Synchronously run `db.prepare('SELECT 1').get()`                                                             | N/A (Sync)     |
| **Redis (`ioredis` / `redis`)** | `ioredis`, `redis` in `package.json`                                 | `await redis.ping()`                                                                                         | 1000ms         |
| **No Database Detected**        | None of the above dependencies present                               | **Omit database checks completely.** Provide pure runtime and system metrics.                                | N/A            |

---

## 2. Probe Implementation Guidelines

### 1. Strict Timeout Wrapping

Database calls must never hang the health check endpoint. Always wrap async database pings in `Promise.race` with an explicit timeout rejection:

```ts
async function checkDatabaseConnectivity(): Promise<DependencyCheck> {
  const start = performance.now();
  try {
    await Promise.race([
      // Actual database client ping
      dbClient.ping(),
      new Promise((_, reject) =>
        setTimeout(
          () => reject(new Error("Database probe timed out after 2000ms")),
          2000,
        ),
      ),
    ]);

    return {
      status: "healthy",
      latencyMs: Math.round(performance.now() - start),
    };
  } catch (err: unknown) {
    return {
      status: "unhealthy",
      latencyMs: Math.round(performance.now() - start),
      error: err instanceof Error ? err.message : "Database connection failed",
    };
  }
}
```

### 2. Error Masking & Security

- Never expose sensitive connection strings, credentials, or internal query parameters in the health check error response payload.
- Log detailed connection errors server-side via `console.error` or OpenTelemetry, and return high-level error summaries in the API response.
