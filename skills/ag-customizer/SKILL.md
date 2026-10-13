---
name: ag-customizer
description: Create, configure, manage, and validate Google Antigravity customizations including skills, rules, MCP servers, lifecycle hooks, plugins, and custom JSON configs. Use when adding new capabilities to Antigravity, configuring MCP servers, writing rules, creating skills, setting up hooks, or modernizing legacy workflows.
---

# Antigravity Customizer (`ag-customizer`)

Use this skill to autonomously design, scaffold, configure, migrate, and validate customizations for Google Antigravity across workspace and global scopes.

---

## Quick Navigation Decision Matrix

Determine which customization mechanism best solves the problem:

| Need                                                                      | Mechanism              | File Location                                                                      | Reference Guide                                             |
| :------------------------------------------------------------------------ | :--------------------- | :--------------------------------------------------------------------------------- | :---------------------------------------------------------- |
| Teach the agent a multi-step runbook, procedure, or slash command         | **Skill**              | `.agents/skills/<name>/SKILL.md` or `~/.gemini/antigravity/skills/<name>/SKILL.md` | [skills-guide.md](references/skills-guide.md)               |
| Enforce persistent constraints, coding standards, or style rules          | **Rule**               | `.agents/rules/<name>.md`, `AGENTS.md`, or `~/.gemini/GEMINI.md`                   | [rules-guide.md](references/rules-guide.md)                 |
| Connect external services, local databases, or custom tools               | **MCP Server**         | `.agents/mcp_config.json` or `~/.gemini/config/mcp_config.json`                    | [mcp-guide.md](references/mcp-guide.md)                     |
| Intercept lifecycle events (gate commands, inject prompts, stop watchdog) | **Lifecycle Hook**     | `.agents/hooks.json` or `~/.gemini/config/hooks.json`                              | [hooks-guide.md](references/hooks-guide.md)                 |
| Bundle skills, rules, hooks, and MCP into a shareable package             | **Plugin**             | `.agents/plugins/<name>/` or `~/.gemini/config/plugins/<name>/`                    | [plugins-and-configs.md](references/plugins-and-configs.md) |
| Register non-standard paths or share customizations via VCS               | **JSON Config**        | `.agents/skills.json` or `.agents/plugins.json`                                    | [plugins-and-configs.md](references/plugins-and-configs.md) |
| Upgrade deprecated workflows into modern slash-command skills             | **Workflow Migration** | `.agents/workflows/*.md` -> `.agents/skills/<name>/SKILL.md`                       | [workflows-migration.md](references/workflows-migration.md) |

---

## Operational Workflows

### 1. Adding a New Skill

1. **Determine Scope**:
   - **Workspace**: `.agents/skills/<name>/` (checked into repository for team use).
   - **Global**: `~/.gemini/antigravity/skills/<name>/` (available across all projects).
2. **Structure the Directory**:
   ```text
   <customization_root>/skills/<skill-name>/
   ├── SKILL.md             # Required: Entry point with YAML frontmatter
   ├── scripts/             # Optional: Helper scripts (run with --help pattern)
   ├── references/          # Optional: Disclosed manuals & heavy documentation
   └── examples/            # Optional: Sample code or output references
   ```
3. **Draft Frontmatter**:
   - `name`: Lowercase, hyphenated (e.g. `nextjs-otel`, `docker-deploy`). This also registers as a slash command (`/<name>`).
   - `description`: 1-3 sentences in **third person**, explicitly stating **what** the skill does and **specific trigger phrases/scenarios** when the agent should activate it.
4. **Apply Progressive Disclosure**:
   - Keep the main `SKILL.md` tightly focused on the sequence of operational steps and completion criteria.
   - Disclose deep reference material into `references/<topic>.md` files and link them relatively.
   - Refer to [skills-guide.md](references/skills-guide.md) for structure templates.
5. **Obsidian Mirroring Check**:
   - When updating or creating skills in this workspace, mirror the skill folder to `d:/Scripts/Obsidian/skills/<name>/` per repository guidelines.

---

### 2. Creating a Rule

1. **Determine Scope & Format**:
   - **Workspace Rule**: `.agents/rules/<rule-name>.md` or `AGENTS.md` at project root.
   - **Global Rule**: `~/.gemini/GEMINI.md`.
2. **Choose Activation Mode** (for `.agents/rules/*.md`):
   - `always_on`: Injected unconditionally into every turn. Use sparingly to preserve context.
   - `model_decision`: Disclosed when the agent determines relevance based on the description.
   - `glob`: Automatically activated whenever matching files are touched or opened (e.g. `*.tsx`, `src/api/**/*.ts`).
   - `manual`: Only loaded when explicitly invoked via `@mention` in chat (e.g. `@my-rule.md`).
3. **Author Content**:
   - Keep within the **12,000-character budget** per file.
   - State target behaviors in the **positive** ("Do X", "Always structure Y") rather than negative prohibitions.
   - Use `@filename` to link to companion context files if needed.
   - Refer to [rules-guide.md](references/rules-guide.md) for full syntax and activation frontmatter.

---

### 3. Configuring an MCP Server

1. **Determine File Location**:
   - Workspace: `<workspace>/.agents/mcp_config.json`
   - Global: `~/.gemini/config/mcp_config.json`
2. **Select Transport**:
   - **stdio** (Local executable):
     ```json
     {
       "mcpServers": {
         "my-server": {
           "command": "npx",
           "args": ["-y", "@modelcontextprotocol/server-sqlite", "app.db"],
           "env": { "SQLITE_READONLY": "true" }
         }
       }
     }
     ```
   - **Remote (SSE / Streamable HTTP)**:
     > [!IMPORTANT]
     > Always use the key **`serverUrl`**. The legacy keys `url` or `httpUrl` are not supported.
     ```json
     {
       "mcpServers": {
         "my-remote": {
           "serverUrl": "https://api.example.com/mcp/",
           "headers": { "Authorization": "Bearer YOUR_TOKEN" }
         }
       }
     }
     ```
3. **Authentication**:
   - Google Application Default Credentials: `"authProviderType": "google_credentials"` (requires `gcloud auth application-default login`).
   - OAuth: `"oauth": { "clientId": "...", "clientSecret": "..." }` with redirect URI `https://antigravity.google/oauth-callback`.
4. **Tool Filtering**:
   - Temporarily disable tools without removing server: `"disabledTools": ["destructive_command"]`.
   - Refer to [mcp-guide.md](references/mcp-guide.md) for pre-built configurations.

---

### 4. Setting Up Lifecycle Hooks

1. **Target File**: `.agents/hooks.json` (or `~/.gemini/config/hooks.json`).
2. **Supported Events**:
   - `PreToolUse`: Match tool names (`run_command`, `write_to_file`, `*`) to gate execution (`allow`, `deny`, `ask`, `force_ask`) or shallow-overwrite arguments.
   - `PostToolUse`: Audit output, run linters, or format code after tool completes.
   - `PreInvocation`: Inject context or system instructions (`injectSteps` with `ephemeralMessage`) before model processes the turn.
   - `PostInvocation`: Force continuation (`terminationBehavior: "force_continue"`) or stop.
   - `Stop`: Inspect task completion (`terminationReason`, `fullyIdle`) and return `decision: "continue"` with `reason` to block premature exit.
3. **Contract Rules**:
   - Execution passes context via **stdin** and receives response via **stdout**.
   - All JSON payload keys use **camelCase** (`conversationId`, `stepIdx`, `toolCall`, etc.).
   - Commands execute synchronously and block the agent loop until timeout (default 30s).
   - Refer to [hooks-guide.md](references/hooks-guide.md) for templates in Python, PowerShell, and Bash.

---

### 5. Packaging a Plugin or VCS Shared Config

1. **Plugin Package**:
   - Group related skills, rules, hooks, and MCP servers into `.agents/plugins/<plugin-name>/`.
   - Add `plugin.json` manifest (`{"name": "my-plugin"}`).
   - Manage activation state in `config.json` under `"plugins": { "<plugin-name>": { "enabled": true } }`.
2. **JSON Configurations (`skills.json` / `plugins.json`)**:
   - Register external directories or shared team repositories.
   - Support `entries` (paths) and `inherits` (other configs) with `include_only` and `exclude` regex filters.
   - Refer to [plugins-and-configs.md](references/plugins-and-configs.md) for complete manifest examples.

---

### 6. Modernizing Legacy Workflows

1. Inspect for deprecated `.agents/workflows/*.md` or `~/.gemini/config/workflows/*.md`.
2. Extract operational instructions and generate equivalent `SKILL.md` with proper YAML frontmatter.
3. Archive original file to `<name>.md.bak` (safe preservation).
4. Refer to [workflows-migration.md](references/workflows-migration.md) for the automated migration runbook.

---

## Validation & Verification Checklist

Before considering any customization complete:

- [ ] **JSON Syntax**: Ensure all `.json` files parse cleanly without syntax errors or comments.
- [ ] **Frontmatter Check**: Verify `SKILL.md` contains valid YAML frontmatter with `name` and descriptive `description`.
- [ ] **Character Budget**: Ensure rule Markdown files are within the 12,000 character limit.
- [ ] **MCP Connection**: Verify command binaries or remote URLs exist and authenticate.
- [ ] **Hook Contract**: Verify hook scripts accept camelCase JSON on stdin and return valid JSON on stdout.
- [ ] **Obsidian Mirroring**: For skills in this workspace, sync the created skill folder to `d:/Scripts/Obsidian/skills/<name>/`.
