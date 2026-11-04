<#
.SYNOPSIS
    Verifies Next.js test artifacts and runs the targeted QA suites.

.DESCRIPTION
    Audits baseline, adversarial, and page test files for forbidden patterns,
    then executes only the files under test. Exits 0 on success, 1 on failure,
    2 on usage error.

    Tier 'fast' (default) runs Jest only and DEFERS Playwright to the pre-push
    gate. Tier 'full' runs every suite and is reserved for pre-push, CI, or an
    explicit user request. See references/shared/test-execution-tiers.md.

.PARAMETER TargetPath
    Component file (e.g. components/home/hero.tsx) or route directory
    (e.g. app/[locale]/about). Components are flat files, so pass the file
    itself; passing a surface folder (components/home) requires -ComponentName.

.PARAMETER Mode
    baseline | adversarial | page | all | audit. Default: all.

.PARAMETER Tier
    fast | full. Default: fast. Never select 'full' during development.

.PARAMETER ComponentName
    Optional explicit component name. Required when TargetPath is a surface folder.

.PARAMETER NoRun
    Audit files only; do not execute test runners.

.PARAMETER Help
    Show this help text.

.EXAMPLE
    pwsh verify-qa.ps1 -TargetPath components/home/hero.tsx -Mode all

.EXAMPLE
    pwsh verify-qa.ps1 -TargetPath components/home/hero.tsx -Mode all -Tier full

.EXAMPLE
    pwsh verify-qa.ps1 -TargetPath app/[locale]/about -Mode page
#>
param(
    [Parameter(Position = 0)]
    [string]$TargetPath,

    [Parameter(Position = 1)]
    [ValidateSet("baseline", "adversarial", "page", "all", "audit")]
    [string]$Mode = "all",

    [Parameter(Position = 2)]
    [ValidateSet("fast", "full")]
    [string]$Tier = "fast",

    [string]$ComponentName,

    [switch]$NoRun,

    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help -or -not $TargetPath) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    if (-not $TargetPath -and -not $Help) { exit 2 }
    exit 0
}

if (-not (Test-Path -LiteralPath $TargetPath)) {
    Write-Host "[FAIL] Target not found: $TargetPath" -ForegroundColor Red
    exit 2
}

$resolvedItem = Get-Item -LiteralPath $TargetPath
if ($resolvedItem.PSIsContainer) {
    $resolvedDir = $resolvedItem.FullName
    $compName = if ($ComponentName) { $ComponentName } else { $resolvedItem.Name }
} else {
    $resolvedDir = $resolvedItem.DirectoryName
    $compName = if ($ComponentName) { $ComponentName } else { [System.IO.Path]::GetFileNameWithoutExtension($resolvedItem.Name) }
}

$jestFiles = @()
$e2eFiles = @()
$missing = @()

function Get-JestFiles {
    param([string]$Dir, [string]$Name)
    return @(
        (Join-Path $Dir "$Name.test.tsx"),
        (Join-Path $Dir "$Name.edge.test.tsx")
    )
}

$baselineFile = Join-Path $resolvedDir "$compName.test.tsx"
$edgeFile = Join-Path $resolvedDir "$compName.edge.test.tsx"

switch ($Mode) {
    "baseline" {
        if (Test-Path -LiteralPath $baselineFile) { $jestFiles += $baselineFile } else { $missing += "$compName.test.tsx" }
    }
    "adversarial" {
        if (Test-Path -LiteralPath $edgeFile) { $jestFiles += $edgeFile } else { $missing += "$compName.edge.test.tsx" }
    }
    "page" {
        $pageFile = Join-Path $resolvedDir "page.tsx"
        if (-not (Test-Path -LiteralPath $pageFile)) { $missing += "page.tsx" }

        $leaf = Split-Path $resolvedDir -Leaf
        $pageSpecRoot = Join-Path (Get-Location) "tests/e2e/pages"
        if (Test-Path -LiteralPath $pageSpecRoot) {
            $specs = Get-ChildItem -Path $pageSpecRoot -Recurse -Filter "*$leaf*.spec.ts" -ErrorAction SilentlyContinue
            if ($specs) { $e2eFiles += $specs.FullName } else { $missing += "tests/e2e/pages/*$leaf*.spec.ts" }
        } else {
            $missing += "tests/e2e/pages/"
        }
    }
    "all" {
        if (Test-Path -LiteralPath $baselineFile) { $jestFiles += $baselineFile } else { $missing += "$compName.test.tsx" }
        if (Test-Path -LiteralPath $edgeFile) { $jestFiles += $edgeFile } else { $missing += "$compName.edge.test.tsx" }
    }
    "audit" {
        if (Test-Path -LiteralPath $baselineFile) { $jestFiles += $baselineFile }
        if (Test-Path -LiteralPath $edgeFile) { $jestFiles += $edgeFile }
        if ($jestFiles.Count -eq 0) { $missing += "$compName.test.tsx or $compName.edge.test.tsx" }
    }
}

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Missing required QA artifacts for '$compName' in ${resolvedDir}:" -ForegroundColor Red
    foreach ($m in $missing) { Write-Host "  - Missing: $m" -ForegroundColor Red }
    exit 1
}

$forbidden = '(?m)^\s*(it|test|describe)\.(only|skip|fixme)\s*\('
$placeholder = 'expect\(\s*(true|1)\s*\)\.toBe\(\s*(true|1)\s*\)'

foreach ($file in ($jestFiles + $e2eFiles)) {
    $content = Get-Content -LiteralPath $file -Raw
    if ($content -match $forbidden) {
        Write-Host "[FAIL] Forbidden focused/skipped test in $(Split-Path $file -Leaf)" -ForegroundColor Red
        exit 1
    }
    if ($content -match $placeholder) {
        Write-Host "[FAIL] Placeholder assertion detected in $(Split-Path $file -Leaf)" -ForegroundColor Red
        exit 1
    }
    if ($file -like "*.edge.test.tsx") {
        $caseCount = ([regex]::Matches($content, '(?m)^\s*(it|test)\s*\(')).Count
        if ($caseCount -lt 6) {
            Write-Host "[FAIL] Edge suite has $caseCount cases; minimum is 6." -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "[PASS] Audited $(Split-Path $file -Leaf)" -ForegroundColor Green
}

if ($NoRun) {
    Write-Host "[SUCCESS] Audit complete (NoRun)." -ForegroundColor Green
    exit 0
}

$pkgManager = "pnpm"
if (Test-Path "pnpm-lock.yaml") { $pkgManager = "pnpm" }
elseif (Test-Path "bun.lockb") { $pkgManager = "bun" }
elseif (Test-Path "package-lock.json") { $pkgManager = "npm" }
elseif (Test-Path "yarn.lock") { $pkgManager = "yarn" }

foreach ($file in $jestFiles) {
    Write-Host "[INFO] Running Jest: $file" -ForegroundColor Cyan
    if ($pkgManager -eq "bun") { & bun test $file } else { & $pkgManager test -- $file }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Jest suite failed: $(Split-Path $file -Leaf)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

if ($e2eFiles.Count -gt 0 -and $Tier -ne "full") {
    Write-Host "[DEFERRED] Playwright suites are expensive and run pre-push:" -ForegroundColor Yellow
    foreach ($file in $e2eFiles) { Write-Host "  - $file" -ForegroundColor Yellow }
    Write-Host "  Run now only on explicit request: $pkgManager run test:e2e <file>  (or -Tier full)" -ForegroundColor Yellow
    Write-Host "[DEFERRED] A deferred suite is not a passing suite." -ForegroundColor Yellow
} else {
    foreach ($file in $e2eFiles) {
        Write-Host "[INFO] Running Playwright: $file" -ForegroundColor Cyan
        if ($pkgManager -eq "bun") { & bun run test:e2e $file }
        elseif ($pkgManager -eq "npm") { & npm run test:e2e -- $file }
        else { & $pkgManager run test:e2e -- $file }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[FAIL] Playwright suite failed: $(Split-Path $file -Leaf)" -ForegroundColor Red
            exit $LASTEXITCODE
        }
    }
}

Write-Host "[SUCCESS] QA verification passed for '$compName' (mode: $Mode, tier: $Tier)." -ForegroundColor Green
exit 0
