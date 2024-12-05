using 'imagetemplate.bicep'


//parameters for the deployment.
param updatedBy = 'yourname'
param subscriptionId = 'yoursubscriptionid'
param environmentType = 'prod' 
param customerName = 'pof' 
param location = 'westeurope' 
param locationShortCode = 'weu' 
param productType = 'avd'

///Paremeters for the SKU version.
param skuVersion = '2022-datacenter-azure-edition-hotpatch'
param publisherName = 'MicrosoftWindowsServer'
param offerName = 'WindowsServer'
    
//Parameters for the Shared Image Gallery.
param sigImageVersion = '1.0.0'
param azureSharedImageGalleryName = 'gal${customerName}${productType}${environmentType}${locationShortCode}'

//Parameters for the Image Template.
param imageTemplateName = 'it-${customerName}-${productType}-${environmentType}-${locationShortCode}'
param imagesSharedGalleryName = 'img-${customerName}-${productType}-${environmentType}-${locationShortCode}'

//Paremeters for the Managed Identity.
param userAssignedManagedIdentityName = 'mi-${customerName}-${productType}-${environmentType}-${locationShortCode}'

