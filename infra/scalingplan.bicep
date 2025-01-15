targetScope = 'subscription'

param updatedBy string 

@allowed([
  'test'
  'dev'
  'prod'
  'acc'
  
])
param environmentType string 

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
param location string

@description('Location shortcode. Used for end of resource names.')
param locationShortCode string 

@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentType
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
}

param existingSubscriptionId string = ''

param existingResourcegroupName string = 'rg-${productType}-${environmentType}-${locationShortCode}'
param existingHostpoolName string = 'vdpool-${productType}-${environmentType}-${locationShortCode}'
param scalingPlanName string = 'scalingplan-${productType}-${environmentType}-${locationShortCode}'

@description('Reference to the existing VNet')
resource existingHostpool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' existing= {
  name: existingHostpoolName
  scope: resourceGroup(existingSubscriptionId, existingResourcegroupName)
}

module createScalingPlan 'br/public:avm/res/desktop-virtualization/scaling-plan:0.3.0' = {
  name: 'createScalingPlan-${deploymentGuid}'
  scope: resourceGroup(existingResourcegroupName)
  params: {
    name: scalingPlanName
    hostPoolType: 'Pooled'
    timeZone: 'W. Europe Standard Time'
    schedules: [
  {
    rampUpStartTime:  {
      hour: 8
      minute: 0
    }
    peakStartTime: {
      hour: 9
      minute: 0
    }
    rampDownStartTime: {
      hour: 18
      minute: 0
    }
    offPeakStartTime: {
      hour: 20
      minute: 0
    }
    name: 'weekdays_schedule'
    daysOfWeek: [
      'Monday'
      'Tuesday'
      'Wednesday'
      'Thursday'
      'Friday'
    ]
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 20
    rampUpCapacityThresholdPct: 60
    peakLoadBalancingAlgorithm: 'BreadthFirst'
    rampDownLoadBalancingAlgorithm: 'BreadthFirst'
    rampDownMinimumHostsPct: 10
    rampDownCapacityThresholdPct: 90
    rampDownForceLogoffUsers: true
    rampDownWaitTimeMinutes: 30
    rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
    rampDownStopHostsWhen: 'ZeroSessions'
    offPeakLoadBalancingAlgorithm: 'BreadthFirst'
  }
]
    hostPoolReferences: [
      {
        hostPoolArmPath: existingHostpool.id
        scalingPlanEnabled: true
      }
    ]
tags: tags


  }
}
