targetScope = 'subscription'


@description('Logged in user details. Passed in from parent "deployNow.ps1" script.')
param updatedBy string = ''

@description('Environment Type: Test, Acceptance/UAT, productTypeion, etc. Passed in from parent "deployNow.ps1" script.')
@allowed([
  'test'
  'dev'
  'prod'
  'acc'
  'poc'
])
param environmentType string = 'test'

param subscriptionId string = '6bc2a89b-8ffc-4c4a-8973-83d75a65f7c4'

@description('Unique identifier for the deployment')
param deploymentGuid string = newGuid()

@description('Network Type: hub or spoke "deployNow.ps1" script.')
@allowed([
  'avd'
  ])
param productType string

@description('The customer name.')
param customerName string

@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
  'northeurope'
  'uksouth'
  'ukwest'
])
param location string = 'westeurope'
@description('Location shortcode. Used for end of resource names.')
param locationShortCode string 

@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentType
  Customer: customerName
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
}

param resourceGroupName string = 'rg-${customerName}-${productType}-${environmentType}-${locationShortCode}'

param skuVersion string
param publisherName string
param offerName string

param sigImageVersion string = utcNow('yyyy.MM.dd')
param azureSharedImageGalleryName string 
param imageTemplateName string
param imagesSharedGalleryName string
param avdHostpoolName string
param applicationGroupName string
param workspaceName string
param availabilitySetName string

param userAssignedManagedIdentityName string
param vnetName string 
param subnetName string

param storageAccountName string

param vnetAddressPrefix string
param avdSubnetPrefix string
param networksecurityGroupName string

var VNetConfiguration = {
  Subnets: [
    {
      name: subnetName
      addressPrefix: avdSubnetPrefix
      privateLinkServiceNetworkPolicies: 'Disabled'
      networkSecurityGroupResourceId: createNetworkSecurityGroup.outputs.resourceId
      
      
    }
      ]
  
}

// Deploy required Resource Groups - New Resources
module createResourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = { 
    scope: subscription(subscriptionId)
    name: 'rg-${deploymentGuid}'
    params: {
      name: resourceGroupName
      location: location
      tags: tags
      
               
    }
    
  }

  module createNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.4.0' = {
    scope: resourceGroup(resourceGroupName)
    name: 'deploy-${deploymentGuid}'
    params: {
      name: networksecurityGroupName
      location: location
      securityRules: []
      tags: tags
    }
    dependsOn: [
      createResourceGroup
    ]
  }

module createVirtualNetwork 'br/public:avm/res/network/virtual-network:0.4.0' = {
scope: resourceGroup(resourceGroupName)
name: 'vnet-${deploymentGuid}'
params: {
  name: vnetName
  location: location
  addressPrefixes: [vnetAddressPrefix] 
  subnets: VNetConfiguration.Subnets
  tags:tags 
  roleAssignments: [
    {
      roleDefinitionIdOrName: 'contributor'
      principalId: userAssignedManagedIdentity.outputs.principalId
      principalType: 'ServicePrincipal'
    }] 
}
dependsOn: [createResourceGroup]

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
        inline: [
          'C:\\AVDImage\\enableFslogix.ps1 -FSLogixInstaller "https://aka.ms/fslogix_download" -VHDSize "30000" -ProfilePath "\\test\\test\\"'
        ]
        name: 'avdBuiltInScript_enableFsLogix-parameter'
        runAsSystem: true
        runElevated: true
        type: 'PowerShell'
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
   
    subnetResourceId: createVirtualNetwork.outputs.subnetResourceIds[0]
    
   

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
  dependsOn: [createSharedImageGallery, createResourceGroup, createVirtualNetwork]
}

module createAVDHostpool 'br/public:avm/res/desktop-virtualization/host-pool:0.5.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'avd-${deploymentGuid}'
  params: {
    name: avdHostpoolName
    location: location
    hostPoolType: 'Pooled'
    maxSessionLimit: 100
    vmTemplate: {
      customImageId: null
      domain: 'domainname.onmicrosoft.com'
      galleryImageOffer: 'WindowsServer'
      galleryImagePublisher: 'MicrosoftWindowsServer'
      galleryImageSKU: skuVersion
      imageType: 'Gallery'
      imageUri: null
      namePrefix: 'avdv2'
      osDiskType: 'StandardSSD_LRS'
      useManagedDisks: true
      vmSize: {
        cores: 2
        id: 'Standard_D2s_v3'
        ram: 8
      }
    }
    tags: tags
  }
  dependsOn: [createResourceGroup]
}

module createApplicationGroup 'br/public:avm/res/desktop-virtualization/application-group:0.3.0' ={
  scope: resourceGroup(resourceGroupName)
  name: 'app-${deploymentGuid}'
  params:{
    name: applicationGroupName
    applicationGroupType: 'Desktop'
    hostpoolName: createAVDHostpool.outputs.name
    tags: tags
  }

dependsOn: [createAVDHostpool]

}

module createWorkspace 'br/public:avm/res/desktop-virtualization/workspace:0.7.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'ws-${deploymentGuid}'
  params:{
    name: workspaceName
    location: location
    applicationGroupReferences: [ createApplicationGroup.outputs.resourceId ]
    tags: tags
    


  }

  dependsOn: [createApplicationGroup]
}

module createStorageAccount 'br/public:avm/res/storage/storage-account:0.14.1' = {
  scope: resourceGroup(resourceGroupName)
  name: 'stg-${deploymentGuid}'
  params:{
    name: storageAccountName
    skuName: 'Standard_LRS'
    fileServices: {
      Shares: [
        {
          name: 'fslogix'
          shareQuota: 20
        }
      ]
    }
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Storage File Data SMB Share Contributor'
        principalId: '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
        principalType: 'ServicePrincipal'
      }
    ]
  }
dependsOn: [createResourceGroup]


}

module createAvailabilitySet 'br/public:avm/res/compute/availability-set:0.2.0' = {
  scope: resourceGroup(resourceGroupName)
  name: 'avail-${deploymentGuid}'
  params:{
    name: availabilitySetName
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
    skuName: 'Aligned'
    location: location
    tags: tags
  }
  dependsOn: [createResourceGroup]
}


