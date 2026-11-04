param (
    [Parameter(Mandatory = $true)]
    [string]$RoutePath
)

$ErrorActionPreference = "Stop"
Write-Host "Verifying Next.js Page at: $RoutePath"

$pageFile = Join-Path $RoutePath "page.tsx"
if (-not (Test-Path -LiteralPath $pageFile)) {
    Write-Error "Missing required page file: $pageFile"
    exit 1
}
Write-Host "Found page.tsx"

$pageContent = Get-Content -LiteralPath $pageFile -Raw
if ($pageContent -notmatch "generateMetadata") {
    Write-Warning "Warning: page.tsx does not export generateMetadata."
} else {
    Write-Host "Exports generateMetadata"
}

$loadingFile = Join-Path $RoutePath "loading.tsx"
if (Test-Path -LiteralPath $loadingFile) {
    Write-Host "Found loading.tsx skeleton fallback"
} else {
    Write-Host "No loading.tsx found; assuming in-page component Suspense boundaries."
}

Write-Host "Page verification complete for: $RoutePath"
exit 0
