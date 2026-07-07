# Van Dwellers — Azure deployment script
param(
    [string]$ResourceGroup = "rg-vandwellers-prod",
    [string]$Location = "australiaeast",
    [string]$CosmosAccount = "cosmosvdwellersmk",
    [string]$StorageAccount = "stvandwellersmk01",
    [string]$FunctionApp = "func-vandwellers-mk01"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Van Dwellers Azure Deployment ===" -ForegroundColor Cyan

# Generate production JWT secret
$jwtKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | ForEach-Object { [char]$_ })
Write-Host "Generated JWT key for production."

Write-Host "Registering Azure providers..."
az provider register --namespace Microsoft.DocumentDB --wait --output none
az provider register --namespace Microsoft.Web --output none
az provider register --namespace Microsoft.Storage --output none

Write-Host "Creating resource group..."
az group create --name $ResourceGroup --location $Location --output none

Write-Host "Creating Cosmos DB (serverless)..."
az cosmosdb create `
    --name $CosmosAccount `
    --resource-group $ResourceGroup `
    --locations regionName=$Location `
    --default-consistency-level Session `
    --capabilities EnableServerless `
    --output none

Write-Host "Creating Cosmos database and containers..."
az cosmosdb sql database create `
    --account-name $CosmosAccount `
    --resource-group $ResourceGroup `
    --name VanDwellers `
    --output none

az cosmosdb sql container create `
    --account-name $CosmosAccount `
    --resource-group $ResourceGroup `
    --database-name VanDwellers `
    --name users `
    --partition-key-path "/id" `
    --output none

az cosmosdb sql container create `
    --account-name $CosmosAccount `
    --resource-group $ResourceGroup `
    --database-name VanDwellers `
    --name messages `
    --partition-key-path "/conversationId" `
    --output none

Write-Host "Creating storage account..."
az storage account create `
    --name $StorageAccount `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --allow-blob-public-access true `
    --output none

Write-Host "Creating photos blob container..."
$storageKey = az storage account keys list --resource-group $ResourceGroup --account-name $StorageAccount --query "[0].value" -o tsv
az storage container create `
    --name photos `
    --account-name $StorageAccount `
    --account-key $storageKey `
    --public-access blob `
    --output none

Write-Host "Creating Function App..."
az functionapp create `
    --resource-group $ResourceGroup `
    --consumption-plan-location $Location `
    --runtime dotnet-isolated `
    --runtime-version 9 `
    --functions-version 4 `
    --name $FunctionApp `
    --storage-account $StorageAccount `
    --os-type Linux `
    --output none

$cosmosConn = az cosmosdb keys list --name $CosmosAccount --resource-group $ResourceGroup --type connection-strings --query "connectionStrings[0].connectionString" -o tsv
$blobConn = az storage account show-connection-string --name $StorageAccount --resource-group $ResourceGroup --query connectionString -o tsv

Write-Host "Configuring Function App settings..."
az functionapp config appsettings set `
    --name $FunctionApp `
    --resource-group $ResourceGroup `
    --settings `
        "Azure__UseLocalFallback=false" `
        "Azure__CosmosDb__ConnectionString=$cosmosConn" `
        "Azure__CosmosDb__DatabaseName=VanDwellers" `
        "Azure__CosmosDb__UsersContainer=users" `
        "Azure__CosmosDb__MessagesContainer=messages" `
        "Azure__BlobStorage__ConnectionString=$blobConn" `
        "Azure__BlobStorage__ContainerName=photos" `
        "Jwt__Key=$jwtKey" `
        "Jwt__Issuer=VanDwellers" `
        "Jwt__Audience=VanDwellersApp" `
    --output none

Write-Host "Publishing Azure Functions..."
Push-Location "$PSScriptRoot\..\VanDwellers.Functions"
func azure functionapp publish $FunctionApp --dotnet-isolated
Pop-Location

$apiUrl = "https://$FunctionApp.azurewebsites.net"
Write-Host ""
Write-Host "=== Deployment complete ===" -ForegroundColor Green
Write-Host "API URL: $apiUrl"
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Function App: $FunctionApp"
Write-Host ""
Write-Host "Build the app with:"
Write-Host "  flutter build apk --release --dart-define=API_BASE_URL=$apiUrl"

# Save deployment info
@{
    apiUrl = $apiUrl
    resourceGroup = $ResourceGroup
    functionApp = $FunctionApp
    cosmosAccount = $CosmosAccount
    storageAccount = $StorageAccount
    deployedAt = (Get-Date -Format o)
} | ConvertTo-Json | Set-Content "$PSScriptRoot\deployment-info.json"
