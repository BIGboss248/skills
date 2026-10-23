# HTTP Methods Semantics & Status Code Matrix

Universal reference based on RFC 9110 (HTTP Semantics) and OpenAPI Specification standards.

---

## 1. HTTP Methods Matrix: Safety & Idempotency

- **Safe**: Calling the endpoint never modifies server state (read-only).
- **Idempotent**: Calling the endpoint multiple times with identical arguments produces the exact same server state as calling it once.

| Method | Operation | Safe | Idempotent | Success Code | Response Body |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | Read resource or collection | **Yes** | **Yes** | `200 OK` | Requested data |
| `HEAD` | Read metadata / headers | **Yes** | **Yes** | `200 OK` | Empty body (headers only) |
| `OPTIONS` | Discover CORS & supported verbs | **Yes** | **Yes** | `204 No Content` | Empty body (`Allow` header) |
| `POST` | Create resource / run action | **No** | **No** | `201 Created` / `200 OK` / `202 Accepted` | Created entity + `Location` |
| `PUT` | Complete replace of resource | **No** | **Yes** | `200 OK` / `204 No Content` | Replaced entity or empty |
| `PATCH` | Partial update of resource | **No** | **No / Yes\*** | `200 OK` | Updated entity |
| `DELETE` | Remove resource | **No** | **Yes** | `204 No Content` | Empty body |

*\*Note on `PATCH`: While JSON Merge Patch (RFC 7396) is typically idempotent, operations like increment/append are non-idempotent.*

---

## 2. Standard HTTP Status Codes Catalog

### 2xx Success Codes
- `200 OK`: Standard success response for `GET`, `PUT`, `PATCH`, or non-creation `POST`.
- `201 Created`: Resource successfully created via `POST`. **MUST** include `Location: /api/v1/resource/{id}` response header.
- `202 Accepted`: Request accepted for asynchronous/batch processing, but processing is not yet complete. Include status probe URI in `Location`.
- `204 No Content`: Request succeeded, but there is intentionally no response body. Mandatory for `DELETE` and options preflight.

### 3xx Redirection Codes
- `301 Moved Permanently`: Resource relocated permanently.
- `304 Not Modified`: Cached copy on client is valid (used with `If-None-Match` / `ETag`).

### 4xx Client Error Codes
- `400 Bad Request`: Malformed payload syntax, invalid JSON, or missing required headers.
- `401 Unauthorized`: Missing, invalid, or expired authentication credentials.
- `403 Forbidden`: Client is authenticated, but lacks authorization/permission for this resource.
- `404 Not Found`: Target resource URI does not exist.
- `405 Method Not Allowed`: HTTP verb not supported for this URI. Include `Allow: GET, POST` header.
- `409 Conflict`: Request conflicts with current state (e.g. duplicate unique key, concurrent edit mismatch).
- `410 Gone`: Resource existed previously but has been permanently deleted with no forwarding address.
- `412 Precondition Failed`: ETag / conditional precondition failed (`If-Match`).
- `415 Unsupported Media Type`: Payload format not supported (e.g., sent XML instead of `application/json`).
- `422 Unprocessable Content`: Payload syntax is valid JSON, but violates business validation rules (Zod, Pydantic, JSON Schema).
- `429 Too Many Requests`: Client exceeded rate limit quota. Include `Retry-After: <seconds>` header.

### 5xx Server Error Codes
- `500 Internal Server Error`: Unhandled server exception. Never expose internal stack traces in client responses.
- `502 Bad Gateway`: Invalid response from an upstream server (reverse proxy / microservice).
- `503 Service Unavailable`: Server or dependent database is temporarily overloaded or undergoing maintenance.
- `504 Gateway Timeout`: Upstream service timed out.

---

## 3. Concurrency Control with ETags

For critical update operations (`PUT`, `PATCH`), prevent the "lost update" problem:
1. Server returns `ETag: "v3-abc123hash"` on `GET`.
2. Client sends `If-Match: "v3-abc123hash"` on `PUT` / `PATCH`.
3. If server state changed in the interim, server rejects with `412 Precondition Failed`.
