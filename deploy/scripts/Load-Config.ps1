param(
    [string]$ConfigPath = "$PSScriptRoot\config.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ConfigPath)) {
    throw "Config not found: $ConfigPath. Copy config.example.json to config.json and edit values."
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

[PSCustomObject]@{
    ResourceGroup  = $config.resourceGroup
    Location       = $config.location
    CosmosAccount  = $config.cosmosAccount
    StorageAccount = $config.storageAccount
    FunctionApp    = $config.functionApp
    ApiUrl         = $config.apiUrl
    GitHubRemote   = $config.githubRemote
    GitHubBranch   = $config.githubBranch
}
