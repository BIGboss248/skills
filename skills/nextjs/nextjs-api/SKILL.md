---
name: nextjs-api
description: >-
  Write Next.js Route Handlers with OpenAPI 3.1 contracts. Use when adding or
  changing files under app/api/, designing endpoints, or fixing request
  validation and error payloads.
---

# Next.js Route Handler Standards

How a correct HTTP endpoint is built in Next.js 16. This skill writes route
handlers only: it does not plan, verify, or author tests.

## 1. Route Handler or Server Action

| Use | When |
| :--- | :--- |
| `app/api/**/route.ts` | Public or third-party API, mobile client, webhook, streaming (`text/event-stream`) |
| `'use server'` action | Private mutation invoked by this app's own React tree |

Never expose a REST endpoint for a mutation only your own components call.

## 2. Resource and URI modeling

- Plural nouns: `/api/v1/orders`, never `/api/v1/getOrders`.
- Verbs belong to HTTP: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`.
- `GET`, `PUT`, and `DELETE` are safe or idempotent; `POST` is neither.
- Version at the path root, not per resource.
- Decide the auth scheme before writing the handler (bearer JWT, API key, session
  cookie) and state it in the OpenAPI document.
- Framework-agnostic HTTP semantics: `rest-api-design`.

## 3. Contracts

- Request, query, and response models are Zod schemas with `.openapi()`
  metadata; the schema is the single source of both runtime validation and the
  published document.
- Register paths and schemas in the central registry (`lib/openapi.ts`).
- Unknown fields are rejected, not stripped, unless the API documents otherwise.
- Details: [Zod to OpenAPI](./references/zod-to-openapi.md) ·
  [OpenAPI guidelines](./references/openapi-spec-guidelines.md).

## 4. Handler rules

- Await `context.params`, `cookies()`, and `headers()`.
- Validate with `safeParse` and return a `400` problem document on failure.
- Errors use RFC 9457 `application/problem+json` with `type`, `title`, `status`,
  `detail`, and `instance`.
- Forward `request.signal` to upstream calls so a client disconnect cancels work.
- Cache deliberately: `'use cache'` with `cacheLife()` and `cacheTag()`, never by
  accident.
- Streaming endpoints set `Content-Type: text/event-stream` and flush explicitly.
- Patterns and templates: [route patterns](./references/route-handler-patterns.md) ·
  [templates](./resources/templates/).

## 5. Documentation

- Serve the compiled document at `/api/openapi.json`.
- Serve interactive docs at `/api/docs` from a zero-bundle viewer.
- Keep examples in the schema, not only in prose.

## Definition of Done

- [ ] Path, method, and status codes match the resource model.
- [ ] Every input is validated; every failure returns a problem document.
- [ ] The route appears in the OpenAPI registry and the served document.
- [ ] Auth scheme is enforced and documented.
- [ ] Caching is explicit or absent.
- [ ] No test was authored here; `tdd` owns tests.
- [ ] Type checking and the targeted contract check pass.

## Edge Cases & Pitfalls

- **Synchronous params** — Next.js 16 params are promises; awaiting is mandatory.
- **Validation after use** — validating after a database call wastes the request
  and can leak partial writes.
- **Leaking internals** — problem `detail` must not carry stack traces or SQL.
- **Status-code soup** — choose the status from the resource outcome, not from
  the exception type.
- **Unbounded lists** — pagination is part of the contract, not an afterthought.
- **Accidental caching** — a `GET` that reads a session must not be cached
  publicly.
- **Docs drift** — a handler not registered in the registry is invisible to
  clients.

## References

- [OpenAPI spec guidelines](./references/openapi-spec-guidelines.md)
- [Route handler patterns](./references/route-handler-patterns.md)
- [Zod to OpenAPI](./references/zod-to-openapi.md)
- [Templates](./resources/templates/)
- [Working example](./examples/products-api-example.ts)
