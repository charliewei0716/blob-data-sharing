param location string = resourceGroup().location
param tags object = {}
param sourceStorageAccountName string
param targetStorageAccountName string
param FunctionPlanName string
param functionAppName string
param identityId string
param identityClientId string
param principalID string
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
  tags: union(tags, { 'azd-service-name': 'blob-sharing-func' })
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { 
      '${identityId}': {}
    }
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
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: identityId
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
      AzureWebJobsStorage__clientId: identityClientId
      AzureWebJobsStorage__credential : 'managedidentity'
      SOURCE_STORAGE_ACCOUNT_NAME: sourceStorageAccount.name
      TARGET_STORAGE_ACCOUNT_NAME: targetStorageAccount.name
    }
  }
}

resource sourceStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(sourceStorageAccount.id, principalID, 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  scope: sourceStorageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
    principalId: principalID
    principalType: 'ServicePrincipal'
  }
}

resource targetStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(targetStorageAccount.id, principalID, 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  scope: targetStorageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
    principalId: principalID
    principalType: 'ServicePrincipal'
  }
}

//output key object = listkeys(concat(resourceId('Microsoft.Web/sites', flexFunctionApp), '/host/default/'),'2021-02-01').
