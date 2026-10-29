# F2 — Agent Contract (`AGENTS.md` + `autofix.json`)

## Enable when

Always. Without it, every session re-discovers the same constraints and repeats
the same corrections.

## Questions

1. Which stack-specific mandatory skills apply? (For example
   `nextjs-component-dev` / `nextjs-page-dev` for App Router, or the Flutter
   equivalents.) Keep `self-repair` and `codebase-memory` regardless. Add
   `github-triage` when GitHub Issues are enabled (F7).
2. Should `.agents/autofix.json` be created if it does not exist?

## Steps

1. Deploy [AGENTS.md.template](../../resources/templates/AGENTS.md.template) to `AGENTS.md`.
2. **Merge, never overwrite.** Framework blocks are machine-owned (Next.js
   rewrites `nextjs-agent-rules` on every `next dev`). Keep them and append
   project rules around them.
3. Fill the mandatory-skills table with the answers from question 1; delete rows
   for stacks the repository does not use.
4. Copy the "Issue logging (`github-triage`)" section from the template when
   GitHub Issues are enabled; keep it next to the rule-capture section.
4. Create `.agents/autofix.json` with `[]` if missing; the `self-repair` skill
   owns the schema and appends rules.
5. Link `PLAN.md`, `CONTRIBUTING.md`, `SECURITY.md`, and `README.md` rather than
   duplicating their content.

## Acceptance

- [ ] `AGENTS.md` names `self-repair`, `codebase-memory`, the confirmed stack skills, and `github-triage` when GitHub Issues are enabled.
- [ ] The issue-logging contract is present when `github-triage` is listed.
- [ ] No machine-owned block was removed or reworded.
- [ ] `.agents/autofix.json` parses as a JSON array.

## Notes

- Keep the contract about constraints, not documentation. If a rule needs a
  paragraph of justification, it belongs in a reference file.
