# PowerShell script to verify translation dictionary parity across all languages
param (
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

Write-Host "=== Verifying i18n Translation Dictionary Parity ===" -ForegroundColor Cyan

$workspaceRoot = Get-Location
$messagesDir = Join-Path $workspaceRoot "messages"

if (-not (Test-Path $messagesDir)) {
    Write-Host "  [FAIL] 'messages/' directory not found at project root." -ForegroundColor Red
    exit 1
}

$files = Get-ChildItem -Path $messagesDir -Filter "*.json"
if ($files.Count -lt 2) {
    Write-Host "  [WARN] Fewer than 2 translation files found in 'messages/'. Found: $($files.Count)" -ForegroundColor Yellow
    if (-not $Quiet) { Write-Host "  [WARN] Fewer than 2 translation files found in 'messages/'. Found: $($files.Count)" -ForegroundColor Yellow }
    exit 0
}

function Get-FlattenedKeys($obj, $prefix = "") {
    $keys = [System.Collections.Generic.List[string]]::new()
    foreach ($prop in $obj.PSObject.Properties) {
        $keyName = if ($prefix -eq "") { $prop.Name } else { "$prefix.$($prop.Name)" }
        if ($prop.Value -is [PSCustomObject]) {
            $subKeys = Get-FlattenedKeys $prop.Value $keyName
            foreach ($sk in $subKeys) {
                $keys.Add($sk)
            }
        } else {
            $keys.Add($keyName)
        }
    }
    return $keys
}

# Use en.json as primary baseline if present, otherwise the first file
$baselineFile = $files | Where-Object { $_.Name -eq "en.json" } | Select-Object -First 1
if (-not $baselineFile) {
    $baselineFile = $files[0]
}

Write-Host "  [INFO] Baseline dictionary: '$($baselineFile.Name)'" -ForegroundColor Gray
if (-not $Quiet) {
    Write-Host "=== Verifying i18n Translation Dictionary Parity ===" -ForegroundColor Cyan
    Write-Host "  [INFO] Baseline dictionary: '$($baselineFile.Name)'" -ForegroundColor Gray
}

$baselineContent = Get-Content $baselineFile.FullName -Raw | ConvertFrom-Json
$baselineKeys = Get-FlattenedKeys $baselineContent
Write-Host "  [INFO] Total baseline keys: $($baselineKeys.Count)" -ForegroundColor Gray
if (-not $Quiet) { Write-Host "  [INFO] Total baseline keys: $($baselineKeys.Count)" -ForegroundColor Gray }

$hasDiscrepancies = $false

foreach ($file in $files) {
    if ($file.Name -eq $baselineFile.Name) { continue }

    Write-Host "`nChecking '$($file.Name)' against '$($baselineFile.Name)'..." -ForegroundColor Cyan
    if (-not $Quiet) { Write-Host "`nChecking '$($file.Name)' against '$($baselineFile.Name)'..." -ForegroundColor Cyan }
    try {
        $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $keys = Get-FlattenedKeys $content

        # Missing keys
        $missingKeys = $baselineKeys | Where-Object { $_ -notin $keys }
        if ($missingKeys.Count -gt 0) {
            Write-Host "  [FAIL] Missing in $($file.Name) ($($missingKeys.Count) keys):" -ForegroundColor Red
            foreach ($k in $missingKeys) {
                Write-Host "    - $k" -ForegroundColor Red
            }
            $hasDiscrepancies = $true
        }

        # Extra keys
        $extraKeys = $keys | Where-Object { $_ -notin $baselineKeys }
        if ($extraKeys.Count -gt 0) {
        if ($extraKeys.Count -gt 0 -and -not $Quiet) {
            Write-Host "  [WARN] Extra keys in $($file.Name) ($($extraKeys.Count) keys):" -ForegroundColor Yellow
            foreach ($k in $extraKeys) {
                Write-Host "    + $k" -ForegroundColor Yellow
            }
        }

        if ($missingKeys.Count -eq 0) {
        if ($missingKeys.Count -eq 0 -and -not $Quiet) {
            Write-Host "  [PASS] 100% key parity with baseline ($($keys.Count) keys)." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [FAIL] Error parsing JSON in '$($file.Name)': $_" -ForegroundColor Red
        $hasDiscrepancies = $true
    }
}

if ($hasDiscrepancies) {
    Write-Host "`nDictionary parity check completed with issues." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll translation dictionaries are in 100% parity!" -ForegroundColor Green
    if ($Quiet) {
        Write-Host "i18n-dictionaries: PASS ($($baselineKeys.Count) keys)" -ForegroundColor Green
    } else {
        Write-Host "`nAll translation dictionaries are in 100% parity!" -ForegroundColor Green
    }
    exit 0
}

