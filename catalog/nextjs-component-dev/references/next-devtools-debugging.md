# Next DevTools Runtime Diagnostics & Debugging Guide

This reference outlines the standard protocol for checking the dev server status, tuning into running instances, and using the `next-devtools` MCP server to detect and resolve runtime issues during component development.

---

## 1. Dev Server Discovery & Tuning In

Next.js 16+ automatically exposes an MCP endpoint at `/_next/mcp` on startup.

### Protocol:
1. **Discover Running Server:**
   Call `call_mcp_tool` on `next-devtools`:
   ```json
   {
     "ServerName": "next-devtools",
     "ToolName": "nextjs_index",
     "Arguments": {}
   }
   ```
2. **If Server is Running:**
   - Note the active `port`, `PID`, and list of available tools (e.g., `get_errors`, `get_routes`, `get_page_info`, `clear_cache`).
   - Tune in directly without restarting the server.
3. **If Server is NOT Running:**
   - Launch the dev server as a background daemon process:
     - `run_command` with `CommandLine: "pnpm dev"`, `IsDaemon: true`, `WaitMsBeforeAsync: 3000`.
   - Re-run `nextjs_index` to verify connection and discover available tools.
   - If auto-discovery does not find the port immediately, pass `{"port": "3000"}` to `nextjs_index`.

---

## 2. Post-Component Runtime Diagnostics

After authoring a component, skeleton, and dictionary entries:

1. **Query Diagnostics & Compilation Errors:**
   Use `nextjs_call` to check runtime compilation status:
   ```json
   {
     "ServerName": "next-devtools",
     "ToolName": "nextjs_call",
     "Arguments": {
       "port": "3000",
       "toolName": "get_errors"
     }
   }
   ```
2. **Inspect Route & Component Tree:**
   Verify the route or component renders without server action or RSC serialization breaks using tools provided by `nextjs_index`.
3. **Interactive / DOM Diagnostics:**
   - Use `browser_eval` to execute browser-side JavaScript expressions or check DOM state if needed.
   - Use Playwright MCP tools (`browser_navigate`, `browser_snapshot`) for full visual verification when necessary.

## 3. Navigation Inspector & Instant Navigation Diagnostics

When `cacheComponents: true` is enabled in `next.config.ts`, Next.js DevTools provides the **Navigation Inspector**:

1. **Pause on Navigations**:
   - Toggle **Pause on navigations** in Next.js DevTools.
   - Trigger a direct refresh or click a link: the page freezes at its initial loading state.
   - Inspect the **Static Shell** on page loads or the **App Shell** on client navigations.
   - Verify which `<Suspense>` boundaries are showing fallbacks and confirm cached content renders immediately without flashing spinners.
   - Click **Resume** to release the freeze and stream in the remaining data.

2. **Resolving "Blocking-Route" Insights**:
   Next.js surfaces dev overlay insights when a component blocks instant navigation:
   - **Stream Card**: Move slug/URL/header-dependent fetches into a sub-component wrapped in `<Suspense>`.
   - **Cache Card**: Add `'use cache'` and `cacheLife` to cache async functions in the static shell.
   - **Block Card**: Export `export const instant = false` from the route segment if instant navigation is explicitly not desired.

---

## 4. Resolving Runtime Issues

- **Compilation / Syntax Errors:** Inspect error stacks returned by `nextjs_call` and immediately resolve import paths, syntax errors, or TypeScript mismatches.
- **Hydration Mismatches:** Ensure Client Components (`"use client"`) don't render non-deterministic content (dates, random IDs) without proper hydration suppression or `useEffect` mounts.
- **i18n Missing Keys:** If next-intl reports missing key warnings at runtime, verify all dictionary files (`messages/[locale].json`) contain the required namespace and key.
- **Cache / Hot-Reload Inconsistencies:** If changes are not reflected, call the cache clearing tool via `nextjs_call` on `next-devtools`.
