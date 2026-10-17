# Next.js & WooCommerce Integration Reference Guide

Comprehensive developer guide for building a headless e-commerce frontend in [[Next JS]] (App Router) powered by WooCommerce via WPGraphQL, WooGraphQL, and JWT Authentication.

---

## 1. Documentation & Source References

This implementation architecture is based on official guides, repository notes, and live integration benchmarks:

- **Repository Knowledge Base**:
  - [[WordPress]] - WordPress architecture, REST API, registration settings, and hosting behavior.
  - [[WooCommerce]] - Headless commerce, customer management, and store configuration.
- **Next.js Official Documentation**:
  - [Next.js App Router Data Fetching & Caching](https://nextjs.org/docs/app/building-your-application/data-fetching/fetching)
  - [Next.js Server Actions & Mutations](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
  - [Next.js Route Handlers & Cookies](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
- **WPGraphQL & WooGraphQL Reference**:
  - [WPGraphQL Quick Start & Core Docs](https://www.wpgraphql.com/docs/quick-start)
  - [WPGraphQL Authentication and Authorization](https://www.wpgraphql.com/docs/authentication-and-authorization)
  - [wp-graphql-woocommerce GitHub Schema & Types](https://github.com/wp-graphql/wp-graphql-woocommerce)
  - [wp-graphql-jwt-authentication GitHub](https://github.com/wp-graphql/wp-graphql-jwt-authentication)
- **WooCommerce Core Documentation**:
  - [WooCommerce REST API Documentation - Customers](https://woocommerce.github.io/woocommerce-rest-api-docs/#customers)
  - [Configuring WooCommerce Settings - Accounts & Privacy](https://woocommerce.com/document/configuring-woocommerce-settings/#accounts-and-privacy-settings)

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

## 3. Universal Data Fetcher Pattern

Production environments (LiteSpeed, Apache, Nginx, Hostinger) often strip standard `Authorization` headers unless specifically configured. In addition, WordPress security layers may respond with an `HTTP 403 Forbidden` status code on non-admin Bearer requests while WPGraphQL still executes successfully and returns valid payload data.

### Resilient Universal Fetcher
```ts
// lib/woocommerce/client.ts
interface FetchOptions {
  variables?: Record<string, unknown>;
  revalidate?: number | false;
  authToken?: string;
}

export async function fetchWooCommerce<T>(
  query: string,
  options: FetchOptions = {}
): Promise<{ data: T | null; error: string | null; endpoint: string }> {
  const endpoint = process.env.NEXT_PUBLIC_WORDPRESS_API_URL || 'http://localhost:8080/graphql';

  try {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    // Dual headers to ensure compatibility across hosting environments
    if (options.authToken) {
      headers['Authorization'] = `Bearer ${options.authToken}`;
      headers['X-JWT-Auth'] = options.authToken;
    }

    const fetchConfig: RequestInit = {
      method: 'POST',
      headers,
      body: JSON.stringify({
        query,
        variables: options.variables,
      }),
    };

    if (options.revalidate !== undefined) {
      fetchConfig.next = { revalidate: options.revalidate };
    } else {
      fetchConfig.cache = 'no-store';
    }

    const res = await fetch(endpoint, fetchConfig);

    let json: { data?: T; errors?: Array<{ message: string }> } | null = null;
    try {
      json = await res.json();
    } catch {
      // Body not JSON
    }

    if (json?.errors && json.errors.length > 0) {
      const errorMsg = json.errors.map((e) => e.message).join(' | ');
      return {
        data: json.data || null,
        error: res.ok ? errorMsg : `${errorMsg} (HTTP ${res.status})`,
        endpoint,
      };
    }

    if (!res.ok) {
      // If WordPress emitted HTTP 403 but WPGraphQL returned valid data, accept payload
      if (json?.data && typeof json.data === 'object' && Object.keys(json.data).length > 0) {
        return {
          data: json.data as T,
          error: null,
          endpoint,
        };
      }

      return {
        data: null,
        error: `HTTP ${res.status}: ${res.statusText}`,
        endpoint,
      };
    }

    return {
      data: (json?.data as T) || null,
      error: null,
      endpoint,
    };
  } catch (err) {
    return {
      data: null,
      error: err instanceof Error ? err.message : String(err),
      endpoint,
    };
  }
}
```

---

## 4. Customer Registration (Sign-Up)

### 4.1. Required Backend WordPress & WooCommerce Settings
Before sign-up can succeed, verify the following configuration on WordPress:
1. **WordPress Core (`Settings → General`)**:
   - Check **"Anyone can register"**.
   - Set **"New User Default Role"** to **Customer**.
2. **WooCommerce (`WooCommerce → Settings → Accounts & Privacy`)**:
   - Check *"Allow customers to create an account during checkout"*.
   - Check *"Allow customers to create an account on the 'My account' page"*.
   - **Uncheck** *"When creating an account, automatically generate an account password"*. (If kept checked, user passwords submitted from Next.js will be ignored and replaced with emailed WordPress random strings).

### 4.2. WooGraphQL Registration Mutation
```graphql
mutation RegisterCustomer($input: RegisterCustomerInput!) {
  registerCustomer(input: $input) {
    customer {
      id
      databaseId
      email
      displayName
    }
  }
}
```

### 4.3. Registration Server Action
```ts
// app/register/actions.ts
'use server';

import { fetchWooCommerce } from '@/lib/woocommerce/client';
import { REGISTER_CUSTOMER_MUTATION } from '@/lib/woocommerce/queries';

export interface RegisterActionResult {
  success: boolean;
  error?: string | null;
  username?: string;
}

export async function registerAction(
  prevState: RegisterActionResult | null,
  formData: FormData
): Promise<RegisterActionResult> {
  const username = (formData.get('username') as string)?.trim();
  const email = (formData.get('email') as string)?.trim();
  const password = formData.get('password') as string;

  if (!username || !email || !password) {
    return { success: false, error: 'All fields are required.' };
  }

  const res = await fetchWooCommerce<{ registerCustomer: { customer: { id: string } } }>(
    REGISTER_CUSTOMER_MUTATION,
    {
      variables: {
        input: { username, email, password },
      },
    }
  );

  if (res.error || !res.data?.registerCustomer?.customer) {
    return {
      success: false,
      error: res.error || 'Failed to create customer account.',
    };
  }

  return { success: true, username };
}
```

---

## 5. JWT Authentication Pipeline (Login & Logout)

Authentication with `wp-graphql-jwt-authentication` issues an `authToken` which must be kept in a secure `HttpOnly` cookie.

### 5.1. Login Mutation
```graphql
mutation LoginUser($username: String!, $password: String!) {
  login(input: { username: $username, password: $password }) {
    authToken
    refreshToken
    user {
      id
      databaseId
      name
      email
    }
    customer {
      id
      sessionToken
    }
  }
}
```

### 5.2. Login Server Action
```ts
// app/login/actions.ts
'use server';

import { cookies } from 'next/headers';
import { fetchWooCommerce } from '@/lib/woocommerce/client';
import { LOGIN_MUTATION } from '@/lib/woocommerce/queries';

export async function loginAction(prevState: unknown, formData: FormData) {
  const username = (formData.get('username') as string)?.trim();
  const password = formData.get('password') as string;

  const res = await fetchWooCommerce<{ login: { authToken: string; user: any; customer: any } }>(
    LOGIN_MUTATION,
    { variables: { username, password } }
  );

  if (res.error || !res.data?.login) {
    return { success: false, error: res.error || 'Invalid credentials' };
  }

  const { authToken, user, customer } = res.data.login;
  const cookieStore = await cookies();

  cookieStore.set('auth_token', authToken, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    maxAge: 60 * 60 * 24 * 7, // 7 days
  });

  if (customer?.sessionToken) {
    cookieStore.set('wc_session', customer.sessionToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
    });
  }

  return { success: true, user };
}

export async function logoutAction() {
  const cookieStore = await cookies();
  cookieStore.delete('auth_token');
  cookieStore.delete('wc_session');
  return { success: true };
}
```

### 5.3. Client Navigation on Login Success
Always use `window.location.href = '/login'` (or `/account`) rather than `window.location.reload()`. A fresh GET request forces Next.js Server Components to evaluate the new `auth_token` cookie without re-transmitting action form data.

---

## 6. Protected User Profile & Orders

### 6.1. Combined Profile Query
Do NOT query `capabilities` or `nicename` for non-admin accounts. Keep viewer fields minimal:
```graphql
query GetUserProfile {
  viewer {
    id
    databaseId
    name
    email
  }
  customer {
    id
    databaseId
    displayName
    email
    billing {
      firstName
      lastName
      address1
      city
      country
      phone
      email
    }
    orders(first: 10) {
      nodes {
        id
        orderNumber
        status
        total
        date
      }
    }
  }
}
```

### 6.2. Hydrating Profile in Server Components
```ts
export async function getAuthSessionAction() {
  const cookieStore = await cookies();
  const token = cookieStore.get('auth_token')?.value;

  if (!token) return { authenticated: false };

  const res = await fetchWooCommerce<UserProfileQueryResult>(GET_USER_PROFILE_QUERY, {
    authToken: token,
  });

  const hasViewer = Boolean(res.data?.viewer?.id || res.data?.viewer?.name);
  const hasCustomer = Boolean(res.data?.customer?.id && res.data.customer.id !== 'guest');

  if (!hasViewer && !hasCustomer) {
    return { authenticated: false, error: res.error };
  }

  const user = res.data?.viewer || {
    id: res.data?.customer?.id || 'customer',
    databaseId: res.data?.customer?.databaseId || undefined,
    name: res.data?.customer?.displayName || 'Customer',
    email: res.data?.customer?.email || undefined,
  };

  return {
    authenticated: true,
    user,
    customer: res.data?.customer || null,
  };
}
```

---

## 7. Deep Dive: WordPress HTTP 403 Status Code with Valid GraphQL Payloads

### Root Cause
When a non-admin user (role `customer` or `subscriber`) requests `/graphql` with `Authorization: Bearer <token>`, WordPress core REST filters or security plugins (e.g. Wordfence, ModSecurity) evaluate user capabilities. Because the account lacks `edit_posts` or `read_private_posts`, a filter hook calls `status_header(403)`.

### WPGraphQL Behavior
WPGraphQL hooks into WordPress before headers are finalized. Even if the HTTP status header is set to 403, WPGraphQL executes the entire query, evaluates the customer's schema permissions, and emits the completed `data` object with refreshed headers (`x-jwt-auth`, `woocommerce-session`).

### Resolution Strategy
The universal fetcher must not discard the response solely on `!res.ok`. If `json.data` is present with non-empty keys and `json.errors` is absent, treat the query as successful.

---

## 8. Public Data Fetching (ISR / SSG)

Public catalog queries must leverage Next.js static pre-rendering and polymorphic union fragments (`... on SimpleProduct`, `... on VariableProduct`).

```ts
export async function getProducts(first = 20) {
  const query = `
    query GetProducts($first: Int!) {
      products(first: $first) {
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

  return fetchWooCommerce(query, { variables: { first }, revalidate: 60 });
}
```

---

## 9. Checkout: The Native Checkout Bridge Pattern

Re-building address validation, multi-step shipping, tax calculation, and local Iranian payment gateways (Mellat, ZarinPal, etc.) in Next.js introduces high maintenance and compliance risks.

### 9.1. Cross-Origin Session Block
In decoupled setups (`localhost:3000` or `frontend.com` vs `shop.domain.com`), browsers block cross-origin third-party cookies. Navigating directly to a bare `https://your-store.com/checkout` will load an empty cart because WordPress cannot read the frontend session.

### 9.2. Order-Pay Bridge via WooGraphQL `checkout` Mutation
The production pattern converts the Next.js cart session into a pending order on the backend and redirects the user directly to the order payment screen:

```graphql
mutation ProcessCheckout($input: CheckoutInput!) {
  checkout(input: $input) {
    result
    redirect
    order {
      id
      databaseId
      orderKey
      total
      status
    }
  }
}
```

```ts
// Server Action: Convert GraphQL cart session into WooCommerce order
export async function processCheckoutAction(formData?: {
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
  address1: string;
  city: string;
}) {
  const cookieStore = await cookies();
  const sessionToken = cookieStore.get('wc_session')?.value;
  const authToken = cookieStore.get('auth_token')?.value;

  const res = await fetchWooCommerce<CheckoutMutationResult>(CHECKOUT_MUTATION, {
    authToken,
    variables: {
      input: {
        isPaid: false,
        billing: formData || {
          firstName: 'Customer',
          lastName: 'Account',
          email: 'order@customer.com',
          phone: '09120000000',
          address1: 'Tehran',
          city: 'Tehran',
          country: 'IR',
        },
      },
    },
  });

  const redirectUrl = res.data?.checkout?.redirect;
  if (redirectUrl) {
    return { success: true, redirectUrl };
  }

  // Fallback: Construct order-pay URL manually from returned order ID and key
  const order = res.data?.checkout?.order;
  if (order?.databaseId && order?.orderKey) {
    const backendUrl = process.env.NEXT_PUBLIC_WORDPRESS_URL || 'https://your-store.com';
    return {
      success: true,
      redirectUrl: `${backendUrl}/checkout/order-pay/${order.databaseId}/?pay_for_order=true&key=${order.orderKey}`,
    };
  }

  return { success: false, error: res.error || 'Checkout failed' };
}
```

### 9.3. Native Checkout Page Transfer (Allowing Address & Dynamic Shipping Selection)
When an e-commerce store requires the customer to choose their shipping address (e.g. Iranian province and city selectors via Persian WooCommerce Shipping) so that shipping tariffs and options calculate dynamically before payment, avoid locking the customer into an `order-pay` URL.

Instead, transfer cart items directly to WooCommerce's native checkout page:

```
https://your-store.com/checkout/?add-to-cart=<id>&quantity=<qty>&fill_cart=38:2,25:1
```

#### WordPress Bridge Snippet (`functions.php`)
```php
/**
 * Headless Cart Transfer: Support adding multiple products to WooCommerce cart via URL
 * Example: https://shop.meetjamali.com/checkout/?fill_cart=38:2,25:1
 */
add_action( 'template_redirect', function() {
    if ( ! empty( $_GET['fill_cart'] ) && function_exists( 'WC' ) && WC()->cart ) {
        WC()->cart->empty_cart();
        
        $items = explode( ',', sanitize_text_field( $_GET['fill_cart'] ) );
        foreach ( $items as $item ) {
            $parts = explode( ':', $item );
            $product_id   = isset( $parts[0] ) ? absint( $parts[0] ) : 0;
            $quantity     = isset( $parts[1] ) ? absint( $parts[1] ) : 1;
            $variation_id = isset( $parts[2] ) ? absint( $parts[2] ) : 0;
            
            if ( $product_id > 0 ) {
                WC()->cart->add_to_cart( $product_id, $quantity, $variation_id );
            }
        }
        
        // Redirect cleanly to checkout
        wp_safe_redirect( wc_get_checkout_url() );
        exit;
    }
});
```

#### Next.js Checkout Link Generation
```ts
export async function getCheckoutUrlAction(
  items?: Array<{ databaseId: number; quantity: number; variationId?: number }>,
  customerInfo?: { email?: string; phone?: string; firstName?: string; lastName?: string }
): Promise<{ url: string }> {
  const base = process.env.NEXT_PUBLIC_WORDPRESS_URL || 'https://shop.meetjamali.com';
  const cleanBase = base.replace(/\/$/, '');

  if (!items || items.length === 0) {
    return { url: `${cleanBase}/checkout/` };
  }

  const primaryItem = items[0];
  const fillCartParam = items
    .map((item) => `${item.databaseId}:${item.quantity || 1}${item.variationId ? `:${item.variationId}` : ''}`)
    .join(',');

  const params = new URLSearchParams();
  if (primaryItem.databaseId) {
    params.set('add-to-cart', String(primaryItem.databaseId));
    params.set('quantity', String(primaryItem.quantity || 1));
  }
  params.set('fill_cart', fillCartParam);

  if (customerInfo?.email) params.set('billing_email', customerInfo.email);
  if (customerInfo?.phone) params.set('billing_phone', customerInfo.phone);

  return {
    url: `${cleanBase}/checkout/?${params.toString()}`,
  };
}
```


