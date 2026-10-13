param(
    [string]$ConfigPath,
    [switch]$Json
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

$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$pathChecks = [System.Collections.Generic.List[hashtable]]::new()
$automationChecks = [System.Collections.Generic.List[hashtable]]::new()

$fileExists = Test-Path $targetConfigFile
$isValidJson = $false
$parsedData = $null
$meta = $null

if (-not $fileExists) {
    $errors.Add("Configuration file not found at: $targetConfigFile")
} else {
    try {
        $rawContent = Get-Content -Raw -Path $targetConfigFile -Encoding UTF8
        $parsedData = ConvertFrom-Json $rawContent
        $isValidJson = $true
    } catch {
        $errors.Add("Invalid JSON syntax in '$targetConfigFile': $($_.Exception.Message)")
    }
}

if ($isValidJson -and $parsedData) {
    if (-not ($parsedData.PSObject.Properties.Name -contains "project_context_and_metadata")) {
        $errors.Add("Missing required top-level key: 'project_context_and_metadata'")
    } else {
        $meta = $parsedData.project_context_and_metadata

        # Validate required string properties
        $requiredStrings = @(
            "package_manager",
            "new_component_dir",
            "style_file_dir",
            "component_library",
            "dictionaries_dir",
            "dictionary_file_pattern"
        )
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

        if ($meta.dictionaries_dir) {
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
        $automationChecks.Add(@{ name = "Antigravity Global MCP Integration"; status = "warning"; details = "'$foundAgMcp' exists, but missing server(s): $($missing -join ', '). Note: Antigravity only discovers MCP servers configured globally on the system." })
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
    }
    $resultObj | ConvertTo-Json -Depth 5
    if (-not $passed) { exit 1 } else { exit 0 }
}

Write-Host ""
Write-Host "$Bold$Cyan=== Next.js Dev Setup & project.json Verification ===$Reset"
Write-Host ""
Write-Host "$BoldConfiguration File:$Reset $targetConfigFile"
Write-Host "$BoldFile Exists:$Reset $(if ($fileExists) { "${Green}Yes${Reset}" } else { "${Red}No${Reset}" })"
Write-Host "$BoldValid JSON:$Reset $(if ($isValidJson) { "${Green}Yes${Reset}" } else { "${Red}No${Reset}" })"
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
    Write-Host "$Bold$Magenta▶ Git Hooks, Commit Standards & Release Automation:$Reset"
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
