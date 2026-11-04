<#
.SYNOPSIS
    Audits which file classes an agent changed during a pipeline phase.

.DESCRIPTION
    Classifies every file changed since a git ref (plus untracked files) and
    fails when the current phase touched a class it does not own. Used by
    nextjs-component-create to prove that the dev agent never wrote tests and
    the test agents never wrote implementation.

.PARAMETER Since
    Git ref to diff against. Defaults to HEAD (working tree + untracked files).

.PARAMETER Phase
    Pipeline phase whose allowed write classes are enforced.

.PARAMETER Json
    Emit a machine-readable result object.

.PARAMETER Help
    Show this help text.

.EXAMPLE
    pwsh audit-agent-writes.ps1 -Since origin/main -Phase implementation

.EXAMPLE
    pwsh audit-agent-writes.ps1 -Since 4f2c1ab -Phase adversarial -Json
#>
param(
    [string]$Since = "HEAD",

    [ValidateSet("baseline", "page", "implementation", "adversarial", "final", "all")]
    [string]$Phase = "all",

    [switch]$Json,

    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

function Get-ChangedFiles {
    param([string]$Ref)

    # git writes CRLF/lockfile warnings to stderr; Windows PowerShell turns
    # redirected native stderr into terminating errors under EAP=Stop.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    $tracked = & git diff --name-only $Ref 2>$null
    $diffExit = $LASTEXITCODE

    $untracked = & git ls-files --others --exclude-standard 2>$null
    $lsExit = $LASTEXITCODE

    $ErrorActionPreference = $previous

    if ($diffExit -ne 0) {
        throw "git diff failed for ref '$Ref'. Is this a git repository?"
    }
    if ($lsExit -ne 0) {
        throw "git ls-files failed."
    }

    $all = @()
    if ($tracked) { $all += $tracked }
    if ($untracked) { $all += $untracked }

    return $all |
        Where-Object { $_ -and $_.Trim() -ne "" } |
        ForEach-Object { $_.Trim().Replace('\', '/') } |
        Sort-Object -Unique
}

function Get-FileClass {
    param([string]$Path)

    $p = $Path.Replace('\', '/')

    if ($p -match '(^|/)package\.json$' -or
        $p -match '(^|/)(pnpm-lock\.yaml|package-lock\.json|yarn\.lock|bun\.lockb)$' -or
        $p -match '(^|/)jest(\.config)?\.[a-z]+$' -or
        $p -match '(^|/)jest\.setup\.[a-z]+$' -or
        $p -match '(^|/)playwright\.config\.[a-z]+$' -or
        $p -match '(^|/)next\.config\.[a-z]+$' -or
        $p -match '(^|/)tsconfig[^/]*\.json$' -or
        $p -match '(^|/)eslint\.config\.[a-z]+$' -or
        $p -match '(^|/)vitest\.config\.[a-z]+$') {
        return "config"
    }

    if ($p -match '(^|/)[^/]*test-plan\.md$') { return "test-plan" }
    if ($p -match '\.edge\.test\.(ts|tsx|js|jsx)$') { return "test-edge" }
    if ($p -match '\.test\.(ts|tsx|js|jsx)$') { return "test-baseline" }
    if ($p -match '(^|/)tests/e2e/pages/') { return "test-e2e-page" }
    if ($p -match '(^|/)tests/e2e/components/') { return "test-e2e-component" }
    if ($p -match '(^|/)tests/e2e/') { return "test-e2e-other" }
    if ($p -match '(^|/)docs/plan/') { return "plan" }
    if ($p -match '(^|/)docs/design/') { return "design" }
    if ($p -match '(^|/)(app|components|lib|hooks|messages)/') { return "impl" }
    if ($p -match '(^|/)i18n/') { return "impl" }

    return "other"
}

function Get-AllowedClasses {
    param([string]$PhaseName)

    switch ($PhaseName) {
        "baseline" { return @("test-baseline", "test-plan") }
        "page" { return @("test-e2e-page", "test-plan") }
        "implementation" { return @("impl") }
        "adversarial" { return @("test-edge", "test-e2e-component") }
        "final" { return @("plan", "design") }
        default { return @("impl", "test-baseline", "test-edge", "test-e2e-page", "test-e2e-component", "test-plan", "plan", "design", "other") }
    }
}

try {
    $changes = Get-ChangedFiles -Ref $Since
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}

if (-not $changes) {
    if ($Json) {
        [ordered]@{
            since = $Since
            phase = $Phase
            result = "pass"
            changed = 0
            violations = @()
        } | ConvertTo-Json -Depth 5
        exit 0
    }
    Write-Host "[PASS] No changes since '$Since' for phase '$Phase'." -ForegroundColor Green
    exit 0
}

$allowed = Get-AllowedClasses -PhaseName $Phase
$rows = @()
$violations = @()

foreach ($file in $changes) {
    $class = Get-FileClass -Path $file
    $ok = $allowed -contains $class
    if ($class -eq "config") { $ok = $false }
    $rows += [pscustomobject]@{ Path = $file; Class = $class; Allowed = $ok }
    if (-not $ok) {
        $violations += [pscustomobject]@{ path = $file; class = $class }
    }
}

if ($Json) {
    [ordered]@{
        since = $Since
        phase = $Phase
        result = if ($violations.Count -eq 0) { "pass" } else { "violation" }
        changed = $changes.Count
        violations = $violations
    } | ConvertTo-Json -Depth 5
    if ($violations.Count -eq 0) { exit 0 } else { exit 1 }
}

Write-Host ""
Write-Host "=== Agent Write Audit ===" -ForegroundColor Cyan
Write-Host "Since : $Since"
Write-Host "Phase : $Phase"
Write-Host "Allowed: $($allowed -join ', ')"
Write-Host ""

foreach ($row in $rows) {
    if ($row.Allowed) {
        Write-Host ("  [OK]   {0,-18} {1}" -f $row.Class, $row.Path) -ForegroundColor Green
    } else {
        Write-Host ("  [DENY] {0,-18} {1}" -f $row.Class, $row.Path) -ForegroundColor Red
    }
}

Write-Host ""
if ($violations.Count -eq 0) {
    Write-Host "[PASS] All $($changes.Count) changed file(s) match phase '$Phase'." -ForegroundColor Green
    exit 0
}

Write-Host "[FAIL] $($violations.Count) path(s) outside phase '$Phase' boundary:" -ForegroundColor Red
foreach ($v in $violations) {
    Write-Host "  - $($v.path) ($($v.class))" -ForegroundColor Red
}
exit 1
