param location string = resourceGroup().location
param tags object = {}
param sourceStorageAccountName string
param targetStorageAccountName string
param FunctionPlanName string
param functionAppName string
param functionContainerName string
param integrationSubnetId string

resource sourceStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: sourceStorageAccountName
}

resource targetStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: targetStorageAccountName
}

resource flexFunctionPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: FunctionPlanName
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

resource flexFunctionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: flexFunctionPlan.id
    httpsOnly: true
    virtualNetworkSubnetId: integrationSubnetId
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${sourceStorageAccount.properties.primaryEndpoints.blob}${functionContainerName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 100
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'python'
        version: '3.11'
      }
    }
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      AzureWebJobsStorage__accountName: sourceStorageAccount.name
      AzureWebJobsStorage__credential : 'managedidentity'
      SOURCE_STORAGE_ACCOUNT_NAME: sourceStorageAccount.name
      TARGET_STORAGE_ACCOUNT_NAME: targetStorageAccount.name
    }
  }
}

resource sourceStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(sourceStorageAccount.id, flexFunctionApp.id, 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  scope: sourceStorageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
    principalId: flexFunctionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource targetStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(targetStorageAccount.id, flexFunctionApp.id, 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  scope: targetStorageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
    principalId: flexFunctionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
