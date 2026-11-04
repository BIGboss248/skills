# REST Resource Modeling & URI Design Conventions

A universal standard for URI hierarchy, resource identification, and query parameters adhering to OpenAPI Initiative best practices.

---

## 1. Core Principles of REST URIs

- **Nouns, Never Verbs**: URIs identify *resources* (things), while HTTP methods define *actions* (verbs).
  - ❌ Incorrect: `POST /api/createOrder`, `GET /api/getUsers`, `POST /api/deleteItem`
  - ✅ Correct: `POST /api/v1/orders`, `GET /api/v1/users`, `DELETE /api/v1/items/{id}`
- **Plural Collections**: Use plural nouns consistently for resource collections:
  - `/api/v1/users` (Collection)
  - `/api/v1/users/{userId}` (Single Entity)
- **Kebab-Case Path Segments**: All multi-word path slugs must be lowercase kebab-case:
  - `/api/v1/payment-methods`, `/api/v1/shipping-addresses`
- **Hierarchical Sub-Resources**: Express 1-to-N relationships by nesting, limited to 2 levels maximum:
  - `/api/v1/tenants/{tenantId}/users`
  - `/api/v1/articles/{articleId}/comments/{commentId}`
  - *Anti-Pattern*: Deep nesting beyond 2 levels (`/teams/{tId}/projects/{pId}/boards/{bId}/cards/{cId}`). Instead, promote deep resources to top-level collections with query filters: `/api/v1/cards?boardId={bId}`.

---

## 2. Controller Pattern (Non-CRUD Operations)

When an operation represents a complex business workflow or state transition that does not map cleanly to standard CRUD (e.g., checkout, cancel, publish, verify):

1. **Sub-resource State Action**: Use a `POST` request to a sub-resource verb:
   - `POST /api/v1/orders/{orderId}/cancel`
   - `POST /api/v1/articles/{articleId}/publish`
   - `POST /api/v1/auth/reset-password`
2. **Batch Operations**:
   - `POST /api/v1/inventory/batch-update`
3. Always make state actions safe against double-execution using an `Idempotency-Key` request header.

---

## 3. Query Parameter Standards

Never create new paths for filtering, sorting, pagination, or projection. Use standard query parameters:

### A. Pagination (Two Canonical Flavors)
1. **Offset-Based** (Simple, UI page grids):
   - `?page=1&limit=25` (defaults: `page=1`, `limit=20`, `max=100`)
2. **Cursor-Based** (Recommended for large datasets, infinite scrolls, real-time feeds):
   - `?cursor=eyJpZCI6MTAxfQ==&limit=50`

### B. Filtering
- Use exact match: `?status=active&category=electronics`
- Use comparison operators via brackets or prefixes:
  - Range: `?created_after=2026-01-01T00:00:00Z` or `?price[gte]=100&price[lte]=500`
  - Multiple values (IN): `?status=pending,approved`

### C. Sorting
- Use comma-separated fields with `-` prefix for descending order:
  - Ascending: `?sort=createdAt`
  - Descending: `?sort=-createdAt`
  - Multi-column: `?sort=-priority,createdAt`

### D. Sparse Fieldsets (Field Projection)
- Allow clients to request only required attributes to minimize payload size:
  - `?fields=id,title,price`
