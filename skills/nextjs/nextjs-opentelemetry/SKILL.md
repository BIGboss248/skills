---
name: nextjs-opentelemetry
description: >-
  Instrument Next.js with OpenTelemetry. Use when adding tracing, wiring
  instrumentation.ts, configuring an OTLP exporter, or debugging missing spans.
---

# OpenTelemetry Standards

How server tracing is initialized and verified. This skill wires telemetry only.

## Files

| File | Purpose |
| :--- | :--- |
| `instrumentation.ts` (root or `src/`) | Registers the SDK once, server-side |
| `.env.example` / `.env.development` | OTLP endpoint, protocol, service name, kill switch |
| `scripts/mock_collector.js` | Local OTLP/HTTP collector for verification |

Dependencies: `@vercel/otel` and `@opentelemetry/api`.

## Single kill switch

`OTEL_SDK_DISABLED` is the only switch. Never add `OTEL_ENABLED`,
`NEXT_PUBLIC_OTEL_ENABLED`, or any secondary flag: two switches produce states
nobody can reason about.

## The string-truthiness trap

`@vercel/otel` evaluates `!!process.env.OTEL_SDK_DISABLED`. Because
`Boolean("false")` is `true`, writing `OTEL_SDK_DISABLED=false` silently
**disables** tracing. The registration must delete the variable unless it is
exactly `"true"`:

- `if (process.env.OTEL_SDK_DISABLED === "true") return;`
- `delete process.env.OTEL_SDK_DISABLED;`
- then `registerOTel({ serviceName })`.

## Server-only boundary

`instrumentation.ts` runs on the server. Never import it, or a Node SDK package,
into a `"use client"` file.

## Error context

`onRequestError` records the exception on the active span and sets
`next.error.digest`, `next.error.router_kind`, `next.error.route_path`,
`next.error.route_type`, `http.target`, and `http.method`. The digest is the only
key linking a user-facing error to a trace.

## Exporter protocol

- Local debugging: `OTEL_EXPORTER_OTLP_PROTOCOL=http/json` for readable payloads.
- Production: `http/protobuf`.
- Test harnesses: `OTEL_BSP_SCHEDULE_DELAY=1000`, because the default 5000 ms
  makes a working harness look broken.

## Verification

| Check | Expected |
| :--- | :--- |
| Initialization | hook registered, no error |
| Trace dispatch | `POST /v1/traces` → 200, bytes > 0 |
| Kill switch | `OTEL_SDK_DISABLED=true` → skip log, zero exports |
| Type check | 0 errors |

Run the collector and the dev server as separate commands, then make one
request. A green build proves nothing about spans.

## Definition of Done

- [ ] Exactly one switch, `OTEL_SDK_DISABLED`.
- [ ] Non-`"true"` values are deleted before `registerOTel`.
- [ ] `onRequestError` attaches the digest and route attributes.
- [ ] No SDK import reaches a client bundle.
- [ ] Export and kill-switch proofs were both observed.
- [ ] No token, cookie, or customer data appears in a span.

## Edge Cases & Pitfalls

- **Truthiness bug** — `false` disables tracing with no error.
- **Secondary flag** — contradictory state and a silent no-op.
- **Client import** — Node SDK in the browser, then a build failure.
- **No kill-switch proof** — CI and tests export traces nobody asked for.
- **Default batch delay** — five seconds of apparent silence.
- **PII in spans** — tokens and cookies reach the collector.
- **Chained setup** — run install, dev server, and request separately so a
  failure is attributable.

## References

- [Full OTel contract](./references/otel-contract.md)
- [Instrumentation template](./resources/templates/instrumentation.ts.template)
- [Env template](./resources/templates/env.otel.template)
- [Local collector](./scripts/mock_collector.js)
