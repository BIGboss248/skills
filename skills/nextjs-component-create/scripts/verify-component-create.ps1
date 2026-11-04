<#
.SYNOPSIS
    End-to-end verification for the Next.js component-creation pipeline.

.DESCRIPTION
    Runs the phase gates in order: dev companions/i18n, Storybook, then the QA
    suites (baseline + adversarial). Stops at the first failure and returns its
    exit code.

    Tier 'fast' (default) runs Jest only and DEFERS Playwright to the pre-push
    gate. Tier 'full' runs every gate and belongs to pre-push, CI, or an explicit
    user request. See nextjs-adversarial-qa/references/shared/test-execution-tiers.md.

.PARAMETER ComponentPath
    Target component directory.

.PARAMETER ComponentName
    Optional explicit component name.

.PARAMETER TargetKind
    Verify a component (default) or a page route.

.PARAMETER Tier
    fast | full. Default: fast.

.PARAMETER SkipStorybook
    Skip the Storybook smoke/build gate (when stories are out of scope).

.PARAMETER SkipTests
    Skip the QA suite gate.

.PARAMETER Help
    Show this help text.

.EXAMPLE
    pwsh verify-component-create.ps1 -ComponentPath components/home/Hero

.EXAMPLE
    pwsh verify-component-create.ps1 -ComponentPath components/home/Hero -SkipStorybook

.EXAMPLE
    pwsh verify-component-create.ps1 -ComponentPath app/[locale]/about -TargetKind page
#>
param(
    [Parameter(Position = 0)]
    [string]$ComponentPath,

    [string]$ComponentName,

    [ValidateSet("component", "page")]
    [string]$TargetKind = "component",

    [ValidateSet("fast", "full")]
    [string]$Tier = "fast",

    [switch]$SkipStorybook,

    [switch]$SkipTests,

    [switch]$Help
)

$ErrorActionPreference = "Stop"

if ($Help -or -not $ComponentPath) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    if (-not $ComponentPath -and -not $Help) { exit 2 }
    exit 0
}

if (-not (Test-Path -LiteralPath $ComponentPath)) {
    Write-Host "[FAIL] Path not found: $ComponentPath" -ForegroundColor Red
    exit 2
}

$skillsRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

function Invoke-Gate {
    param([string]$Label, [scriptblock]$Action)

    Write-Host "[GATE] $Label" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Gate failed: $Label" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    Write-Host "[PASS] Gate passed: $Label" -ForegroundColor Green
}

$devArgs = @{ ComponentPath = $ComponentPath }
if ($ComponentName) { $devArgs.ComponentName = $ComponentName }

if ($TargetKind -eq "page") {
    Invoke-Gate -Label "Phase 2 - page infrastructure, metadata, and i18n" -Action {
        & (Join-Path $skillsRoot "nextjs-page-dev/scripts/verify-page.ps1") -RoutePath $ComponentPath
    }
} else {
    Invoke-Gate -Label "Phase 2 - dev companions and i18n" -Action {
        & (Join-Path $skillsRoot "nextjs-component-dev/scripts/verify-dev.ps1") @devArgs
    }
}

if ($TargetKind -eq "page") {
    Write-Host "[SKIP] Storybook gate (not applicable to pages)" -ForegroundColor Yellow
} elseif (-not $SkipStorybook) {
    $storyArgs = @{ ComponentPath = $ComponentPath }
    if ($ComponentName) { $storyArgs.ComponentName = $ComponentName }
    Invoke-Gate -Label "Phase 3 - Storybook smoke and build" -Action {
        & (Join-Path $skillsRoot "nextjs-storybook-story/scripts/verify-storybook.ps1") @storyArgs
    }
} else {
    Write-Host "[SKIP] Storybook gate (SkipStorybook)" -ForegroundColor Yellow
}

if (-not $SkipTests) {
    $qaMode = if ($TargetKind -eq "page") { "page" } else { "all" }
    Invoke-Gate -Label "Phase 4 - QA suites ($qaMode, tier $Tier)" -Action {
        & (Join-Path $skillsRoot "nextjs-adversarial-qa/scripts/verify-qa.ps1") -TargetPath $ComponentPath -Mode $qaMode -Tier $Tier
    }
} else {
    Write-Host "[SKIP] QA suite gate (SkipTests)" -ForegroundColor Yellow
}

if ($Tier -ne "full") {
    Write-Host "[DEFERRED] Expensive tier not executed. It runs at 'git push' through .husky/pre-push:" -ForegroundColor Yellow
    Write-Host "  - full Jest project, Playwright component + page E2E, production build, Storybook build" -ForegroundColor Yellow
    Write-Host "  Explicit re-run: pwsh verify-component-create.ps1 -ComponentPath $ComponentPath -TargetKind $TargetKind -Tier full" -ForegroundColor Yellow
    Write-Host "[DEFERRED] A deferred suite is not a passing suite." -ForegroundColor Yellow
}

Write-Host "[SUCCESS] $TargetKind creation verification passed for: $ComponentPath (tier: $Tier)" -ForegroundColor Green
exit 0
