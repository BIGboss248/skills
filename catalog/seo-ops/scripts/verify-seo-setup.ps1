[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("mcp", "cicd", "all")]
    [string]$Mode = "all",

    [Parameter(Mandatory = $false)]
    [switch]$AutoInstall
)

$ErrorActionPreference = "Stop"

Write-Host "=== SEO Operations Setup Verification ===" -ForegroundColor Cyan
Write-Host "Verification Mode: $Mode" -ForegroundColor Yellow
if ($AutoInstall) {
    Write-Host "AutoInstall Flag: ENABLED" -ForegroundColor Yellow
}

$failures = 0
$restartRequired = $false

# Check Node.js version >= 22
Write-Host "`n[1/3] Checking Node.js runtime..." -ForegroundColor Cyan
try {
    $nodeVersionRaw = node -v
    $nodeMajor = [int]($nodeVersionRaw -replace '^v','').Split('.')[0]
    if ($nodeMajor -ge 22) {
        Write-Host "  [OK] Node.js version: $nodeVersionRaw (>= 22)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Node.js version $nodeVersionRaw is below required v22+" -ForegroundColor Red
        $failures++
    }
} catch {
    Write-Host "  [FAIL] Node.js binary not found in PATH" -ForegroundColor Red
    $failures++
}

# Verify MCP Mode
if ($Mode -eq "mcp" -or $Mode -eq "all") {
    Write-Host "`n[2/3] Checking SEO MCP / CLI configuration..." -ForegroundColor Cyan
    
    # Check CLI availability
    $cliFound = $false
    try {
        $seoVersion = npx -y seo --version 2>$null
        if ($seoVersion) {
            Write-Host "  [OK] seo CLI available via npx: $seoVersion" -ForegroundColor Green
            $cliFound = $true
        }
    } catch {}

    if (-not $cliFound) {
        if ($AutoInstall) {
            Write-Host "  [INSTALL] Installing seo CLI globally..." -ForegroundColor Yellow
            npm install -g seo
            $restartRequired = $true
        } else {
            Write-Host "  [WARN] seo CLI not detected. Run: npm install -g seo" -ForegroundColor Yellow
        }
    }

    # Check .agents/mcp_config.json
    $mcpConfigFile = Join-Path (Get-Location) ".agents/mcp_config.json"
    $mcpConfigExists = Test-Path $mcpConfigFile
    $mcpConfigured = $false

    if ($mcpConfigExists) {
        $mcpContent = Get-Content $mcpConfigFile -Raw | ConvertFrom-Json
        if ($mcpContent.mcpServers.seo) {
            $mcpConfigured = $true
            Write-Host "  [OK] SEO MCP server configured in .agents/mcp_config.json" -ForegroundColor Green
        }
    }

    if (-not $mcpConfigured -and $AutoInstall) {
        Write-Host "  [INSTALL] Adding seo MCP server entry to .agents/mcp_config.json..." -ForegroundColor Yellow
        $agentsDir = Join-Path (Get-Location) ".agents"
        if (-not (Test-Path $agentsDir)) {
            New-Item -ItemType Directory -Path $agentsDir | Out-Null
        }
        
        $mcpObj = if ($mcpConfigExists) { Get-Content $mcpConfigFile -Raw | ConvertFrom-Json } else { [PSCustomObject]@{ mcpServers = [PSCustomObject]@{} } }
        if (-not $mcpObj.mcpServers) {
            $mcpObj | Add-Member -MemberType NoteProperty -Name "mcpServers" -Value ([PSCustomObject]@{})
        }
        $mcpObj.mcpServers | Add-Member -MemberType NoteProperty -Name "seo" -Value ([PSCustomObject]@{
            command = "npx"
            args = @("-y", "seo", "mcp", "serve")
        }) -Force

        $mcpObj | ConvertTo-Json -Depth 10 | Set-Content $mcpConfigFile
        Write-Host "  [OK] Successfully configured .agents/mcp_config.json" -ForegroundColor Green
        $restartRequired = $true
    }

    # Test MCP server startup
    try {
        $testRes = npx -y seo mcp serve --test 2>&1
        if ($testRes -match "constructed successfully") {
            Write-Host "  [OK] SEO MCP daemon startup test passed" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [WARN] Could not test MCP daemon: $_" -ForegroundColor Yellow
    }
}

# Verify CI/CD Mode
if ($Mode -eq "cicd" -or $Mode -eq "all") {
    Write-Host "`n[3/3] Checking CI/CD and pre-push gates..." -ForegroundColor Cyan
    $ciWorkflow = Join-Path (Get-Location) ".github/workflows/seo-check.yml"
    if (Test-Path $ciWorkflow) {
        Write-Host "  [OK] CI/CD workflow found: .github/workflows/seo-check.yml" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] CI/CD workflow .github/workflows/seo-check.yml not created yet" -ForegroundColor Gray
    }

    $prePushHook = Join-Path (Get-Location) ".husky/pre-push"
    if (Test-Path $prePushHook) {
        Write-Host "  [OK] Husky pre-push hook found" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Husky pre-push hook not configured" -ForegroundColor Gray
    }

    $prePushScript = (Test-Path (Join-Path (Get-Location) "scripts/seo-pre-push.ps1")) -or (Test-Path (Join-Path (Get-Location) "scripts/seo-pre-push.sh"))
    if ($prePushScript) {
        Write-Host "  [OK] SEO pre-push runner script found in scripts/" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] SEO pre-push runner script not found in scripts/ (see resources/templates/)" -ForegroundColor Gray
    }
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
if ($restartRequired) {
    Write-Host ">> ACTION REQUIRED: The MCP server configuration was newly installed/updated. Please reload the IDE window or restart the agent session so Antigravity can connect to the new tools. <<" -ForegroundColor Magenta
}
if ($failures -eq 0) {
    Write-Host "All prerequisite checks passed successfully." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Verification encountered $failures failure(s)." -ForegroundColor Red
    exit 1
}
