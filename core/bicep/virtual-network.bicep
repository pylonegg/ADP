param virtualNetworkName string
param subnetName string
param vNetIPAddressPrefixes array
param subnetIPAddressPrefix string
param ctrlDeployVirtualNetwork string


resource r_virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name:virtualNetworkName
  location: resourceGroup().location
  properties:{
    addressSpace:{
      addressPrefixes: vNetIPAddressPrefixes
    }
  }
}

resource r_subNet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: subnetName
  parent: r_virtualNetwork
  properties: {
    addressPrefix: subnetIPAddressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies:'Enabled'
  }
}


var vNetID = ctrlDeployVirtualNetwork == 'new' ? r_virtualNetwork.id : resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Network/virtualNetworks',virtualNetworkName)
var subnetID = ctrlDeployVirtualNetwork == 'new' ? r_subNet.id : '${vNetID}/subnets/${subnetName}'
output vNetID string = vNetID
output subnetID string = subnetID
