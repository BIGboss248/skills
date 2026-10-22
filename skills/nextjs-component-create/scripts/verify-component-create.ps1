param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ComponentPath,

    [Parameter(Mandatory = $false)]
    [string]$ComponentName,

    [Parameter(Mandatory = $false)]
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ComponentPath)) {
    Write-Host "[FAIL] Path not found: $ComponentPath" -ForegroundColor Red
    exit 1
}

$resolvedItem = Get-Item $ComponentPath

if ($resolvedItem.PSIsContainer) {
    $resolvedDir = $resolvedItem.FullName
    if ($ComponentName) {
        $compName = $ComponentName
    } else {
        $compName = $resolvedItem.Name
    }
} else {
    $resolvedDir = $resolvedItem.DirectoryName
    $compName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedItem.Name)
}

$componentFile = Join-Path $resolvedDir "$compName.tsx"
$skeletonFile = Join-Path $resolvedDir "${compName}Skeleton.tsx"
$indexFile = Join-Path $resolvedDir "index.ts"
$testFile = Join-Path $resolvedDir "$compName.test.tsx"
$edgeTestFile = Join-Path $resolvedDir "$compName.edge.test.tsx"

$missing = @()
if (-not (Test-Path $componentFile)) { $missing += "$compName.tsx" }
if (-not (Test-Path $skeletonFile))  { $missing += "${compName}Skeleton.tsx" }
if (-not (Test-Path $indexFile))     { $missing += "index.ts" }
if (-not (Test-Path $testFile))      { $missing += "$compName.test.tsx" }
if (-not (Test-Path $edgeTestFile))  { $missing += "$compName.edge.test.tsx" }

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Missing component artifacts for $compName in $($resolvedDir):" -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host "  - Missing: $m" -ForegroundColor Red
    }
    exit 1
}

Write-Host "[PASS] All component files verified: $compName.tsx, ${compName}Skeleton.tsx, index.ts, $compName.test.tsx, $compName.edge.test.tsx" -ForegroundColor Green

# Verify zero in-file i18n placeholders / mock translation dictionaries
if (Test-Path $componentFile) {
    $content = Get-Content -Path $componentFile -Raw
    if ($content -match "const\s+DEFAULT_CONTENT\s*=" -or $content -match "const\s+DEFAULT_TRANSLATIONS\s*=") {
        Write-Host "[FAIL] In-file i18n placeholder dictionary detected in $compName.tsx (e.g., DEFAULT_CONTENT). Extract all strings to messages/[locale].json and consume via next-intl." -ForegroundColor Red
        exit 1
    }
}

# Verify dictionary directory existence
$dictDir = "messages"
if (Test-Path "docs/project.json") {
    try {
        $projJson = Get-Content -Path "docs/project.json" -Raw | ConvertFrom-Json
        if ($projJson.project_context_and_metadata.dictionaries_dir) {
            $dictDir = $projJson.project_context_and_metadata.dictionaries_dir
        }
    } catch {}
}

if (-not (Test-Path $dictDir)) {
    Write-Host "[WARN] Translation dictionary directory '$dictDir' not found." -ForegroundColor Yellow
} else {
    Write-Host "[PASS] Translation dictionary directory verified: $dictDir" -ForegroundColor Green
}

if (-not $SkipTests) {
    # Detect package manager
    $pkgManager = "pnpm"
    if (Test-Path "pnpm-lock.yaml") { $pkgManager = "pnpm" }
    elseif (Test-Path "bun.lockb") { $pkgManager = "bun" }
    elseif (Test-Path "package-lock.json") { $pkgManager = "npm" }
    elseif (Test-Path "yarn.lock") { $pkgManager = "yarn" }

    Write-Host "[INFO] Executing targeted unit & adversarial test suites via $pkgManager..." -ForegroundColor Cyan

    $testCmd = "$pkgManager test -- `"$testFile`" `"$edgeTestFile`""
    Write-Host "Running: $testCmd" -ForegroundColor DarkGray

    Invoke-Expression $testCmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Unit/edge tests failed for $compName." -ForegroundColor Red
        exit $LASTEXITCODE
    }

    Write-Host "[SUCCESS] All unit and adversarial tests passed for $compName." -ForegroundColor Green
}

Write-Host "[SUCCESS] nextjs-component-create verification passed for $compName." -ForegroundColor Green
exit 0

