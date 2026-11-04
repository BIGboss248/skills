# Agent Roster & Delegation Boundaries

Guide for feature N9 of `nextjs-dev-setup`. Installs the OpenCode agents that keep
implementation and test authorship in separate contexts.

The roster is **instruction-scoped, not permission-locked**: the subagents carry no
`permission` block, run their own commands, and verify their own work. The
orchestrator writes an explicit brief before every spawn and audits the diff when
the agent returns.

---

## 1. Why Briefs + Audit, Not Permission Blocks

A `permission` block that denies `edit` also removes the tools a role needs to do
its job well: no dependency install, no config fix, no runner workaround, and no
self-verification. The result is a pipeline that stops on breadcrumbs and asks the
user for every shell command.

This roster inverts that: **trust the agent, verify the result.**

1. **The orchestrator briefs.** Every spawn names the role, objective, mode,
   `write_scope`, `read_scope`, `forbidden`, expected commands, and definition of
   done.
2. **The subagent runs.** It has full tool access, runs its own build/lint/type
   check/tests, and returns real command output.
3. **The orchestrator audits.** `git status --short` + `git diff --stat` against
   `write_scope`; anything outside the brief is restored and reported. The suite
   is re-run, not trusted.

Three boundaries remain load-bearing, now as contract:

1. **Dev does not edit tests** → a failing suite cannot be silenced by rewriting it.
2. **Test agents do not edit implementation** → a test cannot be "fixed" by
   changing product code.
3. **Edge tests are owned only by the auditor** → the baseline author cannot grade
   its own coverage.

---

## 2. Roster

| Agent | Mode | Spawned by | Purpose |
| :--- | :--- | :--- | :--- |
| `nextjs-orchestrator` | primary | user (Tab / command) | Runs the pipeline, owns gates, briefs, audits, final report |
| `nextjs-dev` | subagent | orchestrator | Components, pages, skeletons, dictionaries, barrel files |
| `nextjs-test-author` | subagent | orchestrator | Baseline unit tests, page E2E, test plan |
| `nextjs-qa-auditor` | subagent | orchestrator | Immutable edge tests, component E2E, audit report |

The orchestrator's `permission.task` allows only these three names, so it cannot
wander into unrelated subagents. That is the only permission rule in the roster:
delegation gating, not work gating.

---

## 3. Brief Contract

Every spawn starts with this block, filled in. A subagent that receives a task
without a brief returns `BLOCKED: missing brief`.

```text
role: nextjs-test-author | nextjs-dev | nextjs-qa-auditor
objective: <one sentence; the artifact to produce>
mode: baseline | page | implementation | repair | adversarial | audit
write_scope: <explicit globs, e.g. "src/components/**" or "e2e/pages/**">
read_scope: <paths, plus the spec and plan documents>
forbidden: <paths owned by another role + package.json, lockfiles, runner configs>
commands: <exact expected commands, e.g. "pnpm test src/components/Foo.test.tsx">
done_when: <acceptance evidence: green suite, build output, file list>
report: the agent's JSON return block, no prose
```

Brief rules:

- One owner per artifact; never split a single test file between two roles.
- Name the spec (`design-spec.md` / `page-spec.md`) and `implementation_plan.md`.
- Point at the skill path; do not restate the runbook in the brief.
- Never widen `forbidden` to dodge a decision, and never narrow `write_scope` to a
  single file when the role legitimately needs a directory.
- Re-brief on repair rounds; route the same failing test back to its owner.

---

## 4. Review Loop

```
brief -> subagent runs + self-verifies -> orchestration audits diff + re-runs suite
      -> accept | re-brief with failures -> repeat
```

The orchestrator, on every return:

1. `git status --short` and `git diff --stat`; compare with `write_scope`.
2. Restore any out-of-scope path, then report the violation.
3. Re-run the claimed-green command and compare counts.
4. Run `audit-agent-writes` (when installed) and `verify-component-create` /
   `verify-page`.
5. Accept only with the command output that proves the claim.

---

## 5. Placeholders

Never deploy a template verbatim. Substitute:

| Token | pnpm | npm | yarn | bun |
| :--- | :--- | :--- | :--- | :--- |
| `{{PM}}` | `pnpm` | `npm` | `yarn` | `bun` |
| `{{PM_RUN}}` | `pnpm` | `npm run` | `yarn` | `bun run` |
| `{{MODEL_LINE}}` | `model: <provider>/<model>` or an empty line | same | same | same |

Also update the `commands:` examples in the orchestrator brief and the
verification commands in the review step to the repository's real script names
(`test:all`, `e2e`, `check`, ...). Do not invent a script.

---

## 6. Deployment Checklist

- [ ] `.opencode/agents/nextjs-dev.md` — no `permission` block
- [ ] `.opencode/agents/nextjs-test-author.md` — no `permission` block
- [ ] `.opencode/agents/nextjs-qa-auditor.md` — no `permission` block
- [ ] `.opencode/agents/nextjs-orchestrator.md` — `task` allows only the three
      roles; brief + review sections present
- [ ] `.agents/rules/agent-boundaries.md`
- [ ] `.opencode/commands/create-nextjs-component.md`
- [ ] `.opencode/commands/create-nextjs-page.md`
- [ ] `docs/project.json` → `project_context_and_metadata.agents`
- [ ] `AGENTS.md` → Agent Roster & Delegation section
- [ ] No `{{TOKEN}}` remains in any deployed file
- [ ] `opencode debug agents` lists all four with the expected modes

---

## 7. Smoke Tests

Run once after installation, in a throwaway branch. These check *behavior*, not
tool locks:

| Test | Agent | Expected |
| :--- | :--- | :--- |
| Ask it to edit `Foo.test.tsx` during implementation | `nextjs-dev` | Refuses, reports the file as owned by the test author; `git diff` clean for that path |
| Ask it to fix `Foo.tsx` to make a suite pass | `nextjs-test-author` | Refuses, returns `code_fixes_required`; `git diff` clean for `Foo.tsx` |
| Ask it to weaken an existing edge assertion | `nextjs-qa-auditor` | Refuses, returns `immutable_edits` |
| Spawn `@general` | any role agent | Refuses; only the orchestrator delegates |
| Run its own suite | any role agent | Executes it directly, no approval prompt from the user |
| Return `PASS` without output | any role agent | Rejected by the orchestrator review step |

New agent files register on the **next** session. A session already running will
not see them.

---

## 8. Repair Ownership

```
suite fails
  -> owning test agent returns failures[] + code_fixes_required[]
  -> nextjs-dev fixes implementation
  -> owning test agent re-runs the same files
  -> repeat until exit 0
```

- Baseline assertion wrong -> `nextjs-test-author` may fix it, and must record the
  reason. This is the only permitted test edit during repair.
- Edge assertion wrong -> requires an explicit user decision; the orchestrator
  applies it and logs it. No test agent may edit an edge test.
- Implementation wrong -> dev fixes it. Always the default assumption.

---

## 9. Harnesses Without a Roster

Repositories without `.opencode/agents/` (or non-OpenCode harnesses) can still run
the pipeline, but the orchestrator must:

1. Announce `DEGRADED: agent permissions unavailable`.
2. Use the prompts in `nextjs-adversarial-qa/resources/prompts/`.
3. Run the write audit (`audit-agent-writes`) before reporting success — it is
   the only boundary check in that mode.
