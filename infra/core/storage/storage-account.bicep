param location string = resourceGroup().location
param tags object = {}
param storageAccountName string
param containerNames array
param integrationSubnetId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: integrationSubnetId
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
    }
  }

  resource blobService 'blobServices' existing = {
    name: 'default'

    resource container 'containers' = [
      for containerName in containerNames:{
        name: containerName
      }
    ]
  }
}

output storageAccountName string = storageAccount.name
