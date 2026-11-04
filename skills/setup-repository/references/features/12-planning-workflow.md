# F12 — Planning workflow (`plan` skill + `/plan` command)

## Enable when

The repository receives multi-step requests from a human or an agent and the
result should be reviewable before code changes start. Recommended for every
repository: it is the cheapest gate against an agent implementing the wrong
thing quickly.

Skip it for generated repositories, docs-only mirrors, and throwaway sandboxes.

## Questions

1. Where do plans live? (Default: `docs/plan/<slug>.md`, one file per plan.
   Repositories that keep a single living `PLAN.md` may choose that instead; the
   skill supports both, and the choice is recorded in `AGENTS.md`.)
2. Should plans be committed? (Default: yes, one file per plan, committed with
   `docs(plan): add <slug> plan`. Never commit a plan that contains secrets.)
3. Should `/plan` be installed as a command, or is the skill enough? (Default:
   yes — both are installed by this feature.)
4. Plan review gate — stop after every phase, or only at the end? (Default:
   only at the end, and always before destructive steps.)

## Steps

1. Create the directories that do not exist yet: `skills/`, and
   `.opencode/commands/` (only when `/plan` is installed).
2. Deploy the `plan` skill from the skills source into `skills/plan/`:
   `SKILL.md`, `references/interview-rounds.md`, `references/plan-structure.md`,
   `references/task-types.md`, `resources/templates/plan.md.template`.
   - Source of truth: the skills vault (`skills/plan/`).
   - **Merge, never overwrite.** If `skills/plan/` already exists with local
     edits, keep the local edits, add only the missing files, and record the
     divergence in `.agents/setup-features.json` under `notes`.
3. Deploy [plan.command.md.template](../../resources/templates/plan.command.md.template)
   to `.opencode/commands/plan.md` when question 3 is accepted.
4. Add the "Planning (`plan` skill)" section from
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template) to
   `AGENTS.md`, recording the plan location from question 1 and the review gate
   from question 4.
5. Add `plan` to the mandatory-skills table in `AGENTS.md` with the trigger
   "before starting any task that needs three or more steps, and whenever the
   user says `/plan`".
6. **Do not** create `docs/plan/` yet and **do not** add placeholder plan files.
   The directory appears with the first real plan.
7. Keep the skill read-only in spirit: planning must not edit source files. If a
   repository already forbids it, do not weaken that rule — planning stays a
   separate step from execution.

## Acceptance

- [ ] `skills/plan/SKILL.md` exists, declares `name: plan`, and is under ~250
      lines with every reference link resolving.
- [ ] `skills/plan/references/` contains `interview-rounds.md`,
      `plan-structure.md`, and `task-types.md`;
      `skills/plan/resources/templates/plan.md.template` exists.
- [ ] `.opencode/commands/plan.md` exists and points at the skill.
- [ ] `AGENTS.md` contains the planning section, names the plan location, and
      lists `plan` in the mandatory-skills table.
- [ ] No `docs/plan/` placeholder files were created.
- [ ] Smoke test: `/plan add a health check endpoint` on a scratch branch.
      The agent inspects first, asks at most three rounds, writes
      `docs/plan/add-health-check-endpoint.md`, prints the summary, asks the
      approval question, and **stops** — `git status` shows no source change.
- [ ] Second smoke test: a one-line request ("rename this variable"). The agent
      declines to write a plan file and does the work instead.

## Notes

- **Plan is not permission.** Producing a plan never authorizes execution; the
  plan ends with an approval gate for that reason. Approval of a plan is also
  not approval of a destructive step inside it.
- **Interview economy.** Three rounds and fifteen questions are ceilings, not
  targets. A request with a clear outcome and a known verification needs one
  round.
- **Ask after inspecting.** Questions already answered by `docs/project.json`,
  the manifests, or `AGENTS.md` waste the round and train the user to answer
  "whatever you think".
- **No plan for trivial work.** A one-line fix with a one-line plan file is
  overhead; the skill says so explicitly.
- **Plan drift.** When execution reveals a wrong assumption, amend the plan in
  place (`A1 — P2.1 superseded because …`, insert `P2.1a`). Never renumber or
  delete a completed step; links and execution logs depend on the numbers.
- **Overwrite hazard.** A slug that already exists gets `-2`/`-3`. Overwriting
  silently breaks every reference to the old plan.
- **Secrets.** Plans are committed. Reference variable names (`$DEPLOY_TOKEN`),
  never values.
- **Two plans for one job.** If F8/Release Please or another feature already
  generates a roadmap in `docs/plan/`, verify it and record `[UNTOUCHED]` instead
  of adding a second planning convention. One plan location per repository.
- **Command registration.** A new command file registers on the next session,
  not in a session that is already running.
