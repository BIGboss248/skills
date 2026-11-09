<#
.SYNOPSIS
    Creates, reviews, approves, merges, and cleans up per-task agent worktrees.

.DESCRIPTION
    Implements the isolation contract in
    references/agent-worktree-isolation.md: every agent writes in its own
    worktree on branch agent/<slug>, then merges into the base branch only
    after the user approves the change set.

    'merge' refuses to run without -Approved. Without it the script prints the
    review summary (commits, diffstat, changed paths) and exits 4, so nothing
    reaches the base branch before approval.

    A merge conflict is never resolved automatically. The merge is aborted,
    main is left clean, and the script exits 3 with the conflicting paths so
    the calling agent stops and asks the user.

.PARAMETER Action
    create | review | list | merge | abort | remove

.PARAMETER Slug
    Kebab-case task slug (e.g. hero-card). Required for every action except list.

.PARAMETER BaseBranch
    Base branch. Defaults to 'main'.

.PARAMETER Approved
    merge: explicit user approval of the reviewed change set.

.PARAMETER Force
    remove: delete the branch even when it is not merged.

.EXAMPLE
    pwsh agent-worktree.ps1 -Action create -Slug hero-card

.EXAMPLE
    pwsh agent-worktree.ps1 -Action review -Slug hero-card

.EXAMPLE
    pwsh agent-worktree.ps1 -Action merge -Slug hero-card -Approved
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("create", "review", "list", "merge", "abort", "remove")]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$Slug,

    [string]$BaseBranch = "main",

    [switch]$Approved,

    [switch]$Force,

    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

function Fail([string]$Message, [int]$Code = 1) {
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    exit $Code
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { Fail "Not inside a git repository." 2 }
$repoRoot = $repoRoot.Trim()

$repoName = Split-Path $repoRoot -Leaf
$parentDir = Split-Path $repoRoot -Parent
$worktreeRoot = Join-Path $parentDir "$repoName-worktrees"

function Get-Branch([string]$s) { return "agent/$s" }
function Get-WorktreePath([string]$s) { return (Join-Path $worktreeRoot $s) }

function Assert-Slug {
    if (-not $Slug) { Fail "Slug is required for action '$Action'." 2 }
    if ($Slug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        Fail "Slug must be kebab-case (a-z, 0-9, single dashes): '$Slug'." 2
    }
}

function Test-BranchExists([string]$b) {
    & git -C $repoRoot show-ref --verify --quiet "refs/heads/$b"
    return ($LASTEXITCODE -eq 0)
}

function Show-Review([string]$branch, [string]$base) {
    $count = (& git -C $repoRoot rev-list --count "$base..$branch").Trim()
    Write-Host "Review: $branch -> $base" -ForegroundColor Cyan
    Write-Host "  commits: $count"
    $commits = @(& git -C $repoRoot log --oneline "$base..$branch")
    foreach ($c in $commits) { Write-Host "    $c" }
    Write-Host "  diffstat:"
    $stat = @(& git -C $repoRoot diff --stat "$base...$branch")
    foreach ($s in $stat) { Write-Host "    $s" }
    Write-Host "  changed paths:"
    $paths = @(& git -C $repoRoot diff --name-status "$base...$branch")
    foreach ($p in $paths) { Write-Host "    $p" }
}

switch ($Action) {
    "list" {
        & git -C $repoRoot worktree list
        exit 0
    }

    "review" {
        Assert-Slug
        $branch = Get-Branch $Slug
        if (-not (Test-BranchExists $branch)) { Fail "Branch '$branch' does not exist." }
        Show-Review $branch $BaseBranch
        Write-Host ""
        Write-Host "Nothing was merged. Approve, then run:" -ForegroundColor Yellow
        Write-Host "  agent-worktree.ps1 -Action merge -Slug $Slug -Approved"
        exit 0
    }

    "create" {
        Assert-Slug
        if (-not (Test-BranchExists $BaseBranch)) { Fail "Base branch '$BaseBranch' does not exist." }
        $branch = Get-Branch $Slug
        $path = Get-WorktreePath $Slug

        if (Test-BranchExists $branch) { Fail "Branch '$branch' already exists. Use the existing worktree or remove it first." }
        if (Test-Path -LiteralPath $path) { Fail "Worktree path already exists: $path" }

        if (-not (Test-Path -LiteralPath $worktreeRoot)) {
            New-Item -ItemType Directory -Path $worktreeRoot | Out-Null
        }

        & git -C $repoRoot worktree add -b $branch $path $BaseBranch
        if ($LASTEXITCODE -ne 0) { Fail "git worktree add failed." }

        Write-Host "[PASS] Worktree ready" -ForegroundColor Green
        Write-Host "  branch : $branch"
        Write-Host "  path   : $path"
        Write-Host ""
        Write-Host "Next steps (run inside $path):" -ForegroundColor Cyan
        Write-Host "  1. Install dependencies (worktrees share .git, not node_modules)."
        Write-Host "  2. Implement; run fast tests only. Expensive suites run pre-push."
        Write-Host "  3. git add <paths>; commit on $branch."
        Write-Host "  4. agent-worktree.ps1 -Action review -Slug $Slug   (present to the user)"
        Write-Host "  5. agent-worktree.ps1 -Action merge -Slug $Slug -Approved   (after approval)"
        exit 0
    }

    "merge" {
        Assert-Slug
        $branch = Get-Branch $Slug
        $path = Get-WorktreePath $Slug

        if (-not (Test-BranchExists $branch)) { Fail "Branch '$branch' does not exist." }

        if (-not $Approved) {
            Show-Review $branch $BaseBranch
            Write-Host ""
            Write-Host "[APPROVAL REQUIRED] Nothing was merged; '$BaseBranch' is untouched." -ForegroundColor Yellow
            Write-Host "Present the review above to the user and wait for explicit approval." -ForegroundColor Yellow
            Write-Host "Then re-run with -Approved:" -ForegroundColor Cyan
            Write-Host "  agent-worktree.ps1 -Action merge -Slug $Slug -Approved"
            exit 4
        }

        if (Test-Path -LiteralPath $path) {
            $dirty = (& git -C $path status --porcelain)
            if ($dirty) { Fail "Worktree '$path' has uncommitted changes. Commit or discard them before merging." }
        }

        $current = (& git -C $repoRoot rev-parse --abbrev-ref HEAD).Trim()
        if ($current -ne $BaseBranch) {
            & git -C $repoRoot switch $BaseBranch
            if ($LASTEXITCODE -ne 0) { Fail "Could not switch the main worktree to '$BaseBranch'." }
        }

        $dirtyMain = (& git -C $repoRoot status --porcelain)
        if ($dirtyMain) { Fail "Main worktree is dirty. Commit or stash before merging." }

        & git -C $repoRoot merge --no-ff $branch -m "merge: $branch into $BaseBranch"
        $mergeCode = $LASTEXITCODE

        if ($mergeCode -ne 0) {
            $conflicts = @(& git -C $repoRoot diff --name-only --diff-filter=U)
            & git -C $repoRoot merge --abort 2>$null

            if ($conflicts.Count -gt 0) {
                Write-Host "[BLOCKED] Merge conflict while merging '$branch' into '$BaseBranch'." -ForegroundColor Red
                Write-Host "Conflicting paths:" -ForegroundColor Yellow
                foreach ($c in $conflicts) { Write-Host "  - $c" -ForegroundColor Yellow }
                Write-Host ""
                Write-Host "The merge was aborted; '$BaseBranch' is clean and '$branch' is intact." -ForegroundColor Yellow
                Write-Host "STOP and ask the user which resolution to use:" -ForegroundColor Cyan
                Write-Host "  A) rebase the agent branch onto $BaseBranch and re-merge"
                Write-Host "  B) keep $BaseBranch and drop the conflicting hunk"
                Write-Host "  C) manual resolution by the user"
                Write-Host "Never resolve a conflict by guessing, and never use -X ours/-X theirs."
                exit 3
            }

            Fail "Merge failed for a reason other than a conflict (exit $mergeCode)."
        }

        Write-Host "[PASS] Merged '$branch' into '$BaseBranch' (--no-ff)." -ForegroundColor Green
        Write-Host "Expensive suites have NOT run. They run at 'git push' through .husky/pre-push." -ForegroundColor Cyan
        exit 0
    }

    "abort" {
        Assert-Slug
        $branch = Get-Branch $Slug
        $path = Get-WorktreePath $Slug

        $merging = Test-Path (Join-Path $repoRoot ".git/MERGE_HEAD")
        if ($merging) {
            & git -C $repoRoot merge --abort
            Write-Host "[INFO] Aborted in-progress merge in main worktree." -ForegroundColor Yellow
        }

        if (Test-Path -LiteralPath $path) {
            & git -C $repoRoot worktree remove $path --force
            if ($LASTEXITCODE -ne 0) { Fail "Could not remove worktree: $path" }
            Write-Host "[INFO] Removed worktree: $path" -ForegroundColor Yellow
        }

        if (Test-BranchExists $branch) {
            $deleteFlag = if ($Force) { "-D" } else { "-d" }
            & git -C $repoRoot branch $deleteFlag $branch
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[WARN] Branch '$branch' kept (not merged). Re-run with -Force to delete it." -ForegroundColor Yellow
            } else {
                Write-Host "[INFO] Deleted branch: $branch" -ForegroundColor Yellow
            }
        }

        exit 0
    }

    "remove" {
        Assert-Slug
        $branch = Get-Branch $Slug
        $path = Get-WorktreePath $Slug

        if (-not (Test-Path -LiteralPath $path)) { Fail "Worktree path does not exist: $path" }

        & git -C $repoRoot worktree remove $path --force
        if ($LASTEXITCODE -ne 0) { Fail "Could not remove worktree: $path" }

        if (Test-BranchExists $branch) {
            $deleteFlag = if ($Force) { "-D" } else { "-d" }
            & git -C $repoRoot branch $deleteFlag $branch
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[WARN] Branch '$branch' kept (not merged). Re-run with -Force to delete it." -ForegroundColor Yellow
            }
        }

        Write-Host "[PASS] Removed worktree '$Slug'." -ForegroundColor Green
        exit 0
    }
}
