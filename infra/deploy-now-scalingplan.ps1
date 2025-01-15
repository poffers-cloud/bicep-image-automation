param(
    [Parameter(Mandatory = $true)][string] $subscriptionID = "",
    [Parameter(Mandatory = $true)][ValidateSet("northeurope", "westeurope")][string] $location = "", 
    [ValidateSet("avd")][string][Parameter(Mandatory = $true, ParameterSetName = 'Default')] $productType = "",
    [Parameter(Mandatory = $true, Position = 3)] [validateSet("prod", "acc", "dev", "test")] [string] $environmentType = "",
    [switch] $deploy
)

# Ensure parameters are captured
Write-Host "Subscription ID: $subscriptionID"
Write-Host "Location: $location"
Write-Host "Product Type: $productType"
Write-Host "Environment Type: $environmentType"

$deploymentID = (New-Guid).Guid

<# Set Variables #>
az account set --subscription $subscriptionID --output none
if (!$?) {
    Write-Host "Something went wrong while setting the correct subscription. Please check and try again." -ForegroundColor Red
}


$updatedBy = (az account show | ConvertFrom-Json).user.name 
$location = $location.ToLower() -replace " ", ""

$LocationShortCodeMap = @{
    "westeurope"  = "weu";
    "northeurope" = "neu";
}

$locationShortCode = $LocationShortCodeMap.$location

if ($deploy) {
    Write-Host "Running a Bicep deployment with ID: '$deploymentID' for Environment: '$environmentType' with a 'WhatIf' check." -ForegroundColor Green
    az deployment sub create `
    --name $deploymentID `
    --location $location `
    --template-file ./scalingplan.bicep `
    --parameters updatedBy=$updatedBy location=$location locationShortCode=$LocationShortCode productType=$productType environmentType=$environmentType `
    --confirm-with-what-if `
}