---
name: headless-woocommerce-api
description: >-
  Run a headless WooCommerce backend. Use when standing up WordPress with
  WPGraphQL and WooGraphQL, wiring JWT auth, or debugging cart, checkout, or
  catalog queries.
---

# Headless WooCommerce Standards

How the commerce backend is configured and queried. This skill owns the WordPress
side; the storefront consumes it.

## Prerequisites

- WordPress with WooCommerce, WPGraphQL, WooGraphQL, and
  `wp-graphql-jwt-authentication`.
- Docker and WP-CLI (WP-CLI is not in the official image).
- References: [schema and queries](./references/headless-api-reference.md) ·
  [bootstrap and plugins](./references/wordpress-bootstrap-and-plugins.md) ·
  [Iran store configuration](./references/store-configuration-iran.md) ·
  [container operations](./references/docker-container-operations.md) ·
  [storefront integration](./references/storefront-integration.md).

## Known-good stack

Re-verify before pinning. WordPress 6.x (PHP 8.3), WooCommerce 11.x,
WPGraphQL 2.x, WooGraphQL 1.x, JWT auth 0.7.x, Persian WooCommerce 10.x,
ZarinPal gateway 5.x.

## 1. Plugins

- Install WP-CLI on the host and copy the phar into the container; container
  `curl` often fails behind a proxy.
- Install order: WooCommerce first, then WPGraphQL, then WooGraphQL and JWT
  (both are GitHub release zips, not WP.org packages).
- Create the store through WP-CLI with `-u www-data`; root-owned files break
  plugin updates, and the cache warning is harmless.
- Flush rewrites and confirm `/graphql` returns 200 before going further.

## 2. Authentication

- The official image does not forward arbitrary environment variables into PHP;
  define the JWT secret through `WORDPRESS_CONFIG_EXTRA`.
- Generate a 64-character secret with no `$`, quotes, or backslashes; it is
  embedded in a PHP single-quoted string.
- `graphql_jwt_auth_expire` returns **seconds**, never a timestamp.
- Registration: enable `users_can_register`, role `customer`, no generated
  password or username.
- Do not trust the registration payload for `databaseId`, `email`, or
  `displayName`; re-query the customer after login.

## 3. Store and payments

- Currency `IRT` exists only after Persian WooCommerce is active; configure it
  after activation.
- COD: `wp wc payment_gateway update cod --enabled=true --user=1`.
- Persian WooCommerce bundles Zibal, not ZarinPal. ZarinPal is a separate plugin
  (`WC_ZPal`), and its sandbox accepts a random UUID as `merchantcode`, so local
  checkout is verifiable without a merchant contract.
- Persist gateway defaults with `wp wc payment_gateway update` before patching
  settings; `wp option patch update` fails when the option does not exist yet.
- Shipping zones do not accept `--locations`; use
  `WC_Shipping_Zone::set_locations()` and `add_shipping_method()`.
- Seed products from temporary files outside the repository. Set variation
  attributes and call `WC_Product_Variable::sync()`, then verify with
  `... on VariableProduct { variations { nodes { databaseId } } }`.

## 4. Querying

- `Product` is a union: use `... on SimpleProduct` and `... on VariableProduct`.
  `price`, `stockStatus`, and `variations` do not exist on the base type.
- `price` is display-formatted HTML with entities and a currency symbol; decode
  before rendering.
- Capture the `Woocommerce-Session` response header on `addToCart` and resend it
  as `woocommerce-session: Session <token>`.
- Protected profile: send both `Authorization: Bearer <token>` and
  `X-JWT-Auth: <token>`, then query `viewer` and `customer`.
- A GraphQL response may carry a valid body under an HTTP 403. Return
  `json.data` when it exists.

## 5. Storefront integration

- Native checkout: `/checkout/?fill_cart=productId:qty:variationId`, handled on
  `template_redirect` priority 1.
- Classic checkout AJAX: filter `woocommerce_ajax_get_endpoint` to
  `/checkout/?wc-ajax=<endpoint>`.
- Block checkout: verify the cart through `/wp-json/wc/store/v1/cart` with the
  browser cookie jar; it renders client-side.
- Gateway callbacks: filter `woocommerce_api_request_url` to
  `/checkout/?wc-api=<Gateway>`; do not route `/wc-api` through the frontend.
- CORS: expose `Authorization`, `Content-Type`, `X-JWT-Auth`, `X-JWT-Refresh`,
  and `woocommerce-session`.
- Cross-origin sessions do not persist. Convert the cart through the checkout
  mutation and redirect to the generated `order-pay` URL instead of a bare
  `/checkout/`.
- Full flow: [storefront reference](./references/storefront-reference.md) ·
  [verification playbook](./references/verification-playbook.md) ·
  [Windows local dev](./references/windows-local-dev.md).

## Definition of Done

- [ ] `/graphql` returns 200 and the schema exposes product, cart, and customer
      types.
- [ ] Registration, login, and `viewer` resolve for a customer token.
- [ ] `addToCart` returns a session header and the cart persists on the next
      request.
- [ ] Checkout reaches a payable order without an empty cart.
- [ ] `/wp-admin/` loads (no missing driver).
- [ ] No secret is committed; the JWT secret comes from environment config.

## Edge Cases & Pitfalls

- **Union queries** — a missing inline fragment returns nulls.
- **Missing session header** — the cart empties on the next request.
- **CORS** — an unexposed `woocommerce-session` makes the cart unreadable in the
  browser.
- **Windows Docker I/O** — named volumes for core and MySQL; bind only
  `mu-plugins`.
- **Missing `pdo_mysql`** — Persian plugins return HTTP 500; patch after every
  container recreation.
- **`?add-to-cart=` with a variable product** — use `fill_cart` and variation
  ids.
- **JWT units** — seconds, not milliseconds or timestamps.
- **Bare `/checkout/`** — loads an empty session across origins.
- **Empty block cart** — redirects to `/cart/`; populate first.

## References

- [Headless API reference](./references/headless-api-reference.md)
- [WordPress bootstrap and plugins](./references/wordpress-bootstrap-and-plugins.md)
- [Iran store configuration](./references/store-configuration-iran.md)
- [Docker container operations](./references/docker-container-operations.md)
- [Storefront integration](./references/storefront-integration.md)
- [Storefront reference](./references/storefront-reference.md)
- [Verification playbook](./references/verification-playbook.md)
- [Windows local dev](./references/windows-local-dev.md)
- [Templates and helpers](./resources/templates/)
