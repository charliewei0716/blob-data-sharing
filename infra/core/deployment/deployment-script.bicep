
param location string
param tags object = {}
param deploymentScriptName string
param userAssignedIdentityID string
param resourceGroupName string
param functionAppName string


resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: deploymentScriptName
  location: location
  tags: tags
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityID}': {}
    }
  }
  properties: {
    azPowerShellVersion: '3.0'
    arguments: '-resourceGroupName ${resourceGroupName} -functionAppName ${functionAppName}'
    scriptContent: '''
      param ([string]$resourceGroupName, [string]$functionAppName)
      
      Invoke-RestMethod -Uri 'https://github.com/charliewei0716/blob-data-sharing/raw/main/src/placeholder.zip' -OutFile 'placeholder.zip'
      Publish-AzWebapp -ResourceGroupName $resourceGroupName -Name $functionAppName -ArchivePath 'placeholder.zip' -Force
    '''
    retentionInterval: 'PT1H'
  }
}
