param(
    [Parameter(Mandatory = $true)][string] $subscriptionID = "",
    [Parameter(Mandatory = $true)][ValidateSet("northeurope", "uksouth", "westeurope", "ukwest")][string] $location = "", 
    [Parameter(Mandatory = $true)][string] $customerName = "",
    [ValidateSet("avd")][string][Parameter(Mandatory = $true, ParameterSetName = 'Default')] $productType = "",
    [Parameter(Mandatory = $true, Position = 3)] [validateSet("prod", "acc", "dev", "test")] [string] $environmentType = "",
    [switch] $deploy
)

# Ensure parameters are captured
Write-Host "Subscription ID: $subscriptionID"
Write-Host "Location: $location"
Write-Host "Customer Name: $customerName"
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
$customerName = $customerName.ToLower() -replace " ", ""

$LocationShortCodeMap = @{
    "westeurope"  = "weu";
    "northeurope" = "neu";
    "uksouth"     = "uks";
    "ukwest"      = "ukw"
}

$locationShortCode = $LocationShortCodeMap.$location

if ($deploy) {
    <# deployment timer start #>
    $starttime = [System.DateTime]::Now

    Write-Host "Running a Bicep deployment with ID: '$deploymentID' for Customer: $customerName and Environment: '$environmentType' with a 'WhatIf' check." -ForegroundColor Green
    az deployment sub create `
    --name $deploymentID `
    --location $location `
    --template-file ./imagetemplate.bicep `
    --parameters ./imagetemplate.bicepparam `
    --parameters updatedBy=$updatedBy customerName=$customerName location=$location locationShortCode=$LocationShortCode productType=$productType environmentType=$environmentType `
    --confirm-with-what-if `
        

    if (!$?) {
        Write-Host ""
        Write-Host "Bicep deployment with ID: '$deploymentID' for Customer: $customerName and Environment: '$environmentName' Failed" -ForegroundColor Red
    }
    else {
    }

    <# Deployment timer end #>
    $endtime = [System.DateTime]::Now
    $duration = $endtime - $starttime
    Write-Host ('This deployment took : {0:mm} minutes {0:ss} seconds' -f $duration) -BackgroundColor Yellow -ForegroundColor Magenta
}