param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ComponentPath,

    [Parameter(Mandatory = $false)]
    [string]$ComponentName
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

$storyFile = Join-Path $resolvedDir "$compName.stories.tsx"

if (-not (Test-Path $storyFile)) {
    Write-Host "[FAIL] Missing Storybook story file: $compName.stories.tsx in $($resolvedDir)" -ForegroundColor Red
    exit 1
}

Write-Host "[PASS] Story file present: $compName.stories.tsx" -ForegroundColor Green

# Detect package manager
$pkgManager = "pnpm"
if (Test-Path "pnpm-lock.yaml") { $pkgManager = "pnpm" }
elseif (Test-Path "bun.lockb") { $pkgManager = "bun" }
elseif (Test-Path "package-lock.json") { $pkgManager = "npm" }
elseif (Test-Path "yarn.lock") { $pkgManager = "yarn" }

Write-Host "[INFO] Executing Storybook smoke & indexing check via $pkgManager..." -ForegroundColor Cyan

$hasSmokeScript = $false
if (Test-Path "package.json") {
    $pkgJson = Get-Content "package.json" -Raw | ConvertFrom-Json
    if ($pkgJson.scripts."storybook:smoke") {
        $hasSmokeScript = $true
    }
}

if ($hasSmokeScript) {
    $smokeCmd = "$pkgManager run storybook:smoke"
} else {
    $smokeCmd = "$pkgManager exec storybook dev --smoke-test"
}

Write-Host "Running: $smokeCmd" -ForegroundColor DarkGray
Invoke-Expression $smokeCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Storybook smoke test failed for $compName." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[SUCCESS] Storybook verification passed for $compName." -ForegroundColor Green
exit 0

