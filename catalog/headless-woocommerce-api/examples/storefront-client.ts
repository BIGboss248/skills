import { GraphQLClient } from 'graphql-request';

// Base endpoint for WooCommerce GraphQL (configure in .env)
const GRAPHQL_ENDPOINT = process.env.NEXT_PUBLIC_WORDPRESS_API_URL || 'https://your-store-domain.com/graphql';

/**
 * Execute unauthenticated GraphQL query (e.g. Products, Categories)
 */
export async function fetchStorefront<T>(query: string, variables?: Record<string, unknown>): Promise<T> {
  const client = new GraphQLClient(GRAPHQL_ENDPOINT);
  return client.request<T>(query, variables);
}

/**
 * Execute authenticated GraphQL query or session-aware Cart mutation
 */
export async function fetchWithSession<T>(
  query: string,
  variables?: Record<string, unknown>,
  options?: { authToken?: string; sessionToken?: string }
): Promise<{ data: T; newSessionToken?: string }> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (options?.authToken) {
    headers['Authorization'] = `Bearer ${options.authToken}`;
  }

  if (options?.sessionToken) {
    headers['woocommerce-session'] = `Session ${options.sessionToken}`;
  }

  const response = await fetch(GRAPHQL_ENDPOINT, {
    method: 'POST',
    headers,
    body: JSON.stringify({ query, variables }),
  });

  const nextSession = response.headers.get('woocommerce-session');
  const json = await response.json();

  if (json.errors) {
    throw new Error(json.errors[0]?.message || 'GraphQL Error');
  }

  return {
    data: json.data,
    newSessionToken: nextSession ? nextSession.replace(/^Session\s+/, '') : undefined,
  };
}
