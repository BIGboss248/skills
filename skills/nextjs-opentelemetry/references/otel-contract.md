# OpenTelemetry Contract

Deep reference for tracing initialization, environment contract, and verification.

## 1. Detection

- `@vercel/otel`, `@opentelemetry/api`, `@opentelemetry/sdk-*` in `package.json`.
- `instrumentation.ts` at the root or under `src/`.
- `OTEL_*` keys already in `.env.example` / `.env.development`.
- Existing collector (Jaeger, Tempo, Honeycomb, Datadog, OTLP port 4318).

## 2. Dependencies & files

- `pnpm add @vercel/otel @opentelemetry/api`.
- Deploy [instrumentation.ts.template](../resources/templates/instrumentation.ts.template)
  to the root or `src/`, matching the detected layout.
- Extend `.env.example` and `.env.development` from
  [env.otel.template](../resources/templates/env.otel.template).

## 3. Non-negotiables

### Single kill switch

`OTEL_SDK_DISABLED` is the only switch. Never add `OTEL_ENABLED`,
`NEXT_PUBLIC_OTEL_ENABLED`, or any secondary flag — two switches produce states
nobody can reason about.

### `@vercel/otel` string-truthiness safeguard

`@vercel/otel` evaluates `!!process.env.OTEL_SDK_DISABLED`. `Boolean("false")` is
`true`, so `OTEL_SDK_DISABLED=false` silently disables tracing. `register()` must
delete the variable when it is not strictly `"true"`:

```ts
if (process.env.OTEL_SDK_DISABLED === "true") return;
delete process.env.OTEL_SDK_DISABLED;
registerOTel({ serviceName: process.env.OTEL_SERVICE_NAME || "nextjs-app" });
```

### Server-only boundary

`instrumentation.ts` runs on the server only. Never import it, or any Node SDK
package, into a `"use client"` component.

### Error context

`onRequestError` records the exception on the active span and sets
`next.error.digest`, `next.error.router_kind`, `next.error.route_path`,
`next.error.route_type`, `http.target`, and `http.method`. The digest is the only
key that ties a user-facing error to a trace.

### Exporter protocol

`OTEL_EXPORTER_OTLP_PROTOCOL=http/json` for local debugging (readable payloads);
`http/protobuf` in high-throughput production. Set
`OTEL_BSP_SCHEDULE_DELAY=1000` in test harnesses so traces flush fast (the default
5000 ms makes harnesses look broken).

## 4. Verification harness

```powershell
node scripts/mock_collector.js
pnpm run dev
curl http://localhost:3000/
```

Expect in the collector log: `POST /v1/traces <bytes>`, and in the Next.js log
`@vercel/otel/otlp: onSuccess 200 OK`. Then restart with
`OTEL_SDK_DISABLED=true` and expect the skip log plus **zero** collector
requests.

Report shape:

| Check | Expected | Status |
| :--- | :--- | :--- |
| Initialization hook | registered | PASS |
| Trace dispatch (active) | `POST /v1/traces` 200, > 0 bytes | PASS |
| Kill switch (disabled) | skipped, 0 traces | PASS |
| Type check | 0 errors | PASS |

## 5. Pitfalls

- **Truthiness bug** → `OTEL_SDK_DISABLED=false` disables tracing with no error.
- **Secondary flag** → contradictory states and a silent no-op.
- **Client import** → bundling the Node SDK into the browser and a build failure.
- **No kill switch proof** → an "enabled" trace always exports, including in CI
  and tests.
- **Default batch delay** → a harness that sees no traces for five seconds and is
  reported as broken.
- **PII in spans** → tokens, cookies, and customer data end up in the collector.
- **Chained setup commands** → run install, dev server, and curl separately.
