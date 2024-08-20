param location string = resourceGroup().location
param tags object = {}
param vnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'integration'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }

  resource integrationSubnet 'subnets' existing = {
    name: 'integration'
  }
}

output integrationSubnetId string = virtualNetwork::integrationSubnet.id
