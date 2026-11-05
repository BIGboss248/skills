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
    if (-not $ComponentName) {
        Write-Host "[FAIL] '$($resolvedItem.FullName)' is a surface folder (page or layout region), not a component folder." -ForegroundColor Red
        Write-Host "       Components are flat files: <new_component_dir>/<surface>/<component_name>.tsx" -ForegroundColor Red
        Write-Host "       Re-run with the component file path, or pass -ComponentName <component_name>." -ForegroundColor Red
        exit 1
    }
    $compName = $ComponentName
} else {
    $resolvedDir = $resolvedItem.DirectoryName
    $compName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedItem.Name)
    $compName = $compName -replace '\.edge\.test$', '' -replace '\.test$', '' -replace '\.stories$', '' -replace '_skeleton$', ''
}

$componentFile = Join-Path $resolvedDir "$compName.tsx"

# Flat companion convention: <component_name>_skeleton.tsx. Legacy '<Name>Skeleton.tsx' is tolerated with a rename warning.
$skeletonFile = Join-Path $resolvedDir "${compName}_skeleton.tsx"
$legacySkeleton = $false
if (-not (Test-Path $skeletonFile)) {
    $legacySkeletonFile = Join-Path $resolvedDir "${compName}Skeleton.tsx"
    if (Test-Path $legacySkeletonFile) {
        $skeletonFile = $legacySkeletonFile
        $legacySkeleton = $true
    }
}

$testFile = Join-Path $resolvedDir "$compName.test.tsx"
if (-not (Test-Path $testFile)) {
    $testFile = Join-Path $resolvedDir "$compName.spec.tsx"
}

$missing = @()
if (-not (Test-Path $componentFile)) { $missing += "$compName.tsx" }
if (-not (Test-Path $skeletonFile))  { $missing += "${compName}_skeleton.tsx" }
if (-not (Test-Path $testFile))      { $missing += "$compName.test.tsx" }

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Missing dev companion files for $compName in $($resolvedDir):" -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host "  - Missing: $m" -ForegroundColor Red
    }
    exit 1
}

Write-Host "[PASS] Files present: $compName.tsx, $(Split-Path $skeletonFile -Leaf), $(Split-Path $testFile -Leaf)" -ForegroundColor Green

if ($legacySkeleton) {
    Write-Host "[WARN] Legacy skeleton name found. Rename '${compName}Skeleton.tsx' to '${compName}_skeleton.tsx' (flat snake_case convention)." -ForegroundColor Yellow
}

# Skeleton-first streaming: an orphan skeleton (no Suspense/dynamic/loading.tsx import) is a failed deliverable.
$skeletonRef = "${compName}_skeleton"
$skeletonLeaf = Split-Path $skeletonFile -Leaf
$wired = $false
$scanPaths = @("app", "src", $resolvedDir) | Where-Object { Test-Path $_ } | Select-Object -Unique
foreach ($scanPath in $scanPaths) {
    $candidates = Get-ChildItem -Path $scanPath -Recurse -Filter *.tsx -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/](node_modules|\.next|\.git|dist|build|coverage)[\\/]' -and $_.Name -ne $skeletonLeaf -and $_.Name -notmatch '\.(test|edge\.test|stories)\.tsx$' } |
        Select-Object -First 5000
    foreach ($candidate in $candidates) {
        if (Select-String -Path $candidate.FullName -Pattern $skeletonRef -SimpleMatch -Quiet) {
            $wired = $true
            break
        }
    }
    if ($wired) { break }
}

if (-not $wired) {
    Write-Host "[WARN] Orphan skeleton: '$skeletonLeaf' is not imported by any <Suspense fallback>, next/dynamic loading, or loading.tsx. Wire it so the skeleton renders first while the component streams." -ForegroundColor Yellow
} else {
    Write-Host "[PASS] Skeleton is wired into a streaming boundary." -ForegroundColor Green
}

# Test authoring is owned exclusively by the nextjs-test skill (separate step).
# If tests already exist, run only those files read-only for feedback; never author one here.
Write-Host "[INFO] Test authoring is owned by nextjs-test (separate step). Existing suites may be run read-only; use nextjs-test/scripts/verify-qa.ps1 for the test gate." -ForegroundColor Cyan

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

Write-Host "[SUCCESS] Dev verification passed for $compName." -ForegroundColor Green
exit 0
