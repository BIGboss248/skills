# N10 — MCP Servers & Codebase Memory

**Category:** Delivery & Operations · **Default:** on when tooling is installed · **Depends on:** N1

## Enable when

The repository needs agent tooling (Next.js dev server, browser automation,
Storybook inspection) or graph search beats grep for navigation. Skip in
environments without MCP support.

## Questions

1. **Servers** — which of `next-devtools`, `playwright`, `storybook`, and
   `codebase-memory-mcp` does this repository need? Present the recommendation as
   a multi-select and register only the accepted set.
2. **Install** — is `codebase-memory-mcp` installed? Install it, or skip the
   graph server?
3. **Scope** — workspace-only, or also global for Google Antigravity?
4. **First index** — `fast` or `moderate`?

> [!IMPORTANT]
> Antigravity only discovers MCP servers configured globally on the host system
> (`~/.gemini/antigravity/mcp_config.json` and `~/.gemini/config/mcp_config.json`).
> Workspace `mcp.json` is kept for portability; configure both when global scope
> is selected.

## Steps

1. Register the accepted servers in workspace `mcp.json` (and
   `.agents/plugins/workspace-tools/mcp_config.json` when present); record them in
   `docs/project.json` under `project_context_and_metadata.mcp_servers`.
2. Register globally only when question 3 says yes. Never put unwanted entries
   inside `mcpServers` with `"disabled": true` — AGY ignores it; move them to
   `_disabledMcpServers`.
3. Set `auto_watch = false`:
   `codebase-memory-mcp config set auto_watch false`.
4. Deploy [cbmignore.template](../../resources/templates/cbmignore.template) to
   `.cbmignore` and add `.codebase-memory/` to `.gitignore`.
5. Index once:
   `codebase-memory-mcp cli index_repository --repo-path "<canonical-path>" --mode <fast|moderate>`.
6. Confirm each accepted server reports `connected`; report failures with their
   error instead of retrying silently.

## Acceptance

- [ ] `docs/project.json` lists exactly the accepted `mcp_servers`.
- [ ] `mcp.json` (and the AGY configs when chosen) contain every accepted server
      and no declined server.
- [ ] `codebase-memory-mcp config get auto_watch` returns `false`.
- [ ] `.cbmignore` excludes `.agents/`, `docs/`, `.next/`, and build artifacts.
- [ ] `codebase-memory-mcp cli get_architecture` succeeds.

## Notes

- Prefer pinned local installs over `npx <pkg>@latest`; cold `npx` resolution
  exceeds the MCP connect timeout.
- The watcher stutter is global: do not re-enable it "just for this repo".
- Details: [mcp-configuration-guide.md](../mcp-configuration-guide.md).
