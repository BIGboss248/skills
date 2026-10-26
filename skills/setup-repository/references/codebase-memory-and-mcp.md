# Codebase Memory MCP & Stutter Prevention Guide (`setup-repository`)

Equip the repository with the `codebase-memory-mcp` persistent knowledge graph server (162 languages, Tree-sitter AST, Hybrid LSP semantic type resolution, and 100% local vector search).

---

## 1. Install Binary

- **Windows (PowerShell)**:
  ```powershell
  Invoke-WebRequest -Uri https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1 -OutFile install.ps1
  Unblock-File .\install.ps1
  .\install.ps1
  Remove-Item .\install.ps1
  ```
- **macOS / Linux (Bash)**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash
  ```
- **Global npm Package Alternative**:
  ```bash
  npm install -g codebase-memory-mcp@latest
  ```

---

## 2. Register MCP Server (Workspace & AGY Global Only)

> [!IMPORTANT]
> **Global MCP Registration is for Antigravity (AGY) ONLY.**
> Antigravity discovers and loads MCP servers that are configured globally on the host system. **Never configure or register MCP servers globally for other coding agents** (e.g., Claude Desktop, Cursor, VS Code, Cline).

1. **Workspace Root `mcp.json`** (and `.agents/mcp_config.json` if present):
   ```json
   {
     "mcpServers": {
       "codebase-memory": {
         "command": "codebase-memory-mcp",
         "args": []
       }
     }
   }
   ```
2. **Global Host Config (Google Antigravity / AGY Only)**:
   - `~/.gemini/antigravity/mcp_config.json`
   - `~/.gemini/config/mcp_config.json`
   ```json
   {
     "mcpServers": {
       "codebase-memory": {
         "command": "codebase-memory-mcp",
         "args": []
       }
     }
   }
   ```

---

## 3. Configure `.cbmignore` Exclusions & Disable `auto_watch`

1. **Deploy `.cbmignore`**:
   Copy [`cbmignore.template`](../resources/templates/cbmignore.template) to `<repo>/.cbmignore` at the repository root to exclude `.agents/`, `docs/`, `*.md`, and build/test caches from triggering AST re-indexing.
2. **Disable Automatic Session File-Watching (`auto_watch = false`)**:
   ```bash
   codebase-memory-mcp config set auto_watch false
   ```
3. **Git Hygiene**:
   - Add `.codebase-memory/` to `.gitignore`.
   - If sharing the pre-indexed snapshot with a team, track `.codebase-memory/graph.db.zst` via Git LFS in `.gitattributes`.
4. **Initial On-Demand Indexing & Cadence Script**:
   ```bash
   codebase-memory-mcp cli index_repository --repo-path "<canonical-repo-path>" --mode moderate
   ```
   Add `"cbm:update": "codebase-memory-mcp cli index_repository --repo-path . --mode moderate --persistence true"` to `package.json` scripts.
