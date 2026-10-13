# OpenTelemetry Verification & Reporting Runbook

This guide details the automated test harness and reporting schema for verifying OpenTelemetry tracing in Next.js App Router applications.

---

## 1. Automated Mock Collector Harness

To verify that traces are dispatched without relying on an external Jaeger or Datadog instance:

### Step 1: Run In-Memory Node.js Collector

Start a mock OTLP HTTP collector in the background listening on `http://127.0.0.1:4318`:

```powershell
node -e "const http=require('http'); http.createServer((q,s)=>{let b=''; q.on('data',c=>b+=c); q.on('end',()=>{console.log('[MOCK_COLLECTOR]', q.method, q.url, b.length, 'bytes'); s.writeHead(200,{'Content-Type':'application/json'}); s.end('{}');});}).listen(4318,'127.0.0.1',()=>console.log('[MOCK_COLLECTOR] Ready on port 4318'));"
```

### Step 2: Boot Dev Server & Trigger Requests

Start the Next.js development server:

```powershell
pnpm run dev
```

Send test HTTP requests to generate trace spans:

```powershell
curl http://localhost:3000/
```

### Step 3: Inspect Trace Ingestion

- Verify mock collector logs `POST /v1/traces` with `>0` bytes.
- Confirm Next.js server logs `@vercel/otel/otlp: onSuccess 200 OK`.

### Step 4: Verify Kill Switch (`OTEL_SDK_DISABLED=true`)

Set `OTEL_SDK_DISABLED=true` in `.env.local` or inline:

- Verify Next.js server logs: `[OTel] Instrumentation hook skipped (OTEL_SDK_DISABLED=true).`
- Confirm collector receives `0` bytes / `0` requests.

---

## 2. Verification Report Schema

Output a structured verification report upon completion:

```markdown
# OpenTelemetry Verification Report

## Status Summary

- **OTel Status**: Active / Disabled
- **Service Name**: <configured_service_name>
- **Target Endpoint**: <configured_endpoint>
- **Exporter Protocol**: http/json | http/protobuf

## Verification Results

| Check                   | Expected                 | Actual             | Status |
| :---------------------- | :----------------------- | :----------------- | :----- |
| Initialization Hook     | Registered               | Registered         | PASS   |
| Trace Dispatch (Active) | POST /v1/traces (200 OK) | X batches received | PASS   |
| Kill Switch (Disabled)  | Skipped, 0 traces        | Skipped, 0 traces  | PASS   |
| Type Check              | 0 errors                 | 0 errors           | PASS   |

## Diagnostic Notes

- Notes on payload size, flush timing, or collector configuration.
```

