# N9 — Agent Roster & Permission Boundaries

**Category:** Agents · **Default:** on · **Depends on:** N2

Installs the four OpenCode agents that enforce implementation/test separation,
their boundary rule, and the two command shortcuts.

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
4. **Boundary acknowledgement** — the operator confirms the implementation agent
   cannot edit tests, test agents cannot edit implementation, and edge tests are
   immutable once created.

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
3. Substitute every placeholder — `{{PM}}`, `{{PM_RUN}}`, `{{MODEL_LINE}}`. A
   deployed file containing a `{{TOKEN}}` is invalid.
4. Deploy the commands from [commands/](../../resources/templates/commands/).
5. Record the roster in `docs/project.json` under
   `project_context_and_metadata.agents`.
6. Update `AGENTS.md` with the Agent Roster & Delegation section from
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template).
7. Run `opencode debug agents` where the CLI is available and confirm all four
   load. New agent files register on the next session, not the current one.

## Acceptance

- [ ] All four agent files exist with the expected `mode`.
- [ ] `nextjs-dev` denies `**/*.test.tsx`; both test agents deny `edit`; all
      three subagents deny `task`.
- [ ] `.agents/rules/agent-boundaries.md` exists.
- [ ] Both command shortcuts exist.
- [ ] No `{{TOKEN}}` placeholder remains.
- [ ] `opencode debug agents` lists the roster (when available).

## Notes

- `edit: deny` removes the write/edit tools but does not block shell
  redirection, which is why the templates also deny `*>*`, `*;*`, `Set-Content`,
  and `Out-File`.
- Other harnesses fall back to prompt-level roles plus the orchestrator's write
  audit (`DEGRADED: agent permissions unavailable`).
- Details: [agent-roster-guide.md](../agent-roster-guide.md).
