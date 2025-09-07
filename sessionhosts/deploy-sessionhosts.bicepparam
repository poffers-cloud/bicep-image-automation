using 'deploy-sessionhost.bicep'

//parameters for the deployment.
param updatedBy = ''
param subscriptionId = ''
param environmentType = '' 
param location = '' 
param locationShortCode = '' 
param productType = ''

//Paramameters for the existing AVD environtment. 
param existingSubscriptionId = ''
param existingResourceGroupName = ''
param existingHostpoolName = ''
param existingVnetName = ''
param existingSubnetName = ''
param existingGalleryName = ''
param existingVersionName  = ''
param existingVersionNumber = ''

//Parameters for the local user account session host VM's
param sessionHostname = ''
param sessionHostUsername = ''
param sessionHostPassword = ''

//Parameters for the session host VM's
param osType = 'Windows'
param vmSize = 'Standard_DS2_v2'
param licenseType = 'Windows_Client'
param diskSizeGB = 128
param diskStorageAccountType = 'Premium_LRS'

///Number of session hosts to deploy
param sessionHostCount = 2

//Parameters for the domain join user account
param domainJoinPassword = ''
param domainJoinUsername = ''
param domainName = ''
