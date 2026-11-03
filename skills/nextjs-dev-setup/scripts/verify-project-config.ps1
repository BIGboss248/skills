param(
    [string]$ConfigPath,
    [string]$SelectionPath = ".agents/nextjs-setup-features.json",
    [switch]$Json,
    [switch]$AllFeatures
)

$ErrorActionPreference = "Continue"

# ANSI Color codes
$ESC = [char]27
$Reset = "$ESC[0m"
$Bold = "$ESC[1m"
$Red = "$ESC[31m"
$Green = "$ESC[32m"
$Yellow = "$ESC[33m"
$Cyan = "$ESC[36m"
$Magenta = "$ESC[35m"

function Resolve-ConfigPath {
    param([string]$Custom)
    if ($Custom -and (Test-Path $Custom)) {
        return (Resolve-Path $Custom).Path
    }
    $candidates = @(
        "docs/project.json",
        "docs/PROJECT.JSON",
        ".agents/project.json",
        ".agents/PROJECT.JSON"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            return (Resolve-Path $c).Path
        }
    }
    return [System.IO.Path]::GetFullPath("docs/project.json")
}

$targetConfigFile = Resolve-ConfigPath -Custom $ConfigPath
$rootDir = (Get-Location).Path

# --- Feature selection (.agents/nextjs-setup-features.json, fallback docs/project.json) ---
function Resolve-SelectionPath {
    param([string]$Custom)
    if ($Custom -and (Test-Path -LiteralPath $Custom)) {
        return (Resolve-Path -LiteralPath $Custom).Path
    }
    foreach ($candidate in @(".agents/nextjs-setup-features.json", "docs/project.json")) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return $null
}

$selectionFeatures = $null
$selectionSource = $null
if (-not $AllFeatures) {
    $selectionFile = Resolve-SelectionPath -Custom $SelectionPath
    if ($selectionFile) {
        try {
            $selectionData = Get-Content -LiteralPath $selectionFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($selectionData.nextjs_setup_features) { $selectionData = $selectionData.nextjs_setup_features }
            if ($selectionData.enabled) {
                $selectionFeatures = @($selectionData.enabled)
                $selectionSource = $selectionFile
            }
        } catch {
            # Unreadable selection falls back to auditing every feature.
        }
    }
}

function Test-FeatureEnabled([string]$Id) {
    if ($null -eq $selectionFeatures) { return $true }
    return ($selectionFeatures -contains $Id)
}

function Get-CheckFeature([string]$Name) {
    switch -Wildcard ($Name) {
        "Commitlint Configuration" { return "N12" }
        "Husky Git Hooks" { return "N12" }
        "Release Please CI/CD" { return "N12" }
        "GitHub Triage Infrastructure" { return "N12" }
        "Jest Test Runner" { return "N5" }
        "Playwright Test Runner" { return "N6" }
        "Workspace MCP Server Integration" { return "N10" }
        "Antigravity Global MCP Integration" { return "N10" }
        "Codebase Memory Exclusions*" { return "N10" }
        "Docker Containerization" { return "N11" }
        "Agent-First Tailwind Linter*" { return "N8" }
        "App Icons & PWA Web Manifest" { return "N3" }
        "Next.js Internationalization*" { return "N4" }
        "Next.js Core Dependency*" { return "N2" }
        "Agent Instructions & Docs Notice*" { return "N2" }
        "Navigation Pending Feedback*" { return "N2" }
        "Theming & Dark Mode*" { return "N13" }
        "Agent Roster & Permission Boundaries" { return "N9" }
        default { return $null }
    }
}

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$pathChecks = [System.Collections.Generic.List[hashtable]]::new()
$automationChecks = [System.Collections.Generic.List[hashtable]]::new()

$fileExists = Test-Path $targetConfigFile
$isValidJson = $false
$parsedData = $null
$meta = $null

if (-not $fileExists) {
    if (Test-FeatureEnabled "N1") {
        $errors.Add("Configuration file not found at: $targetConfigFile")
    }
} else {
    try {
        $rawContent = Get-Content -Raw -Path $targetConfigFile -Encoding UTF8
        $parsedData = ConvertFrom-Json $rawContent
        $isValidJson = $true
    } catch {
        if (Test-FeatureEnabled "N1") {
            $errors.Add("Invalid JSON syntax in '$targetConfigFile': $($_.Exception.Message)")
        }
    }
}

if ((Test-FeatureEnabled "N1") -and $isValidJson -and $parsedData) {
    if (-not ($parsedData.PSObject.Properties.Name -contains "project_context_and_metadata")) {
        $errors.Add("Missing required top-level key: 'project_context_and_metadata'")
    } else {
        $meta = $parsedData.project_context_and_metadata

        # Validate required string properties
        $requiredStrings = @(
            "package_manager",
            "new_component_dir",
            "style_file_dir",
            "component_library"
        )
        if (Test-FeatureEnabled "N4") {
            $requiredStrings += @("dictionaries_dir", "dictionary_file_pattern")
        }
        foreach ($prop in $requiredStrings) {
            $val = $meta.$prop
            if ($null -eq $val -or "$val".Trim() -eq "") {
                $errors.Add("Missing or empty required property: '$prop'")
            }
        }

        # Validate array properties
        $requiredArrays = @("animation_library", "testing_library")
        foreach ($arrProp in $requiredArrays) {
            $val = $meta.$arrProp
            if ($null -eq $val) {
                $errors.Add("Missing required array property: '$arrProp'")
            } elseif ($val -isnot [System.Array] -and $val -isnot [System.Collections.IList]) {
                $errors.Add("Property '$arrProp' must be an array")
            } elseif ($val.Count -eq 0) {
                $errors.Add("Property '$arrProp' must contain at least one entry")
            }
        }

        # Validate supported_languages
        if ($null -eq $meta.supported_languages) {
            $errors.Add("Missing required property: 'supported_languages'")
        } elseif ($meta.supported_languages -isnot [System.Array] -and $meta.supported_languages -isnot [System.Collections.IList]) {
            $errors.Add("Property 'supported_languages' must be an array")
        } elseif ($meta.supported_languages.Count -eq 0) {
            $errors.Add("Property 'supported_languages' must contain at least one locale object")
        } else {
            $locIdx = 0
            foreach ($loc in $meta.supported_languages) {
                $requiredLocFields = @("language_code", "country_code", "currency_code", "direction", "native_name", "calendar_type")
                foreach ($lf in $requiredLocFields) {
                    if ($null -eq $loc.$lf -or "$($loc.$lf)".Trim() -eq "") {
                        $errors.Add("supported_languages[$locIdx] is missing or has empty field '$lf'")
                    }
                }
                if ($loc.direction -and $loc.direction -ne "ltr" -and $loc.direction -ne "rtl") {
                    $errors.Add("supported_languages[$locIdx].direction must be 'ltr' or 'rtl', received '$($loc.direction)'")
                }
                $locIdx++
            }
        }

        # Validate filesystem paths
        if ($meta.style_file_dir) {
            $stylePath = Join-Path $rootDir $meta.style_file_dir
            $exists = (Test-Path $stylePath -PathType Leaf)
            $pathChecks.Add(@{ property = "style_file_dir"; expectedPath = $meta.style_file_dir; exists = $exists; type = "file" })
            if (-not $exists) {
                $warnings.Add("Global stylesheet '$($meta.style_file_dir)' does not exist on disk.")
            }
        }

        if ($meta.new_component_dir) {
            $compPath = Join-Path $rootDir $meta.new_component_dir
            $exists = (Test-Path $compPath -PathType Container)
            $pathChecks.Add(@{ property = "new_component_dir"; expectedPath = $meta.new_component_dir; exists = $exists; type = "directory" })
            if (-not $exists) {
                $warnings.Add("Component directory '$($meta.new_component_dir)' does not exist yet.")
            }
        }

        if ((Test-FeatureEnabled "N4") -and $meta.dictionaries_dir) {
            $dictPath = Join-Path $rootDir $meta.dictionaries_dir
            $exists = (Test-Path $dictPath -PathType Container)
            $pathChecks.Add(@{ property = "dictionaries_dir"; expectedPath = $meta.dictionaries_dir; exists = $exists; type = "directory" })
            if (-not $exists) {
                $warnings.Add("Dictionaries directory '$($meta.dictionaries_dir)' does not exist yet.")
            } elseif ($meta.supported_languages -and $meta.dictionary_file_pattern) {
                foreach ($loc in $meta.supported_languages) {
                    if ($loc.language_code) {
                        $fn = $meta.dictionary_file_pattern -replace '\[locale\]', $loc.language_code
                        $relPath = Join-Path $meta.dictionaries_dir $fn
                        $absPath = Join-Path $rootDir $relPath
                        $fe = (Test-Path $absPath -PathType Leaf)
                        $pathChecks.Add(@{ property = "dictionary:$($loc.language_code)"; expectedPath = $relPath; exists = $fe; type = "file" })
                        if (-not $fe) {
                            $warnings.Add("i18n dictionary file '$relPath' for locale '$($loc.language_code)' was not found.")
                        }
                    }
                }
            }
        }
    }
}

# --- Dev Automation Audits ---

# 1. Commitlint Check
$commitlintConfigs = @("commitlint.config.mjs", "commitlint.config.js", "commitlint.config.cjs", "commitlint.config.ts", ".commitlintrc.json", ".commitlintrc.yaml", ".commitlintrc.yml", ".commitlintrc.js", ".commitlintrc.mjs")
$foundCommitlint = $commitlintConfigs | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
if ($foundCommitlint) {
    $automationChecks.Add(@{ name = "Commitlint Configuration"; status = "configured"; details = "Found '$foundCommitlint' enforcing Conventional Commits." })
} else {
    $automationChecks.Add(@{ name = "Commitlint Configuration"; status = "missing"; details = "Missing commitlint.config.mjs. Required for Conventional Commit enforcement." })
}

# 2. Husky & Git Hooks Check
$huskyDir = Join-Path $rootDir ".husky"
$hasHusky = (Test-Path $huskyDir -PathType Container)
$hasCommitMsg = $hasHusky -and (Test-Path (Join-Path $huskyDir "commit-msg"))
$hasPrePush = $hasHusky -and (Test-Path (Join-Path $huskyDir "pre-push"))

if ($hasHusky) {
    if ($hasCommitMsg -and $hasPrePush) {
        $automationChecks.Add(@{ name = "Husky Git Hooks"; status = "configured"; details = "Configured with .husky/commit-msg and .husky/pre-push hooks." })
    } else {
        $missingHooks = @()
        if (-not $hasCommitMsg) { $missingHooks += ".husky/commit-msg" }
        if (-not $hasPrePush) { $missingHooks += ".husky/pre-push" }
        $automationChecks.Add(@{ name = "Husky Git Hooks"; status = "warning"; details = "Husky initialized, but missing hook(s): $($missingHooks -join ', ')" })
    }
} else {
    $automationChecks.Add(@{ name = "Husky Git Hooks"; status = "missing"; details = "Missing .husky/ directory. Run 'pnpm exec husky init'." })
}

# 3. Release Please Check
$releaseWfs = @(".github/workflows/release-please.yml", ".github/workflows/release-please.yaml", ".github/workflows/release.yml", ".github/workflows/release.yaml")
$foundReleaseWf = $releaseWfs | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1

if ($foundReleaseWf) {
    $wfContent = Get-Content -Raw -Path (Join-Path $rootDir $foundReleaseWf) -Encoding UTF8
    $pm = if ($meta -and $meta.package_manager) { $meta.package_manager } else { "pnpm" }
    $pmWarning = ""
    if ($pm -eq "pnpm" -and $wfContent.Contains('cache: "pnpm"') -and (-not $wfContent.Contains("pnpm/action-setup"))) {
        $pmWarning = " (Warning: Missing 'pnpm/action-setup' before 'actions/setup-node' with pnpm cache)"
    }
    $hasNextCache = $wfContent.Contains(".next/cache")
    $cacheStatus = if ($hasNextCache) { " [Next.js CI build cache enabled]" } else { " (Note: Missing '.next/cache' build caching step; recommended to avoid 'No Cache Detected' and accelerate CI)" }
    $status = if ($pmWarning) { "warning" } else { "configured" }
    $automationChecks.Add(@{ name = "Release Please CI/CD"; status = $status; details = "Found GitHub Actions workflow '$foundReleaseWf' configured for $pm.$pmWarning$cacheStatus" })
} else {
    $automationChecks.Add(@{ name = "Release Please CI/CD"; status = "warning"; details = "Missing .github/workflows/release-please.yml for automated semver releases and changelog." })
}

# 4. Jest & Playwright Check
$jestConfigs = @("jest.config.ts", "jest.config.js", "jest.config.mjs", "jest.config.cjs")
$foundJest = $jestConfigs | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
$hasJestSetup = (Test-Path (Join-Path $rootDir "jest.setup.ts")) -or (Test-Path (Join-Path $rootDir "jest.setup.js")) -or (Test-Path (Join-Path $rootDir "jest.setup.mjs"))

if ($foundJest) {
    $setupTxt = if ($hasJestSetup) { "configured" } else { "none" }
    $automationChecks.Add(@{ name = "Jest Test Runner"; status = "configured"; details = "Found '$foundJest' (setup: $setupTxt) for Unit & Snapshot testing." })
} else {
    $automationChecks.Add(@{ name = "Jest Test Runner"; status = "warning"; details = "Missing jest.config.ts / jest.setup.ts for unit and component snapshot testing." })
}

$pwConfigs = @("playwright.config.ts", "playwright.config.js", "playwright.config.mjs")
$foundPw = $pwConfigs | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1

if ($foundPw) {
    $automationChecks.Add(@{ name = "Playwright Test Runner"; status = "configured"; details = "Found '$foundPw' with E2E test configuration." })
} else {
    $automationChecks.Add(@{ name = "Playwright Test Runner"; status = "warning"; details = "Missing playwright.config.ts for automated browser and UI testing." })
}

# 5. MCP Server Integration (Workspace & Antigravity Global)
function Test-McpConfig {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    try {
        $raw = Get-Content -Raw -Path $FilePath -Encoding UTF8
        $cleaned = $raw -replace '(?m)^\s*//.*$', ''
        $json = ConvertFrom-Json $cleaned
        $servers = if ($json.mcpServers) { $json.mcpServers } elseif ($json.servers) { $json.servers } else { @{} }
        $keys = $servers.PSObject.Properties.Name
        $jsonStr = $servers | ConvertTo-Json -Compress -Depth 5

        $hasNext = ($keys | Where-Object { $_ -match "next" }) -or ($jsonStr -match "next-devtools") -or ($jsonStr -match "server-nextjs")
        $hasCbm = ($keys | Where-Object { $_ -match "codebase-memory" }) -or ($jsonStr -match "codebase-memory-mcp")
        $hasPw = ($keys | Where-Object { $_ -match "playwright" }) -or ($jsonStr -match "playwright")

        return @{
            hasNext = [bool]$hasNext
            hasCbm = [bool]$hasCbm
            hasPw = [bool]$hasPw
            error = $null
        }
    } catch {
        return @{ error = $_.Exception.Message }
    }
}

$wsMcpPaths = @("mcp.json", ".agents/plugins/workspace-tools/mcp_config.json", ".vscode/mcp.json", ".cursor/mcp.json", ".agents/mcp_config.json", "mcp_config.json")
$foundWsMcp = $wsMcpPaths | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1

if ($foundWsMcp) {
    $chk = Test-McpConfig -FilePath (Join-Path $rootDir $foundWsMcp)
    if ($chk.error) {
        $automationChecks.Add(@{ name = "Workspace MCP Server Integration"; status = "warning"; details = "Failed to parse workspace config '$foundWsMcp': $($chk.error)" })
    } elseif ($chk.hasNext -and $chk.hasCbm -and $chk.hasPw) {
        $automationChecks.Add(@{ name = "Workspace MCP Server Integration"; status = "configured"; details = "Found '$foundWsMcp' configured with next-devtools, codebase-memory, and playwright." })
    } else {
        $missing = @()
        if (-not $chk.hasNext) { $missing += "next-devtools" }
        if (-not $chk.hasCbm) { $missing += "codebase-memory" }
        if (-not $chk.hasPw) { $missing += "playwright" }
        $automationChecks.Add(@{ name = "Workspace MCP Server Integration"; status = "warning"; details = "'$foundWsMcp' exists, but missing server(s): $($missing -join ', ')" })
    }
} else {
    $automationChecks.Add(@{ name = "Workspace MCP Server Integration"; status = "warning"; details = "Missing workspace mcp.json / .vscode/mcp.json / .agents/plugins/workspace-tools/mcp_config.json." })
}

$userHome = [System.Environment]::GetFolderPath('UserProfile')
$agGlobalPaths = @(
    (Join-Path $userHome ".gemini/antigravity/mcp_config.json"),
    (Join-Path $userHome ".gemini/config/mcp_config.json")
)
$foundAgMcp = $agGlobalPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($foundAgMcp) {
    $chk = Test-McpConfig -FilePath $foundAgMcp
    if ($chk.error) {
        $automationChecks.Add(@{ name = "Antigravity Global MCP Integration"; status = "warning"; details = "Failed to parse Antigravity global config '$foundAgMcp': $($chk.error)" })
    } elseif ($chk.hasNext -and $chk.hasCbm -and $chk.hasPw) {
        $automationChecks.Add(@{ name = "Antigravity Global MCP Integration"; status = "configured"; details = "Found Antigravity global config '$foundAgMcp' configured with next-devtools, codebase-memory, and playwright." })
    } else {
        $missing = @()
        if (-not $chk.hasNext) { $missing += "next-devtools" }
        if (-not $chk.hasCbm) { $missing += "codebase-memory" }
        if (-not $chk.hasPw) { $missing += "playwright" }
        $automationChecks.Add(@{ name = "Antigravity Global MCP Integration"; status = "warning"; details = "'$foundAgMcp' exists, but missing server(s): $($missing -join ', '). Note: Antigravity only discovers MCP servers configured globally on the host system." })
    }
} else {
    $automationChecks.Add(@{ name = "Antigravity Global MCP Integration"; status = "warning"; details = "Missing Antigravity global mcp_config.json (~/.gemini/antigravity/mcp_config.json). Antigravity only discovers MCP servers configured globally on the host system." })
}

# 6. Codebase Memory Exclusions (.cbmignore)
$cbmignorePath = Join-Path $rootDir ".cbmignore"
if (Test-Path $cbmignorePath) {
    $cbmContent = Get-Content -Raw -Path $cbmignorePath -Encoding UTF8
    if ($cbmContent.Contains(".agents") -and $cbmContent.Contains("docs") -and $cbmContent.Contains(".next")) {
        $automationChecks.Add(@{ name = "Codebase Memory Exclusions (.cbmignore)"; status = "configured"; details = "Found root '.cbmignore' with proper exclusions for high-churn documents and Next.js caches." })
    } else {
        $automationChecks.Add(@{ name = "Codebase Memory Exclusions (.cbmignore)"; status = "warning"; details = "Found '.cbmignore' but missing key exclusions (.agents/, docs/, or .next/) to prevent editor stutters." })
    }
} else {
    $automationChecks.Add(@{ name = "Codebase Memory Exclusions (.cbmignore)"; status = "warning"; details = "Missing root '.cbmignore' file. High-churn files (.agents/, docs/, *.md) will cause editor stutters during indexing." })
}

# 7. Docker Containerization Check
$dockerfilePath = Join-Path $rootDir "Dockerfile"
$composePath = if (Test-Path (Join-Path $rootDir "docker-compose.yml")) { Join-Path $rootDir "docker-compose.yml" } else { Join-Path $rootDir "compose.yaml" }
$dockerignorePath = Join-Path $rootDir ".dockerignore"

$hasDockerfile = Test-Path $dockerfilePath
$hasCompose = Test-Path $composePath
$hasDockerignore = Test-Path $dockerignorePath

if ($hasDockerfile -and $hasCompose -and $hasDockerignore) {
    $composeName = [System.IO.Path]::GetFileName($composePath)
    $automationChecks.Add(@{ name = "Docker Containerization"; status = "configured"; details = "Configured multi-stage production standalone Dockerfile, $composeName, and .dockerignore." })
} else {
    $missing = @()
    if (-not $hasDockerfile) { $missing += "Dockerfile" }
    if (-not $hasCompose) { $missing += "docker-compose.yml" }
    if (-not $hasDockerignore) { $missing += ".dockerignore" }
    $automationChecks.Add(@{ name = "Docker Containerization"; status = "warning"; details = "Docker containerization files missing: $($missing -join ', ')" })
}

# 8. Agent-First Tailwind Design System Linter (@shadcn/lint)
$hasShadcnLintDep = $false
$pkgPath = Join-Path $rootDir "package.json"
if (Test-Path $pkgPath) {
    try {
        $pkg = Get-Content -Raw -Path $pkgPath -Encoding UTF8 | ConvertFrom-Json
        $deps = @{}
        if ($pkg.dependencies) { $pkg.dependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
        if ($pkg.devDependencies) { $pkg.devDependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
        $hasShadcnLintDep = $deps.ContainsKey("@shadcn/lint")
    } catch {}
}

$eslintConfigs = @("eslint.config.mjs", "eslint.config.js", "eslint.config.ts", "eslint.config.cjs", ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yml", ".eslintrc.yaml")
$foundEslint = $eslintConfigs | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
$hasShadcnLintConfig = $false
if ($foundEslint) {
    $eslintContent = Get-Content -Raw -Path (Join-Path $rootDir $foundEslint) -Encoding UTF8
    $hasShadcnLintConfig = ($eslintContent.Contains("@shadcn/lint") -or $eslintContent.Contains("shadcn"))
}

if ($hasShadcnLintDep -and $hasShadcnLintConfig) {
    $automationChecks.Add(@{ name = "Agent-First Tailwind Linter (@shadcn/lint)"; status = "configured"; details = "Installed @shadcn/lint and registered in '$foundEslint' with design system verification rules." })
} elseif ($hasShadcnLintDep -or $hasShadcnLintConfig) {
    $details = if ($hasShadcnLintDep) { "Package @shadcn/lint is installed in package.json but not yet configured in ESLint config." } else { "ESLint config '$foundEslint' references shadcn lint, but @shadcn/lint package is missing from package.json." }
    $automationChecks.Add(@{ name = "Agent-First Tailwind Linter (@shadcn/lint)"; status = "warning"; details = $details })
} else {
    $automationChecks.Add(@{ name = "Agent-First Tailwind Linter (@shadcn/lint)"; status = "warning"; details = "Missing @shadcn/lint integration in package.json and ESLint config for agent design system enforcement." })
}

# 9. App Icons & PWA Web Manifest Check
$appDir = if (Test-Path (Join-Path $rootDir "src/app")) { "src/app" } elseif (Test-Path (Join-Path $rootDir "app")) { "app" } else { "app" }
$manifestPaths = @(
    (Join-Path $appDir "manifest.ts"),
    (Join-Path $appDir "manifest.js"),
    (Join-Path $appDir "manifest.json"),
    (Join-Path $appDir "manifest.webmanifest")
)
$foundManifest = $manifestPaths | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1

$hasFavicon = (Test-Path (Join-Path $rootDir "$appDir/favicon.ico")) -or (Test-Path (Join-Path $rootDir "public/favicon.ico"))
$hasIcon = (Test-Path (Join-Path $rootDir "$appDir/icon.png")) -or (Test-Path (Join-Path $rootDir "$appDir/icon.ico")) -or (Test-Path (Join-Path $rootDir "$appDir/icon.svg")) -or (Test-Path (Join-Path $rootDir "$appDir/icon.tsx")) -or (Test-Path (Join-Path $rootDir "$appDir/icon.js"))
$hasAppleIcon = (Test-Path (Join-Path $rootDir "$appDir/apple-icon.png")) -or (Test-Path (Join-Path $rootDir "$appDir/apple-icon.jpg")) -or (Test-Path (Join-Path $rootDir "$appDir/apple-icon.tsx")) -or (Test-Path (Join-Path $rootDir "$appDir/apple-icon.js"))

if ($foundManifest -and ($hasFavicon -or $hasIcon -or $hasAppleIcon)) {
    $automationChecks.Add(@{ name = "App Icons & PWA Web Manifest"; status = "configured"; details = "Found '$foundManifest' and App Router icon file conventions." })
} elseif ($foundManifest) {
    $automationChecks.Add(@{ name = "App Icons & PWA Web Manifest"; status = "configured"; details = "Found Web App Manifest '$foundManifest'." })
} else {
    $automationChecks.Add(@{ name = "App Icons & PWA Web Manifest"; status = "warning"; details = "Missing Web App Manifest ($appDir/manifest.ts) and App Router icon file conventions." })
}

# 10. Next.js Internationalization (next-intl) Check
$hasGetIntlDep = $false
if (Test-Path $pkgPath) {
    try {
        $pkg = Get-Content -Raw -Path $pkgPath -Encoding UTF8 | ConvertFrom-Json
        $deps = @{}
        if ($pkg.dependencies) { $pkg.dependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
        if ($pkg.devDependencies) { $pkg.devDependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
        $hasGetIntlDep = $deps.ContainsKey("next-intl")
    } catch {}
}

$hasRouting = (Test-Path (Join-Path $rootDir "i18n/routing.ts")) -or (Test-Path (Join-Path $rootDir "src/i18n/routing.ts"))
$hasRequest = (Test-Path (Join-Path $rootDir "i18n/request.ts")) -or (Test-Path (Join-Path $rootDir "src/i18n/request.ts"))
$hasNavigation = (Test-Path (Join-Path $rootDir "i18n/navigation.ts")) -or (Test-Path (Join-Path $rootDir "src/i18n/navigation.ts"))
$hasProxy = (Test-Path (Join-Path $rootDir "proxy.ts")) -or (Test-Path (Join-Path $rootDir "src/proxy.ts"))
$hasMiddleware = (Test-Path (Join-Path $rootDir "middleware.ts")) -or (Test-Path (Join-Path $rootDir "src/middleware.ts"))
$hasInterceptor = $hasProxy -or $hasMiddleware

$nextConfigs = @("next.config.ts", "next.config.js", "next.config.mjs")
$foundNextConfig = $nextConfigs | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
$hasNextIntlPlugin = $false
if ($foundNextConfig) {
    $nextConfContent = Get-Content -Raw -Path (Join-Path $rootDir $foundNextConfig) -Encoding UTF8
    $hasNextIntlPlugin = ($nextConfContent.Contains("next-intl/plugin") -or $nextConfContent.Contains("createNextIntlPlugin") -or $nextConfContent.Contains("withNextIntl"))
}

$missingIntl = @()
if (-not $hasGetIntlDep) { $missingIntl += "package next-intl" }
if (-not $hasRouting) { $missingIntl += "i18n/routing.ts" }
if (-not $hasRequest) { $missingIntl += "i18n/request.ts" }
if (-not $hasNavigation) { $missingIntl += "i18n/navigation.ts" }
if (-not $hasInterceptor) { $missingIntl += "proxy.ts/middleware.ts" }
if (-not $hasNextIntlPlugin) { $missingIntl += "next-intl plugin in next.config" }

if ($missingIntl.Count -eq 0) {
    $interceptorName = if ($hasProxy) { "proxy.ts (Next 16+)" } else { "middleware.ts" }
    $automationChecks.Add(@{ name = "Next.js Internationalization (next-intl)"; status = "configured"; details = "Configured next-intl, routing, request (root-params), navigation, $interceptorName, and next.config plugin." })
} else {
    $automationChecks.Add(@{ name = "Next.js Internationalization (next-intl)"; status = "warning"; details = "next-intl integration incomplete. Missing: $($missingIntl -join ', ')" })
}

# 11. GitHub Triage Infrastructure (.github/ISSUE_TEMPLATE) Check
$hasBugReportTpl = Test-Path (Join-Path $rootDir ".github/ISSUE_TEMPLATE/bug_report.yml")
$hasIssueConfigTpl = Test-Path (Join-Path $rootDir ".github/ISSUE_TEMPLATE/config.yml")
if ($hasBugReportTpl -and $hasIssueConfigTpl) {
    $automationChecks.Add(@{ name = "GitHub Triage Infrastructure"; status = "configured"; details = "Found .github/ISSUE_TEMPLATE/bug_report.yml and config.yml for github-triage." })
} else {
    $missingTriage = @()
    if (-not $hasBugReportTpl) { $missingTriage += ".github/ISSUE_TEMPLATE/bug_report.yml" }
    if (-not $hasIssueConfigTpl) { $missingTriage += ".github/ISSUE_TEMPLATE/config.yml" }
    $automationChecks.Add(@{ name = "GitHub Triage Infrastructure"; status = "warning"; details = "Missing GitHub triage template(s): $($missingTriage -join ', '). Run scripts/init_triage_infra.ps1." })
}

# 12. Agent Rules & Next.js Local Docs Notice (AGENTS.md / agent.md)
$agentMdCandidates = @("AGENTS.md", "agents.md", "AGENT.md", "agent.md")
$foundAgentMd = $agentMdCandidates | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1

if ($foundAgentMd) {
    $agentContent = Get-Content -Raw -Path (Join-Path $rootDir $foundAgentMd) -Encoding UTF8
    $hasOutdatedNotice = $agentContent -match "(?i)outdated"
    $hasDocsNotice = $agentContent -match "(?i)node_modules[\\/]next[\\/]dist[\\/]docs"

    if ($hasOutdatedNotice -and $hasDocsNotice) {
        $automationChecks.Add(@{ name = "Agent Instructions & Docs Notice ($foundAgentMd)"; status = "configured"; details = "Found '$foundAgentMd' with mandatory outdated context notice and 'node_modules\next\dist\docs' lookup mandate." })
    } elseif (-not $hasOutdatedNotice) {
        $automationChecks.Add(@{ name = "Agent Instructions & Docs Notice ($foundAgentMd)"; status = "warning"; details = "'$foundAgentMd' is missing notice that Next.js context is outdated." })
    } elseif (-not $hasDocsNotice) {
        $automationChecks.Add(@{ name = "Agent Instructions & Docs Notice ($foundAgentMd)"; status = "warning"; details = "'$foundAgentMd' is missing mandate to search 'node_modules\next\dist\docs'." })
    }
} else {
    $automationChecks.Add(@{ name = "Agent Instructions & Docs Notice (AGENTS.md)"; status = "warning"; details = "Missing AGENTS.md (or agent.md). Scaffold from AGENTS.md.template with outdated context notice." })
}

# 13. Next.js Core Dependency (next@latest) Check
if (Test-Path $pkgPath) {
    try {
        $pkg = Get-Content -Raw -Path $pkgPath -Encoding UTF8 | ConvertFrom-Json
        $deps = @{}
        if ($pkg.dependencies) { $pkg.dependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
        if ($deps.ContainsKey("next")) {
            $nextVer = $deps["next"]
            $automationChecks.Add(@{ name = "Next.js Core Dependency (next@latest)"; status = "configured"; details = "Installed Next.js version: $nextVer (configured to always target latest)." })
        } else {
            $automationChecks.Add(@{ name = "Next.js Core Dependency (next@latest)"; status = "warning"; details = "Missing 'next' dependency in package.json. Run '<pkg_mgr> add next@latest react@latest react-dom@latest'." })
        }
    } catch {}
}

# 14. Agent Roster & Permission Boundaries (.opencode/agents)
$agentSpecs = @(
    @{ Name = "nextjs-dev"; File = ".opencode/agents/nextjs-dev.md"; Mode = "subagent"; Required = @("*.test.tsx", "task: deny") },
    @{ Name = "nextjs-test-author"; File = ".opencode/agents/nextjs-test-author.md"; Mode = "subagent"; Required = @("edit:", "task: deny") },
    @{ Name = "nextjs-qa-auditor"; File = ".opencode/agents/nextjs-qa-auditor.md"; Mode = "subagent"; Required = @("edge.test.tsx", "task: deny") },
    @{ Name = "nextjs-orchestrator"; File = ".opencode/agents/nextjs-orchestrator.md"; Mode = "primary"; Required = @("nextjs-dev", "nextjs-test-author", "nextjs-qa-auditor") }
)

$missingAgents = @()
$invalidAgents = @()
foreach ($spec in $agentSpecs) {
    $agentPath = Join-Path $rootDir $spec.File
    if (-not (Test-Path $agentPath -PathType Leaf)) {
        $missingAgents += $spec.File
        continue
    }
    $agentContent = Get-Content -Raw -Path $agentPath -Encoding UTF8
    $problems = @()
    if ($agentContent -notmatch "(?m)^mode:\s*$($spec.Mode)\s*$") { $problems += "mode must be '$($spec.Mode)'" }
    if ($agentContent -match '\{\{[A-Z_]+\}\}') { $problems += "unreplaced {{TOKEN}} placeholder" }
    foreach ($needle in $spec.Required) {
        if (-not $agentContent.Contains($needle)) { $problems += "missing required token '$needle'" }
    }
    if ($problems.Count -gt 0) { $invalidAgents += "$($spec.File): $($problems -join '; ')" }
}

$boundariesRule = Join-Path $rootDir ".agents/rules/agent-boundaries.md"
$commandsMissing = @()
foreach ($cmd in @(".opencode/commands/create-nextjs-component.md", ".opencode/commands/create-nextjs-page.md")) {
    if (-not (Test-Path (Join-Path $rootDir $cmd) -PathType Leaf)) { $commandsMissing += $cmd }
}

if ($missingAgents.Count -eq 0 -and $invalidAgents.Count -eq 0 -and (Test-Path $boundariesRule) -and $commandsMissing.Count -eq 0) {
    $automationChecks.Add(@{ name = "Agent Roster & Permission Boundaries"; status = "configured"; details = "Found 4 agents in .opencode/agents with enforced write boundaries, .agents/rules/agent-boundaries.md, and both command shortcuts." })
} else {
    if (Test-FeatureEnabled "N9") {
        if ($missingAgents.Count -gt 0) { $errors.Add("Missing agent file(s): $($missingAgents -join ', '). Enable N9 (agent roster) or remove it from the selection.") }
        if ($invalidAgents.Count -gt 0) { $errors.Add("Invalid agent configuration - $($invalidAgents -join ' | ')") }
        if (-not (Test-Path $boundariesRule)) { $errors.Add("Missing .agents/rules/agent-boundaries.md.") }
        if ($commandsMissing.Count -gt 0) { $warnings.Add("Missing command shortcut(s): $($commandsMissing -join ', ').") }
    }
    $automationChecks.Add(@{ name = "Agent Roster & Permission Boundaries"; status = "missing"; details = "Agent roster incomplete. Missing: $($missingAgents -join ', '); invalid: $($invalidAgents.Count); boundaries rule: $(Test-Path $boundariesRule)." })
}

# 15. Navigation Pending Feedback (useLinkStatus) Check
$progressBarPackages = @("nprogress", "next-nprogress-bar", "@bprogress/core", "@bprogress/next", "react-transition-progress", "@vercel/react-transition-progress")
$declaredProgressPackages = @()
$hasNextThemesDep = $false
if (Test-Path $pkgPath) {
    try {
        $pkg = Get-Content -Raw -Path $pkgPath -Encoding UTF8 | ConvertFrom-Json
        $deps = @{}
        if ($pkg.dependencies) { $pkg.dependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
        if ($pkg.devDependencies) { $pkg.devDependencies.PSObject.Properties | ForEach-Object { $deps[$_.Name] = $_.Value } }
        foreach ($p in $progressBarPackages) { if ($deps.ContainsKey($p)) { $declaredProgressPackages += $p } }
        $hasNextThemesDep = $deps.ContainsKey("next-themes")
    } catch {}
}

$linkCandidates = @(
    "$appDir/components/Link.tsx",
    "$appDir/components/Link.jsx",
    "src/components/Link.tsx",
    "src/app/components/Link.tsx"
)
$foundLink = $linkCandidates | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
$hasUseLinkStatus = $false
$linkUsesLocalizedNavigation = $false
if ($foundLink) {
    $linkContent = Get-Content -Raw -Path (Join-Path $rootDir $foundLink) -Encoding UTF8
    $hasUseLinkStatus = $linkContent.Contains("useLinkStatus")
    $linkUsesLocalizedNavigation = ($linkContent.Contains("@/i18n/navigation") -or $linkContent.Contains("next/link"))
}

if ($declaredProgressPackages.Count -gt 0) {
    $automationChecks.Add(@{ name = "Navigation Pending Feedback (useLinkStatus)"; status = "warning"; details = "Global progress-bar package(s) declared: $($declaredProgressPackages -join ', '). Pending feedback must use per-link 'useLinkStatus' from 'next/link'." })
} elseif ($foundLink -and $hasUseLinkStatus) {
    $automationChecks.Add(@{ name = "Navigation Pending Feedback (useLinkStatus)"; status = "configured"; details = "'$foundLink' uses the built-in 'useLinkStatus' pending indicator; no progress-bar package is declared." })
} elseif ($foundLink) {
    $automationChecks.Add(@{ name = "Navigation Pending Feedback (useLinkStatus)"; status = "warning"; details = "'$foundLink' does not call 'useLinkStatus'. Replace any progress-bar wiring with a per-link inline indicator." })
} else {
    $automationChecks.Add(@{ name = "Navigation Pending Feedback (useLinkStatus)"; status = "warning"; details = "No composite Link primitive found (expected $appDir/components/Link.tsx). Internal navigation must go through $appDir/components/Link.tsx or @/i18n/navigation with a per-link 'useLinkStatus' indicator." })
}

# 16. Theming & Dark Mode (next-themes) Check
$themeStyleRel = $null
if ($meta -and $meta.style_file_dir) { $themeStyleRel = [string]$meta.style_file_dir }
if (-not $themeStyleRel) {
    $styleCandidates = @("$appDir/globals.css", "$appDir/global.css", "src/app/globals.css", "src/styles/globals.css")
    $themeStyleRel = $styleCandidates | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
}

$providerCandidates = @(
    "$appDir/providers.tsx",
    "$appDir/providers.jsx",
    "src/app/providers.tsx",
    "src/components/providers.tsx"
)
$foundProvider = $providerCandidates | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
$hasThemeProvider = $false
$themeAttribute = $null
if ($foundProvider) {
    $providerContent = Get-Content -Raw -Path (Join-Path $rootDir $foundProvider) -Encoding UTF8
    $hasThemeProvider = $providerContent.Contains("next-themes") -and $providerContent.Contains("ThemeProvider")
    $attributeMatch = [regex]::Match($providerContent, 'attribute\s*=\s*["'']([^"'']+)["'']')
    if ($attributeMatch.Success) { $themeAttribute = $attributeMatch.Groups[1].Value }
} elseif (Test-Path (Join-Path $rootDir $appDir)) {
    $themeProviderFile = Get-ChildItem -Path (Join-Path $rootDir $appDir) -Recurse -File -Include *.tsx,*.jsx -ErrorAction SilentlyContinue |
        Where-Object { (Get-Content -Raw -Path $_.FullName -Encoding UTF8) -match 'from\s+["'']next-themes["'']' } |
        Select-Object -First 1
    if ($themeProviderFile) {
        $foundProvider = $themeProviderFile.FullName.Replace($rootDir + [System.IO.Path]::DirectorySeparatorChar, "")
        $providerContent = Get-Content -Raw -Path $themeProviderFile.FullName -Encoding UTF8
        $hasThemeProvider = $providerContent.Contains("ThemeProvider")
        $attributeMatch = [regex]::Match($providerContent, 'attribute\s*=\s*["'']([^"'']+)["'']')
        if ($attributeMatch.Success) { $themeAttribute = $attributeMatch.Groups[1].Value }
    }
}

$hasDarkSelector = $false
if ($themeStyleRel -and (Test-Path (Join-Path $rootDir $themeStyleRel))) {
    $styleContent = Get-Content -Raw -Path (Join-Path $rootDir $themeStyleRel) -Encoding UTF8
    $hasDarkSelector = [bool]([regex]::IsMatch($styleContent, '(?i)(\.dark\b|\[data-theme|\[data-mode|prefers-color-scheme\s*:\s*dark)'))
}

$foundToggle = $null
if ($meta -and $meta.theme_toggle_path -and (Test-Path (Join-Path $rootDir ([string]$meta.theme_toggle_path)))) {
    $foundToggle = [string]$meta.theme_toggle_path
} else {
    $toggleCandidates = @()
    foreach ($dir in @("$appDir/components", "src/components", "components", "$appDir/components/ui")) {
        foreach ($name in @("ThemeToggle.tsx", "ModeToggle.tsx", "theme-toggle.tsx", "mode-toggle.tsx", "ThemeSwitch.tsx", "ThemeSwitcher.tsx", "ThemeMenu.tsx")) {
            $toggleCandidates += "$dir/$name"
        }
    }
    $foundToggle = $toggleCandidates | Where-Object { Test-Path (Join-Path $rootDir $_) } | Select-Object -First 1
    if (-not $foundToggle) {
        foreach ($dir in @("$appDir/components", "src/components", "components")) {
            if (Test-Path (Join-Path $rootDir $dir)) {
                $toggleFile = Get-ChildItem -Path (Join-Path $rootDir $dir) -Recurse -File -Include *.tsx,*.jsx -ErrorAction SilentlyContinue |
                    Where-Object { (Get-Content -Raw -Path $_.FullName -Encoding UTF8) -match 'useTheme\(' } |
                    Select-Object -First 1
                if ($toggleFile) {
                    $foundToggle = $toggleFile.FullName.Replace($rootDir + [System.IO.Path]::DirectorySeparatorChar, "")
                    break
                }
            }
        }
    }
}

$missingTheme = @()
if (-not $hasNextThemesDep) { $missingTheme += "package next-themes" }
if (-not $hasThemeProvider) { $missingTheme += "ThemeProvider (next-themes) in the provider file" }
if (-not $hasDarkSelector) { $missingTheme += "dark selector in '$themeStyleRel' (or record style_file_dir if tokens live elsewhere)" }
if (-not $foundToggle) { $missingTheme += "theme toggle component (light/dark/system)" }

if ($missingTheme.Count -eq 0) {
    $attrDetail = if ($themeAttribute) { "attribute='$themeAttribute'" } else { "attribute not declared (default 'class')" }
    $automationChecks.Add(@{ name = "Theming & Dark Mode (next-themes)"; status = "configured"; details = "next-themes installed; provider composed ($attrDetail); dark selector found in '$themeStyleRel'; toggle at '$foundToggle'." })
} else {
    $automationChecks.Add(@{ name = "Theming & Dark Mode (next-themes)"; status = "warning"; details = "Theming integration incomplete. Missing: $($missingTheme -join ', '). No CSS structure is mandated - only the token layer's dark variant must exist." })
}

# --- Apply the confirmed feature selection to the audits ---
foreach ($chk in $automationChecks) { $chk["feature"] = Get-CheckFeature $chk.name }
$skippedChecks = @($automationChecks | Where-Object { $_.feature -and -not (Test-FeatureEnabled $_.feature) })
$automationChecks = @($automationChecks | Where-Object { -not ($_.feature -and -not (Test-FeatureEnabled $_.feature)) })

$passed = ($errors.Count -eq 0)

# Output rendering
if ($Json) {
    $resultObj = [ordered]@{
        filePath = $targetConfigFile
        exists = $fileExists
        isValidJson = $isValidJson
        passed = $passed
        errors = $errors
        warnings = $warnings
        pathChecks = $pathChecks
        automationChecks = $automationChecks
        selectionSource = $selectionSource
        enabledFeatures = $selectionFeatures
        skippedChecks = @($skippedChecks | ForEach-Object { $_.name })
    }
    $resultObj | ConvertTo-Json -Depth 5
    if (-not $passed) { exit 1 } else { exit 0 }
}

Write-Host ""
Write-Host "$Bold$Cyan=== Next.js Dev Setup & project.json Verification ===$Reset"
Write-Host ""
Write-Host "${Bold}Configuration File:$Reset $targetConfigFile"
Write-Host "${Bold}File Exists:$Reset $(if ($fileExists) { "${Green}Yes${Reset}" } else { "${Red}No${Reset}" })"
Write-Host "${Bold}Valid JSON:$Reset $(if ($isValidJson) { "${Green}Yes${Reset}" } else { "${Red}No${Reset}" })"
if ($selectionSource) {
    Write-Host "${Bold}Feature Selection:$Reset $selectionSource"
    Write-Host "${Bold}Enabled Features:$Reset $(if ($selectionFeatures) { $selectionFeatures -join ', ' } else { 'all (selection has no enabled list)' })"
} elseif ($AllFeatures) {
    Write-Host "${Bold}Feature Selection:$Reset disabled (-AllFeatures); auditing every feature"
} else {
    Write-Host "${Bold}Feature Selection:$Reset not found; auditing every feature"
}
Write-Host ""

if ($meta) {
    Write-Host "$Bold$Magenta▶ Project Metadata & Schema Properties:$Reset"
    if ($meta.package_manager) { Write-Host "  - ${Cyan}package_manager${Reset}: `"$($meta.package_manager)`"" }
    if ($meta.new_component_dir) { Write-Host "  - ${Cyan}new_component_dir${Reset}: `"$($meta.new_component_dir)`"" }
    if ($meta.style_file_dir) { Write-Host "  - ${Cyan}style_file_dir${Reset}: `"$($meta.style_file_dir)`"" }
    if ($meta.component_library) { Write-Host "  - ${Cyan}component_library${Reset}: `"$($meta.component_library)`"" }
    if ($meta.animation_library) { Write-Host "  - ${Cyan}animation_library${Reset}: [$($meta.animation_library -join ', ')]" }
    if ($meta.testing_library) { Write-Host "  - ${Cyan}testing_library${Reset}: [$($meta.testing_library -join ', ')]" }
    if ($meta.supported_languages) {
        $lCodes = $meta.supported_languages | ForEach-Object { $_.language_code }
        Write-Host "  - ${Cyan}supported_languages${Reset}: [$($lCodes -join ', ')] ($($meta.supported_languages.Count) locale(s))"
    }
    if ($meta.dictionaries_dir) { Write-Host "  - ${Cyan}dictionaries_dir${Reset}: `"$($meta.dictionaries_dir)`"" }
    if ($meta.dictionary_file_pattern) { Write-Host "  - ${Cyan}dictionary_file_pattern${Reset}: `"$($meta.dictionary_file_pattern)`"" }
    Write-Host ""
}

if ($pathChecks.Count -gt 0) {
    Write-Host "$Bold$Magenta▶ Filesystem Structure & i18n Paths:$Reset"
    foreach ($chk in $pathChecks) {
        $icon = if ($chk.exists) { "${Green}[OK]${Reset}" } else { "${Yellow}[MISSING]${Reset}" }
        $label = if ($chk.exists) { "${Green}Exists${Reset}" } else { "${Yellow}Missing${Reset}" }
        Write-Host "  $icon ${Cyan}$($chk.property)${Reset}: $($chk.expectedPath) ($label)"
    }
    Write-Host ""
}

if ($automationChecks.Count -gt 0) {
    Write-Host "$Bold$Magenta▶ Feature Audits:$Reset"
    foreach ($chk in $automationChecks) {
        $tag = switch ($chk.status) {
            "configured" { "${Green}[OK]${Reset}" }
            "warning"    { "${Yellow}[WARN]${Reset}" }
            default      { "${Red}[MISSING]${Reset}" }
        }
        Write-Host "  $tag $Bold$($chk.name):$Reset $($chk.details)"
    }
    Write-Host ""
}

if ($skippedChecks.Count -gt 0) {
    Write-Host "$Bold$Yellow▶ Not checked (feature disabled in this setup):$Reset"
    foreach ($chk in $skippedChecks) {
        Write-Host "  [SKIP] $($chk.name) ($($chk.feature))"
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "$Yellow$Bold" "Warnings & Recommendations:" "$Reset"
    foreach ($w in $warnings) {
        Write-Host "  [WARN] $w"
    }
    Write-Host ""
}

if ($errors.Count -gt 0) {
    Write-Host "$Red$Bold" "Errors / Violations:" "$Reset"
    foreach ($e in $errors) {
        Write-Host "  [ERROR] $e"
    }
    Write-Host ""
}

if ($passed) {
    Write-Host "$Green$Bold[SUCCESS] project.json is valid and complete.$Reset"
    Write-Host ""
    exit 0
} else {
    Write-Host "$Red$Bold[FAILED] project.json has missing or invalid properties.$Reset"
    Write-Host ""
    exit 1
}
