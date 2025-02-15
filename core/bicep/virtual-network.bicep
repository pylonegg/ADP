param virtualNetwork_name string
param subnet_name string
param vnetAddress_prefix string = '10.0.0.0/16'
param subnetAddress_prefix string = '10.0.1.0/24'


resource VirtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name:virtualNetwork_name
  location: resourceGroup().location
  properties:{
    addressSpace:{
      addressPrefixes: [
        vnetAddress_prefix
      ]
    }
  }
}

resource SubNet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: subnet_name
  parent: VirtualNetwork
  properties: {
    addressPrefix: subnetAddress_prefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies:'Disabled'
  }
}


output vNetID string = VirtualNetwork.id
output subnetID string = SubNet.id
