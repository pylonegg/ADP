@description('Specifies whether to deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP) enabled or not')
param disablePublicIp bool = true

@description('Databricks workspace name.')
param workspaceName string

@description('The pricing tier of workspace.')
@allowed([
  'standard'
  'premium'
])
param pricingTier string = 'premium'

@description('Public Network Access.')
param publicNetworkAccess string = 'Enabled'

@description('The name of the network security group to create.')
param Dbks_NSG_Name string

@description('The name of the virtual network to create.')
param vnetNameDbks string

@description('Indicates whether to retain or remove the AzureDatabricks outbound NSG rule - possible values are AllRules or NoAzureDatabricksRules.')
@allowed([
  'AllRules'
  'NoAzureDatabricksRules'
])
param requiredNsgRules string = 'AllRules'

@description('CIDR range for the vnet.')
param vnetCidr string

@description('CIDR range for the private subnet.')
param privateSubnetCidr string

@description('CIDR range for the public subnet.')
param publicSubnetCidr string

@description('CIDR range for the private endpoint subnet..')
param privateEndpointSubnetCidr string

@description('The name of the public subnet to create.')
param publicSubnetName string = 'public-subnet'

@description('The name of the private subnet to create.')
param privateSubnetName string = 'private-subnet'

@description('The name of the subnet to create the private endpoint in.')
param PrivateEndpointSubnetName string = 'default'

@description('Location.')
param location string = resourceGroup().location


// Variables
var managedResourceGroupName = 'databricks-rg-${workspaceName}-${uniqueString(workspaceName, resourceGroup().id)}'
var trimmedMRGName = substring(managedResourceGroupName, 0, min(length(managedResourceGroupName), 90))
var managedResourceGroupId = '${subscription().id}/resourceGroups/${trimmedMRGName}'


// DataBricks NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: Dbks_NSG_Name
  location: location
  properties: {
    securityRules: [
    ]
  }
}

// DataBricks vNet
resource vnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vnetNameDbks
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
    subnets: [
      {
        name: publicSubnetName
        properties: {
          addressPrefix: publicSubnetCidr
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: [
            {
              name: 'databricks-del-public'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: privateSubnetName
        properties: {
          addressPrefix: privateSubnetCidr
          networkSecurityGroup: {
            id: nsg.id
          }
          delegations: [
            {
              name: 'databricks-del-private'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
        }
      }
      {
        name: PrivateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetCidr
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}


// DataBricks Workspace
resource Workspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: workspaceName
  location: location
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      customVirtualNetworkId: {
        value: vnet.id
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
      enableNoPublicIp: {
        value: disablePublicIp
      }
    }
    publicNetworkAccess: publicNetworkAccess
    requiredNsgRules: requiredNsgRules
  }
}

// Outputs
output workspace object = Workspace
output workspace_name_id string = Workspace.id
output workspace_name string = workspaceName
output DBKS_vnet_name string = vnetNameDbks
