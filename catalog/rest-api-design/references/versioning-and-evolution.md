# API Versioning, Evolution & Deprecation Standards

A guide to versioning strategies, non-breaking change policies, and sunsetting endpoints without breaking client integrations.

---

## 1. Versioning Strategy Comparison

| Strategy | Syntax | Pros | Cons | Recommendation |
| :--- | :--- | :--- | :--- | :--- |
| **URI Path** | `/api/v1/orders` | Highest developer clarity, easy browser caching, straightforward routing | Multiple versions duplicate routing trees | **Recommended for public/external APIs** |
| **Header / Content Negotiation** | `Accept: application/vnd.company.v1+json` | Purest REST principle, URLs remain clean | Difficult to test in browser, CDN cache fragmentation | Internal microservices |
| **Custom Header** | `X-API-Version: 2026-10-01` | Easy to pass via client SDKs | Hidden routing state, difficult to debug from access logs | Webhooks / Stripe-style date versions |

---

## 2. Non-Breaking vs Breaking Changes

Always prefer non-breaking API evolution over incrementing the major version.

### Non-Breaking Changes (Safe to deploy to `/v1/` without version bump):
- Adding a new optional request field or query parameter.
- Adding a new field to an existing response payload (clients must ignore unknown fields).
- Adding a completely new endpoint or HTTP verb to an existing resource.
- Adding support for a new media type in `Accept` / `Content-Type`.

### Breaking Changes (Requires new major version `/v2/`):
- Renaming or deleting an existing endpoint or HTTP verb.
- Renaming or removing a field from a request or response payload.
- Changing the data type of an existing field (e.g., number to string).
- Adding a new **required** request body field or header.
- Modifying authentication or authorization requirements.

---

## 3. Deprecation and Sunset Protocol

When deprecating an endpoint, follow RFC 8594 (The Sunset and Deprecation HTTP Headers):

1. **Mark in OpenAPI Specification**:
   ```yaml
   /api/v1/legacy-endpoint:
     get:
       deprecated: true
       summary: Legacy resource (Deprecated)
   ```
2. **Emit HTTP Response Headers**:
   ```http
   Deprecation: @1793577600
   Sunset: Wed, 11 Nov 2027 00:00:00 GMT
   Link: <https://api.example.com/docs/migration-v2>; rel="deprecation"
   ```
3. Provide a minimum **6-month notice period** before hard-decommissioning deprecated endpoints.
