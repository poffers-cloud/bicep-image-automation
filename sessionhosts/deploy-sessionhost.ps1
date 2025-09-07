param(
    [Parameter(Mandatory = $true)][string] $subscriptionID = "",
    [Parameter(Mandatory = $true)][ValidateSet("northeurope", "westeurope")][string] $location = "", 
    [ValidateSet("avd")][string][Parameter(Mandatory = $true, ParameterSetName = 'Default')] $productType = "",
    [Parameter(Mandatory = $true, Position = 3)] [validateSet("prod", "acc", "dev", "test")] [string] $environmentType = "",
    [switch] $deploy,
    [switch] $updateBicep
)

# Ensure parameters are captured
Write-Host "Subscription ID: $subscriptionID"
Write-Host "Location: $location"
Write-Host "Product Type: $productType"
Write-Host "Environment Type: $environmentType"

$deploymentID = (New-Guid).Guid

<# Validate Prerequisites #>
Write-Host "Validating prerequisites..." -ForegroundColor Cyan

# Validate Azure CLI is available
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Azure CLI is not installed or not in PATH. Please install Azure CLI first." -ForegroundColor Red
    Write-Host "Download from: https://aka.ms/installazurecliwindows" -ForegroundColor Yellow
    exit 1
}

# Check Azure CLI version
try {
    $azVersion = az version --query '"azure-cli"' --output tsv 2>$null
    if ($azVersion) {
        Write-Host "Azure CLI version: $azVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Unable to determine Azure CLI version" -ForegroundColor Yellow
}

<# Check and Update Bicep CLI #>
Write-Host "Checking Bicep CLI..." -ForegroundColor Cyan

# Check if Bicep is installed
$bicepInstalled = $false
try {
    $bicepVersion = az bicep version --output tsv 2>$null
    if ($bicepVersion) {
        Write-Host "Current Bicep CLI version: $bicepVersion" -ForegroundColor Green
        $bicepInstalled = $true
    }
} catch {
    Write-Host "Bicep CLI not found or not accessible." -ForegroundColor Yellow
}

# Install or update Bicep
if (-not $bicepInstalled) {
    Write-Host "Installing Bicep CLI..." -ForegroundColor Yellow
    try {
        az bicep install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Bicep CLI installed successfully." -ForegroundColor Green
            $bicepVersion = az bicep version --output tsv 2>$null
            Write-Host "Installed Bicep CLI version: $bicepVersion" -ForegroundColor Green
        } else {
            Write-Host "Failed to install Bicep CLI." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Error installing Bicep CLI: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} elseif ($updateBicep) {
    Write-Host "Updating Bicep CLI to latest version..." -ForegroundColor Yellow
    try {
        az bicep upgrade
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Bicep CLI updated successfully." -ForegroundColor Green
            $newBicepVersion = az bicep version --output tsv 2>$null
            Write-Host "Updated Bicep CLI version: $newBicepVersion" -ForegroundColor Green
        } else {
            Write-Host "Failed to update Bicep CLI." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error updating Bicep CLI: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    # Check for updates and auto-update if available
    Write-Host "Checking for Bicep CLI updates..." -ForegroundColor Cyan
    try {
        $updateCheck = az bicep list-versions --output json | ConvertFrom-Json
        if ($updateCheck -and $updateCheck.Count -gt 0) {
            $latestVersion = $updateCheck[0]
            if ($bicepVersion -ne $latestVersion) {
                Write-Host "Bicep CLI update available: $latestVersion (current: $bicepVersion)" -ForegroundColor Yellow
                Write-Host "Auto-updating Bicep CLI to latest version..." -ForegroundColor Yellow
                
                az bicep upgrade
                if ($LASTEXITCODE -eq 0) {
                    $newBicepVersion = az bicep version --output tsv 2>$null
                    Write-Host "Bicep CLI updated successfully to version: $newBicepVersion" -ForegroundColor Green
                } else {
                    Write-Host "Failed to auto-update Bicep CLI. Continuing with current version." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Bicep CLI is up to date." -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Could not check for Bicep CLI updates. Continuing with current version." -ForegroundColor Yellow
    }
}
# Check if Az.DesktopVirtualization module is installed
Write-Host "Checking for Az.DesktopVirtualization PowerShell module..." -ForegroundColor Cyan
if (-not (Get-Module -ListAvailable -Name Az.DesktopVirtualization)) {
    Write-Host "Az.DesktopVirtualization module not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name Az.DesktopVirtualization -Force -Scope CurrentUser -AllowClobber
        Write-Host "Az.DesktopVirtualization module installed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Az.DesktopVirtualization module: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Az.DesktopVirtualization module is already installed." -ForegroundColor Green
}
<# Set Subscription Context #>
Write-Host "Setting subscription context..." -ForegroundColor Cyan
az account set --subscription $subscriptionID --output none
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to set subscription context. Please verify the subscription ID and your access." -ForegroundColor Red
    Write-Host "Please ensure you are logged in with 'az login' and have access to subscription: $subscriptionID" -ForegroundColor Yellow
    exit 1
}

<# Retrieve Account Information with Error Handling #>
Write-Host "Retrieving account information..." -ForegroundColor Cyan
$accountInfo = az account show --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to retrieve account information. Error: $accountInfo" -ForegroundColor Red
    Write-Host "Please ensure you are logged in to Azure CLI with 'az login'" -ForegroundColor Yellow
    Write-Host "If you're already logged in, try: az account clear && az login" -ForegroundColor Yellow
    exit 1
}

try {
    $accountJson = $accountInfo | ConvertFrom-Json -ErrorAction Stop
    if ($accountJson.user -and $accountJson.user.name) {
        $updatedBy = $accountJson.user.name
        Write-Host "Successfully authenticated as: $updatedBy" -ForegroundColor Green
    } else {
        Write-Host "Warning: Unable to retrieve user name from account information." -ForegroundColor Yellow
        $updatedBy = "Unknown User"
    }
} catch {
    Write-Host "Failed to parse account information. Raw output: $accountInfo" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please try the following steps:" -ForegroundColor Yellow
    Write-Host "1. Run 'az login' to authenticate with Azure CLI" -ForegroundColor Yellow
    Write-Host "2. Run 'az account set --subscription $subscriptionID' to set the correct subscription" -ForegroundColor Yellow
    Write-Host "3. Run 'az account show' to verify your authentication status" -ForegroundColor Yellow
    exit 1
}

<# Validate Subscription Access #>
Write-Host "Validating subscription access..." -ForegroundColor Cyan
$currentSub = az account show --query id --output tsv 2>&1
if ($LASTEXITCODE -ne 0 -or $currentSub -ne $subscriptionID) {
    Write-Host "Subscription validation failed. Expected: $subscriptionID, Current: $currentSub" -ForegroundColor Red
    exit 1
}
Write-Host "Subscription validation successful: $subscriptionID" -ForegroundColor Green

<# Set Variables #>
$location = $location.ToLower() -replace " ", ""

$LocationShortCodeMap = @{
    "westeurope"  = "weu";
    "northeurope" = "neu";
}

$locationShortCode = $LocationShortCodeMap.$location

<# Validate Required Files #>
Write-Host "Validating required files..." -ForegroundColor Cyan
$requiredFiles = @("./deploy-sessionhost.bicep", "./deploy-sessionhosts.bicepparam")
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "Required file not found: $file" -ForegroundColor Red
        exit 1
    }
}
Write-Host "All required files found." -ForegroundColor Green

<# Validate Bicep Template #>
Write-Host "Validating Bicep template..." -ForegroundColor Cyan
try {
    az bicep build --file ./deploy-sessionhost.bicep --stdout > $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Bicep template validation successful." -ForegroundColor Green
    } else {
        Write-Host "Bicep template validation failed. Please check your template." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error validating Bicep template: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

<# Generate Registration Token for Azure Virtual Desktop Host Pool #>
Write-Host "Generating registration token for Azure Virtual Desktop Host Pool..." -ForegroundColor Cyan

# Define Host Pool name and resource group (update these variables as needed)
$hostPoolName = "fillinyourhostpoolname"
$resourceGroupName = "fillinyourresourcegroupname"
$date = (Get-Date).AddHours(2).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffffffK")

try {
    $registrationToken = az desktopvirtualization hostpool update `
        --name $hostPoolName `
        --resource-group $resourceGroupName `
        --registration-info expiration-time=$date registration-token-operation="Update" 

    if ($LASTEXITCODE -eq 0 -and $registrationToken) {
        Write-Host "Registration token generated successfully:" -ForegroundColor Green
        Write-Host $registrationToken -ForegroundColor Cyan
    } else {
        Write-Host "Failed to generate registration token. Error: $registrationToken" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Exception while generating registration token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

<# Deploy Resources #>
if ($deploy) {
    Write-Host "Running a Bicep deployment with ID: '$deploymentID' for Environment: '$environmentType' with a 'WhatIf' check." -ForegroundColor Green
    
    try {
        az deployment sub create `
            --name $deploymentID `
            --location $location `
            --template-file ./deploy-sessionhost.bicep `
            --parameters ./deploy-sessionhosts.bicepparam `
            --parameters updatedBy="$updatedBy" location="$location" locationShortCode="$locationShortCode" productType="$productType" environmentType="$environmentType" `
            --confirm-with-what-if
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Deployment completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Deployment failed. Please check the error messages above." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Deployment failed with exception: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Deployment not requested. Use -deploy switch to execute the deployment." -ForegroundColor Yellow
}

Write-Host "Script execution completed." -ForegroundColor Green