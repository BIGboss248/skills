# MCP Setup & Tool Reference

This guide details configuring, testing, auto-installing, and querying the local `seo` Model Context Protocol (MCP) server within Antigravity and AI coding agents.

---

## 1. Prerequisites & Auto-Installation

- **Node.js**: Version 22.0.0 or higher.
- **Package Installation**:
  ```bash
  npm install -g seo
  ```
- **Daemon Health Verification**:
  ```bash
  npx -y seo mcp serve --test
  ```
  *(Returns exit code 0 on success. Normal `seo mcp serve` runs as a persistent stdio daemon awaiting client JSON-RPC on stdin/stdout).*

---

## 2. Configuration Scopes

### Workspace Scope (`.agents/mcp_config.json`)

```json
{
  "mcpServers": {
    "seo": {
      "command": "npx",
      "args": ["-y", "seo", "mcp", "serve"],
      "env": {}
    }
  }
}
```

### Global Scope (`~/.gemini/config/mcp_config.json`)

```json
{
  "mcpServers": {
    "seo": {
      "command": "npx",
      "args": ["-y", "seo", "mcp", "serve"]
    }
  }
}
```

> [!IMPORTANT]
> **Restart Requirement**: When `.agents/mcp_config.json` or `~/.gemini/config/mcp_config.json` is modified or newly added, Antigravity loads the server only upon a new session start or window reload. Always instruct the user to restart the agent session after configuring the server.

---

## 3. The 3-Tool MCP Discovery-Description-Execution Pattern

The `seo` MCP server deliberately exposes **3 compact tools** to keep agent context windows lean:

```mermaid
flowchart LR
    A["1. seo_list_reports<br/>(Discover Report IDs)"] --> B["2. seo_describe_report<br/>(Get JSON Schema & Rules)"] --> C["3. seo_run_report<br/>(Execute with Bounded Params)"]
```

### 1. `seo_list_reports`
- **Purpose**: Lists available report IDs, descriptions, and categories.
- **Optional Argument**: `category` (e.g., `"crawl"`, `"gsc"`, `"keywords"`, `"competitors"`, `"pseo"`, `"ai"`).

### 2. `seo_describe_report`
- **Purpose**: Returns the exact JSON Schema for parameters, required/optional fields, reading order (`readOrder`), verification steps, and non-claims (`doNotClaim`).
- **Required Argument**: `reportId` (e.g., `"quick-wins"`, `"audit-page"`, `"competitor-keyword-gap"`).

### 3. `seo_run_report`
- **Purpose**: Executes the report and returns structured findings.
- **Arguments**:
  - `reportId` (string, required)
  - `params` (object, optional): Bounded parameters conforming to the schema.
  - `view` (string, optional): Pass `"actions"` for high-priority action queues.

---

## 4. Key Report Categories & Workflow Recipes

| Category | Primary Reports | Purpose |
| :--- | :--- | :--- |
| **Crawl & Page** | `site-crawl`, `audit-page`, `audit-urls`, `redirect-trace`, `performance-audit` | Local and live technical validations, Core Web Vitals, and redirects. |
| **Findings & Rules** | `top-fixes`, `affected-urls`, `explain-crawl-issue`, `crawler-rules` | Plain-English explanations of crawler rules and affected URL inventories. |
| **Search Console** | `quick-wins`, `second-page`, `lost-clicks`, `cannibalisation`, `period-comparison` | High-impression low-CTR wins, striking-distance queries, and deploy impact. |
| **Programmatic SEO** | `pseo-patterns`, `pseo-opportunities` | Repeatable query patterns, entity combination templates, and route audits. |
| **Competitors & SERP** | `serp-competitors`, `competitor-keyword-gap`, `domain-overview` | Real ranking competitors, SERP intent, and keyword gaps. |
| **AI Search Visibility** | `ai-mention-research`, `ai-prompt-observations` | Tracking brand mentions, citations, and model responses across ChatGPT, Claude, Perplexity. |

---

## 5. Agent Verification & Discipline

1. **Pre-Flight First**: Check if MCP tools (`seo_list_reports`, `seo_describe_report`, `seo_run_report`) are active in context. If not, auto-install and ask for a session restart.
2. **Read Status First**: Inspect data status (`complete`, `partial`, `capped`, `filtered`, `unavailable`) and caveats before forming conclusions.
3. **Assign Explicit Outcomes**:
   - For technical fixes: Mark each as `fixed`, `deferred`, or `not-needed`.
   - For content reviews: Mark each as `changed`, `no-change`, or `deferred`.
4. **Never Drop Findings**: Track every finding ID and URL inventory item returned by `seo_run_report`.
