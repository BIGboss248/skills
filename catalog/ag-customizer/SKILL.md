---
name: ag-customizer
description: >-
  Configure Antigravity and OpenCode customizations. Use when adding a skill,
  rule, MCP server, hook, or plugin, or when converting a legacy workflow.
---

# Antigravity Customization

How a customization is chosen, placed, and validated. This skill owns
configuration files only.

## Choose the mechanism

| Need | Mechanism | Location |
| :--- | :--- | :--- |
| Teach a procedure or capability | Skill | `.agents/skills/<name>/SKILL.md` or `~/.gemini/antigravity/skills/<name>/` |
| Persist a constraint or standard | Rule | `.agents/rules/<name>.md`, `AGENTS.md`, `~/.gemini/GEMINI.md` |
| Connect an external service or tool | MCP server | Workspace `mcp.json` / `.agents/mcp_config.json` / `opencode.json`, plus AG global configs |
| Intercept a lifecycle event | Hook | `.agents/hooks.json` or `~/.gemini/config/hooks.json` |
| Ship a bundle | Plugin | `.agents/plugins/<name>/` with `plugin.json` |

References: [skills](./references/skills-guide.md) ·
[rules](./references/rules-guide.md) · [MCP](./references/mcp-guide.md) ·
[hooks](./references/hooks-guide.md) ·
[plugins and configs](./references/plugins-and-configs.md).

## Skills

- Workspace scope for team use; global scope only for cross-project tools.
- `name` is lowercase and hyphenated; it also becomes `/<name>`.
- `description` states the job and when to invoke it, in one or two sentences.
- Body under ~200 lines; deep material in `references/`, boilerplate in
  `resources/templates/`, deterministic helpers in `scripts/` as both `.ps1`
  and `.sh`.
- Authoring detail: use the `skill-creator` skill.

## Rules

- Workspace rule files or `AGENTS.md`; global rules in `~/.gemini/GEMINI.md`.
- Activation: `always_on` (every turn, use sparingly), `model_decision`
  (disclosed by description), `glob` (matching files), `manual` (`@mention`).
- Keep under the 12,000-character budget per file.
- Write positive instructions ("Do X") before prohibitions.
- Prefer a deterministic check (lint, hook, CI) over a prose rule whenever the
  constraint is mechanical.

## MCP servers

Register in every place that must discover it:

| Scope | Files |
| :--- | :--- |
| Antigravity global (AG only) | `~/.gemini/antigravity/mcp_config.json`, `~/.gemini/config/mcp_config.json` |
| Workspace (AG and generic) | `<workspace>/mcp.json`, `<workspace>/.agents/mcp_config.json` |
| Workspace OpenCode (local only) | `<workspace>/opencode.json` under `mcp.servers` |

- Never write OpenCode config to `~/.config/opencode/`.
- Schema differs: AG uses `mcpServers` with `command`/`args`/`env` and
  `serverUrl` for remote; OpenCode uses `mcp.servers` with `type: "local"`,
  a single `command` array, `environment`, and `url` for remote.
- `agy.exe` ignores `"disabled": true`; move a disabled server out to
  `_disabledMcpServers`.
- Ask before enabling: every server adds tool definitions to every request.
- Exact recipes and the translation table:
  [MCP guide](./references/mcp-guide.md).

## Hooks

- Events: `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`,
  `Stop`.
- Contract: JSON on stdin, JSON on stdout, camelCase keys, synchronous execution
  (default 30 s timeout).
- `Stop` returns `decision: "continue"` with a reason to block a premature exit.
- Templates in Python, PowerShell, and Bash:
  [hooks guide](./references/hooks-guide.md).

## Plugins and shared config

- A plugin groups skills, rules, hooks, and MCP entries, with a `plugin.json`
  manifest and an enable flag in `config.json`.
- `skills.json` / `plugins.json` register external directories with `entries`,
  `inherits`, and include/exclude filters.

## Legacy workflows

- `.agents/workflows/*.md` is deprecated. Convert to `SKILL.md`, archive the
  original as `<name>.md.bak`, and keep the trigger phrases.
- Runbook: [workflows migration](./references/workflows-migration.md).

## Definition of Done

- [ ] The mechanism matches the need in the table above.
- [ ] Every JSON file parses and contains no comments.
- [ ] MCP entries exist in the workspace **and** the AG global configs, in each
      schema, and not in the global OpenCode config.
- [ ] Rule files are within budget and use the declared activation mode.
- [ ] Hook scripts accept stdin JSON and return valid stdout JSON.
- [ ] Skill frontmatter has `name` and a trigger-first `description`.

## Edge Cases & Pitfalls

- **Global OpenCode writes** — leaking a workspace server into every project.
- **AG remote schema** — `url`/`httpUrl` are not read; use `serverUrl`.
- **Disabled flag** — ignored by `agy.exe`; move the entry out.
- **Secrets in config** — tokens belong in environment variables, not committed
  JSON.
- **Always-on rules** — every always-on rule is paid on every turn.
- **Duplicate servers** — the same server registered twice doubles tool context.
- **Legacy workflow left behind** — two sources of truth for one procedure.
