targetScope = 'subscription'

param environmentName string
param location string

var abbrs = loadJsonContent('./abbreviations.json')

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

var functionAppName = '${abbrs.webSitesFunctions}${resourceToken}'
var functionContainerName = 'app-package-${functionAppName}'

var tags = { 'azd-env-name': environmentName }


resource resourceGroups 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  location: location
  tags: tags
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
}

module vnet 'core/networking/vnet.bicep' = {
  name: 'vnet'
  scope: resourceGroups
  params: {
    location: location
    tags: tags
    vnetName: '${abbrs.networkVirtualNetworks}${resourceToken}'
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: resourceGroups
  params: {
    location: location
    tags: tags
    storageAccountName: '${abbrs.storageStorageAccounts}${resourceToken}'
    functionContainerName: functionContainerName
    integrationSubnetId: vnet.outputs.integrationSubnetId
  }
}

module flexFunction 'core/host/function.bicep' = {
  name: 'functionapp'
  scope: resourceGroups
  params: {
    location: location
    tags: tags
    storageAccountName: storage.outputs.storageAccountName
    FunctionPlanName: '${abbrs.webServerFarms}${resourceToken}'
    functionAppName: functionAppName
    functionContainerName: functionContainerName
    integrationSubnetId: vnet.outputs.integrationSubnetId
  }
}
