# Global Rules

Cross-project defaults for every OpenCode session. Project `AGENTS.md` files add
to these; they never conflict-resolve, so keep the specifics in the project file.

## Git

- Never commit or push unless the user explicitly asks. Stage changes after edits.

## Shell

- Run one command per invocation. Never chain with `&&`, `||`, or `;`.
- On Windows, use PowerShell for file operations rather than ad-hoc scripts.

## Downloads

- Fetch binary or raw files with PowerShell `Invoke-WebRequest -OutFile`. A text
  fetcher corrupts images and exports.

## Images

- Do not generate images. Output the structured image prompt instead and let the
  user place the asset.

## Tools

- Ask which MCP servers a repository needs before enabling any. Every enabled
  server costs context on every request, so never enable all of them.
- When a project has code-intelligence MCP configured, prefer its symbol and
  reference tools over blind text grep.

## Knowledge

- Record root causes, gotchas, and architectural lessons in the project's notes
  with prescriptive wording, so the next agent avoids the same mistake.
