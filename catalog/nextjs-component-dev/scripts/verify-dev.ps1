param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ComponentPath,

    [Parameter(Mandatory = $false)]
    [string]$ComponentName,

    # Skeleton decision gate (SKILL.md §1.2):
    #   auto         - infer from the component source (default)
    #   required     - the component can suspend/lazy-load; a wired skeleton is mandatory
    #   not-required - the component is static; a skeleton would be dead code
    [Parameter(Mandatory = $false)]
    [ValidateSet("auto", "required", "not-required")]
    [string]$SkeletonMode = "auto"
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

# --- Skeleton decision gate (SKILL.md §1.2) --------------------------------------
# A skeleton is a streaming fallback, not a mandatory companion. Only components that
# can suspend, lazy-load, or wait on I/O need one; static components must not ship one.
function Test-SuspendsOrLazyLoads {
    param ([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    $code = Get-Content -Path $Path -Raw
    # Lazy/client-only signals apply regardless of the RSC/client classification.
    if ($code -match 'next/dynamic' -or $code -match '\bdynamic\(' -or
        $code -match 'useSuspenseQuery' -or $code -match 'ssr:\s*false') { return $true }
    # Await inside a client component is usually an event handler, not a suspend point.
    $isClient = $code -match '"use client"' -or $code -match "'use client'"
    if ($isClient) { return $false }
    if ($code -match '\bawait\b') { return $true }
    if ($code -match 'cookies\(\)|headers\(\)|connection\(\)|noStore\(\)') { return $true }
    return $false
}

switch ($SkeletonMode) {
    "required"     { $skeletonRequired = $true }
    "not-required" { $skeletonRequired = $false }
    default        { $skeletonRequired = Test-SuspendsOrLazyLoads -Path $componentFile }
}

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
if ($skeletonRequired -and -not (Test-Path $skeletonFile)) { $missing += "${compName}_skeleton.tsx" }

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Missing dev companion files for $compName in $($resolvedDir):" -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host "  - Missing: $m" -ForegroundColor Red
    }
    exit 1
}

$present = @("$compName.tsx")
if (Test-Path $skeletonFile) { $present += (Split-Path $skeletonFile -Leaf) }
Write-Host "[PASS] Files present: $($present -join ', ')" -ForegroundColor Green

if ($legacySkeleton) {
    Write-Host "[WARN] Legacy skeleton name found. Rename '${compName}Skeleton.tsx' to '${compName}_skeleton.tsx' (flat snake_case convention)." -ForegroundColor Yellow
}

if (-not $skeletonRequired) {
    if (Test-Path $skeletonFile) {
        Write-Host "[WARN] Static component carries a skeleton ('$(Split-Path $skeletonFile -Leaf)'). It can never paint, so it is dead code that will drift from the real layout. Delete it unless the component gains await / a data hook / next/dynamic." -ForegroundColor Yellow
    } else {
        Write-Host "[PASS] Skeleton not required: static component (no suspend/lazy/await trigger detected)." -ForegroundColor Green
    }
} else {
    Write-Host "[INFO] Skeleton required: component can suspend, lazy-load, or wait on I/O." -ForegroundColor Cyan

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
}

# Test authoring is owned exclusively by the nextjs-test skill (separate step).
# If tests already exist, run only those files read-only for feedback; never author one here.
if (Test-Path $testFile) {
    Write-Host "[PASS] Existing suite found: $(Split-Path $testFile -Leaf) (run read-only for feedback)." -ForegroundColor Green
}
Write-Host "[INFO] Test authoring is owned by nextjs-test (separate step). Use nextjs-test/scripts/verify-qa.ps1 for the test gate." -ForegroundColor Cyan

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
