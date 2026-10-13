# Model Context Protocol (MCP) Configuration Guide

Model Context Protocol (MCP) servers equip AI coding agents with direct runtime inspection, dev server telemetry, code intelligence, and browser automation.

---

## 1. Mandatory Dual MCP Configuration Architecture

> [!IMPORTANT]
> **Antigravity (AG) MCP Discovery & Loading Rule:**
> Antigravity (AG) **only sees and loads MCP servers that are configured globally on the host system** (in `~/.gemini/antigravity/mcp_config.json` and `~/.gemini/config/mcp_config.json`). Workspace-level MCP configuration files alone are NOT loaded by AG's Language Server.
> However, workspace-level configuration files (`mcp.json`, `.vscode/mcp.json`, or `.agents/plugins/workspace-tools/mcp_config.json`) are required for repository portability, version control, and non-AG coding agents (Cursor, Windsurf, Claude Code, Junie, VS Code).
> **Therefore, the agent MUST configure MCP servers for BOTH the workspace AND globally for AG on the host system.**

### Dual Configuration Targets:

1. **Antigravity (AG) Host Global Configuration (`~/.gemini/antigravity/mcp_config.json` & `~/.gemini/config/mcp_config.json`)**:
   - Strictly for Google Antigravity / AGY (per Rule 14; never register globally for other coding agents).
   - Enables tools in the agent toolset and the `@` mentions menu.
2. **Workspace Configuration (`mcp.json`, `.vscode/mcp.json`, `.agents/plugins/workspace-tools/mcp_config.json`)**:
   - Standard root `mcp.json` for universal cross-editor portability.

---

## 2. Server Specifications

### 2.1. Next.js Dev Server MCP (`next-devtools`)

- **Package**: `next-devtools` (`@modelcontextprotocol/server-nextjs`)
- **Purpose**: Query live Next.js compilation status, inspect runtime/build errors, list active routes, clear cache, and evaluate browser scripts against the running dev server on port 3000.
- **Config**:
  ```json
  "next-devtools": {
    "command": "npx",
    "args": ["-y", "next-devtools"]
  }
  ```

### 2.2. Codebase Memory Intelligence MCP (`codebase-memory-mcp`) with Stutter Prevention

- **Package**: `codebase-memory-mcp`
- **Purpose**: Persistent AST knowledge graph (162 languages, Tree-sitter, Hybrid LSP) for 99% token reduction in code exploration.

#### Installation:

- **Windows (PowerShell)**:
  ```powershell
  Invoke-WebRequest -Uri https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1 -OutFile install.ps1
  Unblock-File .\install.ps1
  .\install.ps1
  Remove-Item .\install.ps1
  ```
- **macOS / Linux**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash
  ```

#### Crucial Stutter Prevention Gate (`auto_watch = false`):

> [!CAUTION]
> **Eliminate Editor Stutters On Save:**
> By default, `codebase-memory-mcp` automatically registers connected workspaces with its background git watcher (`auto_watch = true`). Whenever a file is edited, the watcher detects changes and compresses `.codebase-memory/graph.db.zst` on every single save, causing severe editor stutters.
> **Always disable automatic session watching globally during dev setup:**
>
> ```bash
> codebase-memory-mcp config set auto_watch false
> ```

#### Root Exclusions (`.cbmignore`) and Git Hygiene:

- Copy starter `.cbmignore` from [`cbmignore.template`](../resources/templates/cbmignore.template) to project root.
- Add `.codebase-memory/` to `.gitignore`.

### 2.3. Playwright Browser Automation MCP (`@playwright/mcp`)

- **Package**: `@playwright/mcp@latest`
- **Purpose**: Real browser automation, accessibility snapshot inspection, and DOM interaction.
- **Config**:
  ```json
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
  ```

### 2.4. Storybook AI MCP (`@storybook/addon-mcp`)

- **Endpoint**: `http://localhost:6006/mcp` (active when `pnpm run storybook` is running).
- **Purpose**: Component preview, story discovery (`stories-find-by-component`), doc querying (`docs-show-story`), and test execution (`test-run`).
- **Config**:
  ```json
  "storybook": {
    "url": "http://localhost:6006/mcp"
  }
  ```

---

## 3. Unified Dual Configuration Schema

```json
{
  "mcpServers": {
    "next-devtools": {
      "command": "npx",
      "args": ["-y", "next-devtools"]
    },
    "codebase-memory": {
      "command": "codebase-memory-mcp",
      "args": []
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "storybook": {
      "url": "http://localhost:6006/mcp"
    }
  }
}
```

> [!NOTE]
> In Antigravity global MCP configurations, `agy.exe` does not respect `"disabled": true` inside `mcpServers`. To disable a server, move it completely out of `mcpServers` (e.g. into `_disabledMcpServers`).
