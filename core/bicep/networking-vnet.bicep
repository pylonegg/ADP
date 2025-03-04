param virtualNetwork_name         string
param NSG_name                    string = replace(virtualNetwork_name,'-vnet','-nsg')

@description('CIDR range for the vnet.')
param virtualNetwork_cidr string

@description('CIDR range for the private subnet.')
param privateSubnet_cidr string

@description('CIDR range for the public subnet.')
param publicSubnet_cidr string

@description('CIDR range for the private endpoint subnet..')
param privateEndpointSubnet_cidr string

@description('Generate resource name for UDR table')
var routeTable_name = replace(virtualNetwork_name,'-vnet','-default-udr-table')

// Service Endpoints
var serviceEndpoints = [
  {
    service: 'Microsoft.Storage'
    locations: [resourceGroup().location]
  }
  {
    service: 'Microsoft.Sql'
    locations: [resourceGroup().location]
  }
  {
    service: 'Microsoft.KeyVault'
    locations: ['*']
  }
]


// Virtual Network ---------------------------------------------------------
resource VirtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: virtualNetwork_name
  location: resourceGroup().location
  tags: resourceGroup().tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_cidr
      ]
    }
    subnets: [
      {
        name: 'public-subnet'
        properties: {
          addressPrefix: publicSubnet_cidr
          networkSecurityGroup: {
            id: NSG.id
          }
          routeTable: {
            id: RouteTable.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: serviceEndpoints
          delegations: [
            {
              name: 'Microsoft.Databricks.workspaces'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: 'private-subnet'
        properties: {
          addressPrefix: privateSubnet_cidr
          networkSecurityGroup: {
            id: NSG.id
          }
          routeTable: {
            id: RouteTable.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: serviceEndpoints
          delegations: [
            {
              name: 'Microsoft.Databricks.workspaces'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: privateEndpointSubnet_cidr
          routeTable: {
            id: RouteTable.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: serviceEndpoints
        }
      }
    ]
  }
}



// RouteTable ---------------------------------------------------------
resource RouteTable 'Microsoft.Network/routeTables@2021-08-01' = {
  name: routeTable_name
  location: resourceGroup().location
  tags: resourceGroup().tags
  properties: {
    disableBgpRoutePropagation: true
  }
}

resource Route1 'Microsoft.Network/routeTables/routes@2021-08-01' = {
  parent: RouteTable
  name: 'Az1_p_az1-central-vnet'
  properties: {
    addressPrefix: '10.21.0.0/19'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.21.1.4'
  }
}

resource Route2 'Microsoft.Network/routeTables/routes@2021-08-01' = {
  parent: RouteTable
  name: 'p-az1-cent-fw01'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.21.1.4'
  }
}


// NSG ---------------------------------------------------------
resource NSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: NSG_name
  location: resourceGroup().location
  tags: resourceGroup().tags
  properties: {
    securityRules: [
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp'
        properties: {
          description: 'Required for workers communication with Databricks control plane.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: ['443', '3306', '8443-8451']
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDatabricks'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
        properties: {
          description: 'Required for workers communication with Azure SQL services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
        properties: {
          description: 'Required for workers communication with Azure Storage services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 103
          direction: 'Outbound'
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
        properties: {
          description: 'Required for worker communication with Azure Eventhub services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9093'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 104
          direction: 'Outbound'
        }
      }
    ]
  }
}
