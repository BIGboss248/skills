# Verifies the next-intl App Router setup produced by feature F11.
# Usage: powershell -ExecutionPolicy Bypass -File verify-i18n-setup.ps1 [-Root <repo>] [-Quiet]

param (
    [string]$Root = (Get-Location).Path,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$script:errors = 0

function Write-Log([string]$Message, [string]$Color) {
    if (-not $Quiet) { Write-Host $Message -ForegroundColor $Color }
}

function Assert-Condition([bool]$Condition, [string]$Message) {
    if ($Condition) {
        Write-Log "  [PASS] $Message" "Green"
    } else {
        Write-Host "  [FAIL] $Message" -ForegroundColor Red
        $script:errors++
    }
}

function Find-FirstFile([string[]]$RelativePaths) {
    foreach ($relative in $RelativePaths) {
        $candidate = Join-Path $Root $relative
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

function Read-Text([string]$Path) {
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Get-KeyPaths($Node, [string]$Prefix) {
    $paths = @()
    if ($null -eq $Node) { return $paths }
    if ($Node -is [System.Management.Automation.PSCustomObject]) {
        foreach ($property in $Node.PSObject.Properties) {
            $child = if ($Prefix) { "$Prefix.$($property.Name)" } else { $property.Name }
            $paths += $child
            $paths += Get-KeyPaths $property.Value $child
        }
    }
    return $paths
}

Write-Log "=== Verifying Next.js i18n setup (F11) ===" "Cyan"

# 1. next-intl dependency
$packageJsonPath = Join-Path $Root "package.json"
$hasDependency = $false
if (Test-Path $packageJsonPath) {
    $packageJson = Read-Text $packageJsonPath | ConvertFrom-Json
    $declared = @()
    if ($packageJson.dependencies) { $declared += $packageJson.dependencies.PSObject.Properties.Name }
    if ($packageJson.devDependencies) { $declared += $packageJson.devDependencies.PSObject.Properties.Name }
    $hasDependency = $declared -contains "next-intl"
}
Assert-Condition $hasDependency "next-intl is declared in package.json"

# 2. next-intl core files
$routingPath = Find-FirstFile @("i18n/routing.ts", "src/i18n/routing.ts")
$requestPath = Find-FirstFile @("i18n/request.ts", "src/i18n/request.ts")
$navigationPath = Find-FirstFile @("i18n/navigation.ts", "src/i18n/navigation.ts")
Assert-Condition ($null -ne $routingPath) "routing.ts exists (i18n/ or src/i18n/)"
Assert-Condition ($null -ne $requestPath) "request.ts exists (i18n/ or src/i18n/)"
Assert-Condition ($null -ne $navigationPath) "navigation.ts exists (i18n/ or src/i18n/)"

# 3. Request handler uses next/root-params and the deprecated APIs are gone
if ($requestPath) {
    $requestContent = Read-Text $requestPath
    Assert-Condition ($requestContent -match "next/root-params") "request.ts reads the locale from next/root-params"
    Assert-Condition ($requestContent -notmatch "requestLocale") "request.ts does not use the deprecated requestLocale"
    Assert-Condition ($requestContent -notmatch "setRequestLocale") "request.ts does not use setRequestLocale()"
}

# 4. Exactly one request interceptor
$proxyPath = Find-FirstFile @("proxy.ts", "src/proxy.ts")
$middlewarePath = Find-FirstFile @("middleware.ts", "src/middleware.ts")
Assert-Condition (($null -ne $proxyPath) -or ($null -ne $middlewarePath)) "request interceptor exists (proxy.ts or middleware.ts)"
Assert-Condition (-not (($null -ne $proxyPath) -and ($null -ne $middlewarePath))) "only one interceptor exists (proxy.ts XOR middleware.ts)"

$nextMajor = 0
if (Test-Path $packageJsonPath) {
    $nextVersion = $packageJson.dependencies.next
    if ($nextVersion -and ($nextVersion -match "(\d+)")) { $nextMajor = [int]$Matches[1] }
}
if ($nextMajor -ge 16) {
    Assert-Condition ($null -ne $proxyPath) "Next.js $nextMajor requires proxy.ts"
} elseif ($nextMajor -gt 0) {
    Assert-Condition ($null -ne $middlewarePath) "Next.js $nextMajor requires middleware.ts"
}

# 5. next.config composes the next-intl plugin
$nextConfigPath = Find-FirstFile @(
    "next.config.ts", "next.config.mjs", "next.config.js", "next.config.cjs",
    "src/next.config.ts", "src/next.config.mjs", "src/next.config.js"
)
$hasPlugin = $false
if ($nextConfigPath) {
    $nextConfigContent = Read-Text $nextConfigPath
    $hasPlugin = $nextConfigContent -match "createNextIntlPlugin"
}
Assert-Condition $hasPlugin "next.config wraps the config with createNextIntlPlugin()"

# 6. Locale layout owns the document shell
$layoutPath = Find-FirstFile @("app/[locale]/layout.tsx", "src/app/[locale]/layout.tsx")
Assert-Condition ($null -ne $layoutPath) "app/[locale]/layout.tsx exists"
if ($layoutPath) {
    $layoutContent = Read-Text $layoutPath
    Assert-Condition ($layoutContent -match "generateStaticParams") "locale layout exports generateStaticParams()"
    Assert-Condition ($layoutContent -match "NextIntlClientProvider") "locale layout renders NextIntlClientProvider"
}

$rootLayoutPath = Find-FirstFile @("app/layout.tsx", "src/app/layout.tsx")
if (($null -ne $rootLayoutPath) -and ($null -ne $layoutPath)) {
    $rootLayoutContent = Read-Text $rootLayoutPath
    Assert-Condition ($rootLayoutContent -notmatch "<html") "root layout does not render a second <html> element"
}

# 7. Global type augmentation
$globalTypesPath = Find-FirstFile @(
    "global.d.ts", "src/global.d.ts", "types/global.d.ts", "src/types/global.d.ts"
)
$hasAugmentation = $false
if ($globalTypesPath) {
    $globalTypesContent = Read-Text $globalTypesPath
    $hasAugmentation = ($globalTypesContent -match "AppConfig") -and ($globalTypesContent -match "Messages")
}
Assert-Condition $hasAugmentation "global.d.ts augments AppConfig.Messages"

# 8. Dictionaries exist for every configured locale and share the same keys
$dictionariesDir = Join-Path $Root "messages"
if (-not (Test-Path -LiteralPath $dictionariesDir)) { $dictionariesDir = Join-Path $Root "src/messages" }
Assert-Condition (Test-Path -LiteralPath $dictionariesDir) "messages/ dictionary directory exists"

$locales = @()
if ($routingPath) {
    $routingContent = Read-Text $routingPath
    $localeMatch = [regex]::Match($routingContent, "locales\s*:\s*\[([^\]]*)\]")
    if ($localeMatch.Success) {
        $locales = $localeMatch.Groups[1].Value -split "," |
            ForEach-Object { $_.Trim().Trim('"', "'") } |
            Where-Object { $_ }
    }
}
Assert-Condition ($locales.Count -gt 0) "routing.ts declares at least one locale"

$dictionaryFiles = @()
foreach ($locale in $locales) {
    $dictionaryPath = Join-Path $dictionariesDir "$locale.json"
    Assert-Condition (Test-Path -LiteralPath $dictionaryPath) "dictionary messages/$locale.json exists"
    if (Test-Path -LiteralPath $dictionaryPath) { $dictionaryFiles += $dictionaryPath }
}

if ($dictionaryFiles.Count -gt 0) {
    $baselineKeys = @(Get-KeyPaths (Read-Text $dictionaryFiles[0] | ConvertFrom-Json) "") |
        Where-Object { $_ } |
        Sort-Object -Unique
    foreach ($dictionaryPath in $dictionaryFiles) {
        $keys = @(Get-KeyPaths (Read-Text $dictionaryPath | ConvertFrom-Json) "") |
            Where-Object { $_ } |
            Sort-Object -Unique
        $drift = Compare-Object -ReferenceObject $baselineKeys -DifferenceObject $keys
        Assert-Condition ($null -eq $drift) "dictionary keys match baseline in $(Split-Path -Leaf $dictionaryPath)"
        if ($drift) {
            $drift | ForEach-Object {
                $side = if ($_.SideIndicator -eq "<=") { "missing" } else { "unexpected" }
                Write-Host "         $side key: $($_.InputObject)" -ForegroundColor Yellow
            }
        }
    }
}

# 9. Project metadata contract
$projectJsonPath = Join-Path $Root "docs/project.json"
$hasMetadata = $false
if (Test-Path -LiteralPath $projectJsonPath) {
    $projectText = Read-Text $projectJsonPath
    $hasMetadata = ($projectText -match '"dictionaries_dir"') -and ($projectText -match '"dictionary_file_pattern"')
}
Assert-Condition $hasMetadata "docs/project.json records dictionaries_dir and dictionary_file_pattern"

if ($script:errors -gt 0) {
    Write-Host "i18n-setup: FAIL ($($script:errors) error(s))" -ForegroundColor Red
    exit 1
}

Write-Host "i18n-setup: PASS" -ForegroundColor Green
exit 0
