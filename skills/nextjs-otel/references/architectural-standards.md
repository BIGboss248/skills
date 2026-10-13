# Architectural Standards & Guardrails: Next.js OpenTelemetry

This document defines the core architectural principles, bug mitigations, runtime boundaries, and conventions when integrating OpenTelemetry with the Next.js App Router.

---

## 1. The Single Kill Switch Principle (`OTEL_SDK_DISABLED`)

### The Problem with Custom Flags

Developers often introduce flags like `OTEL_ENABLED=true/false` alongside standard OpenTelemetry flags. This introduces:

- **Ambiguous State**: `OTEL_ENABLED=true` while `OTEL_SDK_DISABLED=true`.
- **Specification Deviation**: The official OpenTelemetry specification defines `OTEL_SDK_DISABLED` as the canonical standard.
- **Maintenance Burden**: Multi-environment configurations become error-prone.

### Standardized Rule

- Standardize exclusively on `OTEL_SDK_DISABLED`.
- `OTEL_SDK_DISABLED=true`: Completely skips registration and disables all tracing hooks.
- `OTEL_SDK_DISABLED=false` (or unset/empty): Enables OpenTelemetry SDK and exports spans.
- **Never** introduce secondary flags like `OTEL_ENABLED` or `NEXT_PUBLIC_OTEL_ENABLED`.

---

## 2. The `@vercel/otel` String Truthiness Safeguard

### Root Cause Analysis

In `@vercel/otel` internals, the initialization check inspects the environment variable using double-negation:

```javascript
// Internal @vercel/otel logic:
let disabled = !!process.env.OTEL_SDK_DISABLED;
if (disabled) return;
```

In JavaScript and Node.js environments:

- `Boolean("false")` evaluates to `true`.
- `Boolean("0")` evaluates to `true`.
- `!!"false"` evaluates to `true`.

Consequently, setting `OTEL_SDK_DISABLED=false` in `.env` causes `@vercel/otel` to mistakenly evaluate the string as truthy, completely disabling the OpenTelemetry SDK silently!

### The Mitigation Workaround

Before calling `registerOTel()`, verify whether `process.env.OTEL_SDK_DISABLED` is strictly `"true"`. If it is not strictly `"true"`, delete the environment variable from `process.env`:

```typescript
export function register() {
  if (process.env.OTEL_SDK_DISABLED === "true") {
    console.log(
      "[OTel] Instrumentation hook skipped (OTEL_SDK_DISABLED=true).",
    );
    return;
  }

  // Workaround for @vercel/otel truthiness bug:
  if (process.env.OTEL_SDK_DISABLED !== "true") {
    delete process.env.OTEL_SDK_DISABLED;
  }

  registerOTel({
    serviceName: process.env.OTEL_SERVICE_NAME || "nextjs-app",
  });
}
```

---

## 3. Server-Only Execution Scope

### Runtime Boundaries

- `instrumentation.ts` runs strictly on the Node.js or Edge runtime when the Next.js server boots.
- Telemetry packages (`@vercel/otel`, `@opentelemetry/api`, `@opentelemetry/sdk-trace-node`) use Node.js-specific modules (`perf_hooks`, `async_hooks`, `http`).
- **Never** import `instrumentation.ts` or server OpenTelemetry packages into React Client Components (`"use client"`).

---

## 4. Rich Error Tracking via `onRequestError`

Next.js 15+ provides the `onRequestError` export in `instrumentation.ts` to capture server errors during request handling and rendering.

### Captured Context Properties

| Context Key    | Type                                         | Description                                           |
| :------------- | :------------------------------------------- | :---------------------------------------------------- |
| `routerKind`   | `"Pages Router" \| "App Router"`             | Router type handling the request                      |
| `routePath`    | `string`                                     | Target page or API route path                         |
| `routeType`    | `"render" \| "route" \| "action" \| "proxy"` | Execution type (RSC render, Server Action, etc.)      |
| `renderSource` | `string`                                     | Rendering phase (`react-server-components`, etc.)     |
| `digest`       | `string`                                     | Unique Next.js error digest for telemetry correlation |

### Span Attribute Mapping

When `onRequestError` is invoked, record the exception onto the active span and set semantic attributes:

```typescript
span.recordException(err instanceof Error ? err : String(err));
span.setStatus({ code: SpanStatusCode.ERROR, message: ... });
span.setAttribute("next.error.digest", digest);
span.setAttribute("next.error.router_kind", context.routerKind);
span.setAttribute("next.error.route_path", context.routePath);
span.setAttribute("next.error.route_type", context.routeType);
span.setAttribute("http.target", request.path);
span.setAttribute("http.method", request.method);
```

---

## 5. Exporter Protocols and Batching

- **Protocol**: `OTEL_EXPORTER_OTLP_PROTOCOL=http/json` is recommended for local development and debugging because trace payloads can be logged and inspected as clean JSON. Use `http/protobuf` in high-throughput production environments.
- **Batch Schedule Delay (`OTEL_BSP_SCHEDULE_DELAY`)**: The default batch processor interval is 5000ms. In local testing or test harnesses, set `OTEL_BSP_SCHEDULE_DELAY=1000` to ensure traces flush rapidly after HTTP requests.
