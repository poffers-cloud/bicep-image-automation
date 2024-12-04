using 'imagetemplate.bicep'


//parameters for the deployment.
param subscriptionId = ''
param environmentType = 'prod' // When deploying please choose from hub or spoke
param customerName = 'pof' // Customer name
param location = 'westeurope' // Location 
param locationShortCode = 'weu' // Location short code
param productType = 'avd'

///Paremeters for the SKU version.
param skuVersion = '2022-datacenter-azure-edition-hotpatch'
param publisherName = 'MicrosoftWindowsServer'
param offerName = 'WindowsServer'
    
//Parameters for the Shared Image Gallery.
param sigImageVersion = '1.0.0'
param azureSharedImageGalleryName = 'galpofavdprodweu'

//Parameters for the Image Template.
param imageTemplateName = 'it-pof-avd-prod-weu'
param imagesSharedGalleryName = 'img-pof-avd-prod-weu'

//Paremeters for the Managed Identity.
param userAssignedManagedIdentityName = 'rg-pof-hub-dev-weu'

