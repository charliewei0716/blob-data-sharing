targetScope = 'subscription'

param environmentName string
param location string

var abbrs = loadJsonContent('./abbreviations.json')

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

var functionAppName = '${abbrs.webSitesFunctions}${resourceToken}'
var functionContainerName = 'app-package-${functionAppName}'

var tags = { 'azd-env-name': environmentName }


resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: location
  tags: tags
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
}

module userAssignedIdentity 'core/identity/user-assigned-identity.bicep' = {
  name: 'UserAssignedIdentity'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  }
}

module vnet 'core/networking/vnet.bicep' = {
  name: 'vnet'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    vnetName: '${abbrs.networkVirtualNetworks}${resourceToken}'
  }
}

var storages = [
  {
    name: 'sourceStorage'
    storageAccountName: '${abbrs.storageStorageAccounts}source${resourceToken}'
    containerNames: [functionContainerName, 'source']
  }
  {
    name: 'targetStorage'
    storageAccountName: '${abbrs.storageStorageAccounts}target${resourceToken}'
    containerNames: ['target']
  }
]

module storage 'core/storage/storage-account.bicep' = [
  for storage in  storages:{
    name: storage.name
    scope: resourceGroup
    params: {
      location: location
      tags: tags
      storageAccountName: storage.storageAccountName
      containerNames: storage.containerNames
      integrationSubnetId: vnet.outputs.integrationSubnetId
    }
  }
]

module flexFunction 'core/host/function.bicep' = {
  name: 'functionapp'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    sourceStorageAccountName: storage[0].outputs.storageAccountName
    targetStorageAccountName: storage[1].outputs.storageAccountName
    FunctionPlanName: '${abbrs.webServerFarms}${resourceToken}'
    functionAppName: functionAppName
    identityId: userAssignedIdentity.outputs.identityId
    identityClientId: userAssignedIdentity.outputs.identityClientId
    principalID: userAssignedIdentity.outputs.identityPrincipalId
    functionContainerName: functionContainerName
    integrationSubnetId: vnet.outputs.integrationSubnetId
  }
}

module eventgrid 'core/integration/eventgrid.bicep' = {
  name: 'eventgrid'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    storageAccountName: storage[0].outputs.storageAccountName
    systemTopicName: '${abbrs.eventGridDomainsTopics}${resourceToken}'
  }
}

output SOURCE_STORAGE_ACCOUNT_NAME string = storage[0].outputs.storageAccountName
output TARGET_STORAGE_ACCOUNT_NAME string = storage[1].outputs.storageAccountName

output RESOURCE_GROUP_NAME string = resourceGroup.name
output SYSTEM_TOPIC_NAME string = eventgrid.outputs.systemTopicName
output FUNCTION_APP_NAME string = functionAppName
