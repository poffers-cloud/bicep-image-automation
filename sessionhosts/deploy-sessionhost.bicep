targetScope = 'subscription'

param updatedBy string

@allowed([
  'test'
  'dev'
  'prod'
  'acc'
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
  'ukwest'
  'uksouth'
  'francecentral'
  'francesouth'
  'switzerlandnorth'
  'switzerlandwest'
  'germanywestcentral'
  'germanynorth'
  'centralus'
  'eastus'
  'swedencentral'
  'swedensouth'
])
param location string 

@description('Location shortcode. Used for end of resource names.')
param locationShortCode string 

@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentType
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
}

param existingSubscriptionId string 
param existingResourceGroupName string 
param existingHostpoolName string 
param existingVnetName string
param existingSubnetName string 
param existingGalleryName string
param existingVersionName string 
param existingVersionNumber string

@minValue(1)
@description('Number of session hosts to deploy')
param sessionHostCount int

@description('Number of session hosts to deploy')
param sessionHostname string 

@description('local admin username for the session host VMs')
param sessionHostUsername string 

@secure()
@description('local admin password for the session host VMs')
param sessionHostPassword string

@description('OS type for the session host VM')
param osType string

@description('vm size for the session host VM')
param vmSize string

@description('license type for the session host VM')
param licenseType string

@description('disk size in GB for the session host VM')
param diskSizeGB int

@description('disk sku for the session host VM')
param diskStorageAccountType string

@description('Username for the domain join user account')
param domainJoinUsername string

@secure()
@description('Password for the domain join user account')
param domainJoinPassword string 

@description('Domain name for the domain join user account')
param domainName string 

@description('Reference to the existing existing hostpool')
resource existingResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: existingResourceGroupName
  scope: subscription(existingSubscriptionId)
}

@description('Reference to the existing existing hostpool')
resource existingResourceHostpool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' existing = {
  name: existingHostpoolName
  scope: resourceGroup(existingSubscriptionId, existingResourceGroupName)
}

@description('Reference to the existing existing hostppol')
resource existingResourceVnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: existingVnetName
  scope: resourceGroup(existingSubscriptionId, existingResourceGroupName)
}

@description('Reference to the existing existing hostppol')
resource existingResourceSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: existingSubnetName
  parent: existingResourceVnet
}

// Loop to create multiple session hosts
module createSessionHost 'br/public:avm/res/compute/virtual-machine:0.18.0' = [
  for i in range(0, sessionHostCount): {
    scope: resourceGroup(existingSubscriptionId, existingResourceGroupName)
    name: 'avd-${i}'
    params: {
      name: '${sessionHostname}-${i + 1}'
      location: location
      osType: osType
      vmSize: vmSize
      availabilityZone: 1
      bootDiagnostics: true
      secureBootEnabled: true
      licenseType: licenseType
      enableAutomaticUpdates: true
      encryptionAtHost: true
      securityType: 'TrustedLaunch'
      adminUsername: sessionHostUsername
      adminPassword: sessionHostPassword
      managedIdentities: {
        systemAssigned: true
      }
      imageReference: {
        id: '/subscriptions/${existingSubscriptionId}/resourceGroups/${existingResourceGroupName}/providers/Microsoft.Compute/galleries/${existingGalleryName}/images/${existingVersionName}/versions/${existingVersionNumber}'
      }
      osDisk: {
        caching: 'ReadWrite'
        diskSizeGB: diskSizeGB
        managedDisk: {
          storageAccountType: diskStorageAccountType
        }
      }
      nicConfigurations: [
        {
          name: 'nic-avd-${i + 1}'
          enableAcceleratedNetworking: true
          ipConfigurations: [
            {
              name: 'ipconfig-${deploymentGuid}-${i + 1}'
              subnetResourceId: existingResourceSubnet.id
            }
          ]
        }
      ]
      
      extensionDomainJoinConfig: {
        enabled: true
        settings: {
          name: domainName
          user: domainJoinUsername

          restart: true
          options: 3
        }
      }
      extensionDomainJoinPassword: domainJoinPassword 

      extensionHostPoolRegistration: {
        enabled: true
        modulesUrl: 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'
        configurationFunction: 'Configuration.ps1\\AddSessionHost'
        hostPoolName: existingResourceHostpool.name
        registrationInfoToken: existingResourceHostpool.listRegistrationTokens().value[0].token
      }
      tags: tags
    }
    dependsOn: [existingResourceGroup]
  }
]
