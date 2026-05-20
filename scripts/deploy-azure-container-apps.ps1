param(
    [string]$SubscriptionId = "5d4623ff-af44-4c47-af07-0f8ebbb66fdf",
    [string]$Location = "eastus",
    [string]$ResourceGroup = "rg-helpdesk-system",
    [string]$NamePrefix = "helpdesk"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$az = "az"
$knownAz = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
if (-not (Get-Command $az -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $knownAz)) {
    $az = $knownAz
}

$suffix = (Get-Random -Minimum 10000 -Maximum 99999)
$acrName = ($NamePrefix + "acr" + $suffix).ToLower()
$cosmosName = ($NamePrefix + "cosmos" + $suffix).ToLower()
$envName = "$NamePrefix-env"
$ticketApp = "$NamePrefix-ticket-service"
$userApp = "$NamePrefix-user-service"
$gatewayApp = "$NamePrefix-api-gateway"
$frontendApp = "$NamePrefix-frontend"

Write-Host "Using subscription $SubscriptionId"
& $az account set --subscription $SubscriptionId

Write-Host "Creating resource group $ResourceGroup in $Location"
& $az group create --name $ResourceGroup --location $Location --output none

Write-Host "Creating Azure Container Registry $acrName"
& $az acr create `
    --resource-group $ResourceGroup `
    --name $acrName `
    --sku Basic `
    --admin-enabled true `
    --output none

$loginServer = & $az acr show --resource-group $ResourceGroup --name $acrName --query loginServer -o tsv
$acrUsername = & $az acr credential show --resource-group $ResourceGroup --name $acrName --query username -o tsv
$acrPassword = & $az acr credential show --resource-group $ResourceGroup --name $acrName --query "passwords[0].value" -o tsv

Write-Host "Building backend images in Azure Container Registry"
& $az acr build --registry $acrName --image "ticket-service:1.0" "$root\ticket-service"
& $az acr build --registry $acrName --image "user-service:1.0" "$root\user-service"
& $az acr build --registry $acrName --image "api-gateway:1.0" "$root\api-gateway"

Write-Host "Creating Cosmos DB for MongoDB account $cosmosName"
& $az cosmosdb create `
    --resource-group $ResourceGroup `
    --name $cosmosName `
    --kind MongoDB `
    --capabilities EnableMongo `
    --locations regionName=$Location failoverPriority=0 isZoneRedundant=False `
    --enable-free-tier true `
    --output none

$cosmosConnectionString = & $az cosmosdb keys list `
    --resource-group $ResourceGroup `
    --name $cosmosName `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" `
    -o tsv

function Add-DatabaseToMongoUri {
    param(
        [string]$Uri,
        [string]$DatabaseName
    )

    if ($Uri.Contains("?")) {
        $parts = $Uri.Split("?", 2)
        $baseUri = $parts[0].TrimEnd("/")
        return "$baseUri/$DatabaseName`?$($parts[1])"
    }

    return "$($Uri.TrimEnd("/"))/$DatabaseName"
}

$ticketMongoUri = Add-DatabaseToMongoUri -Uri $cosmosConnectionString -DatabaseName "helpdesk_tickets"
$userMongoUri = Add-DatabaseToMongoUri -Uri $cosmosConnectionString -DatabaseName "helpdesk_users"

Write-Host "Creating MongoDB databases and collections"
& $az cosmosdb mongodb database create `
    --resource-group $ResourceGroup `
    --account-name $cosmosName `
    --name "helpdesk_tickets" `
    --throughput 400 `
    --output none

& $az cosmosdb mongodb collection create `
    --resource-group $ResourceGroup `
    --account-name $cosmosName `
    --database-name "helpdesk_tickets" `
    --name "tickets" `
    --output none

& $az cosmosdb mongodb database create `
    --resource-group $ResourceGroup `
    --account-name $cosmosName `
    --name "helpdesk_users" `
    --throughput 400 `
    --output none

& $az cosmosdb mongodb collection create `
    --resource-group $ResourceGroup `
    --account-name $cosmosName `
    --database-name "helpdesk_users" `
    --name "users" `
    --output none

Write-Host "Creating Container Apps environment $envName"
& $az containerapp env create `
    --resource-group $ResourceGroup `
    --name $envName `
    --location $Location `
    --output none

Write-Host "Creating internal ticket and user services"
& $az containerapp create `
    --resource-group $ResourceGroup `
    --environment $envName `
    --name $ticketApp `
    --image "$loginServer/ticket-service:1.0" `
    --registry-server $loginServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --target-port 8081 `
    --ingress internal `
    --env-vars "SPRING_DATA_MONGODB_URI=$ticketMongoUri" `
    --cpu 0.5 `
    --memory 1Gi `
    --min-replicas 1 `
    --output none

& $az containerapp create `
    --resource-group $ResourceGroup `
    --environment $envName `
    --name $userApp `
    --image "$loginServer/user-service:1.0" `
    --registry-server $loginServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --target-port 8082 `
    --ingress internal `
    --env-vars "SPRING_DATA_MONGODB_URI=$userMongoUri" `
    --cpu 0.5 `
    --memory 1Gi `
    --min-replicas 1 `
    --output none

$ticketFqdn = & $az containerapp show --resource-group $ResourceGroup --name $ticketApp --query "properties.configuration.ingress.fqdn" -o tsv
$userFqdn = & $az containerapp show --resource-group $ResourceGroup --name $userApp --query "properties.configuration.ingress.fqdn" -o tsv

Write-Host "Creating external API gateway"
& $az containerapp create `
    --resource-group $ResourceGroup `
    --environment $envName `
    --name $gatewayApp `
    --image "$loginServer/api-gateway:1.0" `
    --registry-server $loginServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --target-port 8080 `
    --ingress external `
    --env-vars "TICKET_SERVICE_URL=https://$ticketFqdn" "USER_SERVICE_URL=https://$userFqdn" `
    --cpu 0.5 `
    --memory 1Gi `
    --min-replicas 1 `
    --output none

$gatewayFqdn = & $az containerapp show --resource-group $ResourceGroup --name $gatewayApp --query "properties.configuration.ingress.fqdn" -o tsv
$gatewayUrl = "https://$gatewayFqdn"

Write-Host "Building frontend image with API URL $gatewayUrl"
& $az acr build `
    --registry $acrName `
    --image "frontend:1.0" `
    --build-arg "VITE_API_BASE_URL=$gatewayUrl" `
    "$root\frontend"

Write-Host "Creating external frontend"
& $az containerapp create `
    --resource-group $ResourceGroup `
    --environment $envName `
    --name $frontendApp `
    --image "$loginServer/frontend:1.0" `
    --registry-server $loginServer `
    --registry-username $acrUsername `
    --registry-password $acrPassword `
    --target-port 5173 `
    --ingress external `
    --cpu 0.5 `
    --memory 1Gi `
    --min-replicas 1 `
    --output none

$frontendFqdn = & $az containerapp show --resource-group $ResourceGroup --name $frontendApp --query "properties.configuration.ingress.fqdn" -o tsv
$frontendUrl = "https://$frontendFqdn"

Write-Host "Updating gateway CORS for $frontendUrl"
& $az containerapp update `
    --resource-group $ResourceGroup `
    --name $gatewayApp `
    --set-env-vars "FRONTEND_ALLOWED_ORIGIN=$frontendUrl" `
    --output none

Write-Host ""
Write-Host "Deploy complete."
Write-Host "Frontend: $frontendUrl"
Write-Host "Gateway:  $gatewayUrl"
Write-Host ""
Write-Host "To delete all Azure resources created by this script:"
Write-Host "az group delete --name $ResourceGroup --yes --no-wait"
