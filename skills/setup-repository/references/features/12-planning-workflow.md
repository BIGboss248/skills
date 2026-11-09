# F12 — Planning workflow (`to-spec` → `to-tickets`)

## Enable when

The repository receives multi-step requests from a human or an agent and the
result should be reviewable before code changes start. Recommended for every
repository: it is the cheapest gate against an agent implementing the wrong thing
quickly.

Skip it for generated repositories, docs-only mirrors, and throwaway sandboxes.

## Questions

1. Where do specs and tickets live? (Default: the tracker configured for
   `to-tickets`; local-file mode writes one file per ticket under
   `.scratch/<feature-slug>/issues/`.)
2. Should specs be committed when file mode is used? (Default: yes. Never commit
   a spec that contains secrets.)
3. Review gate — stop after every ticket, or only at the end? (Default: only at
   the end, and always before destructive steps.)

## Steps

1. Verify the planning skills are available: `grilling` (or `grill-with-docs`),
   `to-spec`, and `to-tickets`. Do not deploy a local planning skill.
2. Record the planning convention in `AGENTS.md`: which skills own planning,
   where specs and tickets live, and the review gate.
3. Add `to-spec` and `to-tickets` to the mandatory-skills table with the trigger
   "before starting any task that needs three or more steps".
4. Do **not** create a plan directory or placeholder files. The first real spec
   creates its artifacts.
5. Do not install a second planning convention. If the repository already
   generates a roadmap or a `PLAN.md`, verify it and report `[UNTOUCHED]`.

## Acceptance

- [ ] `AGENTS.md` names `to-spec` and `to-tickets` and states the spec location.
- [ ] No local planning skill was deployed and no `docs/plan/` placeholder exists.
- [ ] One planning convention governs the repository.
- [ ] Smoke test: "add a health check endpoint" produces a spec and tickets, no
      source change, and `git status` is clean.
- [ ] Second smoke test: a one-line request ("rename this variable") does not
      produce a spec.

## Notes

- **A spec is not permission.** Producing a spec never authorizes execution; the
  approval gate still applies, and a destructive step inside an approved spec
  asks again.
- **Ask after inspecting.** Questions already answered by `docs/project.json`,
  the manifests, or `AGENTS.md` waste a round.
- **No spec for trivial work.** A one-line change with a one-line spec is
  overhead.
- **Drift.** When execution reveals a wrong assumption, amend the spec in place;
  never renumber completed tickets.
- **Secrets.** Specs may be committed. Reference variable names
  (`$DEPLOY_TOKEN`), never values.
- **One source of truth.** Two planning conventions in one repository diverge
  within a week.
