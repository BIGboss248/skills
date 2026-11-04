# MCP Server Catalog (`setup-repository`)

Reference for Step 3. Register only the servers the repository needs: every enabled server adds tool definitions and server instructions to **every** model request.

## 1. Available Servers

| Server | Transport | Command / URL | Tools | Use it for |
| :--- | :--- | :--- | ---: | :--- |
| `codebase-memory` | stdio | `codebase-memory-mcp` | 15 | Indexed code/notes graph: `search_graph`, `trace_path`, `get_code_snippet`, change impact |
| `github` | HTTP | `https://api.githubcopilot.com/mcp/` + `Authorization: Bearer <PAT>` | 46 | Issues, PRs, releases, code search, `github-triage` |
| `next-devtools` | stdio | `npx -y next-devtools-mcp@latest` | 4 | Next.js 16+ `/_next/mcp`: errors, routes, logs, compile, `nextjs_docs` |
| `chrome-devtools-mcp` | stdio | `npx -y chrome-devtools-mcp@latest` | 32 | DOM/console/network inspection, Lighthouse, performance traces, screencasts |
| `playwright` | stdio | `npx -y @playwright/mcp@latest` | 25 | E2E flows and multi-browser automation |
| `seo` | stdio | `npx -y seo mcp serve` | 6 | SEO audits, Search Console/GA/Bing reports, quick wins |
| `dart-mcp-server` | stdio | `dart mcp-server` | 24 | Dart/Flutter analyzer, hot reload, devices, widget tree |
| `gopls-mcp-server` | stdio | `gopls mcp` | 8 | Go symbols, references, diagnostics, rename, `govulncheck` |
| `developer-knowledge` | HTTP | `https://developerknowledge.googleapis.com/mcp` + `X-Goog-Api-Key` | 3 | Grounded answers from official Google developer docs |
| `android-management-api` | HTTP | `https://androidmanagement.googleapis.com/mcp` | 9 | Android Enterprise policies, devices, web apps |

Removed on 2026-10-31 — do **not** re-add without an explicit request: `StitchMCP`, `storybook` (`http://localhost:6006/mcp`).

## 2. Recommendation Matrix

Derive the recommendation from Step 1 discovery, then let the user confirm.

| Detected signal | Recommend |
| :--- | :--- |
| Any repository | `codebase-memory` (always) |
| `git remote` points to GitHub, or `github-triage` is used | `github` |
| `next` >= 16 in `package.json` | `next-devtools`, `chrome-devtools-mcp` |
| Browser debugging, Lighthouse, Core Web Vitals work | `chrome-devtools-mcp` |
| E2E test suite (Playwright/Cypress) or scripted browser flows | `playwright` |
| Public site, marketing pages, sitemap/metadata work | `seo` |
| `pubspec.yaml` present | `dart-mcp-server` |
| `go.mod` present | `gopls-mcp-server` |
| Google Cloud / Google API integration questions | `developer-knowledge` |
| Android Enterprise device management | `android-management-api` |

Ask with these options in a multi-select, recommended entries first and labelled `(Recommended)`. If the user declines to choose, register the recommended set and report what was skipped.

## 3. Registration

1. **Workspace** — `mcp.json` (`mcpServers`), `.vscode/mcp.json`, or `.agents/mcp_config.json` when present:
   ```json
   {
     "mcpServers": {
       "codebase-memory": { "command": "codebase-memory-mcp" },
       "next-devtools": { "command": "npx", "args": ["-y", "next-devtools-mcp@latest"] }
     }
   }
   ```
2. **Global (Google Antigravity only)** — `~/.gemini/antigravity/mcp_config.json` and `~/.gemini/config/mcp_config.json`.
3. **Record the accepted set** in `docs/project.json` under `project_context_and_metadata.mcp_servers`.
4. **Disabling differs by client**:
   - OpenCode/VS Code/Claude: `"disabled": true` on the server object.
   - Antigravity: ignores `disabled` inside `mcpServers`; move the entry to `_disabledMcpServers` instead.
5. **Startup latency** — prefer a pinned local install over `npx <pkg>@latest`. Cold `npx` resolution frequently exceeds the 30s MCP connect timeout and the server shows `failed: Request timed out`.

## 4. Known Pitfalls

| Symptom | Cause / Fix |
| :--- | :--- |
| `npm error could not determine executable to run` | Wrong package name. The Next.js server is `next-devtools-mcp`, not `next-devtools`. |
| `seo` fails to start | `seo@0.13.0` requires Node `^22.23.4`; pin `seo@0.2.41` on Node 22.23.0. |
| `next-devtools` connects but lists no server | Dev server not running; start `next dev` (Next.js 16+) and ensure `experimental.mcpServer` is not `false`. |
| Server connects after ~15s | `npx` cold start; install pinned and invoke the binary. |
