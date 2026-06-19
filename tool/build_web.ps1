# Production Flutter Web build with deployment-safe caching.
# Usage: .\tool\build_web.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host "Building Flutter Web (service worker disabled)..." -ForegroundColor Cyan
flutter build web --release --pwa-strategy=none @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$buildDir = Join-Path $repoRoot "build\web"
$lastBuildIdPath = Join-Path $buildDir ".last_build_id"

if (-not (Test-Path $lastBuildIdPath)) {
    Write-Error "Missing build/web/.last_build_id - Flutter build output incomplete."
}

$buildId = (Get-Content $lastBuildIdPath -Raw).Trim()
$buildIdJson = @{ build_id = $buildId } | ConvertTo-Json -Compress
$buildIdJson | Set-Content -Path (Join-Path $buildDir "build_id.json") -Encoding UTF8

Write-Host "Wrote build/web/build_id.json => $buildId" -ForegroundColor Green
Write-Host "Deploy the entire build/web directory." -ForegroundColor Green
