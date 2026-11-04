# N9 — Agent Roster & Delegation Boundaries

**Category:** Agents · **Default:** on · **Depends on:** N2

Installs the four OpenCode agents that keep implementation and test authorship in
separate contexts, their boundary contract, and the two command shortcuts.

Subagents run unrestricted: no `permission` block, no shell allowlist. The
orchestrator briefs each spawn with an explicit write scope and audits the diff on
return. Two rules made the roster safe in practice:

- **Fast tier only** — targeted Jest during development; Playwright, full Jest, and
  builds run at `git push`.
- **One worktree per task** — implementation happens on `agent/<slug>`, merged into
  `main` only after the fast gates pass; conflicts are escalated to the user.

## Enable when

The repository is driven by OpenCode agents. Skip when another harness owns
delegation and accept the documented degraded mode.

## Questions

1. **Roster** — install `nextjs-dev`, `nextjs-test-author`, `nextjs-qa-auditor`,
   and the `nextjs-orchestrator` primary agent? The three-role roster is the
   contract; do not offer a two-role downgrade.
2. **Model overrides** — per role (orchestrator, implementation, test author, QA
   auditor), or inherit the primary agent's model (`null`)?
3. **Command shortcuts** — install `/create-nextjs-component` and
   `/create-nextjs-page`? Default yes.
4. **Verification commands** — confirm the exact script names the brief and review
   step should name (`test`, `test:fast`, `test:all`, `lint`, `e2e`, `check`). Do
   not invent one. The brief defaults to `tier: fast`.
5. **Worktree isolation** — install the worktree helper and require one branch per
   task? Default yes.
6. **Boundary acknowledgement** — the operator confirms the model: dev does not
   edit tests, test agents do not edit implementation, edge tests are immutable
   once created, the orchestrator audits the diff, expensive suites run pre-push,
   and merge conflicts go to the user.

## Steps

1. Create `.opencode/agents/`, `.opencode/commands/`, `.agents/rules/`, and
   `scripts/` when missing.
2. Deploy from [agents/](../../resources/templates/agents/),
   [rules/](../../resources/templates/rules/), and [scripts/](../../scripts/):
   - [nextjs-dev.md.template](../../resources/templates/agents/nextjs-dev.md.template)
   - [nextjs-test-author.md.template](../../resources/templates/agents/nextjs-test-author.md.template)
   - [nextjs-qa-auditor.md.template](../../resources/templates/agents/nextjs-qa-auditor.md.template)
   - [nextjs-orchestrator.md.template](../../resources/templates/agents/nextjs-orchestrator.md.template)
   - [agent-boundaries.md.template](../../resources/templates/rules/agent-boundaries.md.template)
   - [agent-worktree.ps1](../../scripts/agent-worktree.ps1) → `scripts/agent-worktree.ps1`
   - [agent-worktree.sh](../../scripts/agent-worktree.sh) → `scripts/agent-worktree.sh`
3. **Do not add `permission` blocks to the three subagents.** Only the orchestrator
   keeps `permission.task` (allow the three roles, deny everything else). Any other
   rule reintroduces approval prompts and blocks self-verification.
4. Substitute every placeholder — `{{PM}}`, `{{PM_RUN}}`, `{{MODEL_LINE}}` — and
   replace the sample commands in the orchestrator's brief/review sections with
   the repository's real scripts. A deployed file containing a `{{TOKEN}}` is
   invalid.
5. Deploy the commands from [commands/](../../resources/templates/commands/).
6. Confirm the tier scripts exist (`test:fast`, `test:e2e`, `test:all`,
   `test:prepush`) and `.husky/pre-push` calls `test:prepush`.
7. Record the roster in `docs/project.json` under
   `project_context_and_metadata.agents`, including `worktree_isolation: true`.
8. Update `AGENTS.md` with the Agent Roster & Delegation section from
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template), including
   §4.1 (tiers + isolated branches).
9. Run `opencode debug agents` where the CLI is available and confirm all four
   load. New agent files register on the next session, not the current one.

## Acceptance

- [ ] All four agent files exist with the expected `mode`.
- [ ] `nextjs-dev`, `nextjs-test-author`, and `nextjs-qa-auditor` contain **no**
      `permission:` block.
- [ ] `nextjs-orchestrator` gates `task` to the three role agents and documents
      the delegation brief and the review/audit step.
- [ ] `.agents/rules/agent-boundaries.md` exists and describes brief + audit
      enforcement, the fast tier, and the worktree/conflict rules.
- [ ] `scripts/agent-worktree.ps1` and `.sh` exist and `create` + `merge` work in a
      scratch repository.
- [ ] `.husky/pre-push` invokes the expensive tier (`test:prepush`).
- [ ] Both command shortcuts exist.
- [ ] No `{{TOKEN}}` placeholder remains.
- [ ] `opencode debug agents` lists the roster (when available).

## Notes

- The briefs name explicit paths and the worktree; the orchestrator restores
  anything written outside `write_scope` before accepting the work.
- `git diff` is the audit surface. For that reason the contract prefers
  `write`/`edit` over shell redirection.
- Scoped commits on `agent/<slug>` are the one permitted commit path (the merge
  handoff). Pushing stays with the user.
- Other harnesses fall back to prompt-level roles plus the orchestrator's write
  audit (`DEGRADED: agent permissions unavailable`).
- Details: [agent-roster-guide.md](../agent-roster-guide.md) and
  [agent-worktree-isolation.md](../agent-worktree-isolation.md).
