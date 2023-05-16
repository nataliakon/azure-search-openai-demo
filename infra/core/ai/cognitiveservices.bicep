param name string
param location string = resourceGroup().location
param tags object = {}

param PrivateEndPointSubnetId string = ''
param PrivateDnsZoneResourceGroupId string = ''

param customSubDomainName string = name
param deployments array = []
param kind string = 'OpenAI'
param publicNetworkAccess string = 'Disabled'
param sku object = {
  name: 'S0'
}

@description('Do not modify, used to set unique value for resource deployment.')
param time string = utcNow()

resource account 'Microsoft.CognitiveServices/accounts@2022-10-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2022-10-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
    scaleSettings: deployment.scaleSettings
  }
}]

// private endpoints 

module  cognitive_service_endpoint '../Microsoft.Network/privateEndpoints/main.bicep' = {
  name: 'Deploy-${account.name}-pe-${time}'
  params: {
    tags:tags
    groupIds: [
      'account'
    ]
    name: '${account.name}-pe'
    serviceResourceId: account.id
    subnetResourceId: PrivateEndPointSubnetId
    customNetworkInterfaceName: '${account.name}-pe-nic'
    privateDnsZoneGroup: {
      privateDNSResourceIds: [
        '${PrivateDnsZoneResourceGroupId}'
      ]
    }
  }
}

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
