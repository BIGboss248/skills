import { cookies } from 'next/headers';

const GRAPHQL_ENDPOINT = process.env.NEXT_PUBLIC_WORDPRESS_API_URL || 'https://your-store.com/graphql';

interface FetchOptions {
  variables?: Record<string, unknown>;
  revalidate?: number | false;
  tags?: string[];
  requireAuth?: boolean;
}

/**
 * Universal Next.js fetcher for WooCommerce GraphQL
 * Supports ISR caching for public data and Bearer token injection for authenticated queries.
 */
export async function fetchWooCommerce<T>(query: string, options: FetchOptions = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (options.requireAuth) {
    const cookieStore = await cookies();
    const token = cookieStore.get('auth_token')?.value;
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
  }

  const fetchConfig: RequestInit = {
    method: 'POST',
    headers,
    body: JSON.stringify({ query, variables: options.variables }),
  };

  if (options.requireAuth || options.revalidate === 0) {
    fetchConfig.cache = 'no-store';
  } else if (options.revalidate !== undefined || options.tags) {
    fetchConfig.next = {
      revalidate: options.revalidate,
      tags: options.tags,
    };
  }

  const response = await fetch(GRAPHQL_ENDPOINT, fetchConfig);
  const json = await response.json();

  if (json.errors) {
    throw new Error(json.errors[0]?.message || 'GraphQL Query Execution Failed');
  }

  return json.data;
}
