# Agent Roster & Permission Boundaries

Guide for feature N9 of `nextjs-dev-setup`. Installs the OpenCode agents that keep
implementation and test authorship in separate, permission-bounded contexts.

---

## 1. Why Permissions, Not Prompts

A prompt telling an agent "do not edit tests" is a suggestion. OpenCode's
`permission` block is enforcement: with `edit` denied on a path, the `write`,
`edit`, and `apply_patch` tools are unavailable for that path, so a confused or
manipulated model cannot touch it.

Three boundaries are load-bearing:

1. **Dev cannot edit tests** → a failing suite cannot be silenced by rewriting it.
2. **Test agents cannot edit implementation** → a test cannot be "fixed" by
   changing product code.
3. **Edge tests are owned only by the auditor** → the baseline author cannot grade
   its own coverage.

---

## 2. Roster

| Agent | Mode | Spawned by | Purpose |
| :--- | :--- | :--- | :--- |
| `nextjs-orchestrator` | primary | user (Tab / command) | Runs the pipeline, owns gates, plan checklist, final report |
| `nextjs-dev` | subagent | orchestrator | Components, pages, skeletons, dictionaries, barrel files |
| `nextjs-test-author` | subagent | orchestrator | Baseline unit tests, page E2E, test plan |
| `nextjs-qa-auditor` | subagent | orchestrator | Immutable edge tests, component E2E, audit report |

The orchestrator's `permission.task` allows only these three names, so it cannot
wander into unrelated subagents.

---

## 3. Permission Model (verified behavior)

Agent frontmatter uses the documented map form:

```yaml
permission:
  edit:
    "*": allow
    "**/*.test.tsx": deny
  bash:
    "*": deny
    "pnpm test *": allow
```

Verified against OpenCode V2:

- Rules are appended **after** the global defaults and evaluated **last match
  wins**, so a broad `"*"` rule first and narrow exceptions after is correct.
- `bash` is compiled to the internal action **`shell`**; command patterns match
  the whole command string.
- `edit` gates `write`, `edit`, and `apply_patch` together.
- `task` gates subagent spawning; `deny` removes the target from the task tool.
- The CLI's `opencode debug agents` prints the resolved permission list — use it
  to confirm ordering instead of trusting the YAML by eye.
- The list form (`permissions: [{ action, resource, effect }]`) also resolves, but
  the map form is the documented agent field. New files use the map form.

### Shell write vectors

`edit: deny` does not stop a shell from writing a file. Every template therefore
denies, after its allows:

`*>*`, `*<*`, `*;*`, `*&&*`, `*&*`, `*|*`, `` *`* ``, `*$(*`,
`*Set-Content*`, `*Add-Content*`, `*Out-File*`, `*New-Item*`, `*Remove-Item*`,
`*Copy-Item*`, `*Move-Item*`, `*Invoke-WebRequest*`, `*Invoke-RestMethod*`.

This trades some legitimate compound commands for a real write boundary. Agents
run one command per call, which is also the repository convention (Rule 12).

---

## 4. Placeholders

Never deploy a template verbatim. Substitute:

| Token | pnpm | npm | yarn | bun |
| :--- | :--- | :--- | :--- | :--- |
| `{{PM}}` | `pnpm` | `npm` | `yarn` | `bun` |
| `{{PM_RUN}}` | `pnpm` | `npm run` | `yarn` | `bun run` |
| `{{MODEL_LINE}}` | `model: <provider>/<model>` or an empty line | same | same | same |

Then reconcile the shell allow-list with the real `package.json` scripts. If a
repository names its scripts differently (`check`, `e2e`, `vitest`), add the exact
commands; do not widen `"*"`.

---

## 5. Deployment Checklist

- [ ] `.opencode/agents/nextjs-dev.md`
- [ ] `.opencode/agents/nextjs-test-author.md`
- [ ] `.opencode/agents/nextjs-qa-auditor.md`
- [ ] `.opencode/agents/nextjs-orchestrator.md`
- [ ] `.agents/rules/agent-boundaries.md`
- [ ] `.opencode/commands/create-nextjs-component.md`
- [ ] `.opencode/commands/create-nextjs-page.md`
- [ ] `docs/project.json` → `project_context_and_metadata.agents`
- [ ] `AGENTS.md` → Agent Roster & Delegation section
- [ ] No `{{TOKEN}}` remains in any deployed file
- [ ] `opencode debug agents` lists all four with expected rules

---

## 6. Smoke Tests

Run these once after installation, in a throwaway branch. Each must be **refused**,
and the agent must report the restriction rather than work around it.

| Test | Agent | Expected |
| :--- | :--- | :--- |
| Edit an existing `Foo.test.tsx` | `nextjs-dev` | Denied by permission |
| Edit `Foo.tsx` | `nextjs-test-author` | Denied by permission |
| Edit `Foo.test.tsx` | `nextjs-qa-auditor` | Denied by permission |
| Edit `Foo.edge.test.tsx` | `nextjs-qa-auditor` | Allowed |
| Write a file through `Set-Content` / `echo >` | any | Denied by shell rule |
| Spawn `@general` | any role agent | Denied by `task` |
| Ask the user a question | any role agent | Denied; must return `BLOCKED` |

**Verified on OpenCode V2 (Nov 2026)** with `ollama/gemma4:e4b` in a scratch
repository: `nextjs-test-author` → component `write` was rejected with
`Permission denied: edit`; `nextjs-dev` → `Foo.test.tsx` was rejected;
`nextjs-dev` → `Foo.tsx` succeeded; `nextjs-qa-auditor` → `Foo.test.tsx` was
rejected and `Foo.edge.test.tsx` succeeded; `nextjs-dev` running
`Set-Content -Path …` was rejected with `Permission denied: shell`. Re-run the
same matrix after changing any pattern.

New agent files register on the **next** session. A session already running will
not see them.

---

## 7. Repair Ownership

```
suite fails
  -> owning test agent returns failures[] + code_fixes_required[]
  -> nextjs-dev fixes implementation
  -> owning test agent re-runs the same files
  -> repeat until exit 0
```

- Baseline assertion wrong → `nextjs-test-author` may fix it, and must record the
  reason. This is the only permitted test edit during repair.
- Edge assertion wrong → requires an explicit user decision; the orchestrator
  applies it and logs it. No test agent may edit an edge test.
- Implementation wrong → dev fixes it. Always the default assumption.

---

## 8. Degraded Mode

Repositories without `.opencode/agents/` (or non-OpenCode harnesses) can still run
the pipeline, but the orchestrator must:

1. Announce `DEGRADED: agent permissions unavailable`.
2. Use the prompts in `nextjs-adversarial-qa/resources/prompts/`.
3. Run the write audit (`audit-agent-writes`) before reporting success, since
   boundaries are no longer enforced at write time.
