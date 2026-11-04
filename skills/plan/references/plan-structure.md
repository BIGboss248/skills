# Plan Structure — Schema, Step Grammar, Audit

## File location and naming

```text
docs/plan/<slug>.md          # one file per plan
docs/plan/<slug>-2.md        # collision: never overwrite, append a suffix
```

Slug = kebab-case of the outcome, 2–5 words: `add-export-button`,
`fix-login-redirect`, `migrate-postgres-17`.

`docs/plan/README.md` is optional and only becomes useful with three or more
plans; it lists plan · status · owner · next step.

## Required sections

| Section | Rule |
| :--- | :--- |
| Title + metadata | Task type, created date, status (`draft`/`approved`/`in progress`/`done`), owner |
| Goal | One sentence: the outcome, in the user's words |
| Definition of done | Observable proof, not an opinion |
| Non-goals | What is explicitly excluded; each with a follow-up note |
| Decisions | Locked interview answers with the round they came from |
| Assumptions | Unasked facts and the fallback if they are wrong |
| Prerequisites | Access, files, branches, approvals, tools — available **now** |
| Phases → steps | The executable body (grammar below) |
| Risks & rollback | Top risks, mitigation, and the exact restore path |
| Open questions | Owner: `user` or `agent`; blocking or non-blocking |
| Execution log | One line per completed step, newest last |
| Approval gate | The literal question that starts execution |

## Step grammar

```markdown
### P2.1 — <imperative action>

- **Does**: <what happens, in one or two sentences>
- **Touches**: `path/to/file`, service, or document
- **Depends on**: P1.2 | none
- **Done when**: `<command>` → `<expected output>` **or** `<observable state>`
- **Evidence**: <where the proof is recorded: log line, test name, screenshot path>
- **Negative case**: <what must still be rejected / unchanged>   (only when it can fail open)
```

Rules:

- **One logical change per step.** If a step needs two commits, it is two steps.
- **Every step is independently checkable.** A reviewer must be able to tick it
  without asking the author what "done" meant.
- **Every phase ends with an exit check** — a dated line naming the commands run
  and what was observed.
- **Dependency-correct order.** Prerequisites first; no step relies on something
  a later step creates.
- **Amendments, not rewrites.** When reality changes the plan, add
  `A1 — P3.2 superseded because …` and insert `P3.2a`; never renumber completed
  steps or delete them.

## Phase shapes

Use the smallest shape that fits; do not pad to four phases.

- **Two-phase** (small): Prepare → Execute & verify.
- **Three-phase** (default): Set up → Build → Verify & hand off.
- **Four/five-phase** (large): Discover → Prepare → Build → Verify → Ship,
  with the discovery phase allowed to be a timeboxed spike.

## Audit rubric (Stage 4)

| Check | Fails when |
| :--- | :--- |
| Executable by a stranger | a step assumes interview knowledge |
| Verifiable | `Done when` is subjective |
| Atomic | a step contains "and" twice |
| Dependency-correct | a step uses an artifact created later |
| In scope | steps appear that no decision or goal justified |
| Decision-complete | an "either/or" remains inside a step |
| Safe | destructive step without backup or approval |
| Secret-free | any literal token, key, or personal datum |
| Consistent | the same file is described differently in two steps |
| Reversible | no rollback path for the risky phase |

Any failure means **revise the plan**, not annotate it.

## Approval gate

```markdown
## Approval gate

Approve this plan and I will start at `P1.1`.
Reply **go** to execute, **go P2** to run a single phase, or tell me what to
change and I will revise before starting.
```

Never treat silence, a topic change, or "looks fine" about something else as
approval. Approval is per plan; a destructive step still asks again.
