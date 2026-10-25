<#
.SYNOPSIS
    Initializes repository GitHub Issues infrastructure (issue templates and triage labels).

.DESCRIPTION
    Checks for the existence of .github/ISSUE_TEMPLATE/ and copies starter bug report templates.
    Ensures that standard triage labels ('bug', 'agent-triage', 'self-repair', 'verified') are created
    in the remote GitHub repository using GitHub CLI ('gh') if available and authenticated.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .agents/skills/github-triage/scripts/init_triage_infra.ps1
#>

[CmdletBinding()]
param ()

# Prevent native command stderr from triggering terminating errors
$ErrorActionPreference = "Continue"

Write-Host "==> Checking GitHub Issues infrastructure..." -ForegroundColor Cyan

# 1. Resolve repository root
$repoRoot = (Get-Location).Path
$templatesDir = Join-Path $repoRoot ".github/ISSUE_TEMPLATE"

# 2. Scaffold templates directory if missing
if (-not (Test-Path $templatesDir)) {
    Write-Host "Creating directory: $templatesDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $templatesDir -Force | Out-Null
}

# 3. Copy starter issue templates if missing
$sourceDir = Join-Path $PSScriptRoot "../resources/templates"

$bugTemplateDest = Join-Path $templatesDir "bug_report.yml"
if (-not (Test-Path $bugTemplateDest)) {
    $bugTemplateSrc = Join-Path $sourceDir "bug_report.yml"
    if (Test-Path $bugTemplateSrc) {
        Copy-Item -Path $bugTemplateSrc -Destination $bugTemplateDest -Force
        Write-Host "Installed: .github/ISSUE_TEMPLATE/bug_report.yml" -ForegroundColor Green
    }
} else {
    Write-Host "Existing template found: .github/ISSUE_TEMPLATE/bug_report.yml" -ForegroundColor Gray
}

$configTemplateDest = Join-Path $templatesDir "config.yml"
if (-not (Test-Path $configTemplateDest)) {
    $configTemplateSrc = Join-Path $sourceDir "config.yml"
    if (Test-Path $configTemplateSrc) {
        Copy-Item -Path $configTemplateSrc -Destination $configTemplateDest -Force
        Write-Host "Installed: .github/ISSUE_TEMPLATE/config.yml" -ForegroundColor Green
    }
} else {
    Write-Host "Existing config found: .github/ISSUE_TEMPLATE/config.yml" -ForegroundColor Gray
}

# 4. Check GitHub CLI and ensure labels exist
$gh = Get-Command "gh" -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Host "NOTE: GitHub CLI ('gh') is not installed in PATH. Skipping remote label provisioning." -ForegroundColor Yellow
    exit 0
}

# Check gh auth status safely
$null = & gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "NOTE: GitHub CLI ('gh') is not currently authenticated. Local templates scaffolded successfully; skipping remote label provisioning." -ForegroundColor Yellow
    exit 0
}

# Define required triage labels
$labels = @(
    @{ Name = "bug"; Color = "d73a4a"; Description = "Something isn't working" },
    @{ Name = "agent-triage"; Color = "0e8a16"; Description = "Triaged and managed by AI agent" },
    @{ Name = "self-repair"; Color = "1d76db"; Description = "Linked to an autofix.json imperative rule" },
    @{ Name = "verified"; Color = "5319e7"; Description = "Fix verified through automated test suites" }
)

Write-Host "Syncing triage labels..." -ForegroundColor Cyan
foreach ($lbl in $labels) {
    $name = $lbl.Name
    $color = $lbl.Color
    $desc = $lbl.Description

    & gh label create $name --color $color --description $desc --force 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Label ensured: $name" -ForegroundColor Green
    } else {
        Write-Host "  [--] Label check/skip: $name" -ForegroundColor Gray
    }
}

Write-Host "GitHub Issues infrastructure successfully initialized." -ForegroundColor Green
exit 0
