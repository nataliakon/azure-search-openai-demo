param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([ 'Hot', 'Cool', 'Premium' ])
param accessTier string = 'Hot'
param allowBlobPublicAccess bool = false
param allowCrossTenantReplication bool = true
param allowSharedKeyAccess bool = true
param defaultToOAuthAuthentication bool = false
param deleteRetentionPolicy object = {}
@allowed([ 'AzureDnsZone', 'Standard' ])
param dnsEndpointType string = 'Standard'
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Disabled'
param sku object = { name: 'Standard_LRS' }

param containers array = []

param PrivateEndPointSubnetId string = ''
param PrivateDnsZoneResourceGroupId string = ''

@description('Do not modify, used to set unique value for resource deployment.')
param time string = utcNow()

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    dnsEndpointType: dnsEndpointType
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    publicNetworkAccess: publicNetworkAccess
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    properties: {
      deleteRetentionPolicy: deleteRetentionPolicy
    }
    resource container 'containers' = [for container in containers: {
      name: container.name
      properties: {
        publicAccess: contains(container, 'publicAccess') ? container.publicAccess : 'None'
      }
    }]
  }
}

// private endpoints

module blob_storage_endpoint '../Microsoft.Network/privateEndpoints/main.bicep' = {
  name: 'Deploy-blob-pe-${name}-${time}'
  params: {
    tags:tags
    groupIds: [
      'blob'
    ]
    name: '${storage.name}-pe'
    serviceResourceId: storage.id
    subnetResourceId: PrivateEndPointSubnetId
    customNetworkInterfaceName: '${storage.name}-pe-nic'
    privateDnsZoneGroup: {
      privateDNSResourceIds: [
        '${PrivateDnsZoneResourceGroupId}privatelink.blob.${environment().suffixes.storage}'
      ]
    }
  }
}

output name string = storage.name
output primaryEndpoints object = storage.properties.primaryEndpoints
