param name string
param location string = resourceGroup().location
param tags object = {}

param sku object = {
  name: 'standard'
}

param authOptions object = {}
param semanticSearch string = 'disabled'

param PrivateEndPointSubnetId string = ''
param PrivateDnsZoneResourceGroupId string = ''

@description('Do not modify, used to set unique value for resource deployment.')
param time string = utcNow()


resource search 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    authOptions: authOptions
    disableLocalAuth: false
    disabledDataExfiltrationOptions: []
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    hostingMode: 'default'
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
    partitionCount: 1
    publicNetworkAccess: 'Disabled'
    replicaCount: 1
    semanticSearch: semanticSearch
  }
  sku: sku
}


// private endpoints 

module  cognitive_service_endpoint '../Microsoft.Network/privateEndpoints/main.bicep' = {
  name: 'Deploy-${search.name}-pe-${name}-${time}'
  params: {
    tags:tags
    groupIds: [
      'searchService'
    ]
    name: '${search.name}-pe'
    serviceResourceId: search.id
    subnetResourceId: PrivateEndPointSubnetId
    customNetworkInterfaceName: '${search.name}-pe-nic'
    privateDnsZoneGroup: {
      privateDNSResourceIds: [
        '${PrivateDnsZoneResourceGroupId}'
      ]
    }
  }
}
output id string = search.id
output endpoint string = 'https://${name}.search.windows.net/'
output name string = search.name
