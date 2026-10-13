# Next.js & WooCommerce Integration Reference Guide

Comprehensive developer guide for building a headless e-commerce frontend in [[Next JS]] (App Router) powered by WooCommerce via WPGraphQL, WooGraphQL, and JWT Authentication.

---

## 1. Documentation & Source References

This implementation architecture is based on official guides and production case studies:

- **Next.js Official Documentation**:
  - [Next.js App Router Data Fetching & Caching](https://nextjs.org/docs/app/building-your-application/data-fetching/fetching)
  - [Next.js Server Actions & Mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
  - [Next.js Route Handlers & Cookies](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
- **WPGraphQL & WooGraphQL Reference**:
  - [WPGraphQL Quick Start & Core Docs](https://www.wpgraphql.com/docs/quick-start)
  - [WPGraphQL Authentication and Authorization](https://www.wpgraphql.com/docs/authentication-and-authorization)
  - [wp-graphql-woocommerce GitHub Schema & Types](https://github.com/wp-graphql/wp-graphql-woocommerce)
  - [wp-graphql-jwt-authentication GitHub](https://github.com/wp-graphql/wp-graphql-jwt-authentication)
- **Community Real-World Insights**:
  - [Headless WooCommerce with Next.js Front-End: Anyone Tried This for a Live Website? (r/nextjs)](https://www.reddit.com/r/nextjs/comments/1mcegud/headless_woocommerce_with_nextjs_frontend_anyone/)
  - [WooCommerce Official REST API Reference](https://woocommerce.github.io/woocommerce-rest-api-docs/)

---

## 2. Environment Configuration

Define the WordPress backend endpoint in Next.js environment files (`.env.example` and `.env.development`):

```env
# Public GraphQL Endpoint for Server & Client Components
NEXT_PUBLIC_WORDPRESS_API_URL=https://your-store-domain.com/graphql

# Optional Backend Base URL for Native Checkout Redirects
NEXT_PUBLIC_WORDPRESS_URL=https://your-store-domain.com
```

---

## 3. Public Data Fetching (ISR / SSG)

Public catalog queries (categories, products, attributes) do not require authentication headers and should leverage Next.js static pre-rendering and tag revalidation:

### 3.1. Fetching Products in React Server Components (RSC)
```ts
// lib/woocommerce/products.ts
export async function getProducts(limit = 20) {
  const query = `
    query GetProducts($limit: Int!) {
      products(first: $limit) {
        nodes {
          id
          databaseId
          name
          slug
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
          }
          ... on VariableProduct {
            price
            regularPrice
            stockStatus
          }
        }
      }
    }
  `;

  const res = await fetch(process.env.NEXT_PUBLIC_WORDPRESS_API_URL!, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables: { limit } }),
    next: { revalidate: 300, tags: ['products'] }, // Revalidate every 5 minutes
  });

  const json = await res.json();
  if (json.errors) throw new Error(json.errors[0].message);
  return json.data.products.nodes;
}
```

### 3.2. Fetching Single Product Detail by Slug
```ts
export async function getProductBySlug(slug: string) {
  const query = `
    query GetProduct($slug: ID!) {
      product(id: $slug, idType: SLUG) {
        id
        databaseId
        name
        slug
        description
        shortDescription
        sku
        galleryImages {
          nodes {
            sourceUrl
            altText
          }
        }
        ... on SimpleProduct {
          price
          regularPrice
          stockStatus
          stockQuantity
        }
        ... on VariableProduct {
          price
          variations {
            nodes {
              id
              databaseId
              name
              price
              stockStatus
            }
          }
        }
      }
    }
  `;

  const res = await fetch(process.env.NEXT_PUBLIC_WORDPRESS_API_URL!, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables: { slug } }),
    next: { revalidate: 3600, tags: [`product-${slug}`] },
  });

  const json = await res.json();
  return json.data.product;
}
```

---

## 4. Protected User Authentication (JWT)

Authentication with `wp-graphql-jwt-authentication` is handled via Server Actions or Route Handlers, storing the `authToken` in an `HttpOnly` cookie to protect against XSS.

### 4.1. Login Server Action
```ts
// app/actions/auth.ts
'use server';

import { cookies } from 'next/headers';

export async function loginAction(formData: FormData) {
  const username = formData.get('username') as string;
  const password = formData.get('password') as string;

  const mutation = `
    mutation LoginUser($username: String!, $password: String!) {
      login(input: { username: $username, password: $password }) {
        authToken
        refreshToken
        user {
          id
          name
          email
        }
        customer {
          id
          sessionToken
        }
      }
    }
  `;

  const response = await fetch(process.env.NEXT_PUBLIC_WORDPRESS_API_URL!, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: mutation, variables: { username, password } }),
  });

  const json = await response.json();
  if (json.errors) {
    return { success: false, error: json.errors[0].message };
  }

  const { authToken, customer } = json.data.login;
  const cookieStore = await cookies();

  // Store JWT in secure HttpOnly cookie
  cookieStore.set('auth_token', authToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    maxAge: 60 * 60 * 24 * 7, // 7 days
  });

  // Store WooCommerce customer session if returned
  if (customer?.sessionToken) {
    cookieStore.set('wc_session', customer.sessionToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
    });
  }

  return { success: true, user: json.data.login.user };
}
```

### 4.2. Accessing Protected User Profile & Orders
```ts
// lib/woocommerce/customer.ts
import { cookies } from 'next/headers';

export async function getCustomerProfile() {
  const cookieStore = await cookies();
  const token = cookieStore.get('auth_token')?.value;

  if (!token) return null;

  const query = `
    query GetViewerProfile {
      viewer {
        id
        name
        email
        capabilities
      }
      customer {
        id
        orders {
          nodes {
            id
            orderNumber
            total
            status
            date
          }
        }
      }
    }
  `;

  const res = await fetch(process.env.NEXT_PUBLIC_WORDPRESS_API_URL!, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({ query }),
    cache: 'no-store', // Always dynamic for personal customer data
  });

  const json = await res.json();
  if (json.errors) return null;
  return json.data;
}
```

---

## 5. Cart & Session Management

WooGraphQL maintains anonymous and customer carts via the `woocommerce-session` header:

1. **Add to Cart Request**:
   Send `addToCart` mutation with current session token (if one exists).
2. **Session Token Capture**:
   Inspect response headers for `woocommerce-session: Session <token>` and save token.
3. **Subsequent Cart Calls**:
   Always pass `headers['woocommerce-session'] = 'Session ' + sessionToken`.

---

## 6. Checkout: The Native Checkout Bridge Pattern

Re-building checkout, address validation, multi-step shipping, tax calculation, and local Iranian payment gateways (Mellat, ZarinPal, etc.) in Next.js introduces high maintenance and compliance risks.

**The Battle-Tested Pattern**:
1. Next.js handles all catalog browsing, category filtering, product pages, and cart previews.
2. When the user clicks **"Proceed to Checkout"**, redirect the user to the native WooCommerce checkout page (`https://your-store.com/checkout`) while maintaining their cart session.
3. WordPress completes the payment gateway handshake, bank callback, SMS confirmation, and invoice email generation reliably.
