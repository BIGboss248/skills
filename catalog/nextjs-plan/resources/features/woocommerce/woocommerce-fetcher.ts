import { cookies } from 'next/headers';

const GRAPHQL_ENDPOINT =
  process.env.NEXT_PUBLIC_WORDPRESS_API_URL || 'https://your-store.com/graphql';

interface FetchOptions {
  variables?: Record<string, unknown>;
  revalidate?: number | false;
  tags?: string[];
  requireAuth?: boolean;
  authToken?: string;
}

export interface WooCommerceResponse<T> {
  data: T | null;
  error: string | null;
  endpoint: string;
}

/**
 * Universal Next.js fetcher for WooCommerce GraphQL (WPGraphQL & WooGraphQL).
 *
 * Features:
 * - Dual auth headers (`Authorization: Bearer` and `X-JWT-Auth`) for LiteSpeed/Apache compatibility.
 * - Resilient payload inspection: accepts valid GraphQL data even if WordPress filters send HTTP 403 on Bearer tokens.
 * - Automatic cookie resolution in Next.js Server Components and Server Actions.
 * - Granular ISR tag revalidation and no-store caching.
 */
export async function fetchWooCommerce<T>(
  query: string,
  options: FetchOptions = {}
): Promise<WooCommerceResponse<T>> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  // Resolve auth token either explicitly or via Next.js cookie store
  let token = options.authToken;
  if (!token && options.requireAuth) {
    try {
      const cookieStore = await cookies();
      token = cookieStore.get('auth_token')?.value;
    } catch {
      // Running outside Server Action/Component context
    }
  }

  // Inject dual headers if token is present
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
    headers['X-JWT-Auth'] = token;
  }

  const fetchConfig: RequestInit = {
    method: 'POST',
    headers,
    body: JSON.stringify({
      query,
      variables: options.variables,
    }),
  };

  if (options.requireAuth || token || options.revalidate === 0) {
    fetchConfig.cache = 'no-store';
  } else if (options.revalidate !== undefined || options.tags) {
    fetchConfig.next = {
      revalidate: options.revalidate,
      tags: options.tags,
    };
  }

  try {
    const res = await fetch(GRAPHQL_ENDPOINT, fetchConfig);

    let json: { data?: T; errors?: Array<{ message: string }> } | null = null;
    try {
      json = await res.json();
    } catch {
      // Non-JSON response
    }

    if (json?.errors && json.errors.length > 0) {
      const errorMsg = json.errors.map((e) => e.message).join(' | ');
      return {
        data: json.data || null,
        error: res.ok ? errorMsg : `${errorMsg} (HTTP ${res.status})`,
        endpoint: GRAPHQL_ENDPOINT,
      };
    }

    if (!res.ok) {
      // In WordPress/WooCommerce, security filters or core REST auth hooks may emit
      // HTTP 403 Forbidden on Bearer tokens for non-admin accounts, while WPGraphQL
      // still successfully executes and returns the complete valid JSON data payload.
      if (json?.data && typeof json.data === 'object' && Object.keys(json.data).length > 0) {
        return {
          data: json.data as T,
          error: null,
          endpoint: GRAPHQL_ENDPOINT,
        };
      }

      return {
        data: null,
        error: `HTTP ${res.status}: ${res.statusText}`,
        endpoint: GRAPHQL_ENDPOINT,
      };
    }

    return {
      data: (json?.data as T) || null,
      error: null,
      endpoint: GRAPHQL_ENDPOINT,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      data: null,
      error: message,
      endpoint: GRAPHQL_ENDPOINT,
    };
  }
}
