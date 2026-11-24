<#
.SYNOPSIS
    Initializes repository GitHub Issues triage infrastructure (issue templates and triage labels).

.DESCRIPTION
    Scaffolds .github/ISSUE_TEMPLATE/bug_report.yml, .github/ISSUE_TEMPLATE/feature_request.yml,
    .github/ISSUE_TEMPLATE/config.yml, and .github/PULL_REQUEST_TEMPLATE.md from skill templates.
    Ensures standard triage labels ('bug', 'enhancement', 'agent-triage', 'self-repair', 'verified')
    are created in the remote GitHub repository using GitHub CLI ('gh') if available and authenticated.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .agents/skills/setup-repository/scripts/init_triage_infra.ps1
#>

[CmdletBinding()]
param ()

$ErrorActionPreference = "Continue"

Write-Host "==> Initializing GitHub Triage Infrastructure..." -ForegroundColor Cyan

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
    $bugCandidates = @(
        (Join-Path $sourceDir "bug_report.yml.template"),
        (Join-Path $sourceDir "bug_report.yml")
    )
    $bugTemplateSrc = $bugCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($bugTemplateSrc) {
        Copy-Item -Path $bugTemplateSrc -Destination $bugTemplateDest -Force
        Write-Host "Installed: .github/ISSUE_TEMPLATE/bug_report.yml" -ForegroundColor Green
    }
} else {
    Write-Host "Existing template found: .github/ISSUE_TEMPLATE/bug_report.yml" -ForegroundColor Gray
}

$configTemplateDest = Join-Path $templatesDir "config.yml"
if (-not (Test-Path $configTemplateDest)) {
    $configCandidates = @(
        (Join-Path $sourceDir "issue_config.yml.template"),
        (Join-Path $sourceDir "config.yml.template"),
        (Join-Path $sourceDir "config.yml")
    )
    $configTemplateSrc = $configCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($configTemplateSrc) {
        Copy-Item -Path $configTemplateSrc -Destination $configTemplateDest -Force
        Write-Host "Installed: .github/ISSUE_TEMPLATE/config.yml" -ForegroundColor Green
    }
} else {
    Write-Host "Existing config found: .github/ISSUE_TEMPLATE/config.yml" -ForegroundColor Gray
}

$featureTemplateDest = Join-Path $templatesDir "feature_request.yml"
if (-not (Test-Path $featureTemplateDest)) {
    $featureCandidates = @(
        (Join-Path $sourceDir "feature_request.yml.template"),
        (Join-Path $sourceDir "feature_request.yml")
    )
    $featureTemplateSrc = $featureCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($featureTemplateSrc) {
        Copy-Item -Path $featureTemplateSrc -Destination $featureTemplateDest -Force
        Write-Host "Installed: .github/ISSUE_TEMPLATE/feature_request.yml" -ForegroundColor Green
    }
} else {
    Write-Host "Existing template found: .github/ISSUE_TEMPLATE/feature_request.yml" -ForegroundColor Gray
}

$prTemplateDest = Join-Path $repoRoot ".github/PULL_REQUEST_TEMPLATE.md"
$prTemplatesDir = Join-Path $repoRoot ".github"
if (-not (Test-Path $prTemplatesDir)) {
    New-Item -ItemType Directory -Path $prTemplatesDir -Force | Out-Null
}
if (-not (Test-Path $prTemplateDest)) {
    $prCandidates = @(
        (Join-Path $sourceDir "pull_request_template.md.template"),
        (Join-Path $sourceDir "PULL_REQUEST_TEMPLATE.md.template"),
        (Join-Path $sourceDir "PULL_REQUEST_TEMPLATE.md")
    )
    $prTemplateSrc = $prCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($prTemplateSrc) {
        Copy-Item -Path $prTemplateSrc -Destination $prTemplateDest -Force
        Write-Host "Installed: .github/PULL_REQUEST_TEMPLATE.md" -ForegroundColor Green
    }
} else {
    Write-Host "Existing template found: .github/PULL_REQUEST_TEMPLATE.md" -ForegroundColor Gray
}

# 4. Check GitHub CLI and ensure triage labels exist
$gh = Get-Command "gh" -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Host "NOTE: GitHub CLI ('gh') is not installed in PATH. Skipping remote label provisioning." -ForegroundColor Yellow
    exit 0
}

# Check gh auth status safely (with automatic fallback to Git Credential Manager)
$null = & gh auth status 2>$null
if ($LASTEXITCODE -ne 0 -and -not $env:GH_TOKEN) {
    $credInput = "protocol=https`nhost=github.com`n`n"
    $credOut = $credInput | git credential fill 2>$null
    foreach ($line in $credOut) {
        if ($line -match "^password=(.+)$") {
            $env:GH_TOKEN = $matches[1].Trim()
            break
        }
    }
}

$null = & gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "NOTE: GitHub CLI ('gh') is not currently authenticated. Local templates scaffolded successfully; skipping remote label provisioning." -ForegroundColor Yellow
    exit 0
}

$labels = @(
    @{ Name = "bug"; Color = "d73a4a"; Description = "Something isn't working" },
    @{ Name = "enhancement"; Color = "a2eeef"; Description = "New feature or request" },
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

Write-Host "GitHub Triage infrastructure successfully initialized." -ForegroundColor Green
exit 0
