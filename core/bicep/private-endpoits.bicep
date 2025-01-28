@description('The name of the virtual network')
param virtualNetworkName string

@description('Location for resources')
param location string

@description('Private DNS zone names')
param dnsZoneNames array

@description('Private endpoints configuration')
param privateEndpoints array


// Lookup Virtual Network resource
resource r_virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: virtualNetworkName
}

resource r_privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zoneName in dnsZoneNames: {
  name: zoneName
  location: 'global'
}]

resource r_privateEndpoints 'Microsoft.Network/privateEndpoints@2023-05-01' = [for endpoint in privateEndpoints: {
  name: endpoint.name
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, endpoint.subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: endpoint.privateLinkServiceConnectionName
        properties: {
          privateLinkServiceId: endpoint.privateLinkServiceId
          groupIds: endpoint.groupIds
          requestMessage: 'Auto-approved private endpoint connection'
        }
      }
    ]
  }
}]

resource r_dnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zoneName, i) in dnsZoneNames: {
  name: '${zoneName}-${virtualNetworkName}-link'
  location: 'global'
  parent: r_privateDnsZones[i]
  properties: {
    virtualNetwork: {
      id: r_virtualNetwork.id
    }
    registrationEnabled: false
  }
}]
