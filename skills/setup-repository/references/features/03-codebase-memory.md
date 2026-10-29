# F3 — Codebase Memory MCP

## Enable when

The `codebase-memory` skill is installed and the repository is large enough that
graph search beats grep.

## Questions

1. If the binary/MCP is missing: install it, or skip this feature?
2. Register workspace-only, or also globally for Google Antigravity (AGY)?
3. Index mode for the first run: `fast` or `moderate`?

## Steps

1. Register in workspace `mcp.json` (and `.agents/mcp_config.json` if present).
2. Register globally for AGY only, in `~/.gemini/antigravity/mcp_config.json` and
   `~/.gemini/config/mcp_config.json` — only if question 2 says yes.
3. Deploy [cbmignore.template](../../resources/templates/cbmignore.template) to `.cbmignore`.
4. Disable background watching: `codebase-memory-mcp config set auto_watch false`.
5. Add `.codebase-memory/` to `.gitignore`.
6. Index once:
   `codebase-memory-mcp cli index_repository --repo-path "<canonical-path>" --mode <fast|moderate>`.

## Acceptance

- [ ] `codebase-memory-mcp config get auto_watch` returns `false`.
- [ ] `.codebase-memory/` is ignored by git.
- [ ] `codebase-memory-mcp cli get_architecture` succeeds.

## Notes

- Full configuration details: [codebase-memory-and-mcp.md](../codebase-memory-and-mcp.md).
- Do not enable the watcher "just for this repo"; the stutter is global.
