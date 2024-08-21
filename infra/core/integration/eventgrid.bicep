param location string = resourceGroup().location
param tags object = {}
param storageAccountName string
param systemTopicName string
param functionAppName string

resource StorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource systemTopics 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: systemTopicName
  location: location
  tags: tags
  properties: {
    source: StorageAccount.id
    topicType: 'microsoft.storage.storageaccounts'
  }
}

resource eventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  parent: systemTopics
  name: 'BlobCreated'
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: 'https://${functionAppName}.azurewebsites.net/runtime/webhooks/EventGrid?functionName=blob_sharing'
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    filter: {
      subjectBeginsWith: '/blobServices/default/containers/source'
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
}

