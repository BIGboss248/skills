<#
.SYNOPSIS
    End-to-end verification for the Next.js component-creation pipeline.

.DESCRIPTION
    Runs the phase gates in order: dev companions/i18n, Storybook, then the QA
    suites (baseline + adversarial + Playwright). Stops at the first failure and
    returns its exit code.

.PARAMETER ComponentPath
    Target component directory.

.PARAMETER ComponentName
    Optional explicit component name.

.PARAMETER TargetKind
    Verify a component (default) or a page route.

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
    Invoke-Gate -Label "Phase 4 - QA suites ($qaMode)" -Action {
        & (Join-Path $skillsRoot "nextjs-adversarial-qa/scripts/verify-qa.ps1") -TargetPath $ComponentPath -Mode $qaMode
    }
} else {
    Write-Host "[SKIP] QA suite gate (SkipTests)" -ForegroundColor Yellow
}

Write-Host "[SUCCESS] $TargetKind creation verification passed for: $ComponentPath" -ForegroundColor Green
exit 0
