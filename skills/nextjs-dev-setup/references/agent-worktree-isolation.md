# Agent Worktree Isolation & Merge Protocol

Every agent that writes implementation (components, pages, skeletons,
dictionaries) works in its **own git worktree** on its own branch. The branch is
a **proposal**: it merges into `main` only after the user explicitly approves
the reviewed change set. The user's working tree stays untouched while an agent
works, and a bad agent run is discarded by deleting a directory instead of
reverting files.

Two gates are mandatory and cannot be waived by a passing test run:

1. **Isolation** — no writes outside the agent worktree.
2. **Approval** — no merge into `main` before the user approves the review.

The helper enforces the second: `merge` without `-Approved` / `--approved`
prints the review summary and exits `4` (`[APPROVAL REQUIRED]`), leaving the
base branch untouched.

Merge conflicts are **never resolved by an agent**. The agent stops, leaves the
conflict intact, and asks the user how to proceed.

---

## 1. Layout

```text
<repo parent>/
├── <repo>/                       # main working tree, branch main
└── <repo>-worktrees/
    ├── hero-card/                # branch agent/hero-card
    └── product-grid/             # branch agent/product-grid
```

Worktrees live **outside** the repository so they never pollute the vault, the
indexer, or `.gitignore`. The helper script resolves the path from the repo root
automatically.

| Item | Value |
| :--- | :--- |
| Base branch | `base_branch` in `docs/project.json`, otherwise `main` |
| Branch name | `agent/<kebab-task-slug>` |
| Worktree path | `../<repo-name>-worktrees/<kebab-task-slug>` |
| Commit policy | Scoped commits inside the agent worktree only (see §5) |

---

## 2. Lifecycle

```text
1. create    git worktree add -b agent/<slug> <path> <base_branch>
2. install   <pm> install --prefer-offline        (worktrees share .git, not node_modules)
3. work      implement, run fast tests only, git add, commit
4. verify    fast gates + staged-diff write audit inside the worktree
5. review    agent-worktree review <slug>         (commits, diffstat, changed paths)
6. approve   STOP: present the review and wait for explicit user approval
7. merge     agent-worktree merge <slug> -Approved (only after that approval)
8. cleanup   git worktree remove <path> && git branch -d agent/<slug>
```

Helper:

```powershell
pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action create -Slug hero-card
pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action list
pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action review -Slug hero-card
pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action merge -Slug hero-card -Approved
pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action abort -Slug hero-card
```

```bash
bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh create hero-card
bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh list
bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh review hero-card
bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh merge hero-card --approved
bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh abort hero-card
```

`create` prints the absolute worktree path; the agent `cd`s there (or uses
`workdir`) for the entire task. Never write to the main tree while a worktree task
is open.

---

## 3. Who Prepares and Who Merges

| Invocation | Owner of the merge |
| :--- | :--- |
| `/create-nextjs-component`, `/create-nextjs-page`, orchestrator pipeline | `nextjs-orchestrator` presents the review after all gates pass, then merges **after** the user approves |
| `nextjs-dev` called directly by the user | `nextjs-dev` presents the review, then merges its own branch **after** the user approves |
| Test agents (`nextjs-test-author`, `nextjs-qa-auditor`) | Do not open worktrees; they write inside the dev worktree that the orchestrator names |

**Approval is a user action.** An agent never self-approves. A green fast gate,
a clean write audit, silence in the chat, or a vague "looks fine" is not
approval — wait for an explicit go-ahead that names the merge (for example
"merge it" / "approved").

Only one merge runs at a time. Never merge while another worktree task is open on
the same target files.

---

## 4. Merge Procedure

Run from the **main worktree**, never from inside the agent worktree.

**Step 0 — approval gate (do not skip):**

```powershell
pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action review -Slug <slug>
```

```bash
bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh review <slug>
```

Present the output (commits, diffstat, changed paths) to the user and **stop**.
Continue only after explicit approval.

**Step 1 — approved merge:**

```powershell
pwsh .agents/skills/nextjs-dev-setup/scripts/agent-worktree.ps1 -Action merge -Slug <slug> -Approved
```

```bash
bash .agents/skills/nextjs-dev-setup/scripts/agent-worktree.sh merge <slug> --approved
```

Rules:

1. `--no-ff` always, so the agent run stays visible as one merge commit.
2. Fast-forward is not used; it hides the isolation boundary.
3. Never merge without the approved flag, and never replace the helper with a
   raw `git merge` to skip the approval prompt.
4. Never `rebase`, `reset --hard`, `force-push`, or rewrite history to "make the
   merge work".
5. Never merge with a dirty main worktree; report it instead.
6. `merge` without `-Approved`/`--approved` exits `4` and changes nothing; treat
   that exit as "waiting for the user", not as a command failure to retry.

---

## 5. Commit Policy

Autofix Rule 52 forbids committing unless the user asked. This workflow is the
explicit exception the user requested: an agent may commit **inside its own
worktree branch** as part of the review handoff.

- Commit only files inside the brief's `write_scope`.
- Conventional commit message, e.g. `feat(home): add HeroCard component`.
- Never commit on `main` directly.
- Committing on the agent branch is not approval and does not authorize a merge.
- Never `git push`, never tag, never open a PR unless the user asks.
- Never `--no-verify` (it would bypass the expensive pre-push gate).

---

## 6. Conflict Protocol (mandatory)

A conflict is a **decision**, not an obstacle to route around. Stop immediately.

1. Run `git merge --abort` in the main worktree so `main` stays clean.
2. Keep the agent branch and worktree — nothing is lost.
3. Collect conflict facts: `git merge-tree`, changed paths on both sides, and the
   agent's intent summary.
4. Report and **ask the user**:
   - `BLOCKED: merge conflict` plus the conflicting paths,
   - which side changed what (agent branch vs main),
   - the three options below.

| Option | Meaning | Orchestrator action |
| :--- | :--- | :--- |
| **A — rebase onto main** | Agent's change wins, replayed on latest main | In the worktree: `git rebase <base_branch>`, resolve only with user guidance, re-run fast gates, merge again |
| **B — keep main** | Drop the conflicting hunk, keep main's version | Re-apply the agent change without the conflicting hunk, then merge |
| **C — manual merge** | User resolves the files | User edits the conflict markers, agent resumes at the verify step |

Hard rules:

- Never resolve a conflict by guessing intent, `-X theirs`, `-X ours`,
  `--strategy-option`, or deleting the other side.
- Never re-run the merge hoping it passes.
- Never resolve a dependency/lockfile conflict — that is a human decision; report
  it and stop (`BLOCKED: lockfile conflict`).
- Record the chosen option and the resolution in the execution report.

---

## 7. Pre-Push Interaction

Worktrees share `.git`, so `.husky/` hooks apply to every push, from any
worktree. The expensive test tier therefore runs on push, exactly once:

- Pushing `agent/<slug>` runs the full suite through `pre-push`.
- Merging locally into `main` does **not** run tests; the next `git push` does.
- If the push fails on a deferred suite, that failure belongs to the agent branch
  and reopens the repair loop — it is not fixed by disabling the hook.
