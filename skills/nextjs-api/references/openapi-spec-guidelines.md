# OpenAPI 3.1 API Design Guidelines for Next.js

This guide outlines the architectural rules and conventions required to build RESTful APIs compliant with the [OpenAPI Specification (OAS 3.1)](https://spec.openapis.org/oas/latest.html).

---

## 1. Resource URI Conventions

- **Plural Nouns**: Use plural nouns for resource collections (e.g., `/api/v1/orders`, `/api/v1/users`), never verbs (`/api/v1/getOrders`).
- **Hierarchy for Sub-Resources**: Express relationships through URL nesting:
  - Collection: `/api/v1/projects`
  - Single item: `/api/v1/projects/{projectId}`
  - Nested sub-resource: `/api/v1/projects/{projectId}/tasks`
- **Kebab-Case Paths**: Always use lowercase kebab-case for multi-word path segments (e.g., `/api/v1/order-items`).
- **Query Parameters for Filtering**: Never create separate paths for filtering, sorting, or pagination. Use query parameters:
  - Pagination: `?page=1&limit=20` or cursor-based `?cursor=xyz`
  - Sorting: `?sort=-created_at`
  - Filtering: `?status=active`

---

## 2. HTTP Methods & Idempotency Matrix

| HTTP Method | Operation | Idempotent | Safe | Expected Success Status | Response Body |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | Retrieve resource(s) | Yes | Yes | `200 OK` | Resource or array |
| `POST` | Create resource or execute non-idempotent action | No | No | `201 Created` | Created resource + `Location` header |
| `PUT` | Replace resource completely | Yes | No | `200 OK` / `204 No Content` | Updated resource or empty |
| `PATCH` | Partially update resource | No / Yes* | No | `200 OK` | Updated resource |
| `DELETE` | Remove resource | Yes | No | `204 No Content` | None (empty body) |
| `HEAD` | Retrieve headers only | Yes | Yes | `200 OK` | None (empty body) |
| `OPTIONS` | CORS preflight & allowed verbs | Yes | Yes | `204 No Content` | None |

---

## 3. Standard HTTP Status Codes

### Success Codes
- `200 OK`: Request succeeded. Returned on `GET`, `PUT`, `PATCH` operations returning data.
- `201 Created`: Resource created successfully via `POST`. MUST include `Location: /api/v1/resource/{id}` header.
- `204 No Content`: Action completed successfully with no response body. Standard for `DELETE` and mutation-without-return.

### Client Error Codes
- `400 Bad Request`: General client error or malformed JSON syntax.
- `401 Unauthorized`: Authentication missing or token invalid/expired.
- `403 Forbidden`: Authenticated caller lacks permission/role for this resource.
- `404 Not Found`: Target URI path or entity does not exist.
- `409 Conflict`: Edit collision, duplicate unique key (e.g., email already registered).
- `422 Unprocessable Content`: Payload is valid JSON but violates schema validation rules (Zod validation failure).
- `429 Too Many Requests`: Rate limit threshold exceeded. Include `Retry-After` header.

### Server Error Codes
- `500 Internal Server Error`: Unhandled server exception. Never leak stack traces in production.
- `503 Service Unavailable`: Dependent upstream database or service is offline.

---

## 4. Error Responses: RFC 9457 Problem Details

All error responses from Next.js route handlers MUST follow the [RFC 9457 (Problem Details for HTTP APIs)](https://www.rfc-editor.org/rfc/rfc9457.html) standard with `Content-Type: application/problem+json`:

```json
{
  "type": "https://api.example.com/errors/validation-failed",
  "title": "Unprocessable Content",
  "status": 422,
  "detail": "The request body failed schema validation.",
  "instance": "/api/v1/products",
  "invalid_params": [
    {
      "name": "price",
      "reason": "Expected number, received string"
    }
  ]
}
```

---

## 5. Security & Authentication Schemes

Declare security requirements in the OpenAPI spec and enforce them uniformly:
- **Bearer JWT**: Pass authorization via header: `Authorization: Bearer <token>`.
- **API Key**: Pass via header: `X-API-Key: <key>`.
- **Session Cookie**: Pass via secure HTTP-only cookie.
