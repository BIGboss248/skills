# F3 — MCP Servers & Codebase Memory

## Enable when

Always recommended for repositories large enough that graph search beats grep, and
whenever the project needs agent tooling (GitHub, browser, Flutter, Go, SEO).

## Questions

1. **Which MCP servers does this repository need?** Present the recommendation from
   [mcp-server-catalog.md](../mcp-server-catalog.md#2-recommendation-matrix) as a
   multi-select, recommended entries first and labelled `(Recommended)`.
2. If the codebase-memory binary/MCP is missing: install it, or skip it?
3. Register workspace-only, or also globally for Google Antigravity (AGY)?
4. Index mode for the first run: `fast` or `moderate`?

> [!IMPORTANT]
> Never silently enable every available server. Each enabled server adds tool
> definitions and instructions to every model request. Register only the accepted
> set and state what was skipped. If the user declines to choose, register the
> recommended set.

## Steps

1. Ask question 1, then record the accepted set in `.agents/setup-features.json`
   and in `docs/project.json` under `project_context_and_metadata.mcp_servers`.
2. Register the accepted set in workspace `mcp.json` (and `.agents/mcp_config.json`
   if present).
3. Register globally for AGY only, in `~/.gemini/antigravity/mcp_config.json` and
   `~/.gemini/config/mcp_config.json` — only if question 3 says yes.
4. Register `codebase-memory` per [codebase-memory-and-mcp.md](../codebase-memory-and-mcp.md),
   then deploy [cbmignore.template](../../resources/templates/cbmignore.template) to `.cbmignore`.
5. Disable background watching: `codebase-memory-mcp config set auto_watch false`.
6. Add `.codebase-memory/` to `.gitignore`.
7. Index once:
   `codebase-memory-mcp cli index_repository --repo-path "<canonical-path>" --mode <fast|moderate>`.
8. Confirm each accepted server reports `connected`; report failures with their error.

## Acceptance

- [ ] `docs/project.json` lists the accepted `mcp_servers`.
- [ ] `mcp.json` (and AGY configs when chosen) contain every accepted server and no declined server.
- [ ] `codebase-memory-mcp config get auto_watch` returns `false`.
- [ ] `.codebase-memory/` is ignored by git.
- [ ] `codebase-memory-mcp cli get_architecture` succeeds.

## Notes

- Server list, recommendation matrix, and disabling semantics: [mcp-server-catalog.md](../mcp-server-catalog.md).
- Prefer pinned local installs over `npx <pkg>@latest`; cold `npx` resolution
  routinely exceeds the 30s MCP connect timeout.
- AGY ignores `"disabled": true` inside `mcpServers`; move unwanted entries to
  `_disabledMcpServers`.
- Do not enable the watcher "just for this repo"; the stutter is global.
