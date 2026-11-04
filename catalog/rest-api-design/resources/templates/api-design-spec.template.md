# API Design Specification: [Service / Domain Name]

An architectural proposal and contract specification created before implementing REST endpoints.

---

## 1. Domain Context & Target Consumers
- **Service Name**: `[e.g. Order Processing Service]`
- **Target Consumers**: `[e.g., Web SPA Frontend, iOS / Android Apps, 3rd Party Webhook Receivers]`
- **Authentication**: `[e.g., Bearer JWT issued by Auth0 / Better-Auth]`
- **Base URI Path**: `[e.g., /api/v1]`

---

## 2. Resource Hierarchy & Endpoints Matrix

| HTTP Verb | URI Path | Operation Summary | Idempotent | Success Code | Auth Required |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/orders` | List paginated orders | Yes | `200 OK` | Yes |
| `POST` | `/api/v1/orders` | Place a new order | No | `201 Created` | Yes |
| `GET` | `/api/v1/orders/{id}` | Retrieve order details | Yes | `200 OK` | Yes |
| `PATCH` | `/api/v1/orders/{id}` | Update shipping address | Yes | `200 OK` | Yes |
| `POST` | `/api/v1/orders/{id}/cancel` | Cancel order (state action) | No | `200 OK` | Yes |

---

## 3. Query Parameters & Pagination
- **Pagination Strategy**: `[Cursor-based / Offset-based]`
- **Default Limit**: `20`, **Max Limit**: `100`
- **Supported Filter Fields**: `[status, created_after, customer_id]`
- **Supported Sort Fields**: `[createdAt, totalAmount]`

---

## 4. Error Responses (RFC 9457)
All 4xx and 5xx responses must return `Content-Type: application/problem+json` with:
- Standard members: `type`, `title`, `status`, `detail`, `instance`.
- 422 Validation failures must include `invalid_params: [{ name, reason }]`.

---

## 5. Security & Rate Limiting
- **Security Scheme**: `[BearerAuth / ApiKeyAuth]`
- **Rate Limit Policy**: `[e.g., 100 requests per minute per IP or Token, returning 429 + Retry-After]`
- **Idempotency**: `[Idempotency-Key header enforced on state transition POST actions]`
