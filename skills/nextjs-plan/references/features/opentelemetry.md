# Feature Pack: OpenTelemetry (OTel) Observability

Plan tracing as **Phase 4** items (initialization + env contract), with the
harness script in **Phase 2** and the exporter destination in **Phase 7**.

---

## 1. Detection (before asking)

- `@vercel/otel`, `@opentelemetry/api`, `@opentelemetry/sdk-*` in `package.json`.
- `instrumentation.ts` at the root or under `src/`.
- `OTEL_*` keys already in `.env.example` / `.env.development`.
- Existing collector (Jaeger, Tempo, Honeycomb, Datadog, OTEL collector port 4318).

---

## 2. Plan items to generate

| Item | Title | Acceptance shape |
| :--- | :--- | :--- |
| 2.x | Trace harness script | `node scripts/mock_collector.js` logs `Ready on port 4318` |
| 4.5 | Telemetry init | a request emits a span to the collector (`POST /v1/traces` → 200) |
| 4.5b | Kill switch | `OTEL_SDK_DISABLED=true` → `[OTel] Instrumentation hook skipped`, 0 exports |
| 7.x | Exporter destination | production collector endpoint configured; no secret in the image |

The Phase 4 gate must cite both the export proof and the kill-switch proof.

---

## 3. Dependencies & files

```powershell
pnpm add @vercel/otel @opentelemetry/api
```

- Deploy [instrumentation.ts.template](../../resources/templates/otel/instrumentation.ts.template)
  to the project root or `src/`, matching the detected layout.
- Extend `.env.example` and `.env.development` from
  [env.otel.template](../../resources/templates/otel/env.otel.template).

---

## 4. Non-negotiables

### Single kill switch

`OTEL_SDK_DISABLED` is the only switch. **Never** add `OTEL_ENABLED`,
`NEXT_PUBLIC_OTEL_ENABLED`, or any secondary flag — two switches produce states
nobody can reason about.

### `@vercel/otel` string-truthiness safeguard

`@vercel/otel` evaluates `!!process.env.OTEL_SDK_DISABLED`. `Boolean("false")` is
`true`, so `OTEL_SDK_DISABLED=false` silently disables tracing. `register()` must
delete the variable when it is not strictly `"true"`:

```ts
if (process.env.OTEL_SDK_DISABLED === "true") return;
if (process.env.OTEL_SDK_DISABLED !== "true") delete process.env.OTEL_SDK_DISABLED;
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
`OTEL_BSP_SCHEDULE_DELAY=1000` in test harnesses so traces flush fast (default
5000 ms makes harnesses look broken).

---

## 5. Verification harness

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

---

## 6. Pitfalls

- **Truthiness bug** → `OTEL_SDK_DISABLED=false` disables tracing with no error.
- **Secondary flag** → contradictory states and a silent no-op.
- **Client import** → bundling the Node SDK into the browser and a build failure.
- **No kill switch proof** → an "enabled" trace always exports, including in CI
  and tests.
- **Default batch delay** → a harness that sees no traces for five seconds and is
  reported as broken.
- **PII in spans** → tokens, cookies, and customer data end up in the collector.
- **Chained setup commands** → run install, dev server, and curl separately.
