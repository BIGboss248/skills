---
name: rest-api-design
description: >-
  Design REST APIs to OpenAPI 3.1 and RFC contracts. Use when modeling resources,
  choosing status codes, writing schemas, or auditing API conformance.
---

# REST API Design Standard

Framework-agnostic HTTP and OpenAPI rules. This skill defines the contract only.

## 1. Resources and URIs

- Plural collection nouns: `/orders`, not `/getOrders`.
- Nested resources at most two levels: `/tenants/{id}/users`.
- Non-CRUD transitions are sub-resource controllers:
  `POST /orders/{id}/cancel`.
- Filtering, sorting, and pagination are standard query parameters, and the
  cursor/offset choice is part of the contract.
- Reference: [resource modeling and URIs](./references/resource-modeling-and-uris.md).

## 2. Methods and status codes

- `GET` safe, `PUT` full replace, `PATCH` partial, `DELETE` remove.
- Canonical codes: `200`, `201` with `Location`, `204`, `400`, `401`, `403`,
  `404`, `409`, `422`, `429`, `500`.
- Concurrency uses `ETag` and `If-Match`, not a bespoke version field.
- Matrix: [methods and status codes](./references/http-methods-and-status-codes.md).

## 3. Schemas and OpenAPI 3.1

- Target OpenAPI 3.1.0 with JSON Schema 2020-12 (`type: ["string", "null"]`).
- Separate entity, create-input, and update-input schemas. A create input never
  accepts `id` or timestamps.
- Templates: [OpenAPI starter](./resources/templates/openapi-v3.1.template.yaml) ·
  [design spec](./resources/templates/api-design-spec.template.md).
- Structure: [OpenAPI 3.1 guide](./references/openapi-3-1-spec-structure.md).

## 4. Errors and security

- Every error is RFC 9457 Problem Details with
  `application/problem+json`.
- `422` carries `invalid_params: [{ name, reason }]`.
- Security schemes live in `components.securitySchemes` (bearer, API key,
  OAuth2).
- References: [RFC 9457](./references/rfc9457-problem-details.md) ·
  [problem schema](./resources/templates/problem-details.schema.yaml).

## 5. Versioning and evolution

- Public APIs use URI path versioning (`/api/v1/`).
- Evolution is additive; deprecation uses RFC 8594 `Sunset` headers.
- Reference: [versioning and deprecation](./references/versioning-and-evolution.md).
- Worked example: [order API](./examples/order-management-api.openapi.yaml).

## Definition of Done

- [ ] Resources, methods, and status codes are consistent across the document.
- [ ] Every error path returns a problem document.
- [ ] Create and update schemas differ from the entity schema.
- [ ] Pagination and filtering are specified, not implied.
- [ ] Security schemes are declared globally.
- [ ] The specification validates against OpenAPI 3.1.

## Edge Cases & Pitfalls

- **Verb in the path** — RPC habits leak into REST routes.
- **`200` for everything** — clients cannot distinguish outcomes.
- **Entity reuse for input** — accepting `id` invites mass assignment.
- **Nullable drift** — 3.0 `nullable: true` is invalid in 3.1.
- **Pagination afterthought** — an unbounded list is a production incident.
- **Error shape per endpoint** — one problem format, everywhere.
- **Breaking change disguised as additive** — removing or retyping a field is
  breaking even if the path version did not change.

## References

- [Resource modeling and URIs](./references/resource-modeling-and-uris.md)
- [HTTP methods and status codes](./references/http-methods-and-status-codes.md)
- [OpenAPI 3.1 structure](./references/openapi-3-1-spec-structure.md)
- [RFC 9457 problem details](./references/rfc9457-problem-details.md)
- [Versioning and evolution](./references/versioning-and-evolution.md)
- [Templates](./resources/templates/)
- [Worked example](./examples/order-management-api.openapi.yaml)
