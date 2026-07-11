# Publish Van Dwellers Azure Functions (code-only update).
# Prerequisites: az login, func CLI, .NET 9 SDK
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$cfg = . "$PSScriptRoot\..\scripts\Load-Config.ps1" -ConfigPath "$PSScriptRoot\config.json"

Write-Host "=== Deploy backend to Azure ===" -ForegroundColor Cyan
Write-Host "Function App: $($cfg.FunctionApp)"
Write-Host "Resource Group: $($cfg.ResourceGroup)"

$projectRoot = Resolve-Path "$PSScriptRoot\..\..\backend\VanDwellers.Functions"
Push-Location $projectRoot

if (-not $SkipBuild) {
    Write-Host "Building Release..."
    dotnet build -c Release
}

Write-Host "Publishing to Azure..."
func azure functionapp publish $cfg.FunctionApp --dotnet-isolated

Pop-Location

$infoPath = Resolve-Path "$PSScriptRoot\..\..\backend\deploy\deployment-info.json"
@{
    apiUrl         = $cfg.ApiUrl
    resourceGroup  = $cfg.ResourceGroup
    functionApp    = $cfg.FunctionApp
    cosmosAccount  = $cfg.CosmosAccount
    storageAccount = $cfg.StorageAccount
    deployedAt     = (Get-Date -Format o)
} | ConvertTo-Json | Set-Content $infoPath

Write-Host ""
Write-Host "Backend deployed: $($cfg.ApiUrl)" -ForegroundColor Green
