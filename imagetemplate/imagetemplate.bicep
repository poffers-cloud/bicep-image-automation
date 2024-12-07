targetScope = 'subscription'

param updatedBy string 

@description('Environment Type: example prod.')
@allowed([
  'test'
  'dev'
  'prod'
  'acc'
  'poc'
])
param environmentType string

param subscriptionId string 

@description('Unique identifier for the deployment')
param deploymentGuid string = newGuid()

@description('Product Type: example avd.')
@allowed([
  'avd'
  ])
param productType string

@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
  'northeurope'
  
])
param location string = 'westeurope'

@description('Location shortcode')
param locationShortCode string 

@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentType
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
}

param resourceGroupName string = 'rg-${productType}-${environmentType}-${locationShortCode}'

param skuVersion string
param publisherName string
param offerName string

param sigImageVersion string = utcNow('yyyy.MM.dd')
param azureSharedImageGalleryName string 
param imageTemplateName string
param imagesSharedGalleryName string

param userAssignedManagedIdentityName string



module createResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = { 
  scope: subscription(subscriptionId)
  name: 'rg-${deploymentGuid}'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
    
             
  }
  
}

module userAssignedManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.3.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'id-${deploymentGuid}'
  params: {
    name: userAssignedManagedIdentityName
    location: location
    tags: tags
    
  }
  dependsOn: [createResourceGroup]
}


module createSharedImageGallery 'br/public:avm/res/compute/gallery:0.7.0' = {
scope: resourceGroup(resourceGroupName)
name: 'gal-${deploymentGuid}'
params:{
  name:azureSharedImageGalleryName
  location: location
  images: [
    {
      name: imagesSharedGalleryName
      identifier: {
        publisher: publisherName
        offer: offerName
        sku: skuVersion
      }
      osType: 'Windows'
      osState: 'Generalized'
      hyperVGeneration: 'V2'
      securityType: 'TrustedLaunch'
      
    }
  ]

  roleAssignments: [
    {
      roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
      principalId: userAssignedManagedIdentity.outputs.principalId
      principalType: 'ServicePrincipal'
    }]
  tags: tags

}
dependsOn: [createResourceGroup]
}

module createImageTemplate 'br/public:avm/res/virtual-machine-images/image-template:0.4.0' = {
scope: resourceGroup(resourceGroupName)
name: 'it-${deploymentGuid}'
params: {
  name: imageTemplateName
  location: location
  customizationSteps: [
    {
      restartTimeout: '10m'
      type: 'WindowsRestart'
    }
    {
      destination: 'C:\\AVDImage\\enableFslogix.ps1'
      name: 'avdBuiltInScript_enableFsLogix'
      sha256Checksum: '027ecbc0bccd42c6e7f8fc35027c55691fba7645d141c9f89da760fea667ea51'
      sourceUri: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/FSLogix.ps1'
      type: 'File'
    }
    {
      name: 'avdBuiltInScript_adminSysPrep'
      runAsSystem: true
      runElevated: true
      scriptUri: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27/AdminSysPrep.ps1'
      sha256Checksum: '1dcaba4823f9963c9e51c5ce0adce5f546f65ef6034c364ef7325a0451bd9de9'
      type: 'PowerShell'
    }
  ]
  
  imageSource: {
    offer: offerName
    publisher: publisherName
    sku: skuVersion
    type: 'PlatformImage'
    version: 'latest'
  }
  tags: tags
 

  distributions: [
    {
      type: 'SharedImage'
      sharedImageGalleryImageDefinitionResourceId: createSharedImageGallery.outputs.imageResourceIds[0]
      sharedImageGalleryImageDefinitionTargetVersion: sigImageVersion
    
    }
  ]

  
  
  managedIdentities: {
    userAssignedResourceIds: [
      userAssignedManagedIdentity.outputs.resourceId
    ]
  }
}
dependsOn: [createSharedImageGallery, createResourceGroup]
}

