#!/usr/bin/env bash
# Creates, lists, merges, and cleans up per-task agent git worktrees.
#
# Implements references/agent-worktree-isolation.md: every agent writes in its
# own worktree on branch agent/<slug>, then merges into the base branch.
#
# A merge conflict is never resolved automatically. The merge is aborted, the
# base branch is left clean, and the script exits 3 with the conflicting paths
# so the calling agent stops and asks the user.
#
# Usage:
#   agent-worktree.sh create <slug> [base-branch]
#   agent-worktree.sh list
#   agent-worktree.sh merge  <slug> [base-branch]
#   agent-worktree.sh abort  <slug> [--force]
#   agent-worktree.sh remove <slug> [--force]
#   agent-worktree.sh --help
#
# Exit codes: 0 success, 1 failure, 2 usage error, 3 merge conflict.

set -u

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

fail() {
    echo "[FAIL] $1"
    exit "${2:-1}"
}

[ $# -eq 0 ] && { usage; exit 2; }

ACTION="$1"
shift

SLUG=""
BASE_BRANCH="main"
FORCE=0

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
        --force) FORCE=1 ;;
        *)
            if [ -z "$SLUG" ]; then SLUG="$arg"; else BASE_BRANCH="$arg"; fi
            ;;
    esac
done

[ "$ACTION" = "list" ] || [ -n "$SLUG" ] || { usage; exit 2; }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "Not inside a git repository." 2
[ -n "$REPO_ROOT" ] || fail "Not inside a git repository." 2

REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"
WORKTREE_ROOT="$PARENT_DIR/$REPO_NAME-worktrees"

BRANCH="agent/$SLUG"
WORKTREE_PATH="$WORKTREE_ROOT/$SLUG"

branch_exists() {
    git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$1"
}

require_slug() {
    if [ -z "$SLUG" ]; then fail "Slug is required for action '$ACTION'." 2; fi
    if ! printf '%s' "$SLUG" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        fail "Slug must be kebab-case (a-z, 0-9, single dashes): '$SLUG'." 2
    fi
}

case "$ACTION" in
    list)
        git -C "$REPO_ROOT" worktree list
        exit 0
        ;;

    create)
        require_slug
        branch_exists "$BASE_BRANCH" || fail "Base branch '$BASE_BRANCH' does not exist."
        branch_exists "$BRANCH" && fail "Branch '$BRANCH' already exists. Use the existing worktree or remove it first."
        [ -e "$WORKTREE_PATH" ] && fail "Worktree path already exists: $WORKTREE_PATH"

        mkdir -p "$WORKTREE_ROOT"
        git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE_BRANCH" || fail "git worktree add failed."

        echo "[PASS] Worktree ready"
        echo "  branch : $BRANCH"
        echo "  path   : $WORKTREE_PATH"
        echo ""
        echo "Next steps (run inside $WORKTREE_PATH):"
        echo "  1. Install dependencies (worktrees share .git, not node_modules)."
        echo "  2. Implement; run fast tests only. Expensive suites run pre-push."
        echo "  3. git add <paths>; commit on $BRANCH."
        echo "  4. agent-worktree.sh merge $SLUG   (from the main worktree)"
        exit 0
        ;;

    merge)
        require_slug
        branch_exists "$BRANCH" || fail "Branch '$BRANCH' does not exist."

        if [ -e "$WORKTREE_PATH" ] && [ -n "$(git -C "$WORKTREE_PATH" status --porcelain)" ]; then
            fail "Worktree '$WORKTREE_PATH' has uncommitted changes. Commit or discard them before merging."
        fi

        CURRENT="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
        if [ "$CURRENT" != "$BASE_BRANCH" ]; then
            git -C "$REPO_ROOT" switch "$BASE_BRANCH" || fail "Could not switch the main worktree to '$BASE_BRANCH'."
        fi

        [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ] && fail "Main worktree is dirty. Commit or stash before merging."

        git -C "$REPO_ROOT" merge --no-ff "$BRANCH" -m "merge: $BRANCH into $BASE_BRANCH"
        MERGE_CODE=$?

        if [ $MERGE_CODE -ne 0 ]; then
            CONFLICTS="$(git -C "$REPO_ROOT" diff --name-only --diff-filter=U)"
            git -C "$REPO_ROOT" merge --abort 2>/dev/null

            if [ -n "$CONFLICTS" ]; then
                echo "[BLOCKED] Merge conflict while merging '$BRANCH' into '$BASE_BRANCH'."
                echo "Conflicting paths:"
                printf '%s\n' "$CONFLICTS" | sed 's/^/  - /'
                echo ""
                echo "The merge was aborted; '$BASE_BRANCH' is clean and '$BRANCH' is intact."
                echo "STOP and ask the user which resolution to use:"
                echo "  A) rebase the agent branch onto $BASE_BRANCH and re-merge"
                echo "  B) keep $BASE_BRANCH and drop the conflicting hunk"
                echo "  C) manual resolution by the user"
                echo "Never resolve a conflict by guessing, and never use -X ours/-X theirs."
                exit 3
            fi

            fail "Merge failed for a reason other than a conflict (exit $MERGE_CODE)."
        fi

        echo "[PASS] Merged '$BRANCH' into '$BASE_BRANCH' (--no-ff)."
        echo "Expensive suites have NOT run. They run at 'git push' through .husky/pre-push."
        exit 0
        ;;

    abort)
        require_slug

        if [ -f "$REPO_ROOT/.git/MERGE_HEAD" ]; then
            git -C "$REPO_ROOT" merge --abort
            echo "[INFO] Aborted in-progress merge in main worktree."
        fi

        if [ -e "$WORKTREE_PATH" ]; then
            git -C "$REPO_ROOT" worktree remove "$WORKTREE_PATH" --force || fail "Could not remove worktree: $WORKTREE_PATH"
            echo "[INFO] Removed worktree: $WORKTREE_PATH"
        fi

        if branch_exists "$BRANCH"; then
            if [ "$FORCE" -eq 1 ]; then
                git -C "$REPO_ROOT" branch -D "$BRANCH"
            else
                git -C "$REPO_ROOT" branch -d "$BRANCH" || echo "[WARN] Branch '$BRANCH' kept (not merged). Re-run with --force to delete it."
            fi
        fi
        exit 0
        ;;

    remove)
        require_slug
        [ -e "$WORKTREE_PATH" ] || fail "Worktree path does not exist: $WORKTREE_PATH"

        git -C "$REPO_ROOT" worktree remove "$WORKTREE_PATH" --force || fail "Could not remove worktree: $WORKTREE_PATH"

        if branch_exists "$BRANCH"; then
            if [ "$FORCE" -eq 1 ]; then
                git -C "$REPO_ROOT" branch -D "$BRANCH"
            else
                git -C "$REPO_ROOT" branch -d "$BRANCH" || echo "[WARN] Branch '$BRANCH' kept (not merged). Re-run with --force to delete it."
            fi
        fi

        echo "[PASS] Removed worktree '$SLUG'."
        exit 0
        ;;

    *)
        usage
        exit 2
        ;;
esac
