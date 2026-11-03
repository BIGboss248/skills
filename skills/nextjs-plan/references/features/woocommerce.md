# Feature Pack: Headless WooCommerce

Plan a Next.js App Router storefront backed by WooCommerce (WPGraphQL +
WooGraphQL + JWT). The pack spans **Phase 1** (ownership, auth contracts),
**Phase 2** (backend orchestration), **Phase 5** (catalog pages), **Phase 6**
(queries, actions, callbacks), and **Phase 7** (production stack). Phase 5 stays
the only page inventory; the pack adds per-page acceptance lines.

Deep references:

- [storefront-reference.md](./woocommerce/storefront-reference.md)
  — queries, fetcher, registration, JWT, profile, cart, checkout bridge, `wc-api`.
- [windows-local-dev.md](./woocommerce/windows-local-dev.md) — ports, Traefik, hosts,
  volumes, container patches, troubleshooting.
- [verification-playbook.md](./woocommerce/verification-playbook.md) — copy-paste
  routing, GraphQL, auth, cart, and build checks.

Templates: [woocommerce-fetcher.ts](../../resources/features/woocommerce/woocommerce-fetcher.ts),
[docker-compose.local.yml](../../resources/features/woocommerce/docker-compose.local.yml),
[dev-traefik/](../../resources/features/woocommerce/dev-traefik/).

> Backend provisioning (plugins, options, seeds) belongs to the
> `headless-woocommerce-api` skill; this pack plans the storefront that consumes it.

---

## 1. Interview questions the plan must answer

1. **Architecture** — single-domain reverse proxy (Traefik/Caddy) or decoupled
   origins? Local and production domains?
2. **Host** — Windows, macOS, Linux? On Windows, is WSL2 healthy (port
   exclusions, bind-mount performance)?
3. **TLS** — `mkcert` trust or the proxy's self-signed default? Can the user
   accept a warning or elevate for a hosts edit?
4. **Catalog** — simple products only, or variable products with attributes?
   Variable products are required to validate `fill_cart`.
5. **Checkout** — native `/checkout` transfer via `fill_cart` (recommended for
   regional gateways) or the WooGraphQL `checkout` → `order-pay` mutation?
6. **Payments** — COD, ZarinPal sandbox, Zibal, other? Sandbox needs no merchant
   contract (UUID in `merchantcode`).
7. **Persistence** — disposable local database or data that must survive
   container recreation?

---

## 2. Plan items to generate

| Phase | Item | Acceptance shape |
| :--- | :--- | :--- |
| 1 | Ownership + auth contracts | every WooCommerce path in `runtime_topology.ownership`; `auth.requires_single_hostname` recorded |
| 2 | Backend orchestration | `docker compose up -d` → WordPress + DB healthy; `/graphql` answers an introspection query |
| 2 | Container patch idempotency | re-run `patch-wordpress.ps1` → `pdo_mysql` present, `/wp-admin` 200 (no `could not find driver`) |
| 4 | Env contract | `NEXT_PUBLIC_WORDPRESS_API_URL`, `NEXT_PUBLIC_WORDPRESS_URL`, `NEXT_PUBLIC_BASE_URL` in both env files |
| 5 | Catalog pages | `/products` and `/products/[slug]` render seeded products; ISR `revalidate: 300`, `tags: ['products']` |
| 5 | Account surfaces | `/login`, `/register`, `/account` with loading/error/metadata tasks |
| 6 | GraphQL fetcher | dual auth headers, session header, returns `json.data` on HTTP 403 |
| 6 | Cart + checkout bridge | `addToCart` returns `woocommerce-session`; a follow-up query retains the item |
| 6 | Gateway callback route | `/wc-api/<Gateway>/` (POST, trailing slash) → 307 to `/checkout/?wc-api=...` |
| 7 | Production stack + critical-flow proof | one real order completes end-to-end |

Every auth, cart, and money item needs a **negative case**; every seed or patch
step needs an **idempotency** line.

---

## 3. Local orchestration (Phase 2)

- **Single domain** — serve Next.js and WordPress on one host (`shop.local`,
  `shop.example.com`) so cookies are first-party.
- **Edge routing** — WordPress router (priority 100): `/checkout`, `/my-account`,
  `/wp-admin`, `/wp-login.php`, `/wp-content`, `/wp-includes`, `/wp-json`,
  `/graphql`, `QueryRegexp('wc-ajax', '.+')`, `QueryRegexp('wc-api', '.+')`.
  Next.js router (priority 10): catch-all for `/`, `/products`, `/cart`,
  `/_next/*`. **Do not route `/wc-api` to WordPress**; Next.js middleware 307s it.
- **Ports** — on Windows run
  `netsh interface ipv4 show excludedportrange protocol=tcp`; if 3000/3001 sit in
  a reserved block (2929–3028 is common) use **4000** and update
  `package.json`, `playwright.config.ts`, `serverActions.allowedOrigins`, and the
  proxy target together.
- **TLS** — for `.local`, `tls=true` without a resolver (proxy default cert);
  keep `NODE_TLS_REJECT_UNAUTHORIZED=0` for dev **and build-time fetches**, never
  in production.
- **Hosts entry** — elevated `127.0.0.1 shop.local` + `::1 shop.local`; verify
  with `Resolve-DnsName shop.local`.
- **WordPress state** — named volumes for core and MySQL, bind only
  `mu-plugins` and `uploads.ini`; `WORDPRESS_CONFIG_EXTRA` (evaluated at runtime)
  sets `WP_HOME`, `WP_SITEURL`, `WP_ENVIRONMENT_TYPE=local`, `DISABLE_WP_CRON`,
  `WP_POST_REVISIONS=false`, `FORCE_SSL_ADMIN`, and
  **`GRAPHQL_JWT_AUTH_SECRET_KEY`**.
- **Container-layer patches** — `pdo_mysql` and WP-CLI vanish on recreation;
  re-run the patch script after every `up`/`down`/image update.

---

## 4. Data, auth, and session rules (Phases 5–6)

- **Universal fetcher** — send `Authorization: Bearer` **and** `X-JWT-Auth`,
  forward `woocommerce-session`, use ISR tags, and return `json.data` when
  WordPress answers HTTP 403 with a valid payload.
- **Catalog** — `productCategories(hideEmpty: true)` for navigation; query
  `products` with inline fragments (`... on SimpleProduct`, `... on
  VariableProduct`) — never `price`/`variations` on the base `Product`; decode
  HTML entities (`&nbsp;`, currency symbol) before rendering.
- **Registration** — enable registration, default role **Customer**, disable
  auto-generated passwords; `registerCustomer` in a Server Action; strip HTML
  from errors. The payload can return `null` fields even on success — re-query
  `customer`/`viewer` after login.
- **JWT** — `login` returns `authToken`, `refreshToken`, `customer.sessionToken`;
  store `authToken` in an `HttpOnly`, `SameSite=Lax` cookie (7 days) and
  `sessionToken` in `wc_session`. Default plugin expiry is **300 s**;
  `graphql_jwt_auth_expire` takes **seconds**, not a timestamp. Drop expired
  tokens (`exp`) instead of sending them.
- **Cart** — resend `woocommerce-session` as `Session <token>` on every mutation;
  include `variation { node { id databaseId name price regularPrice salePrice } }`
  in `GET_CART_QUERY`.
- **Native checkout** — redirect to
  `/checkout/?fill_cart=productId:qty:variationId,...` (never `?add-to-cart=` for
  variable products); handle `fill_cart` in `mu-plugins/headless-redirects.php` on
  `template_redirect` priority 1, call `WC()->session->set_customer_session_cookie(true)`,
  save the session, then `wp_safe_redirect(wc_get_checkout_url())`.
- **Gateway callbacks** — `next.config.ts` sets `skipTrailingSlashRedirect: true`;
  `middleware.ts` issues a method-preserving 307 from `/wc-api/*`,
  `/index.php/wc-api/*`, and `?wc-api=*` to `/checkout/?wc-api=...` with
  `Cache-Control: no-store`; `headless-redirects.php` filters
  `woocommerce_api_request_url`; `woocommerce_ajax_get_endpoint` maps to
  `/checkout/?wc-ajax=<endpoint>`.
- **Account handoff** — logged-in `/my-account/` visitors go to Next.js
  `/account`; inject hidden `redirect_to` fields into the WordPress login/register
  forms and prioritize `redirect_to`.

---

## 5. Verification

Run [verification-playbook.md](./woocommerce/verification-playbook.md) and paste
counts, not adjectives:

- [ ] `https://shop.local/products` → 200 with seeded products.
- [ ] `pnpm build` succeeds (local `NEXT_PUBLIC_*` values + build TLS override).
- [ ] `login` returns `authToken`; the cookie is set and `/account` renders.
- [ ] Registration creates a `customer`-role account.
- [ ] Profile resolves `viewer` + `customer` with billing and orders.
- [ ] `addToCart` returns `woocommerce-session`; a follow-up cart query retains it.
- [ ] `/wc-api/<Gateway>/` → 307 to `/checkout/?wc-api=<Gateway>` for GET **and** POST.
- [ ] ZarinPal sandbox completes a sandbox order through `/checkout/?wc-api=WC_ZPal`.
- [ ] `?wc-ajax=` reaches WordPress, not Next.js HTML.
- [ ] `/wp-admin/` → 200 after login (no `could not find driver`).

---

## 6. Pitfalls

1. **HTTP 403 with valid Bearer tokens** — return `json.data` when present; never
   discard the payload on `!res.ok`.
2. **Dual auth headers** — some hosts strip one of `Authorization` / `X-JWT-Auth`.
3. **Cross-origin empty cart** — third-party cookies are blocked; use the native
   checkout bridge.
4. **Expired JWT** — 403s on cart mutations; validate `exp` and clear the cookie.
5. **Restricted viewer fields** — `capabilities`/`nicename` need admin caps.
6. **Auto-generated registration password** — overrides the submitted password.
7. **Cookie reads de-opt routes to SSR** — keep auth reads inside account/login
   subtrees, not the root layout or product pages.
8. **Polymorphic fragments** — pricing and variations need inline fragments.
9. **Session loss** — a missing `woocommerce-session` header creates a new empty
   cart per mutation.
10. **SPA interception** — WordPress redirects need absolute URLs with trailing
    slashes, rendered as plain `<a>` tags.
11. **Account dashboard lock-in** — hook `template_redirect` to send logged-in
    users back to Next.js.
12. **`redirect_to` loss** — hidden fields + filter priority.
13. **Windows Docker I/O** — named volumes for core/MySQL, bind only active
    folders, `DISABLE_WP_CRON`, `WP_POST_REVISIONS=false`.
14. **Dormant Iranian gateways** — use sandbox or COD locally.
15. **Variable checkout loops** — `?add-to-cart=` fails without attributes.
16. **Recreated containers** — `pdo_mysql`/WP-CLI gone → HTTP 500 on `/wp-admin`.
17. **JWT filter units** — returning `time() + DAY_IN_SECONDS` yields a ~56-year
    token.
18. **Registration payload nulls** — re-query the customer after registration.
19. **Price entities** — `price` contains `&nbsp;` and the currency symbol.
20. **Empty checkout 302** — an empty native cart redirects to `/cart/`; that is
    expected, so assert with `fill_cart` populated.
21. **Build-time TLS** — self-signed certs break `next build` fetches without the
    dev-only override.
22. **WP-CLI ownership** — run as `www-data` (`docker exec -u www-data`).
23. **Apache log hang** — `/var/log/apache2/error.log` is stderr; use
    `docker logs`.
