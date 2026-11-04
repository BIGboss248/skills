# N9 — Agent Roster & Delegation Boundaries

**Category:** Agents · **Default:** on · **Depends on:** N2

Installs the four OpenCode agents that keep implementation and test authorship in
separate contexts, their boundary contract, and the two command shortcuts.

Subagents run unrestricted: no `permission` block, no shell allowlist. The
orchestrator briefs each spawn with an explicit write scope and audits the diff on
return.

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
   step should name (`test`, `test:all`, `lint`, `e2e`, `check`). Do not invent
   one.
5. **Boundary acknowledgement** — the operator confirms the model: dev does not
   edit tests, test agents do not edit implementation, edge tests are immutable
   once created, and the orchestrator audits the diff.

## Steps

1. Create `.opencode/agents/`, `.opencode/commands/`, and `.agents/rules/` when
   missing.
2. Deploy from [agents/](../../resources/templates/agents/) and
   [rules/](../../resources/templates/rules/):
   - [nextjs-dev.md.template](../../resources/templates/agents/nextjs-dev.md.template)
   - [nextjs-test-author.md.template](../../resources/templates/agents/nextjs-test-author.md.template)
   - [nextjs-qa-auditor.md.template](../../resources/templates/agents/nextjs-qa-auditor.md.template)
   - [nextjs-orchestrator.md.template](../../resources/templates/agents/nextjs-orchestrator.md.template)
   - [agent-boundaries.md.template](../../resources/templates/rules/agent-boundaries.md.template)
3. **Do not add `permission` blocks to the three subagents.** Only the orchestrator
   keeps `permission.task` (allow the three roles, deny everything else). Any other
   rule reintroduces approval prompts and blocks self-verification.
4. Substitute every placeholder — `{{PM}}`, `{{PM_RUN}}`, `{{MODEL_LINE}}` — and
   replace the sample commands in the orchestrator's brief/review sections with
   the repository's real scripts. A deployed file containing a `{{TOKEN}}` is
   invalid.
5. Deploy the commands from [commands/](../../resources/templates/commands/).
6. Record the roster in `docs/project.json` under
   `project_context_and_metadata.agents`.
7. Update `AGENTS.md` with the Agent Roster & Delegation section from
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template).
8. Run `opencode debug agents` where the CLI is available and confirm all four
   load. New agent files register on the next session, not the current one.

## Acceptance

- [ ] All four agent files exist with the expected `mode`.
- [ ] `nextjs-dev`, `nextjs-test-author`, and `nextjs-qa-auditor` contain **no**
      `permission:` block.
- [ ] `nextjs-orchestrator` gates `task` to the three role agents and documents
      the delegation brief and the review/audit step.
- [ ] `.agents/rules/agent-boundaries.md` exists and describes brief + audit
      enforcement.
- [ ] Both command shortcuts exist.
- [ ] No `{{TOKEN}}` placeholder remains.
- [ ] `opencode debug agents` lists the roster (when available).

## Notes

- The briefs name explicit paths; the orchestrator restores anything written
  outside `write_scope` before accepting the work.
- `git diff` is the audit surface. For that reason the contract prefers
  `write`/`edit` over shell redirection.
- Other harnesses fall back to prompt-level roles plus the orchestrator's write
  audit (`DEGRADED: agent permissions unavailable`).
- Details: [agent-roster-guide.md](../agent-roster-guide.md).
