# Headless WooCommerce API & Schema Reference

Comprehensive technical guide for connecting decoupled frontend frameworks (Next.js, Remix, Nuxt) to WooCommerce via GraphQL and REST APIs.

---

## 1. Official Documentation & Source References

The implementation patterns and architectural strategies in this skill are synthesized from the following primary sources:

- **WPGraphQL Official Documentation**:
  - [WPGraphQL Quick Start Guide](https://www.wpgraphql.com/docs/quick-start)
  - [WPGraphQL Queries & Introspection](https://www.wpgraphql.com/docs/intro-to-graphql)
- **WooGraphQL (WPGraphQL for WooCommerce)**:
  - [wp-graphql/wp-graphql-woocommerce GitHub Repository](https://github.com/wp-graphql/wp-graphql-woocommerce)
  - [WooGraphQL Schema Definitions & Types](https://github.com/wp-graphql/wp-graphql-woocommerce#readme)
- **Headless Authentication Providers**:
  - [wp-graphql-jwt-authentication GitHub](https://github.com/wp-graphql/wp-graphql-jwt-authentication)
  - [AxeWP/wp-graphql-headless-login GitHub](https://github.com/AxeWP/wp-graphql-headless-login)
- **Ecosystem Best Practices & Reddit Community Case Studies**:
  - [Headless WooCommerce with Next.js Front-End: Anyone Tried This for a Live Website? (r/nextjs)](https://www.reddit.com/r/nextjs/comments/1mcegud/headless_woocommerce_with_nextjs_frontend_anyone/)
  - [WooCommerce Official REST API Documentation](https://woocommerce.github.io/woocommerce-rest-api-docs/)

---

## 2. API Architecture: GraphQL vs REST in Headless Commerce

| Dimension | WooGraphQL (`/graphql`) | WooCommerce REST API (`/wp-json/wc/v3/`) |
| :--- | :--- | :--- |
| **Primary Use Case** | Customer-facing storefront UI, product grids, cart, customer account | Admin operations, webhooks, build scripts, backend inventory sync |
| **Authentication Requirement** | Public queries (products, categories, reviews) require **zero authentication** | Requires `consumer_key` and `consumer_secret` with HMAC-SHA1 or query params |
| **Over-fetching & Payloads** | Client specifies exact fields needed (`name`, `price`, `image`) | Returns full large JSON payloads with all WordPress post meta |
| **HTTP Caching** | GET queries can be edge-cached by Cloudflare / Varnish | REST endpoints often marked `no-cache` or require custom cache headers |

---

## 3. Core Storefront Data Queries

### 3.1. Fetching Categories
```graphql
query GetProductCategories {
  productCategories(first: 50, where: { hideEmpty: true }) {
    nodes {
      id
      databaseId
      name
      slug
      count
      description
      image {
        sourceUrl
        altText
      }
    }
  }
}
```

### 3.2. Fetching Catalog Products with Pricing & Stock
WooCommerce has polymorphic product types. Query specific fields using GraphQL union fragments:
```graphql
query GetProductsList($first: Int = 20, $after: String) {
  products(first: $first, after: $after) {
    pageInfo {
      hasNextPage
      endCursor
    }
    nodes {
      id
      databaseId
      name
      slug
      sku
      image {
        sourceUrl
        altText
      }
      productCategories {
        nodes {
          name
          slug
        }
      }
      ... on SimpleProduct {
        price
        regularPrice
        salePrice
        stockStatus
        stockQuantity
      }
      ... on VariableProduct {
        price
        regularPrice
        stockStatus
        variations {
          nodes {
            id
            databaseId
            name
            price
            stockStatus
            attributes {
              nodes {
                name
                value
              }
            }
          }
        }
      }
    }
  }
}
```

### 3.3. Fetching Single Product Detail by Slug
```graphql
query GetProductBySlug($slug: ID!) {
  product(id: $slug, idType: SLUG) {
    id
    databaseId
    name
    slug
    description
    shortDescription
    sku
    averageRating
    reviewCount
    galleryImages {
      nodes {
        sourceUrl
        altText
      }
    }
    ... on SimpleProduct {
      price
      regularPrice
      salePrice
      stockStatus
    }
    ... on VariableProduct {
      price
      regularPrice
      stockStatus
      attributes {
        nodes {
          name
          options
        }
      }
    }
  }
}
```

---

## 4. Session & Cart Management

WooGraphQL maintains customer cart state across requests via an ephemeral **WooCommerce Session Token**:

1. **Cart Creation & Add to Cart**:
   ```graphql
   mutation AddToCart($productId: Int!, $quantity: Int = 1) {
     addToCart(input: { productId: $productId, quantity: $quantity }) {
       cart {
         total
         subtotal
         contents {
           itemCount
           nodes {
             key
             quantity
             product {
               node {
                 name
                 ... on SimpleProduct { price }
               }
             }
           }
         }
       }
     }
   }
   ```
2. **Session Header (`woocommerce-session`)**:
   - The response headers from WordPress will include a `woocommerce-session: Session <token>` header.
   - The frontend **must capture this header and pass it back in all subsequent cart queries and mutations**:
     ```ts
     headers: {
       'Content-Type': 'application/json',
       'woocommerce-session': `Session ${storedSessionToken}`
     }
     ```

---

## 5. Architectural Battle-Tested Principles (Next.js Headless)

1. **Native Checkout Bridge**:
   - Instead of re-building an entire PCI-compliant checkout in Next.js, transfer the user's cart session to the native WooCommerce checkout endpoint (`https://backend.com/checkout/?fill_cart=productId:qty:variationId`) handled by `mu-plugins/headless-redirects.php` on `template_redirect` (priority `1`), resolving `$variation->get_variation_attributes()` and calling `WC()->session->set_customer_session_cookie(true)` before redirecting to `wc_get_checkout_url()`.
   - Retains existing payment gateways (Mellat, ZarinPal, Stripe, PayPal), regional shipping rules, and trust seals (e-Namad) seamlessly.
2. **Client-Side Session Isolation**:
   - Keep `woocommerce-session` and user tokens in client-side state (Zustand, React Query, LocalStorage).
   - Never access session cookies in Next.js Root Layout or Server Components, which de-opts the site from fast static pre-rendering (ISR/SSG) into dynamic server rendering.
3. **HTTP GET Caching**:
   - Issue public product catalog queries as HTTP `GET` requests with URL-encoded query parameters.
   - Configure reverse proxies (Cloudflare, Varnish, Redis) to cache catalog GET queries at the edge.


---

## 6. Docker on Windows Local Environment Performance Optimization

When running WordPress under Docker Desktop on Windows, mounting Windows host folders (`C:\` or `D:\`) into containers creates severe I/O bottlenecks (15s–45s per page load) due to 9P/virtiofs cross-OS filesystem translation across thousands of PHP core file checks (`stat()`, `require_once()`) and random MySQL disk writes.

> [!IMPORTANT]
> Previous diagnostic findings attributing slowness to internal WordPress container settings, database parameters, or OPcache limits were **invalid**. Tweaking container/database configs does not solve the root problem. The **only true solution** is eliminating cross-OS host bind mounts by using **Docker Named Volumes** or running the project in the native WSL 2 filesystem.

### Primary Solutions:

#### Strategy A: Docker Named Volumes for Core & MySQL (Recommended for Windows Host Workflows)
- Keep WordPress core files and MySQL data in native Linux Docker named volumes (`wp_core` and `wp_db_data`), while bind-mounting only `wp-content` or specific plugins/themes from the Windows host for editing.
- **Example `docker-compose.yml` snippet**:
  ```yaml
  services:
    wordpress:
      image: wordpress:latest
      volumes:
        - wp_core:/var/www/html
        - ./wp-content:/var/www/html/wp-content
        - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini:ro

    wordpress_db:
      image: mysql:8.0
      volumes:
        - wp_db_data:/var/lib/mysql

  volumes:
    wp_core:
    wp_db_data:
  ```

#### Strategy B: WSL 2 Native Filesystem (The "Game Changer" — 500ms Response Times)
- Store the repository and project directory directly inside the native WSL 2 Linux filesystem (e.g. `/home/<username>/projects/...` accessible via `\\wsl$\Ubuntu\home\<username>\...`), rather than the Windows NTFS drive (`/mnt/c/` or `D:\Scripts\...`).
- Docker Desktop's WSL 2 backend interacts with WSL 2 ext4 files natively with zero cross-OS translation penalty, slashing page load times from 45 seconds down to under 500ms.

#### Strategy C: Development `wp-config.php` Optimizations
In local development environments, disable high-overhead background operations via `WORDPRESS_CONFIG_EXTRA`:
```php
// Disable WP-Cron from firing on every HTTP page request
define( 'DISABLE_WP_CRON', true );

// Disable or minimize post revisions to reduce DB bloat
define( 'WP_POST_REVISIONS', false );

// Increase autosave interval to reduce disk writes
define( 'AUTOSAVE_INTERVAL', 86400 );
```


#### Strategy D: Automated Makefile Patching of PHP `pdo_mysql` Driver for Laravel & Regional Plugins
- **Problem**: Plugins using Laravel Capsule or Eloquent (`Illuminate\Database`), such as **Persian WooCommerce (`persian-woocommerce`)** and Gateland, connect to MySQL via PHP PDO (`pdo_mysql`). Official `wordpress:latest` Docker images only bundle `mysqli` and `mysqlnd`.
- **Symptom**: Unhandled `Illuminate\Database\QueryException: could not find driver` crashing `/wp-admin` with HTTP 500 fatal errors.
- **Recommended Solution (No Custom Docker Image)**: Deploy standard `wordpress:latest` containers and execute the automated Makefile patch target to install `pdo_mysql` inside the running container:
  ```bash
  make patch-pdo-mysql
  ```
  Or CLI command:
  ```bash
  docker exec -u 0 <container_name> docker-php-ext-install pdo_mysql
  docker exec <container_name> apache2ctl graceful
  ```
