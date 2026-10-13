# PowerShell script to verify Next.js next-intl setup integrity
param (
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

Write-Host "=== Verifying Next.js i18n Setup Integrity ===" -ForegroundColor Cyan

$workspaceRoot = Get-Location
$errorsFound = 0

function Assert-FileExists($relativePath, $description) {
    $fullPath = Join-Path $workspaceRoot $relativePath
    if (Test-Path $fullPath) {
        Write-Host "  [PASS] $description found at '$relativePath'" -ForegroundColor Green
        if (-not $Quiet) { Write-Host "  [PASS] $description found at '$relativePath'" -ForegroundColor Green }
    } else {
        Write-Host "  [FAIL] $description NOT found at '$relativePath'" -ForegroundColor Red
        $script:errorsFound++
    }
}

# 1. Check routing configuration
if (-not $Quiet) { Write-Host "=== Verifying Next.js i18n Setup Integrity ===" -ForegroundColor Cyan }

# 1. Routing config
if (Test-Path (Join-Path $workspaceRoot "src/i18n/routing.ts")) {
    Assert-FileExists "src/i18n/routing.ts" "Routing configuration"
} else {
    Assert-FileExists "i18n/routing.ts" "Routing configuration"
}

# 2. Check request configuration
# 2. Request config
if (Test-Path (Join-Path $workspaceRoot "src/i18n/request.ts")) {
    Assert-FileExists "src/i18n/request.ts" "Request configuration"
} else {
    Assert-FileExists "i18n/request.ts" "Request configuration"
}

# 3. Check navigation helpers
# 3. Navigation helpers
if (Test-Path (Join-Path $workspaceRoot "src/i18n/navigation.ts")) {
    Assert-FileExists "src/i18n/navigation.ts" "Navigation helpers"
} else {
    Assert-FileExists "i18n/navigation.ts" "Navigation helpers"
}

# 4. Check request interceptor (proxy.ts or middleware.ts)
# 4. Request interceptor
$hasProxy = (Test-Path (Join-Path $workspaceRoot "proxy.ts")) -or (Test-Path (Join-Path $workspaceRoot "src/proxy.ts"))
$hasMiddleware = (Test-Path (Join-Path $workspaceRoot "middleware.ts")) -or (Test-Path (Join-Path $workspaceRoot "src/middleware.ts"))

if ($hasProxy) {
    Write-Host "  [PASS] Next.js 16+ proxy interceptor detected" -ForegroundColor Green
    if (-not $Quiet) { Write-Host "  [PASS] Next.js 16+ proxy interceptor detected" -ForegroundColor Green }
} elseif ($hasMiddleware) {
    Write-Host "  [PASS] Next.js middleware interceptor detected" -ForegroundColor Green
    if (-not $Quiet) { Write-Host "  [PASS] Next.js middleware interceptor detected" -ForegroundColor Green }
} else {
    Write-Host "  [FAIL] No request interceptor (proxy.ts / middleware.ts) detected" -ForegroundColor Red
    $errorsFound++
}

# 5. Check dictionaries directory
# 5. Dictionaries directory
$dictDir = Join-Path $workspaceRoot "messages"
if (Test-Path $dictDir) {
    $dictFiles = Get-ChildItem -Path $dictDir -Filter "*.json"
    if ($dictFiles.Count -gt 0) {
        Write-Host "  [PASS] Translation dictionaries found: $($dictFiles.Name -join ', ')" -ForegroundColor Green
        if (-not $Quiet) { Write-Host "  [PASS] Translation dictionaries found: $($dictFiles.Name -join ', ')" -ForegroundColor Green }
    } else {
        Write-Host "  [FAIL] 'messages/' directory is empty" -ForegroundColor Red
        $errorsFound++
    }
} else {
    Write-Host "  [FAIL] 'messages/' directory not found at project root" -ForegroundColor Red
    $errorsFound++
}

if ($errorsFound -gt 0) {
    Write-Host "`nVerification failed with $errorsFound error(s)." -ForegroundColor Red
    Write-Host "`ni18n setup verification failed with $errorsFound error(s)." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll i18n setup assertions passed successfully!" -ForegroundColor Green
    if ($Quiet) {
        Write-Host "i18n-setup: PASS" -ForegroundColor Green
    } else {
        Write-Host "`nAll i18n setup assertions passed successfully!" -ForegroundColor Green
    }
    exit 0
}

