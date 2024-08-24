param location string = resourceGroup().location
param tags object = {}
param storageAccountName string
param systemTopicName string

resource StorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource systemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: systemTopicName
  location: location
  tags: tags
  properties: {
    source: StorageAccount.id
    topicType: 'microsoft.storage.storageaccounts'
  }
}

output systemTopicName string = systemTopic.name
