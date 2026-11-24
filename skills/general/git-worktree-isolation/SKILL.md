---
name: git-worktree-isolation
description: >-
  Do work on an isolated branch in its own worktree. Use when a change must not
  touch the user's working tree, when preparing work for review, or when merging
  a finished branch.
---

# Git Worktree Isolation

One task, one branch, one worktree, one approval.

## Scope

- **Owns:** branch and worktree lifecycle, the review handoff, the approval gate,
  merge and conflict handling.
- **Does not own:** what to build (`to-spec` / `to-tickets`), whether it is
  correct (`code-review`), or what the user wants committed.

## Contract

| Rule | Value |
| :--- | :--- |
| Branch | `work/<kebab-slug>` |
| Base | The repo's default branch, or the branch the user names |
| Location | `../<repo>-worktrees/<slug>` (sibling of the repo, never inside it) |
| Cardinality | One task per worktree; never reuse another task's worktree |
| Working directory | All reads, writes, and commands run from the worktree path |
| Merge | `--no-ff`, local only, after explicit approval |

- **Sequencing** — `implement` decides the order of work; it does not override
  this contract.

## Stages

1. **Create** — add the worktree and branch in one operation, then install
   dependencies inside it.
2. **Work** — commit scoped changes on the branch. Never write in the user's
   working tree while the task is open.
3. **Review** — present commits, diffstat, and changed paths, then stop.
4. **Merge** — only after the user approves, from the main worktree, `--no-ff`.
5. **Remove** — after a successful merge, remove the worktree and delete the
   branch.

## Commands

- Create: `git worktree add ../<repo>-worktrees/<slug> -b work/<slug> <base>`
- Review: `git log --oneline <base>..work/<slug>` and
  `git diff --stat <base>...work/<slug>`
- Merge: `git merge --no-ff work/<slug>`
- Remove: `git worktree remove ../<repo>-worktrees/<slug>` then
  `git branch -d work/<slug>`
- List: `git worktree list`

### Helper

This skill ships a helper with the approval gate built in:

- Create: `pwsh ./scripts/worktree.ps1 -Action create -Slug <slug>` or
  `bash ./scripts/worktree.sh create <slug>`
- Review: `-Action review -Slug <slug>` or `review <slug>`
- Merge: `-Action merge -Slug <slug> -Approved` or `merge <slug> --approved`
- Remove: `-Action remove -Slug <slug>` or `remove <slug>`

Without approval, `merge` prints the review and exits `4`. A conflict exits `3`
after aborting the merge. Both are stop signals, not errors to route around. If
the repo ships its own helper, its flags win.

## Approval gate

- A green gate, a clean diff, or silence is **not** approval.
- Only an explicit approval from the user releases the merge.
- If a helper exits non-zero because approval is missing, that is the gate
  working: stop, do not bypass it with a raw merge.
- Never push, never `--no-verify`, never rewrite history.

## Conflicts

On a merge conflict:

1. Abort: `git merge --abort`.
2. Keep the branch intact; `main` stays clean.
3. Report the conflicting paths and what each side changed.
4. Ask the user to choose: **A)** rebase the branch onto the base and re-merge,
   **B)** keep the base and drop the conflicting hunk, **C)** resolve manually.

Never pick for the user, never `-X ours`/`-X theirs`, never force-push.

## Definition of Done

- [ ] Work exists only on `work/<slug>` in its own worktree.
- [ ] The review output (commits, diffstat, paths) was presented.
- [ ] The merge happened only after explicit approval, with `--no-ff`.
- [ ] The worktree was removed only after a successful merge.

## Edge Cases & Pitfalls

- **Hooks are shared** — `.husky/` lives in the common `.git`; hooks fire in
  every worktree.
- **Dependencies are not shared** — `node_modules/`, `.venv/`, and build caches
  must be installed per worktree.
- **Untracked and stashed files are not shared** — copy them explicitly if
  needed.
- **Wrong tree** — running the dev server or a build from the main tree verifies
  the wrong code.
- **Long paths on Windows** — deep worktree paths can exceed path limits; use a
  short sibling directory name.
- **Deleting the branch early** — remove the branch only after the merge; a
  deleted branch loses unmerged commits.
- **Silent rebase** — rebasing a branch someone else reviewed invalidates the
  review; re-present it.
