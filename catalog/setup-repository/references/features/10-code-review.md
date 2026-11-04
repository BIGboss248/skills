# F10 — Code Review Gate (`reviewer` subagent + report standard)

## Enable when

The repository receives changes from agents or humans and needs an independent
read of the diff before it is called done. Recommended for every repository
that has an agent contract (F2).

## Questions

1. Should `/review` be installed as a command, or is the subagent enough?
   (Default: yes, it makes reviews reproducible.)
2. Which base branch do reviews compare against? (Default: the current
   upstream of `HEAD`; record it in `AGENTS.md` when it is not `main`.)
3. Should finished reports be archived under `docs/reviews/`? (Default: yes,
   written by the primary agent, not by the reviewer.)

## Steps

1. Create the directories that do not exist yet: `.opencode/agents/`,
   `.opencode/commands/` (only when `/review` is installed), and
   `.agents/rules/`.
2. Deploy [reviewer.agent.md.template](../../resources/templates/reviewer.agent.md.template)
   to `.opencode/agents/reviewer.md`. OpenCode discovers project agents only
   from `.opencode/agents/`; `.agents/agents/` is not a discovery path.
3. Deploy [code-review-report.md.template](../../resources/templates/code-review-report.md.template)
   to `.agents/rules/code-review-report.md`.
4. Deploy [review.command.md.template](../../resources/templates/review.command.md.template)
   to `.opencode/commands/review.md` when question 1 is accepted.
5. Add the "Code review" section from
   [AGENTS.md.template](../../resources/templates/AGENTS.md.template) to
   `AGENTS.md`, recording the base branch from question 2.
6. **Do not** add `.agents/rules/code-review-report.md` to `instructions` or to
   `AGENTS.md` as an always-loaded block. It is review-time context; loading it
   in every request only burns tokens.
7. If `.opencode/agents/reviewer.md` already exists, merge instead of
   overwriting: keep the stricter permission set and the existing prompt
   additions, then record the merge in `.agents/setup-features.json` under
   `notes`.
8. If `docs/reviews/` is enabled, create the directory only when the first
   report is saved. No placeholder files.

### Permission ordering

The template uses the documented map form (`permission:`), which OpenCode
compiles into an ordered rule list. Rules are evaluated **last match wins**, so
the file starts with a blanket deny and re-allows a narrow set:

- `"*": deny` first, then `read`, `glob`, `grep`, `list`, `skill`, and the
  read-only Git inspection commands.
- `edit: deny` removes the edit, write, and patch tools from the agent's tool
  set entirely; the reviewer cannot write even if its prompt is manipulated.
- `*--output*` and `*--ext-diff*` are denied after the Git allows, because
  `git diff --output=<file>` writes files and `--ext-diff` executes external
  drivers.
- Redirects and compound commands (`>`, `<`, `;`, `&&`, `&`, `|`, backtick,
  `$(`) are denied after the allows, so a matched `git …` prefix cannot smuggle
  a write or a second command.
- `.env` reads stay `ask`; `*.env.example` stays allowed. This depends on
  **last-match** semantics, which OpenCode V2 documents; under a hypothetical
  first-match evaluator the broad `read *` allow would win and the `.env` rules
  would be dead, so verify after upgrading.

The list form (`permissions: [{ action, resource, effect }]`) also resolves in
OpenCode, but the map form is the documented agent field and is what all new
templates use. Verify ordering with `opencode debug agents`, which prints the
resolved rule list.

The reviewer must invoke Git directly in the working directory. `cd X && git …`
and `git -C …` do not match the allowlist and are rejected — that is intended,
not a bug; the agent prompt tells it not to use those forms.

## Acceptance

- [ ] `.opencode/agents/reviewer.md` exists, declares `mode: subagent`, denies
      `edit` on `*`, and allows no shell command outside Git inspection.
- [ ] `.agents/rules/code-review-report.md` exists and is **not** listed in any
      `instructions` array.
- [ ] `AGENTS.md` tells the primary agent to run the reviewer before reporting a
      change as complete, and names the review base branch.
- [ ] `/review` exists and selects the `reviewer` agent when question 1 was
      accepted.
- [ ] Smoke test: review a real diff. The report contains Scope, Verdict,
      Findings, Security checklist, and Edge cases, and `git status` is
      unchanged afterwards (no file was written, no report was saved).
- [ ] The reviewer refuses an edit attempt and refuses a command outside the
      allowlist, reporting the restriction rather than working around it.

## Notes

- The reviewer is static analysis plus reading. It cannot execute tests, so its
  verdict never certifies that the test gate passed; that stays with the
  implementer.
- Scope covers three sources: branch commits against the base branch, the
  working tree, and untracked files. A change made only of new files is
  otherwise invisible to `git diff HEAD`.
- Resolve the base as `origin/<base>` first. When work is committed directly on
  the base branch, `git diff <base>...HEAD` is empty by construction and the
  review silently becomes trivial.
- Large diffs can exhaust `steps: 60`. Ask for a scoped review ("only
  `lib/sorter.dart`") instead of raising the budget without bound; the prompt
  requires reporting partial coverage as `BLOCKED`.
- New agent files register on the next session, not in a session that is already
  running.
- Self-review of untrusted code is safe to run but not authoritative: diff
  content is treated as data, and permissions remain the hard limit.

## Residual risks to accept explicitly

- Git may execute configured helpers on otherwise safe commands
  (`diff.external`, `core.pager`, `core.fsmonitor`). Only relevant for
  untrusted checkouts; pin or clear those settings there.
- Shell denies for `.env` paths cover the common shapes (`HEAD:.env`,
  `-- .env`, `dir/.env`), not every possible spelling. Secret-shaped files at
  other names remain readable with the masking rule as the only guard.
- The `*&*` deny is deliberately over-broad: it also rejects `&` inside quoted
  arguments and pathspecs. That trades review coverage for safety.
- `origin/<base>` is used as fetched; the reviewer cannot run `git fetch`, so
  the report records the merge-base SHA to make a stale base detectable.
