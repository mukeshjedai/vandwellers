# First-time Azure infrastructure + backend deploy for Van Dwellers.
# Prerequisites: az login, func CLI, .NET 9 SDK
param(
    [switch]$SkipInfra
)

$ErrorActionPreference = "Stop"
$cfg = . "$PSScriptRoot\..\scripts\Load-Config.ps1" -ConfigPath "$PSScriptRoot\config.json"

if ($SkipInfra) {
    & "$PSScriptRoot\deploy-backend.ps1"
    exit $LASTEXITCODE
}

$legacyScript = Resolve-Path "$PSScriptRoot\..\..\backend\deploy\deploy.ps1"
Write-Host "Running full Azure provision via backend/deploy/deploy.ps1..." -ForegroundColor Cyan

& $legacyScript `
    -ResourceGroup $cfg.ResourceGroup `
    -Location $cfg.Location `
    -CosmosAccount $cfg.CosmosAccount `
    -StorageAccount $cfg.StorageAccount `
    -FunctionApp $cfg.FunctionApp

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Full Azure deployment complete." -ForegroundColor Green
Write-Host "API URL: $($cfg.ApiUrl)"
