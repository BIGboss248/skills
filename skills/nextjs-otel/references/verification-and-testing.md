# OpenTelemetry Verification & Testing Runbook

This guide details the automated test harness, verification procedures, and reporting schema for verifying OpenTelemetry tracing in Next.js App Router applications.

---

## 1. Automated Mock Collector Harness

To verify trace dispatch without needing external infrastructure (e.g., Jaeger, Datadog, Honeycomb), run an in-memory Node.js HTTP mock collector.

### Step 1: Start In-Memory Collector

Run the mock collector in the background listening on `http://127.0.0.1:4318`:

**Inline Node.js**:

```powershell
node -e "const http=require('http'); http.createServer((q,s)=>{let b=''; q.on('data',c=>b+=c); q.on('end',()=>{console.log('[MOCK_COLLECTOR]', q.method, q.url, b.length, 'bytes'); s.writeHead(200,{'Content-Type':'application/json'}); s.end('{}');});}).listen(4318,'127.0.0.1',()=>console.log('[MOCK_COLLECTOR] Ready on port 4318'));"
```

**Or using helper script**:

```powershell
node .agents/skills/nextjs-otel/scripts/mock_collector.js
```

---

## 2. Execution & Verification Steps

### Step 2: Boot Development Server

Start the Next.js development server:

```powershell
pnpm run dev
```

### Step 3: Trigger Trace Requests

Send HTTP requests to route pages or API endpoints:

```powershell
curl http://localhost:3000/
```

### Step 4: Verify Active Trace Dispatch

1. **Mock Collector Log**: Confirm receipt of `POST /v1/traces` with `>0` bytes:
   ```text
   [MOCK_COLLECTOR] POST /v1/traces 1420 bytes
   ```
2. **Next.js Server Log**: Confirm success acknowledgment:
   ```text
   @vercel/otel/otlp: onSuccess 200 OK
   ```

### Step 5: Verify Kill Switch (`OTEL_SDK_DISABLED=true`)

1. Set `OTEL_SDK_DISABLED=true` in environment:
   ```powershell
   $env:OTEL_SDK_DISABLED="true"
   pnpm run dev
   ```
2. Send test request:
   ```powershell
   curl http://localhost:3000/
   ```
3. Confirm:
   - Next.js server logs: `[OTel] Instrumentation hook skipped (OTEL_SDK_DISABLED=true).`
   - Collector receives `0` bytes / `0` requests.

---

## 3. Verification Report Template

After completing setup or verification, output a structured Markdown report:

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
