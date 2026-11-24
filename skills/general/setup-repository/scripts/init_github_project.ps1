<#
.SYNOPSIS
    Creates a GitHub Project (v2) for the current repository and verifies the
    automations that add issues/PRs and check them off on close.

.DESCRIPTION
    Runs the remote half of setup-repository F14:
      1. Checks the GitHub CLI and the 'project' token scope.
      2. Creates the project, or reuses one with the same title.
      3. Re-enables the repository Projects tab and links the project to it.
      4. Reads the Status field and the configured done option.
      5. Reads the built-in workflows and reports whether "Item closed" is on.
      6. In headless mode, copies .github/workflows/project-sync.yml, sets the
         PROJECT_OWNER and PROJECT_NUMBER repository variables, and reports
         whether the PROJECT_TOKEN secret exists.

    The built-in "Auto-add to project" workflow has no API: the script prints
    the exact UI steps in native mode. It never writes to the project UI on
    the user's behalf.

.PARAMETER Owner
    Login that owns the project (a user or an organization).

.PARAMETER Title
    Project title. An existing open project with this title is reused.

.PARAMETER Repo
    Repository as owner/name. Defaults to the origin remote of the current
    directory.

.PARAMETER Mode
    native   - auto-add is configured in the project UI (default).
    headless - deploy the Actions workflow and its repository variables/secret.

.PARAMETER DoneOption
    Status option that means checked off. Defaults to Done.

.PARAMETER DeployWorkflow
    headless only: copy the workflow template into .github/workflows/ when it is
    missing. Existing files are never overwritten.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .agents/skills/setup-repository/scripts/init_github_project.ps1 `
        -Owner monalisa -Title "my-repo roadmap" -Mode headless -DeployWorkflow
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $Owner,

    [Parameter(Mandatory = $true)]
    [string] $Title,

    [string] $Repo = "",

    [ValidateSet("native", "headless")]
    [string] $Mode = "native",

    [string] $DoneOption = "Done",

    [switch] $DeployWorkflow
)

$ErrorActionPreference = "Continue"

function Fail([string] $message) {
    Write-Host "ERROR: $message" -ForegroundColor Red
    exit 1
}

Write-Host "==> Initializing GitHub Project board (F14, $Mode mode)..." -ForegroundColor Cyan

# 1. Preflight: gh installed and authenticated.
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Fail "GitHub CLI ('gh') is not in PATH. Install it, then re-run."
}

$authStatus = (& gh auth status 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0 -and -not $env:GH_TOKEN) {
    Fail "GitHub CLI is not authenticated. Run: gh auth login"
}

if ($authStatus -notmatch "'project'" -and $authStatus -notmatch "read:project") {
    Fail "The token has no 'project' scope. Run: gh auth refresh -s project,read:project"
}

# 2. Resolve the repository from the origin remote when it was not passed.
if ([string]::IsNullOrWhiteSpace($Repo)) {
    $remote = (& gh repo view --json nameWithOwner --jq .nameWithOwner 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remote)) {
        Fail "No origin remote detected. Pass -Repo <owner>/<name>."
    }
    $Repo = $remote.Trim()
}
$RepoOwner, $RepoName = $Repo.Split("/", 2)
if ([string]::IsNullOrWhiteSpace($RepoName)) {
    Fail "Repo must be owner/name, got '$Repo'."
}
Write-Host "  Repository: $RepoOwner/$RepoName" -ForegroundColor Gray

# 3. Reuse a project with the same title, otherwise create one.
$reuseJq = '.projects[] | select(.title == "' + $Title + '") | .number'
$existing = (& gh project list --owner $Owner --format json --jq $reuseJq 2>$null | Select-Object -First 1)

if (-not [string]::IsNullOrWhiteSpace($existing)) {
    $number = $existing.Trim()
    Write-Host "  [OK] Reusing project #$number ('$Title')" -ForegroundColor Green
} else {
    $created = (& gh project create --owner $Owner --title $Title --format json 2>&1)
    if ($LASTEXITCODE -ne 0) {
        Fail "Project creation failed: $created"
    }
    $number = ($created | ConvertFrom-Json).number
    Write-Host "  [OK] Created project #$number ('$Title')" -ForegroundColor Green
}

# 4. Re-enable the Projects tab (F6 turns it off), then link the project.
$null = & gh repo edit "$RepoOwner/$RepoName" --enable-projects=true 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [--] Could not change the Projects setting; continue if it is already on." -ForegroundColor Yellow
}

$null = & gh project link $number --owner $Owner --repo "$RepoOwner/$RepoName" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Linked project #$number to $RepoOwner/$RepoName" -ForegroundColor Green
} else {
    Write-Host "  [--] Link reported an error; it may already be linked." -ForegroundColor Yellow
}

# 5. Status field and done option.
$statusJq = '.fields[] | select(.name == "Status")'
$statusJson = (& gh project field-list $number --owner $Owner --format json --jq $statusJq 2>$null)
if ([string]::IsNullOrWhiteSpace($statusJson)) {
    Write-Host "  [!] No Status field. Create one, then re-run:" -ForegroundColor Yellow
    Write-Host "      gh project field-create $number --owner $Owner --name Status --data-type SINGLE_SELECT --single-select-options `"Todo,In Progress,Done`"" -ForegroundColor Gray
} else {
    $status = $statusJson | ConvertFrom-Json
    $done = $status.options | Where-Object { $_.name -eq $DoneOption } | Select-Object -First 1
    Write-Host "  [OK] Status field: $($status.id)" -ForegroundColor Green
    if ($done) {
        Write-Host "  [OK] Done option '$DoneOption': $($done.id)" -ForegroundColor Green
    } else {
        $names = ($status.options | ForEach-Object { $_.name }) -join ", "
        Write-Host "  [!] No '$DoneOption' option. Options present: $names" -ForegroundColor Yellow
    }
}

# 6. Verify the project link and the built-in workflows.
$ownerType = ((& gh api "users/$Owner" --jq .type 2>$null) -join "").Trim()
$rootField = if ($ownerType -eq "Organization") { "organization" } else { "user" }

$query = @'
query($login: String!, $number: Int!) {
  ROOT(login: $login) {
    projectV2(number: $number) {
      id
      url
      repositories(first: 20) { nodes { nameWithOwner } }
      workflows(first: 20) { nodes { name enabled } }
    }
  }
}
'@
$query = $query.Replace("ROOT", $rootField)

$raw = (& gh api graphql -f "query=$query" -f "login=$Owner" -F "number=$number" 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [!] GraphQL verification failed: $raw" -ForegroundColor Yellow
} else {
    $project = ($raw | ConvertFrom-Json).data.$rootField.projectV2
    Write-Host "  [OK] Project id: $($project.id)" -ForegroundColor Green
    Write-Host "  [OK] Project URL: $($project.url)" -ForegroundColor Green

    $linked = ($project.repositories.nodes | ForEach-Object { $_.nameWithOwner }) -join ", "
    if ($linked -match [regex]::Escape("$RepoOwner/$RepoName")) {
        Write-Host "  [OK] Linked repositories: $linked" -ForegroundColor Green
    } else {
        Write-Host "  [!] Repository not in the project's linked list: $linked" -ForegroundColor Yellow
    }

    $itemClosed = $project.workflows.nodes | Where-Object { $_.name -eq "Item closed" } | Select-Object -First 1
    if ($itemClosed -and $itemClosed.enabled) {
        Write-Host "  [OK] Built-in workflow 'Item closed' is enabled" -ForegroundColor Green
    } else {
        Write-Host "  [!] Built-in workflow 'Item closed' is not enabled." -ForegroundColor Yellow
        Write-Host "      Enable it: project -> menu -> Workflows -> Item closed -> Edit ->" -ForegroundColor Gray
        Write-Host "      set Status to '$DoneOption' -> Save and turn on workflow." -ForegroundColor Gray
    }

    $autoAdd = $project.workflows.nodes | Where-Object { $_.name -like "Auto-add*" } | Select-Object -First 1
    if ($autoAdd -and $autoAdd.enabled) {
        Write-Host "  [OK] Auto-add workflow reports enabled (filter is UI-only, verify in the browser)" -ForegroundColor Green
    } else {
        Write-Host "  [--] No enabled auto-add workflow detected" -ForegroundColor Gray
    }
}

# 7. Headless mode: workflow file, repository variables, secret check.
if ($Mode -eq "headless") {
    if ($DeployWorkflow) {
        $target = Join-Path (Get-Location).Path ".github/workflows/project-sync.yml"
        $template = Join-Path $PSScriptRoot "../resources/templates/project-sync.yml.template"
        if (Test-Path $target) {
            Write-Host "  [--] Existing workflow left untouched: .github/workflows/project-sync.yml" -ForegroundColor Gray
        } elseif (-not (Test-Path $template)) {
            Write-Host "  [!] Template not found: $template" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            Copy-Item -Path $template -Destination $target -Force
            Write-Host "  [OK] Installed: .github/workflows/project-sync.yml" -ForegroundColor Green
        }
    }

    $null = & gh variable set PROJECT_OWNER --body $Owner 2>&1
    $null = & gh variable set PROJECT_NUMBER --body "$number" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Repository variables set: PROJECT_OWNER, PROJECT_NUMBER" -ForegroundColor Green
    } else {
        Write-Host "  [!] Could not set repository variables; set PROJECT_OWNER and PROJECT_NUMBER manually." -ForegroundColor Yellow
    }

    $secretList = (& gh secret list 2>$null) -join "`n"
    if ($secretList -notmatch "PROJECT_TOKEN") {
        Write-Host "  [!] Secret PROJECT_TOKEN is missing. Create a PAT (classic: repo + project;" -ForegroundColor Yellow
        Write-Host "      fine-grained: Projects read/write, Issues read, Pull requests read), then run:" -ForegroundColor Gray
        Write-Host "      gh secret set PROJECT_TOKEN" -ForegroundColor Gray
    } else {
        Write-Host "  [OK] Secret PROJECT_TOKEN exists" -ForegroundColor Green
    }
    Write-Host "  NOTE: the workflow only runs after it lands on the default branch." -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "  Native mode: enable auto-add by hand (no API exists for it):" -ForegroundColor Cyan
    $projectPath = if ($ownerType -eq "Organization") { "orgs/$Owner" } else { "users/$Owner" }
    Write-Host "    https://github.com/$projectPath/projects/$number -> menu -> Workflows ->" -ForegroundColor Gray
    Write-Host "    Auto-add to project -> Edit -> repository $RepoOwner/$RepoName ->" -ForegroundColor Gray
    Write-Host "    filter is:issue,pr -> Save and turn on workflow." -ForegroundColor Gray
}

Write-Host ""
Write-Host "GitHub Project board initialized. Next: run the probe from" -ForegroundColor Green
Write-Host "references/features/14-github-project.md (step 9) before reporting [IMPLEMENTED]." -ForegroundColor Green
exit 0
