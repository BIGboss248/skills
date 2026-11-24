[CmdletBinding()]
param (
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"
$url = "http://127.0.0.1:$Port"
$spawnedServer = $false
$serverProcess = $null

function Cleanup {
    if ($spawnedServer -and $serverProcess -and (-not $serverProcess.HasExited)) {
        Write-Host "[SEO Pre-Push] Shutting down spawned background dev server..." -ForegroundColor Yellow
        try {
            taskkill.exe /PID $serverProcess.Id /T /F 2>$null
        } catch {
            try { Stop-Process -Id $serverProcess.Id -Force -ErrorAction SilentlyContinue } catch {}
        }
    }
}

try {
    Write-Host "[SEO Pre-Push] Probing for active dev server at $url..." -ForegroundColor Cyan

    $httpCode = "000"
    try {
        $rawCode = curl.exe -s -o NUL -w "%{http_code}" --connect-timeout 2 $url 2>$null
        if ($rawCode) { $httpCode = "$rawCode".Trim() }
    } catch {}

    if ($httpCode -and $httpCode -ne "000") {
        Write-Host "[SEO Pre-Push] Detected running dev server with HTTP status $httpCode. Reusing existing instance." -ForegroundColor Green
    } else {
        Write-Host "[SEO Pre-Push] No active dev server detected. Starting dev server..." -ForegroundColor Yellow
        $serverProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c pnpm run dev" -PassThru -NoNewWindow
        $spawnedServer = $true

        Write-Host "[SEO Pre-Push] Waiting for dev server to become ready..." -ForegroundColor Cyan
        $ready = $false
        for ($i = 0; $i -lt 30; $i++) {
            Start-Sleep -Seconds 1
            try {
                $checkRaw = curl.exe -s -o NUL -w "%{http_code}" --connect-timeout 1 $url 2>$null
                $checkCode = "$checkRaw".Trim()
                if ($checkCode -and $checkCode -ne "000") {
                    $ready = $true
                    Write-Host "[SEO Pre-Push] Dev server is ready with HTTP status $checkCode!" -ForegroundColor Green
                    break
                }
            } catch {}
        }

        if (-not $ready) {
            Write-Host "[SEO Pre-Push] Timed out waiting for dev server to start on port $Port." -ForegroundColor Red
            exit 1
        }
    }

    Write-Host "[SEO Pre-Push] Executing SEO technical audit against $url..." -ForegroundColor Cyan
    $auditJsonRaw = (cmd.exe /c npx -y seo report --url $url --actions-only --json) | Out-String
    $auditData = $auditJsonRaw | ConvertFrom-Json

    $fixesCount = 0
    if ($auditData.findings -and $auditData.findings.counts -and $auditData.findings.counts.fixes) {
        $fixesCount = [int]$auditData.findings.counts.fixes
    }

    if ($fixesCount -gt 0) {
        Write-Host "[SEO Pre-Push] SEO quality gate failed! Found $fixesCount critical technical fix(es)." -ForegroundColor Red
        Write-Host $auditJsonRaw
        exit 1
    }

    Write-Host "[SEO Pre-Push] SEO quality gate passed with 0 critical findings." -ForegroundColor Green
    exit 0
} finally {
    Cleanup
}
