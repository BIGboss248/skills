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

## Next.js

- **Creation and test authoring are separate.** `/create-nextjs-component` runs
  `nextjs-component-dev`; `/create-nextjs-page` runs `nextjs-page-dev` and routes
  every new section through `nextjs-component-dev`. Neither command writes tests.
- **Only `nextjs-test` writes tests.** `*.test.*`, `*.edge.test.*`, `*.spec.*`,
  test plans, and `tests/e2e/**` are authored exclusively through the
  `nextjs-test` skill. Creation skills and `nextjs-dev` never create, edit, or
  scaffold test files.
- **Isolated branches, approval-gated merge.** Next.js work happens on
  `agent/<slug>` in its own worktree; merge into `main` only after the user
  approves the `review` summary. Unapproved merges exit `4`.
